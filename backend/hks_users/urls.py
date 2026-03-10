from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.LoginView.as_view(), name='login'),
    path('otp/send/', views.OTPSendView.as_view(), name='otp-send'),
    path('otp/verify/', views.OTPVerifyView.as_view(), name='otp-verify'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    path('me/', views.MeView.as_view(), name='me'),
]
