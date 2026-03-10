from django.contrib import admin
from .models import Collection

@admin.register(Collection)
class CollectionAdmin(admin.ModelAdmin):
    list_display = ['household', 'worker', 'date', 'waste_type', 'weight', 'amount', 'payment_method', 'payment_status']
    list_filter = ['waste_type', 'payment_method', 'payment_status', 'date']
    search_fields = ['household__name', 'worker__worker_id']
    date_hierarchy = 'date'
