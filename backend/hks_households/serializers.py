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
    # Write-only: admin provides login credentials when adding a household
    user_data = serializers.DictField(write_only=True, required=False)
    # Read-only: shows whether a login account exists
    has_user_account = serializers.SerializerMethodField()
    login_username  = serializers.SerializerMethodField()

    def get_qr_base64(self, obj):
        return obj.get_qr_base64()

    def get_pending_amount(self, obj):
        total = sum(c.amount for c in obj.collections.filter(payment_status='pending'))
        return float(total)

    def get_last_collection(self, obj):
        last = obj.collections.order_by('-date').first()
        return str(last.date) if last else None

    def get_has_user_account(self, obj):
        return obj.user_id is not None

    def get_login_username(self, obj):
        return obj.user.username if obj.user else None

    def create(self, validated_data):
        from hks_users.models import HKSUser
        user_data = validated_data.pop('user_data', {})

        phone = validated_data.get('phone', '') or ''
        name  = validated_data.get('name', 'household')

        # Username: explicitly given > phone > name-derived
        username = (
            user_data.get('username')
            or (phone.strip() if phone.strip() else None)
            or name.lower().replace(' ', '_')[:20]
        )
        password = user_data.get('password', 'hks@1234')
        first_name = user_data.get('first_name', name)
        last_name  = user_data.get('last_name', '')

        # Ensure username is unique
        base = username
        n = 1
        while HKSUser.objects.filter(username=username).exists():
            username = f'{base}_{n}'
            n += 1

        user = HKSUser(
            username=username,
            first_name=first_name,
            last_name=last_name,
            role='household',
        )
        # Only attach phone to user account if not already claimed
        if phone.strip() and not HKSUser.objects.filter(phone=phone.strip()).exists():
            user.phone = phone.strip()
        user.set_password(password)
        user.save()

        validated_data['user'] = user
        return Household.objects.create(**validated_data)

    def update(self, instance, validated_data):
        validated_data.pop('user_data', None)   # password changes done separately
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        return instance

    class Meta:
        model = Household
        fields = [
            'id', 'name', 'address', 'phone', 'ward', 'ward_id',
            'qr_code', 'qr_base64', 'monthly_fee', 'is_active',
            'created_at', 'pending_amount', 'last_collection',
            'preferred_payment', 'upi_id',
            'user_data', 'has_user_account', 'login_username',
        ]
        read_only_fields = ['qr_code']
