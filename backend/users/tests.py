import re

from django.core import mail
from django.core.cache import cache
from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APIClient

from .models import Address, User

REGISTER_URL = reverse("register")
VERIFY_URL = reverse("verify-otp")
LOGIN_URL = reverse("login")
LOGOUT_URL = reverse("logout")
ME_URL = reverse("me")
ADMIN_ONLY_URL = reverse("admin-only")


def otp_from_last_email():
    body = mail.outbox[-1].body
    match = re.search(r"\b(\d{6})\b", body)
    return match.group(1)


@override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
class AuthFlowTests(TestCase):
    def setUp(self):
        # Scoped auth throttles (login/register/otp) are per-process counters;
        # reset so tests never trip each other's limits.
        cache.clear()
        self.client = APIClient()
        self.payload = {
            "email": "customer@example.com",
            "password": "strongpass123",
            "first_name": "Ravi",
            "last_name": "Kumar",
        }

    def _register(self, **overrides):
        data = {**self.payload, **overrides}
        return self.client.post(REGISTER_URL, data, format="json")

    def _verify(self, email=None, code=None):
        code = code or otp_from_last_email()
        return self.client.post(
            VERIFY_URL, {"email": email or self.payload["email"], "code": code}, format="json"
        )

    def _login(self, **overrides):
        data = {"email": self.payload["email"], "password": self.payload["password"], **overrides}
        return self.client.post(LOGIN_URL, data, format="json")

    def test_register_creates_customer_and_sends_otp(self):
        response = self._register()
        self.assertEqual(response.status_code, 201)
        self.assertTrue(User.objects.filter(email=self.payload["email"]).exists())
        user = User.objects.get(email=self.payload["email"])
        self.assertEqual(user.role, User.Role.CUSTOMER)
        self.assertFalse(user.is_email_verified)
        self.assertEqual(len(mail.outbox), 1)
        self.assertTrue(otp_from_last_email().isdigit())

    def test_register_rejects_duplicate_email(self):
        self._register()
        response = self._register()
        self.assertEqual(response.status_code, 400)

    def test_verify_otp_marks_email_verified(self):
        self._register()
        response = self._verify()
        self.assertEqual(response.status_code, 200)
        user = User.objects.get(email=self.payload["email"])
        self.assertTrue(user.is_email_verified)

    def test_verify_otp_rejects_wrong_code(self):
        self._register()
        response = self._verify(code="000000")
        self.assertEqual(response.status_code, 400)
        user = User.objects.get(email=self.payload["email"])
        self.assertFalse(user.is_email_verified)

    def test_login_rejected_before_verification(self):
        self._register()
        response = self._login()
        self.assertEqual(response.status_code, 400)

    def test_login_returns_tokens_after_verification(self):
        self._register()
        self._verify()
        response = self._login()
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["email"], self.payload["email"])

    def test_login_with_wrong_password_fails(self):
        self._register()
        self._verify()
        response = self._login(password="wrongpassword")
        self.assertEqual(response.status_code, 401)

    def test_register_rejects_short_password(self):
        response = self._register(password="abc123")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(
            User.objects.filter(email=self.payload["email"]).exists()
        )

    def test_register_rejects_all_numeric_password(self):
        response = self._register(password="12345678901234")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(
            User.objects.filter(email=self.payload["email"]).exists()
        )

    def test_verify_unknown_email_returns_same_generic_error(self):
        self._register()
        wrong = self._verify(code="000000")
        ghost = self.client.post(
            VERIFY_URL, {"email": "ghost@example.com", "code": "123456"}, format="json"
        )
        self.assertEqual(wrong.status_code, 400)
        self.assertEqual(ghost.status_code, 400)
        # Identical message shape: no way to tell registered vs unregistered.
        self.assertEqual(str(wrong.data), str(ghost.data))

    def test_resend_otp_is_rate_limited_and_never_enumerates(self):
        self._register()
        resend_url = reverse("resend-otp")
        for _ in range(5):
            res = self.client.post(
                resend_url, {"email": self.payload["email"]}, format="json"
            )
            self.assertEqual(res.status_code, 200)
        # register(1) + 3 resends inside the 10-minute window; later ones are
        # silently dropped instead of issuing fresh codes.
        self.assertEqual(len(mail.outbox), 4)
        ghost = self.client.post(
            resend_url, {"email": "ghost@example.com"}, format="json"
        )
        self.assertEqual(ghost.status_code, 200)
        self.assertEqual(ghost.data["message"], res.data["message"])


