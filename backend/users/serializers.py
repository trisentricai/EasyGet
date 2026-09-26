from datetime import timedelta

from django.contrib.auth.password_validation import (
    validate_password as django_validate_password,
)
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Address, OTPCode, User
from .services import send_otp_email

# One message for every verify failure (unknown email, no OTP, expired, wrong
# code) so responses never reveal whether an account exists.
OTP_INVALID_MESSAGE = "Invalid or expired OTP code."


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=10, max_length=128)

    class Meta:
        model = User
        fields = ("id", "email", "password", "first_name", "last_name", "phone")
        read_only_fields = ("id",)
        extra_kwargs = {"password": {"write_only": True}}

    def validate(self, attrs):
        password = attrs.get("password")
        # Similarity validator needs the user attributes; build a throwaway
        # instance (nothing is persisted until create()).
        user = User(
            email=attrs.get("email", ""),
            first_name=attrs.get("first_name", ""),
            last_name=attrs.get("last_name", ""),
            phone=attrs.get("phone", ""),
        )
        try:
            django_validate_password(password, user=user)
        except DjangoValidationError as errors:
            raise serializers.ValidationError({"password": list(errors.messages)})
        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User.objects.create_user(password=password, **validated_data)
        otp = OTPCode.issue(user)
        send_otp_email(user, otp.code)
        return user


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(min_length=6, max_length=6)

    def validate(self, attrs):
        try:
            user = User.objects.get(email__iexact=attrs["email"])
        except User.DoesNotExist:
            raise serializers.ValidationError({"code": OTP_INVALID_MESSAGE})

        otp = (
            OTPCode.objects.filter(
                user=user,
                purpose=OTPCode.Purpose.EMAIL_VERIFICATION,
                is_used=False,
            )
            .order_by("-created_at")
            .first()
        )
        if otp is None or otp.is_expired:
            raise serializers.ValidationError({"code": OTP_INVALID_MESSAGE})
        if otp.attempts >= 5:
            raise serializers.ValidationError({"code": "Too many attempts. Request a new OTP."})
        if otp.code != attrs["code"]:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            raise serializers.ValidationError({"code": OTP_INVALID_MESSAGE})

        otp.is_used = True
        otp.save(update_fields=["is_used"])
        user.is_email_verified = True
        user.save(update_fields=["is_email_verified", "updated_at"])
        attrs["user"] = user
        return attrs


class ResendOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate(self, attrs):
        user = User.objects.filter(email__iexact=attrs["email"]).first()
        if user is None or user.is_email_verified:
            # No account (or already verified): no-op downstream, same response.
            attrs["user"] = None
            return attrs
        # Per-account cap that survives reissue: each resend creates a fresh
        # OTP (resetting `attempts`), so without this a 6-digit code could be
        # brute-forced by resending indefinitely. Initial register counts too.
        window_start = timezone.now() - timedelta(minutes=10)
        recent = OTPCode.objects.filter(
            user=user,
            purpose=OTPCode.Purpose.EMAIL_VERIFICATION,
            created_at__gte=window_start,
        ).count()
        if recent >= 4:
            attrs["user"] = None
            return attrs
        attrs["user"] = user
        return attrs


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        if not self.user.is_email_verified:
            raise serializers.ValidationError(
                {"email": "Email not verified. Complete OTP verification before logging in."}
            )
        data["user"] = UserSerializer(self.user).data
        return data


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate(self, attrs):
        try:
            token = RefreshToken(attrs["refresh"])
        except (TokenError, AttributeError, TypeError):
            raise serializers.ValidationError({"refresh": "Invalid or expired refresh token."})
        attrs["token"] = token
        return attrs


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "role", "first_name", "last_name", "phone", "is_email_verified")
        read_only_fields = ("id", "email", "role", "is_email_verified")


class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = (
            "id",
            "label",
            "line1",
            "line2",
            "city",
            "state",
            "postal_code",
            "country",
            "phone",
            "latitude",
            "longitude",
            "is_default",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_is_default(self, value):
        return value