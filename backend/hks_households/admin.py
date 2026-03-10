from django.contrib import admin
from .models import Household

@admin.register(Household)
class HouseholdAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'ward', 'qr_code', 'is_active']
    list_filter = ['ward', 'is_active']
    search_fields = ['name', 'phone', 'address']
    readonly_fields = ['qr_code']