@override_settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend")
class LogoutTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        user = User.objects.create_user(
            email="logout@example.com", password="strongpass123", is_email_verified=True
        )
        login = self.client.post(
            LOGIN_URL,
            {"email": "logout@example.com", "password": "strongpass123"},
            format="json",
        )
        self.access = login.data["access"]
        self.refresh = login.data["refresh"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

    def test_logout_blacklists_refresh_token(self):
        response = self.client.post(LOGOUT_URL, {"refresh": self.refresh}, format="json")
        self.assertEqual(response.status_code, 200)
        refresh = self.client.post(reverse("token-refresh"), {"refresh": self.refresh}, format="json")
        self.assertEqual(refresh.status_code, 401)


class ProfileAndAddressTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(
            email="profile@example.com", password="strongpass123", is_email_verified=True
        )
        self.admin = User.objects.create_user(
            email="admin@example.com",
            password="strongpass123",
            is_email_verified=True,
            role=User.Role.ADMIN,
            is_staff=True,
        )
        self.client = APIClient()
        login = self.client.post(
            LOGIN_URL,
            {"email": "profile@example.com", "password": "strongpass123"},
            format="json",
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_me_returns_profile(self):
        response = self.client.get(ME_URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["email"], self.user.email)

    def test_profile_can_be_updated(self):
        response = self.client.patch(
            ME_URL, {"first_name": "Updated", "phone": "9876543210"}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "Updated")
        self.assertEqual(self.user.phone, "9876543210")

    def test_multiple_addresses_with_single_default(self):
        address_url = reverse("address-list")
        first = self.client.post(
            address_url,
            {
                "label": "Home",
                "line1": "12, Gandhi Street",
                "city": "Chennai",
                "state": "Tamil Nadu",
                "postal_code": "600001",
            },
            format="json",
        )
        self.assertEqual(first.status_code, 201)
        self.assertTrue(first.data["is_default"])
        first_id = first.data["id"]

        second = self.client.post(
            address_url,
            {
                "label": "Office",
                "line1": "25, Anna Salai",
                "city": "Chennai",
                "state": "Tamil Nadu",
                "postal_code": "600002",
            },
            format="json",
        )
        self.assertEqual(second.status_code, 201)
        self.assertFalse(second.data["is_default"])

        set_default = self.client.post(
            reverse("address-set-default", kwargs={"pk": second.data["id"]})
        )
        self.assertEqual(set_default.status_code, 200)
        self.assertTrue(set_default.data["is_default"])

        address_one = Address.objects.get(pk=first_id)
        address_two = Address.objects.get(pk=second.data["id"])
        self.assertFalse(address_one.is_default)
        self.assertTrue(address_two.is_default)
        self.assertEqual(Address.objects.filter(user=self.user, is_default=True).count(), 1)

    def test_me_without_token_forbidden(self):
        self.client.credentials()
        response = self.client.get(ME_URL)
        self.assertEqual(response.status_code, 401)

    def test_unverified_user_forbidden_from_me(self):
        unverified = User.objects.create_user(
            email="unverified@example.com", password="strongpass123"
        )
        login = self.client.post(
            LOGIN_URL,
            {"email": "unverified@example.com", "password": "strongpass123"},
            format="json",
        )
        self.assertEqual(login.status_code, 400)
        self.client.credentials(
            HTTP_AUTHORIZATION=unverified_email_token(unverified)
        )
        response = self.client.get(ME_URL)
        self.assertIn(response.status_code, (401, 403))

    def test_customer_token_gets_403_on_admin_only_endpoint(self):
        response = self.client.get(ADMIN_ONLY_URL)
        self.assertEqual(response.status_code, 403)

    def test_admin_token_allowed_on_admin_only_endpoint(self):
        admin_login = APIClient().post(
            LOGIN_URL,
            {"email": "admin@example.com", "password": "strongpass123"},
            format="json",
        )
        admin = APIClient()
        admin.credentials(HTTP_AUTHORIZATION=f"Bearer {admin_login.data['access']}")
        response = admin.get(ADMIN_ONLY_URL)
        self.assertEqual(response.status_code, 200)


def unverified_email_token(user):
    from rest_framework_simplejwt.tokens import RefreshToken

    return f"Bearer {str(RefreshToken.for_user(user).access_token)}"