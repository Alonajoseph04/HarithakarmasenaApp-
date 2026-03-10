import random
from django.contrib.auth import authenticate
from django.core.cache import cache
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from .models import HKSUser
from .serializers import UserSerializer


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


def _otp_cache_key(phone):
    return f'hks_otp_{phone}'


def _send_sms(phone, otp):
    """
    Send OTP via Twilio if configured; otherwise print to console (DEBUG fallback).
    Phone numbers must be in E.164 format for Twilio, e.g. +919876543210.
    We auto-prepend +91 for Indian numbers that don't start with +.
    """
    if getattr(settings, 'TWILIO_ENABLED', False):
        try:
            from twilio.rest import Client
            to_number = phone if phone.startswith('+') else f'+91{phone}'
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=f'Your Haritha Karma Sena OTP is: {otp}. Valid for 5 minutes. Do not share with anyone.',
                from_=settings.TWILIO_PHONE_NUMBER,
                to=to_number,
            )
            return True, 'sms'
        except Exception as e:
            print(f'[OTP] Twilio SMS failed for {phone}: {e}')
            return False, str(e)
    else:
        # Debug mode — print OTP to console
        print(f'[OTP][DEBUG] Phone: {phone}, OTP: {otp}  (Set TWILIO_* env vars for real SMS)')
        return True, 'console'


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if not user:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
        tokens = get_tokens_for_user(user)
        return Response({
            'tokens': tokens,
            'user': UserSerializer(user).data
        })


class OTPSendView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        if not phone:
            return Response({'error': 'Phone number required'}, status=status.HTTP_400_BAD_REQUEST)

        # Validate: must be registered as a household user
        try:
            HKSUser.objects.get(phone=phone, role='household')
        except HKSUser.DoesNotExist:
            return Response({'error': 'Phone number not registered'}, status=status.HTTP_404_NOT_FOUND)

        # Rate-limit: don't allow re-send within 60s
        existing_key = _otp_cache_key(phone)
        existing_otp = cache.get(existing_key)
        expiry = getattr(settings, 'OTP_EXPIRY_SECONDS', 300)
        if existing_otp:
            # Check if less than 60 seconds since last OTP by checking remaining TTL
            remaining = cache.ttl(existing_key) if hasattr(cache, 'ttl') else 0
            if remaining and remaining > (expiry - 60):
                return Response(
                    {'error': 'Please wait 60 seconds before requesting a new OTP'},
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

        # Generate and store OTP in cache with TTL
        otp = str(random.randint(100000, 999999))  # 6-digit OTP
        cache.set(existing_key, otp, timeout=expiry)

        # Send OTP
        sent, channel = _send_sms(phone, otp)
        if not sent:
            cache.delete(existing_key)
            return Response({'error': 'Failed to send OTP. Please try again.'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        response_data = {'message': f'OTP sent to {phone}'}
        # In DEBUG mode without Twilio, expose OTP for testing convenience
        if settings.DEBUG and not getattr(settings, 'TWILIO_ENABLED', False):
            response_data['demo_otp'] = otp

        return Response(response_data)


class OTPVerifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        otp = str(request.data.get('otp', '')).strip()

        if not phone or not otp:
            return Response({'error': 'Phone and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)

        key = _otp_cache_key(phone)
        stored_otp = cache.get(key)

        if stored_otp is None:
            return Response({'error': 'OTP expired. Please request a new one.'}, status=status.HTTP_400_BAD_REQUEST)

        if stored_otp != otp:
            return Response({'error': 'Invalid OTP. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

        # Consume OTP (delete from cache so it can't be reused)
        cache.delete(key)

        try:
            user = HKSUser.objects.get(phone=phone, role='household')
        except HKSUser.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        tokens = get_tokens_for_user(user)
        return Response({
            'tokens': tokens,
            'user': UserSerializer(user).data
        })


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        if not user.check_password(old_password):
            return Response({'error': 'Old password is incorrect'}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(new_password)
        user.save()
        return Response({'message': 'Password changed successfully'})


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)
