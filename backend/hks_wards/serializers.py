from rest_framework import serializers
from .models import Ward

class WardSerializer(serializers.ModelSerializer):
    household_count = serializers.SerializerMethodField()
    worker_count = serializers.SerializerMethodField()

    def get_household_count(self, obj):
        return obj.households.filter(is_active=True).count()

    def get_worker_count(self, obj):
        return obj.workers.filter(is_active=True).count()

    class Meta:
        model = Ward
        fields = ['id', 'name', 'total_houses', 'description', 'household_count', 'worker_count', 'created_at']
