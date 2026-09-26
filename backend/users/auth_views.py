from rest_framework import status
from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import OTPCode, User
from .serializers import (
    CustomTokenObtainPairSerializer,
    LogoutSerializer,
    RegisterSerializer,
    ResendOTPSerializer,
    UserSerializer,
    VerifyOTPSerializer,
)
from .services import send_otp_email


class RegisterView(CreateAPIView):
    """Create a customer account and email them an OTP. Email must be verified before login."""
    authentication_classes = []
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer
    throttle_scope = "register"

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {
                "message": "Account created. Verify your email with the OTP that was emailed to you.",
                "user": UserSerializer(user).data,
            },
            status=status.HTTP_201_CREATED,
        )


class VerifyOTPView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_scope = "otp"

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        return Response({"message": "Email verified successfully.", "user": UserSerializer(user).data})


class ResendOTPView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_scope = "otp"

    def post(self, request):
        serializer = ResendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data.get("user")
        if user is not None:
            OTPCode.objects.filter(
                user=user, purpose=OTPCode.Purpose.EMAIL_VERIFICATION, is_used=False
            ).update(is_used=True)
            otp = OTPCode.issue(user)
            send_otp_email(user, otp.code)
        # Same response whether or not the email exists/needs verification —
        # prevents account enumeration through this endpoint.
        return Response({"message": "If this email needs verification, a new OTP has been emailed to you."})


class LoginView(TokenObtainPairView):
    authentication_classes = []
    permission_classes = [AllowAny]
    serializer_class = CustomTokenObtainPairSerializer
    throttle_scope = "login"


class LogoutView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.validated_data["token"].blacklist()
        return Response({"message": "Logged out successfully."})