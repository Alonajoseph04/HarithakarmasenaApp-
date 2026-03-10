from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CollectionViewSet, SkipRequestViewSet, ExtraPickupRequestViewSet

router = DefaultRouter()
router.register(r'', CollectionViewSet, basename='collection')
router.register(r'skip-requests', SkipRequestViewSet, basename='skip-request')
router.register(r'extra-pickup', ExtraPickupRequestViewSet, basename='extra-pickup')

urlpatterns = [path('', include(router.urls))]
