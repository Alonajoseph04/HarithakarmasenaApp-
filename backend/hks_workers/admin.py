from django.contrib import admin
from .models import Worker

@admin.register(Worker)
class WorkerAdmin(admin.ModelAdmin):
    list_display = ['worker_id', 'user', 'ward', 'is_active', 'created_at']
    list_filter = ['ward', 'is_active']
    search_fields = ['worker_id', 'user__first_name', 'user__last_name']
