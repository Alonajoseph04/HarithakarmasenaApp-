from django.contrib import admin
from .models import HKSUser

@admin.register(HKSUser)
class HKSUserAdmin(admin.ModelAdmin):
    list_display = ['username', 'role', 'phone', 'first_name', 'last_name', 'is_active']
    list_filter = ['role', 'is_active']
    search_fields = ['username', 'phone', 'first_name', 'last_name']
