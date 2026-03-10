from rest_framework import serializers
from .models import Notification
from hks_users.serializers import UserSerializer

class NotificationSerializer(serializers.ModelSerializer):
    recipient = UserSerializer(read_only=True)
    recipient_id = serializers.PrimaryKeyRelatedField(
        queryset=__import__('hks_users.models', fromlist=['HKSUser']).HKSUser.objects.all(),
        source='recipient', write_only=True
    )

    class Meta:
        model = Notification
        fields = ['id', 'recipient', 'recipient_id', 'title', 'message', 'notification_type', 'is_read', 'created_at']

class NotificationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'recipient', 'title', 'message', 'notification_type']
