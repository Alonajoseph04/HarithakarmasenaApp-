from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Q, Avg
from django.utils import timezone
from datetime import timedelta, date
from .models import Collection, SkipRequest, ExtraPickupRequest, RATING_LABELS, RATING_LABELS_ML
from .serializers import (
    CollectionSerializer, CollectionCreateSerializer,
    SkipRequestSerializer, ExtraPickupRequestSerializer
)
from hks_notifications.models import Notification


def _notify(recipient, title, message, message_ml='', ntype='general'):
    """Helper to create bilingual notifications."""
    Notification.objects.create(
        recipient=recipient,
        title=title,
        message=message,
        message_ml=message_ml or message,
        notification_type=ntype
    )


class CollectionViewSet(viewsets.ModelViewSet):
    queryset = Collection.objects.select_related('household', 'worker').all()
    permission_classes = [IsAuthenticated]
    filterset_fields = ['worker', 'household', 'date', 'payment_method', 'payment_status', 'waste_type']
    search_fields = ['household__name', 'worker__worker_id']
    ordering_fields = ['date', 'amount', 'weight']

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return CollectionCreateSerializer
        return CollectionSerializer

    def perform_create(self, serializer):
        collection = serializer.save()
        household = collection.household
        if household.user:
            _notify(
                household.user,
                'Waste Collection Confirmed',
                (f'Your waste was collected on {collection.date}. '
                 f'Type: {collection.get_waste_type_display()}, '
                 f'Weight: {collection.weight}kg, '
                 f'Amount: Rs{collection.amount}, '
                 f'Payment: {collection.get_payment_method_display()}'),
                message_ml=(f'നിങ്ങളുടെ മാലിന്യം {collection.date}-ൽ ശേഖരിച്ചു. '
                            f'തരം: {collection.get_waste_type_display()}, '
                            f'ഭാരം: {collection.weight}kg, '
                            f'തുക: Rs{collection.amount}'),
                ntype='collection'
            )

    @action(detail=True, methods=['patch'], url_path='rate_worker')
    def rate_worker(self, request, pk=None):
        """Household submits structured feedback for the worker."""
        collection = self.get_object()
        overall     = request.data.get('worker_rating')
        punctuality = request.data.get('feedback_punctuality')
        cleanliness = request.data.get('feedback_cleanliness')
        attitude    = request.data.get('feedback_attitude')
        feedback    = request.data.get('worker_feedback', '')

        # Validate overall rating (1–4)
        if overall is None or not (1 <= int(overall) <= 4):
            return Response({'error': 'Overall rating must be 1–4'}, status=400)

        collection.worker_rating      = int(overall)
        collection.feedback_punctuality = int(punctuality) if punctuality else None
        collection.feedback_cleanliness = int(cleanliness) if cleanliness else None
        collection.feedback_attitude    = int(attitude)    if attitude    else None
        collection.worker_feedback      = feedback
        collection.save()

        # Build bilingual feedback summary for the worker notification
        label_en = RATING_LABELS.get(int(overall), '')
        label_ml = RATING_LABELS_ML.get(int(overall), '')
        _notify(
            collection.worker.user,
            'You received a rating',
            (f'Household {collection.household.name} rated your service: '
             f'Overall: {label_en}. '
             f'Punctuality: {RATING_LABELS.get(int(punctuality), "-") if punctuality else "-"}, '
             f'Cleanliness: {RATING_LABELS.get(int(cleanliness), "-") if cleanliness else "-"}, '
             f'Attitude: {RATING_LABELS.get(int(attitude), "-") if attitude else "-"}. '
             f'{feedback}'),
            message_ml=(f'{collection.household.name} നിങ്ങളുടെ സേവനം വിലയിരുത്തി: '
                        f'മൊത്തം: {label_ml}. '
                        f'കൃത്യനിഷ്ഠ: {RATING_LABELS_ML.get(int(punctuality), "-") if punctuality else "-"}, '
                        f'വൃത്തി: {RATING_LABELS_ML.get(int(cleanliness), "-") if cleanliness else "-"}, '
                        f'മനോഭാവം: {RATING_LABELS_ML.get(int(attitude), "-") if attitude else "-"}. '
                        f'{feedback}'),
            ntype='feedback'
        )
        return Response({'success': True, 'worker_rating': overall})

    @action(detail=False, methods=['get'])
    def stats(self, request):
        worker_id = request.query_params.get('worker_id')
        period = request.query_params.get('period', 'today')

        qs = Collection.objects.all()
        if worker_id:
            qs = qs.filter(worker_id=worker_id)

        today = date.today()
        if period == 'today':
            qs = qs.filter(date=today)
        elif period == 'week':
            start = today - timedelta(days=today.weekday())
            qs = qs.filter(date__gte=start)
        elif period == 'month':
            qs = qs.filter(date__year=today.year, date__month=today.month)
        elif period == 'year':
            qs = qs.filter(date__year=today.year)

        agg = qs.aggregate(
            total_weight=Sum('weight'),
            total_amount=Sum('amount'),
            total_collections=Count('id'),
            avg_rating=Avg('worker_rating'),
        )
        households_visited = qs.values('household').distinct().count()
        waste_breakdown = list(qs.values('waste_type').annotate(count=Count('id'), weight=Sum('weight')))

        return Response({
            'period': period,
            'total_collections': agg['total_collections'] or 0,
            'total_weight': float(agg['total_weight'] or 0),
            'total_amount': float(agg['total_amount'] or 0),
            'households_visited': households_visited,
            'avg_rating': round(float(agg['avg_rating'] or 0), 1),
            'waste_breakdown': waste_breakdown,
        })

    @action(detail=False, methods=['get'])
    def admin_summary(self, request):
        from hks_workers.models import Worker
        from hks_households.models import Household
        from hks_wards.models import Ward

        total_qs = Collection.objects.all()
        total_weight = total_qs.aggregate(w=Sum('weight'))['w'] or 0
        total_amount = total_qs.aggregate(a=Sum('amount'))['a'] or 0

        monthly_data = []
        for i in range(5, -1, -1):
            d = date.today().replace(day=1) - timedelta(days=i*30)
            m = date(d.year, d.month, 1)
            mq = total_qs.filter(date__year=m.year, date__month=m.month)
            monthly_data.append({
                'month': m.strftime('%b %Y'),
                'weight': float(mq.aggregate(w=Sum('weight'))['w'] or 0),
                'amount': float(mq.aggregate(a=Sum('amount'))['a'] or 0),
                'count': mq.count()
            })

        return Response({
            'total_workers': Worker.objects.filter(is_active=True).count(),
            'total_households': Household.objects.filter(is_active=True).count(),
            'total_wards': Ward.objects.count(),
            'total_weight': float(total_weight),
            'total_amount': float(total_amount),
            'total_collections': total_qs.count(),
            'monthly_data': monthly_data,
        })


