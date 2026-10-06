"""Firebase-authenticated login (customer: Google + email/password).

Flow: the client signs in with Firebase, POSTs the Firebase ID token here;
we verify it with firebase-admin and mint OUR SimpleJWT pair, so everything
downstream (roles, throttles, blacklist, cart, orders) works unchanged.

Design constraints (see DESIGN.md §8 + CONTEXT.md hard rules):
- No User model change: users are matched by verified email. Firebase users
  get unusable passwords; an existing password login keeps working alongside.
- New code lives in this module only: no edits to models, serializers, or
  existing tests. The single added route is documented in auth_urls.py.
- Unverified emails are rejected: Firebase email/password accounts must
  complete Firebase's own verification first (Google accounts arrive
  verified).
"""

import json
import logging

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import UserSerializer

logger = logging.getLogger(__name__)

NOT_CONFIGURED = "Firebase login is not configured."
INVALID_TOKEN = "Invalid or expired Firebase credential."
UNVERIFIED_EMAIL = "Email not verified. Verify your email, then try again."


def firebase_app():
    """Initialized firebase app, or None when not configured (local dev).

    Malformed credentials log a loud warning (startup visibility) and behave
    as unconfigured — this must never crash boot.
    """
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass  # not initialized yet
    from django.conf import settings

    raw = getattr(settings, "FIREBASE_SERVICE_ACCOUNT_JSON", "")
    if not raw:
        return None
    try:
        cred = credentials.Certificate(json.loads(raw))
    except (ValueError, KeyError, TypeError) as exc:
        logger.warning("FIREBASE_SERVICE_ACCOUNT_JSON is malformed: %s", exc)
        return None
    try:
        return firebase_admin.initialize_app(cred)
    except Exception as exc:  # pragma: no cover - init failure is environmental
        logger.warning("Firebase initialization failed: %s", exc)
        return None


class FirebaseLoginSerializer(serializers.Serializer):
    id_token = serializers.CharField()


class FirebaseLoginView(APIView):
    """POST /api/v1/auth/firebase/ — exchange a Firebase ID token for our JWT pair.

    Response shape matches /auth/login/ exactly ({access, refresh, user}) so
    clients reuse token storage, refresh, and logout unchanged.
    """

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_scope = "firebase"

    def post(self, request):
        serializer = FirebaseLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        app = firebase_app()
        if app is None:
            return Response({"detail": NOT_CONFIGURED}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        try:
            claims = firebase_auth.verify_id_token(serializer.validated_data["id_token"], app=app)
        except Exception:
            return Response({"detail": INVALID_TOKEN}, status=status.HTTP_401_UNAUTHORIZED)
        email = (claims.get("email") or "").strip().lower()
        if not email:
            return Response({"detail": INVALID_TOKEN}, status=status.HTTP_401_UNAUTHORIZED)
        if not claims.get("email_verified", False):
            return Response({"detail": UNVERIFIED_EMAIL}, status=status.HTTP_400_BAD_REQUEST)
        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            name = (claims.get("name") or "").strip()
            first, _, last = name.partition(" ")
            user = User.objects.create_user(
                email=email,
                first_name=first[:30],
                last_name=last[:30],
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
