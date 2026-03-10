from rest_framework import serializers
from .models import HKSUser

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = HKSUser
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'role', 'phone']

class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=4)
    class Meta:
        model = HKSUser
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'role', 'phone', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = HKSUser(**validated_data)
        user.set_password(password)
        user.save()
        return user
