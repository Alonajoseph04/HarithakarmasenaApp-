from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CollectionViewSet, SkipRequestViewSet, ExtraPickupRequestViewSet

# Use separate routers so the empty-prefix CollectionViewSet
# doesn't shadow skip-requests/ and extra-pickup/ routes.
skip_router = DefaultRouter()
skip_router.register(r'', SkipRequestViewSet, basename='skip-request')

pickup_router = DefaultRouter()
pickup_router.register(r'', ExtraPickupRequestViewSet, basename='extra-pickup')

collection_router = DefaultRouter()
collection_router.register(r'', CollectionViewSet, basename='collection')

urlpatterns = [
    # Register specific routes FIRST so they match before the catch-all collection routes
    path('skip-requests/', include(skip_router.urls)),
    path('extra-pickup/', include(pickup_router.urls)),
    path('', include(collection_router.urls)),
]
