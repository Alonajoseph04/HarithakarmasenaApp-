from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
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

        from datetime import date
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
        default_msg = f'{worker_name} is starting waste collection in {ward.name} today. Please keep your waste ready.'
        message = request.data.get('message', default_msg)

        households = Household.objects.filter(ward=ward, is_active=True).select_related('user')
        count = 0
        for hh in households:
            if hh.user:
                Notification.objects.create(
                    recipient=hh.user,
                    title=f'Collection Starting - {ward.name}',
                    message=message,
                    notification_type='reminder'
                )
                count += 1

        return Response({
            'success': True,
            'notified': count,
            'ward': ward.name,
        })

    @action(detail=False, methods=['get'], url_path='skip_requests')
    def skip_requests(self, request):
        """Worker sees pending skip requests for their ward."""
        try:
            worker = Worker.objects.get(user=request.user)
        except Worker.DoesNotExist:
            return Response({'error': 'Worker profile not found'}, status=404)

        from hks_collections.models import SkipRequest
        from hks_collections.serializers import SkipRequestSerializer
        qs = SkipRequest.objects.filter(household__ward=worker.ward, status='pending').select_related('household')
        return Response(SkipRequestSerializer(qs, many=True).data)

