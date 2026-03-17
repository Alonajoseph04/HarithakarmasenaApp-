from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .models import Household
from .serializers import HouseholdSerializer

class HouseholdViewSet(viewsets.ModelViewSet):
    queryset = Household.objects.select_related('ward').all()
    serializer_class = HouseholdSerializer
    permission_classes = [IsAuthenticated]
    search_fields = ['name', 'phone', 'address']
    filterset_fields = ['ward', 'is_active']

    def perform_destroy(self, instance):
        """Also delete the linked HKSUser so they can't log in as a ghost account."""
        user = instance.user
        instance.delete()
        if user is not None:
            user.delete()

    @action(detail=False, methods=['get'])
    def by_qr(self, request):
        qr_code = request.query_params.get('qr_code')
        if not qr_code:
            return Response({'error': 'qr_code parameter required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            household = Household.objects.get(qr_code=qr_code)
            return Response(HouseholdSerializer(household).data)
        except Household.DoesNotExist:
            return Response({'error': 'Household not found'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['get'])
    def by_code(self, request):
        """Forgiving lookup: match qr_code exactly OR household name (case-insensitive).
        Used for manual entry in the worker scanner screen."""
        code = request.query_params.get('code', '').strip()
        if not code:
            return Response({'error': 'code parameter required'}, status=status.HTTP_400_BAD_REQUEST)
        # Try exact QR code first
        qs = Household.objects.filter(
            Q(qr_code__iexact=code) | Q(name__icontains=code)
        ).select_related('ward')
        if not qs.exists():
            return Response({'error': f'No household found matching "{code}"'}, status=status.HTTP_404_NOT_FOUND)
        # If multiple matches (e.g. partial name), return first active one
        household = qs.filter(is_active=True).first() or qs.first()
        return Response(HouseholdSerializer(household).data)

    @action(detail=True, methods=['get'])
    def qr_code_image(self, request, pk=None):
        household = self.get_object()
        return Response({'qr_base64': household.get_qr_base64(), 'qr_code': household.qr_code})

    @action(detail=False, methods=['get'])
    def me(self, request):
        household = None

        # Strategy 1: direct OneToOne FK link (fastest, preferred)
        try:
            household = Household.objects.get(user=request.user)
        except Household.DoesNotExist:
            pass

        # Strategy 2: match by phone number (household registered before app account)
        if household is None and request.user.phone:
            try:
                household = Household.objects.get(phone=request.user.phone)
                # Auto-link for all future requests
                if not household.user:
                    household.user = request.user
                    household.save(update_fields=['user'])
            except Household.DoesNotExist:
                pass

        if household is None:
            return Response({'error': 'Household profile not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response(HouseholdSerializer(household).data)
