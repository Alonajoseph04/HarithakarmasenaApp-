from rest_framework import serializers
from .models import Household
from hks_wards.serializers import WardSerializer

class HouseholdSerializer(serializers.ModelSerializer):
    ward = WardSerializer(read_only=True)
    ward_id = serializers.PrimaryKeyRelatedField(
        queryset=__import__('hks_wards.models', fromlist=['Ward']).Ward.objects.all(),
        source='ward', write_only=True, required=False, allow_null=True
    )
    qr_base64 = serializers.SerializerMethodField()
    pending_amount = serializers.SerializerMethodField()
    last_collection = serializers.SerializerMethodField()

    def get_qr_base64(self, obj):
        return obj.get_qr_base64()

    def get_pending_amount(self, obj):
        total = sum(
            c.amount for c in obj.collections.filter(payment_status='pending')
        )
        return float(total)

    def get_last_collection(self, obj):
        last = obj.collections.order_by('-date').first()
        return str(last.date) if last else None

    class Meta:
        model = Household
        fields = [
            'id', 'name', 'address', 'phone', 'ward', 'ward_id',
            'qr_code', 'qr_base64', 'monthly_fee', 'is_active',
            'created_at', 'pending_amount', 'last_collection',
            'preferred_payment', 'upi_id',
        ]
        read_only_fields = ['qr_code']
