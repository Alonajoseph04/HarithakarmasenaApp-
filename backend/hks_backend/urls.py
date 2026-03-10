from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('hks_users.urls')),
    path('api/wards/', include('hks_wards.urls')),
    path('api/workers/', include('hks_workers.urls')),
    path('api/households/', include('hks_households.urls')),
    path('api/collections/', include('hks_collections.urls')),
    path('api/notifications/', include('hks_notifications.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