class SkipRequestViewSet(viewsets.ModelViewSet):
    """Household notifies worker they don't need collection on a specific date."""
    serializer_class = SkipRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'household':
            from django.db.models import Q
            # Match by FK (if linked) OR by phone (for unlinked accounts)
            q = Q(household__user=user)
            if user.phone:
                q |= Q(household__phone=user.phone)
            return SkipRequest.objects.filter(q).distinct()
        elif user.role == 'worker':
            try:
                from hks_workers.models import Worker
                worker = Worker.objects.get(user=user)
                return SkipRequest.objects.filter(household__ward=worker.ward)
            except Exception:
                return SkipRequest.objects.none()
        return SkipRequest.objects.all()

    def perform_create(self, serializer):
        from hks_households.models import Household
        from rest_framework.exceptions import ValidationError

        household = None
        user = self.request.user

        # Strategy 1: linked via OneToOne FK (household.user)
        try:
            household = Household.objects.get(user=user)
        except Household.DoesNotExist:
            pass

        # Strategy 2: linked by matching phone number (how the `me` endpoint works)
        if household is None and user.phone:
            try:
                household = Household.objects.get(phone=user.phone)
                # Auto-link the user FK for future requests
                if not household.user:
                    household.user = user
                    household.save(update_fields=['user'])
            except Household.DoesNotExist:
                pass

        if household is None:
            raise ValidationError(
                'No household profile is linked to your account. '
                'Please contact admin to link your account.'
            )

        skip = serializer.save(household=household)
        from hks_workers.models import Worker
        ward_workers = Worker.objects.filter(ward=household.ward, is_active=True)
        for w in ward_workers:
            _notify(
                w.user,
                'Collection Skip Request',
                (f'{household.name} has requested to skip collection on {skip.date}. '
                 f'Reason: {skip.reason or "No reason given"}.'),
                message_ml=(f'{household.name} {skip.date}-ൽ ശേഖരണം ഒഴിവാക്കാൻ അഭ്യർത്ഥിച്ചു. '
                            f'കാരണം: {skip.reason or "കാരണം നൽകിയിട്ടില്ല"}.'),
                ntype='reminder'
            )

    @action(detail=True, methods=['patch'])
    def acknowledge(self, request, pk=None):
        skip = self.get_object()
        skip.status = 'acknowledged'
        skip.acknowledged_at = timezone.now()
        skip.save()
        # Notify household — try FK first, then phone
        recipient = skip.household.user
        if recipient is None and skip.household.phone:
            from hks_users.models import HKSUser
            try:
                recipient = HKSUser.objects.get(phone=skip.household.phone, role='household')
                skip.household.user = recipient
                skip.household.save(update_fields=['user'])
            except HKSUser.DoesNotExist:
                pass
        if recipient:
            _notify(
                recipient,
                'Skip Request Acknowledged',
                f'Your collection skip for {skip.date} has been acknowledged.',
                message_ml=f'{skip.date}-ലെ ശേഖരണം ഒഴിവാക്കൽ അംഗീകരിച്ചു.',
                ntype='general'
            )
        return Response({'success': True})


