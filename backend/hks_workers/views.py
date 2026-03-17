from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from datetime import date
from .models import Worker
from .serializers import WorkerSerializer
from hks_wards.models import Ward

class WorkerViewSet(viewsets.ModelViewSet):
    queryset = Worker.objects.select_related('user', 'ward').all()
    serializer_class = WorkerSerializer
    permission_classes = [IsAuthenticated]
    search_fields = ['worker_id', 'user__first_name', 'user__last_name']
    filterset_fields = ['ward', 'is_active']

    @action(detail=True, methods=['post'])
    def change_password(self, request, pk=None):
        worker = self.get_object()
        new_password = request.data.get('new_password')
        if not new_password:
            return Response({'error': 'New password required'}, status=status.HTTP_400_BAD_REQUEST)
        worker.user.set_password(new_password)
        worker.user.save()
        return Response({'message': 'Password updated successfully'})

    @action(detail=False, methods=['get'])
    def me(self, request):
        try:
            worker = Worker.objects.get(user=request.user)
            return Response(WorkerSerializer(worker).data)
        except Worker.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['get'])
    def ward_progress(self, request):
        ward_id = request.query_params.get('ward_id')
        filter_date = request.query_params.get('date') or str(date.today())
        try:
            ward = Ward.objects.get(id=ward_id)
        except Ward.DoesNotExist:
            return Response({'error': 'Ward not found'}, status=status.HTTP_404_NOT_FOUND)

        from hks_collections.models import Collection
        qs = Collection.objects.filter(worker__ward=ward, date=filter_date)

        visited_ids = qs.values_list('household_id', flat=True).distinct()
        total_houses = ward.households.filter(is_active=True).count()
        visited = len(set(visited_ids))
        remaining = max(0, total_houses - visited)
        expected_amount = sum(h.monthly_fee for h in ward.households.filter(is_active=True))

        return Response({
            'ward': {'id': ward.id, 'name': ward.name},
            'total_houses': total_houses,
            'visited': visited,
            'remaining': remaining,
            'expected_amount': float(expected_amount),
            'date': filter_date,
        })

    @action(detail=False, methods=['get'], url_path='worker_coverage')
    def worker_coverage(self, request):
        """Returns covered and pending houses for a specific worker in a ward.
        Query params: worker_id (pk), ward_id, status=covered|pending|all, date (optional)"""
        from hks_collections.models import Collection
        from hks_households.models import Household

        worker_pk = request.query_params.get('worker_id')
        ward_id   = request.query_params.get('ward_id')
        filter_status = request.query_params.get('status', 'all')  # covered | pending | all
        filter_date   = request.query_params.get('date') or str(date.today())

        if not ward_id:
            return Response({'error': 'ward_id is required'}, status=400)

        try:
            ward = Ward.objects.get(id=ward_id)
        except Ward.DoesNotExist:
            return Response({'error': 'Ward not found'}, status=404)

        all_households = Household.objects.filter(ward=ward, is_active=True).select_related('ward')

        # Determine which households have been collected on the given date (by any worker, or specific worker)
        collection_qs = Collection.objects.filter(
            household__ward=ward,
            date=filter_date,
        )
        if worker_pk:
            collection_qs = collection_qs.filter(worker_id=worker_pk)

        covered_ids = set(collection_qs.values_list('household_id', flat=True).distinct())

        results = []
        for hh in all_households:
            is_covered = hh.id in covered_ids
            if filter_status == 'covered' and not is_covered:
                continue
            if filter_status == 'pending' and is_covered:
                continue
            results.append({
                'id': hh.id,
                'name': hh.name,
                'address': hh.address,
                'phone': hh.phone,
                'monthly_fee': float(hh.monthly_fee),
                'status': 'covered' if is_covered else 'pending',
                'ward': {'id': ward.id, 'name': ward.name},
            })

        # Sort: covered first, then by name
        results.sort(key=lambda x: (0 if x['status'] == 'covered' else 1, x['name']))

        worker_info = None
        if worker_pk:
            try:
                w = Worker.objects.select_related('user').get(pk=worker_pk)
                worker_info = {
                    'id': w.id,
                    'worker_id': w.worker_id,
                    'name': w.user.get_full_name(),
                }
            except Worker.DoesNotExist:
                pass

        return Response({
            'worker': worker_info,
            'ward': {'id': ward.id, 'name': ward.name},
            'date': filter_date,
            'total': len(all_households),
            'covered': sum(1 for r in results if r['status'] == 'covered'),
            'pending': sum(1 for r in results if r['status'] == 'pending'),
            'households': results,
        })


    @action(detail=False, methods=['post'], url_path='notify_ward')
    def notify_ward(self, request):
        """Worker sends a notification to households in a ward that collection is starting.
        Accepts optional ward_id in the request body; falls back to worker's assigned ward."""
        from hks_households.models import Household
        from hks_notifications.models import Notification

        # Try to get worker profile (non-fatal if missing)
        worker = None
        try:
            worker = Worker.objects.get(user=request.user)
        except Worker.DoesNotExist:
            pass

        # Determine which ward to notify
        ward_id = request.data.get('ward_id')
        if ward_id:
            try:
                ward = Ward.objects.get(id=ward_id)
            except Ward.DoesNotExist:
                return Response({'error': f'Ward {ward_id} not found'}, status=404)
        elif worker and worker.ward:
            ward = worker.ward
        else:
            return Response(
                {'error': 'No ward specified. Please select a ward and try again.'},
                status=400
            )

        worker_name = worker.user.get_full_name() if worker else request.user.get_full_name()

        # Use scheduled_date from request if provided, otherwise default to 'today'
        scheduled_date = request.data.get('scheduled_date', '')
        if scheduled_date:
            try:
                from datetime import datetime
                parsed = datetime.strptime(scheduled_date, '%Y-%m-%d')
                date_display = parsed.strftime('%d/%m/%Y')
            except ValueError:
                date_display = scheduled_date
        else:
            date_display = 'today'

        default_msg = (
            f'{worker_name} will be collecting waste in {ward.name} on {date_display}. '
            f'Please keep your waste ready.'
        )
        default_msg_ml = (
            f'{worker_name} {date_display}-ൽ {ward.name}-ൽ മാലിന്യം ശേഖരിക്കും. '
            f'ദയവായി മാലിന്യം തയ്യാറാക്കൂ.'
        )
        message = request.data.get('message', default_msg)

        from hks_users.models import HKSUser

        households = Household.objects.filter(ward=ward, is_active=True).select_related('user')
        total_in_ward = households.count()
        notified_app = 0
        for hh in households:
            recipient = hh.user

            # If not linked via FK, try to find the app user by phone
            if recipient is None and hh.phone:
                try:
                    recipient = HKSUser.objects.get(phone=hh.phone, role='household')
                    # Auto-link for future (skip if user already linked to another household)
                    if not hh.user:
                        try:
                            hh.user = recipient
                            hh.save(update_fields=['user'])
                        except Exception:
                            pass  # IntegrityError — user already linked elsewhere
                except HKSUser.DoesNotExist:
                    pass

            if recipient:
                Notification.objects.create(
                    recipient=recipient,
                    title=f'Collection on {date_display} — {ward.name}',
                    message=message,
                    message_ml=default_msg_ml,
                    notification_type='reminder'
                )
                notified_app += 1

        return Response({
            'success': True,
            'notified': total_in_ward,         # total households in ward
            'notified_app': notified_app,       # those with app accounts (received in-app notification)
            'ward': ward.name,
        })

    @action(detail=False, methods=['get'], url_path='skip_requests')
    def skip_requests(self, request):
        """Worker sees skip requests for their ward.
        Falls back to ?ward_id= query param if worker profile not linked."""
        from hks_collections.models import SkipRequest
        from hks_collections.serializers import SkipRequestSerializer

        ward = None

        # Try to get ward from worker profile first
        try:
            worker = Worker.objects.get(user=request.user)
            ward = worker.ward
        except Worker.DoesNotExist:
            pass

        # Fall back to ward_id query param (for admins or unlinked workers)
        if ward is None:
            ward_id = request.query_params.get('ward_id')
            if ward_id:
                try:
                    ward = Ward.objects.get(id=ward_id)
                except Ward.DoesNotExist:
                    return Response({'error': f'Ward {ward_id} not found'}, status=404)

        if ward is None:
            return Response(
                {'error': 'Worker profile not linked to a ward. '
                          'Please ask admin to assign you to a ward, '
                          'or pass ?ward_id= as a query parameter.'},
                status=400
            )

        # Return all skip requests for the ward (pending + acknowledged), last 30 days
        from datetime import timedelta
        thirty_days_ago = date.today() - timedelta(days=30)
        qs = (SkipRequest.objects
              .filter(household__ward=ward, date__gte=thirty_days_ago)
              .select_related('household')
              .order_by('status', '-date'))  # pending first, then by date
        return Response(SkipRequestSerializer(qs, many=True).data)

