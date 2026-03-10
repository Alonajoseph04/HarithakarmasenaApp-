from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WardViewSet

router = DefaultRouter()
router.register(r'', WardViewSet, basename='ward')

urlpatterns = [path('', include(router.urls))]
