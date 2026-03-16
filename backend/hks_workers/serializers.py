from rest_framework import serializers
from .models import Worker
from hks_users.serializers import UserSerializer
from hks_wards.serializers import WardSerializer

class WorkerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    ward = WardSerializer(read_only=True)
    ward_id = serializers.PrimaryKeyRelatedField(
        queryset=__import__('hks_wards.models', fromlist=['Ward']).Ward.objects.all(),
        source='ward', write_only=True, required=False, allow_null=True
    )
    user_data = serializers.DictField(write_only=True, required=False)

    class Meta:
        model = Worker
        fields = ['id', 'worker_id', 'phone', 'user', 'ward', 'ward_id', 'is_active', 'created_at', 'user_data']

    def create(self, validated_data):
        from hks_users.models import HKSUser
        user_data = validated_data.pop('user_data', {})
        worker_id = validated_data.get('worker_id', '')
        password = user_data.pop('password', 'worker@123')
        user = HKSUser(**user_data, role='worker', username=worker_id)
        user.set_password(password)
        user.save()
        validated_data['user'] = user
        return Worker.objects.create(**validated_data)

    def update(self, instance, validated_data):
        validated_data.pop('user_data', None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        return instance
