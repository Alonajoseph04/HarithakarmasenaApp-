from rest_framework import serializers
from .models import Collection, SkipRequest, ExtraPickupRequest
from hks_households.serializers import HouseholdSerializer
from hks_workers.serializers import WorkerSerializer

RATING_DISPLAY = {1: 'Poor', 2: 'Average', 3: 'Good', 4: 'Excellent'}

class CollectionSerializer(serializers.ModelSerializer):
    household = HouseholdSerializer(read_only=True)
    household_id = serializers.PrimaryKeyRelatedField(
        queryset=__import__('hks_households.models', fromlist=['Household']).Household.objects.all(),
        source='household', write_only=True
    )
    worker = WorkerSerializer(read_only=True)
    worker_id_field = serializers.PrimaryKeyRelatedField(
        queryset=__import__('hks_workers.models', fromlist=['Worker']).Worker.objects.all(),
        source='worker', write_only=True
    )
    # Friendly labels for structured ratings
    rating_punctuality_label = serializers.SerializerMethodField()
    rating_cleanliness_label = serializers.SerializerMethodField()
    rating_attitude_label    = serializers.SerializerMethodField()

    def get_rating_punctuality_label(self, obj): return RATING_DISPLAY.get(obj.feedback_punctuality, '')
    def get_rating_cleanliness_label(self, obj): return RATING_DISPLAY.get(obj.feedback_cleanliness, '')
    def get_rating_attitude_label(self,    obj): return RATING_DISPLAY.get(obj.feedback_attitude, '')

    class Meta:
        model = Collection
        fields = [
            'id', 'household', 'household_id', 'worker', 'worker_id_field',
            'date', 'waste_type', 'weight', 'rate', 'amount',
            'cleanliness', 'payment_method', 'payment_status', 'notes',
            'worker_rating', 'worker_feedback',
            'feedback_punctuality', 'feedback_cleanliness', 'feedback_attitude',
            'rating_punctuality_label', 'rating_cleanliness_label', 'rating_attitude_label',
            'created_at'
        ]

class CollectionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Collection
        fields = [
            'id', 'household', 'worker',
            'date', 'waste_type', 'weight', 'rate', 'amount',
            'cleanliness', 'payment_method', 'payment_status', 'notes',
            'worker_rating', 'worker_feedback',
            'feedback_punctuality', 'feedback_cleanliness', 'feedback_attitude',
        ]

    def create(self, validated_data):
        if 'amount' not in validated_data or not validated_data['amount']:
            validated_data['amount'] = validated_data['weight'] * validated_data['rate']
        return super().create(validated_data)


class SkipRequestSerializer(serializers.ModelSerializer):
    household_name = serializers.CharField(source='household.name', read_only=True)
    ward_name = serializers.CharField(source='household.ward.name', read_only=True)

    class Meta:
        model = SkipRequest
        fields = [
            'id', 'household', 'household_name', 'ward_name',
            'date', 'reason', 'payment_action', 'status',
            'created_at', 'acknowledged_at'
        ]
        read_only_fields = ['status', 'acknowledged_at']


class ExtraPickupRequestSerializer(serializers.ModelSerializer):
    household_name  = serializers.CharField(source='household.name', read_only=True)
    household_address = serializers.CharField(source='household.address', read_only=True)
    ward_name       = serializers.CharField(source='household.ward.name', read_only=True)
    waste_type_display = serializers.CharField(source='get_waste_type_display', read_only=True)
    reviewed_by_name   = serializers.SerializerMethodField()

    def get_reviewed_by_name(self, obj):
        if obj.reviewed_by and obj.reviewed_by.user:
            return f"{obj.reviewed_by.user.first_name} {obj.reviewed_by.user.last_name}".strip()
        return None

    class Meta:
        model = ExtraPickupRequest
        fields = [
            'id', 'household', 'household_name', 'household_address', 'ward_name',
            'waste_type', 'waste_type_display', 'date', 'notes',
            'status', 'reviewed_by', 'reviewed_by_name', 'reviewed_at', 'created_at'
        ]
        read_only_fields = ['status', 'reviewed_by', 'reviewed_at']
