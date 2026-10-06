"""Tests for POST /api/v1/auth/firebase/ (Firebase ID token -> our JWT pair).

Firebase itself is mocked: no network, no credentials. The CI/dev default
(no FIREBASE_SERVICE_ACCOUNT_JSON) is exercised by the unconfigured test.
"""

from unittest import mock

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from .models import User

URL = "/api/v1/auth/firebase/"
CLAIMS = {
    "email": "shopper@gmail.com",
    "email_verified": True,
    "name": "Priya Shopper",
}

def _configured(testcase):
    """Pretend Firebase is initialized so tests exercise verify logic."""
    testcase._app_patcher = mock.patch(
        "users.firebase_auth.firebase_app", return_value=object()
    )
    testcase._app_patcher.start()
    testcase.addCleanup(testcase._app_patcher.stop)


def _claims(**overrides):
    response = dict(CLAIMS)
    response.update(overrides)
    return response


class FirebaseLoginTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_unconfigured_returns_503(self):
        # No service account in this environment: endpoint must say so.
        res = self.client.post(URL, {"id_token": "anything"}, format="json")
        self.assertEqual(res.status_code, 503)

    def test_missing_id_token_returns_400(self):
        _configured(self)
        res = self.client.post(URL, {}, format="json")
        self.assertEqual(res.status_code, 400)

    def test_invalid_token_returns_401(self):
        _configured(self)
        with mock.patch(
            "firebase_admin.auth.verify_id_token", side_effect=Exception("bad")
        ):
            res = self.client.post(URL, {"id_token": "bogus"}, format="json")
        self.assertEqual(res.status_code, 401)
        self.assertFalse(User.objects.filter(email="shopper@gmail.com").exists())

    def test_unverified_email_returns_400_without_creating_user(self):
        _configured(self)
        with mock.patch(
            "firebase_admin.auth.verify_id_token",
            return_value=_claims(email_verified=False),
        ):
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 400)
        self.assertFalse(User.objects.filter(email="shopper@gmail.com").exists())

    def test_new_google_user_created_with_jwt_pair(self):
        _configured(self)
        with mock.patch(
            "firebase_admin.auth.verify_id_token", return_value=_claims()
        ):
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)
        self.assertEqual(res.data["user"]["email"], "shopper@gmail.com")
        user = User.objects.get(email="shopper@gmail.com")
        self.assertTrue(user.is_email_verified)
        self.assertEqual(user.role, User.Role.CUSTOMER)
        self.assertEqual(user.first_name, "Priya")
        # Firebase users authenticate via Firebase: no usable local password.
        self.assertFalse(user.has_usable_password())

    def test_existing_password_user_keeps_password_and_gets_verified(self):
        User.objects.create_user(
            email="shopper@gmail.com", password="StrongPass123!", is_email_verified=False
        )
        _configured(self)
        with mock.patch(
            "firebase_admin.auth.verify_id_token", return_value=_claims()
        ):
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
        _configured(self)
        with mock.patch(
            "firebase_admin.auth.verify_id_token", return_value=_claims()
        ):
            res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 401)

    @override_settings(FIREBASE_SERVICE_ACCOUNT_JSON="not-json{{{")
    def test_malformed_service_account_behaves_unconfigured(self):
        res = self.client.post(URL, {"id_token": "tok"}, format="json")
        self.assertEqual(res.status_code, 503)