class ExtraPickupRequestViewSet(viewsets.ModelViewSet):
    """Household requests an extra waste type collected on the same day."""
    serializer_class = ExtraPickupRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'household':
            from django.db.models import Q
            # Match by FK (if linked) OR by phone (for unlinked accounts)
            q = Q(household__user=user)
            if user.phone:
                q |= Q(household__phone=user.phone)
            return ExtraPickupRequest.objects.filter(q).distinct()
        elif user.role == 'worker':
            try:
                from hks_workers.models import Worker
                worker = Worker.objects.get(user=user)
                return ExtraPickupRequest.objects.filter(
                    household__ward=worker.ward, date=date.today()
                )
            except Exception:
                return ExtraPickupRequest.objects.none()
        # admin sees all today's
        return ExtraPickupRequest.objects.filter(date=date.today())

    def perform_create(self, serializer):
        from hks_households.models import Household
        from rest_framework.exceptions import ValidationError

        household = None
        user = self.request.user

        # Strategy 1: linked via OneToOne FK
        try:
            household = Household.objects.get(user=user)
        except Household.DoesNotExist:
            pass

        # Strategy 2: match by phone and auto-link
        if household is None and user.phone:
            try:
                household = Household.objects.get(phone=user.phone)
                if not household.user:
                    household.user = user
                    household.save(update_fields=['user'])
            except Household.DoesNotExist:
                pass

        if household is None:
            raise ValidationError(
                'No household profile is linked to your account. '
                'Please contact admin to link your account.'
            )

        req = serializer.save(household=household, date=date.today())

        # Notify ward workers
        from hks_workers.models import Worker
        ward_workers = Worker.objects.filter(ward=household.ward, is_active=True)
        for w in ward_workers:
            _notify(
                w.user,
                'Extra Pickup Request',
                (f'{household.name} is requesting extra pickup of '
                 f'{req.get_waste_type_display()} today. Notes: {req.notes or "None"}'),
                message_ml=(f'{household.name} ഇന്ന് '
                            f'{req.get_waste_type_display()} കൂടുതൽ ശേഖരിക്കാൻ അഭ്യർത്ഥിക്കുന്നു. '
                            f'കുറിപ്പ്: {req.notes or "ഇല്ല"}'),
                ntype='pickup'
            )

    @action(detail=True, methods=['patch'])
    def approve(self, request, pk=None):
        req = self.get_object()
        if req.status != 'pending':
            return Response({'error': 'Already reviewed'}, status=400)
        try:
            worker = request.user.worker_profile
        except Exception:
            return Response({'error': 'Worker profile not found'}, status=400)
        req.status = 'approved'
        req.reviewed_by = worker
        req.reviewed_at = timezone.now()
        req.save()
        if req.household.user:
            _notify(
                req.household.user,
                'Extra Pickup Approved ✓',
                (f'Your request for extra {req.get_waste_type_display()} pickup has been approved! '
                 f'The worker will collect it today.'),
                message_ml=(f'നിങ്ങളുടെ {req.get_waste_type_display()} ശേഖരണ അഭ്യർത്ഥന അനുവദിച്ചു! '
                            f'തൊഴിലാളി ഇന്ന് ശേഖരിക്കും.'),
                ntype='pickup'
            )
        return Response({'success': True, 'status': 'approved'})

    @action(detail=True, methods=['patch'])
    def reject(self, request, pk=None):
        req = self.get_object()
        if req.status != 'pending':
            return Response({'error': 'Already reviewed'}, status=400)
        try:
            worker = request.user.worker_profile
        except Exception:
            return Response({'error': 'Worker profile not found'}, status=400)
        reason = request.data.get('reason', '')
        req.status = 'rejected'
        req.reviewed_by = worker
        req.reviewed_at = timezone.now()
        req.notes = (req.notes + f'\nRejection reason: {reason}').strip() if reason else req.notes
        req.save()
        if req.household.user:
            _notify(
                req.household.user,
                'Extra Pickup Not Possible',
                (f'Your request for extra {req.get_waste_type_display()} pickup could not be accommodated today. '
                 f'{reason}'),
                message_ml=(f'ഇന്ന് {req.get_waste_type_display()} ശേഖരണ അഭ്യർത്ഥന നിരസിച്ചു. '
                            f'{reason}'),
                ntype='pickup'
            )
        return Response({'success': True, 'status': 'rejected'})
