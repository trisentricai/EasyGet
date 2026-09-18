from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import auth_views

urlpatterns = [
    path("register/", auth_views.RegisterView.as_view(), name="register"),
    path("verify-otp/", auth_views.VerifyOTPView.as_view(), name="verify-otp"),
    path("resend-otp/", auth_views.ResendOTPView.as_view(), name="resend-otp"),
    path("login/", auth_views.LoginView.as_view(), name="login"),
    path("logout/", auth_views.LogoutView.as_view(), name="logout"),
    path("refresh/", TokenRefreshView.as_view(), name="token-refresh"),
]