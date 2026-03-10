from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Ward
from .serializers import WardSerializer

class WardViewSet(viewsets.ModelViewSet):
    queryset = Ward.objects.all()
    serializer_class = WardSerializer
    permission_classes = [IsAuthenticated]
    search_fields = ['name']
    ordering_fields = ['name', 'total_houses']
