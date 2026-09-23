from rest_framework import serializers
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Address, OTPCode, User
from .services import send_otp_email


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, max_length=128)

    class Meta:
        model = User
        fields = ("id", "email", "password", "first_name", "last_name", "phone")
        read_only_fields = ("id",)
        extra_kwargs = {"password": {"write_only": True}}

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
            raise serializers.ValidationError({"email": "No user found with this email."})

        otp = (
            OTPCode.objects.filter(
                user=user,
                purpose=OTPCode.Purpose.EMAIL_VERIFICATION,
                is_used=False,
            )
            .order_by("-created_at")
            .first()
        )
        if otp is None:
            raise serializers.ValidationError({"code": "No active OTP found. Request a new one."})
        if otp.is_expired:
            raise serializers.ValidationError({"code": "OTP has expired. Request a new one."})
        if otp.attempts >= 5:
            raise serializers.ValidationError({"code": "Too many attempts. Request a new OTP."})
        if otp.code != attrs["code"]:
            otp.attempts += 1
            otp.save(update_fields=["attempts"])
            raise serializers.ValidationError({"code": "Invalid OTP code."})

        otp.is_used = True
        otp.save(update_fields=["is_used"])
        user.is_email_verified = True
        user.save(update_fields=["is_email_verified", "updated_at"])
        attrs["user"] = user
        return attrs


class ResendOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate(self, attrs):
        try:
            user = User.objects.get(email__iexact=attrs["email"])
        except User.DoesNotExist:
            raise serializers.ValidationError({"email": "No user found with this email."})
        if user.is_email_verified:
            raise serializers.ValidationError({"email": "Email is already verified."})
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