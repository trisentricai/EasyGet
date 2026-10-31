"""Tests for POST /api/v1/auth/google/ (Google ID token -> our JWT pair).

Google's verification is mocked: no network, no credentials.
"""

from unittest import mock

from django.core.cache import cache
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from .models import User

URL = "/api/v1/auth/google/"
CLAIMS = {
    "email": "shopper@gmail.com",
    "email_verified": True,
    "given_name": "Priya",
    "family_name": "Shopper",
}


def _claims(**overrides):
    response = dict(CLAIMS)
    response.update(overrides)
    return response


AUDIENCES = "test-web.apps.googleusercontent.com"


@override_settings(GOOGLE_OAUTH_CLIENT_IDS=AUDIENCES)
class GoogleLoginTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def _verify(self, **overrides):
        return mock.patch(
            "google.oauth2.id_token.verify_oauth2_token",
            return_value=_claims(**overrides),
        )

    def test_unconfigured_returns_503(self):
        # No OAuth client IDs: endpoint must say so.
        with override_settings(GOOGLE_OAUTH_CLIENT_IDS=""):
            res = self.client.post(URL, {"id_token": "anything"}, format="json")
        self.assertEqual(res.status_code, 503)

    def test_missing_id_token_returns_400(self):
        res = self.client.post(URL, {}, format="json")
        self.assertEqual(res.status_code, 400)

    def test_invalid_token_returns_401(self):
        with mock.patch(
            "google.oauth2.id_token.verify_oauth2_token", side_effect=ValueError("bad")
        ):
            res = self.client.post(URL, {"id_token": "bogus"}, format="json")
        self.assertEqual(res.status_code, 401)
        self.assertFalse(User.objects.filter(email="shopper@gmail.com").exists())

    def test_unverified_email_returns_400_without_creating_user(self):
        with self._verify(email_verified=False):
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 400)
        self.assertFalse(User.objects.filter(email="shopper@gmail.com").exists())

    def test_new_google_user_created_with_jwt_pair(self):
        with self._verify():
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)
        self.assertEqual(res.data["user"]["email"], "shopper@gmail.com")
        user = User.objects.get(email="shopper@gmail.com")
        self.assertTrue(user.is_email_verified)
        self.assertEqual(user.role, User.Role.CUSTOMER)
        self.assertEqual(user.first_name, "Priya")
        self.assertFalse(user.has_usable_password())

    def test_existing_password_user_linked_not_duplicated(self):
        User.objects.create_user(
            email="shopper@gmail.com", password="StrongPass123!", is_email_verified=False
        )
        with self._verify():
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(User.objects.filter(email="shopper@gmail.com").count(), 1)
        user = User.objects.get(email="shopper@gmail.com")
        self.assertTrue(user.has_usable_password())
        self.assertTrue(user.is_email_verified)

    def test_inactive_user_rejected(self):
        user = User.objects.create_user(email="shopper@gmail.com", password="StrongPass123!")
        user.is_active = False
        user.save(update_fields=["is_active"])
        with self._verify():
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 401)
