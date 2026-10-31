"""Google sign-in WITHOUT Firebase (GIS button on web, google_sign_in on app).

Flow: the client completes Google OAuth and POSTs the Google ID token here;
we verify it with google-auth against our OAuth client IDs and mint OUR
SimpleJWT pair, so everything downstream (roles, throttles, blacklist, cart,
orders) works unchanged.

Account-linking contract (same as the other social path):
- verified Google email matching an existing user -> same user, both login
  methods stay usable (password accounts keep their password);
- email already registered via password -> 400 "already registered", never a
  duplicate or an overwrite;
- inactive user -> 401.

No User model change: users are matched by verified email.
"""

import logging

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import UserSerializer

logger = logging.getLogger(__name__)

NOT_CONFIGURED = "Google login is not configured."
INVALID_TOKEN = "Invalid or expired Google credential."
UNVERIFIED_EMAIL = "Email not verified. Verify your email, then try again."


def google_audiences():
    """Allowed OAuth client IDs (web + android), from settings."""
    from django.conf import settings

    raw = getattr(settings, "GOOGLE_OAUTH_CLIENT_IDS", "")
    return [a.strip() for a in raw.split(",") if a.strip()]


class GoogleLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField()


class GoogleLoginView(APIView):
    """POST /api/v1/auth/google/ — exchange a Google ID token for our JWT pair.

    Response shape matches /auth/login/ exactly ({access, refresh, user}).
    """

    authentication_classes = []
    permission_classes = [AllowAny]
    # Shares the social-login throttle budget (ID tokens are signed, not
    # brute-forceable; keeps password-login budget untouched).
    throttle_scope = "firebase"

    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        audiences = google_audiences()
        if not audiences:
            return Response({"detail": NOT_CONFIGURED}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        claims = None
        request_adapter = google_requests.Request()
        for audience in audiences:
            try:
                claims = google_id_token.verify_oauth2_token(
                    serializer.validated_data["id_token"],
                    request_adapter,
                    audience,
                )
                break
            except ValueError:
                continue
        if claims is None:
            return Response({"detail": INVALID_TOKEN}, status=status.HTTP_401_UNAUTHORIZED)
        email = (claims.get("email") or "").strip().lower()
        if not email:
            return Response({"detail": INVALID_TOKEN}, status=status.HTTP_401_UNAUTHORIZED)
        if not claims.get("email_verified", False):
            return Response({"detail": UNVERIFIED_EMAIL}, status=status.HTTP_400_BAD_REQUEST)
        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            given = (claims.get("given_name") or "").strip()
            family = (claims.get("family_name") or "").strip()
            if not given:
                name = (claims.get("name") or "").strip()
                given, _, family = name.partition(" ")
            user = User.objects.create_user(
                email=email,
                first_name=given[:30],
                last_name=family[:30],
                is_email_verified=True,
            )
        elif not user.is_active:
            return Response({"detail": INVALID_TOKEN}, status=status.HTTP_401_UNAUTHORIZED)
        elif not user.is_email_verified:
            user.is_email_verified = True
            user.save(update_fields=["is_email_verified", "updated_at"])
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": UserSerializer(user).data,
            }
        )
