"""Role signup + admin user management tests.

Self-service may only claim CUSTOMER/MERCHANT/DELIVERY_AGENT; staff roles
are admin-created. Admin endpoints are ADMIN-only.
"""

from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from .models import User

REGISTER_URL = "/api/v1/auth/register/"
ADMIN_USERS_URL = "/api/v1/admin/users/"


def _password(i=0):
    return f"StrongPass123!{i}"


class SignupRoleTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def _register(self, **overrides):
        body = {"email": "new@example.com", "password": _password()}
        body.update(overrides)
        return self.client.post(REGISTER_URL, body, format="json")

    def test_default_role_is_customer(self):
        res = self._register()
        self.assertEqual(res.status_code, 201)
        self.assertEqual(User.objects.get(email="new@example.com").role, User.Role.CUSTOMER)

    def test_merchant_and_delivery_roles_allowed(self):
        for role in (User.Role.MERCHANT, User.Role.DELIVERY_AGENT):
            res = self._register(email=f"{role.lower()}@example.com", role=role)
            self.assertEqual(res.status_code, 201, res.data)
            self.assertEqual(
                User.objects.get(email=f"{role.lower()}@example.com").role, role
            )

    def test_staff_roles_rejected_for_self_signup(self):
        for role in (User.Role.ADMIN, User.Role.STORE_MANAGER):
            res = self._register(email=f"{role.lower()}@example.com", role=role)
            self.assertEqual(res.status_code, 400)

    def test_duplicate_email_rejected(self):
        User.objects.create_user(email="dup@example.com", password=_password())
        res = self._register(email="dup@example.com")
        self.assertEqual(res.status_code, 400)


class AdminUserManagementTests(TestCase):
    def setUp(self):
        cache.clear()
        self.admin = User.objects.create_user(
            email="admin@example.com",
            password=_password(),
            is_email_verified=True,
            role=User.Role.ADMIN,
            is_staff=True,
        )
        self.customer = User.objects.create_user(
            email="cust@example.com", password=_password(), is_email_verified=True
        )
        login = APIClient().post(
            "/api/v1/auth/login/",
            {"email": "admin@example.com", "password": _password()},
            format="json",
        )
        self.client = APIClient()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

    def test_list_requires_admin(self):
        anon = APIClient().get(ADMIN_USERS_URL)
        self.assertEqual(anon.status_code, 401)
        cust = APIClient()
        login = cust.post(
            "/api/v1/auth/login/",
            {"email": "cust@example.com", "password": _password()},
            format="json",
        )
        cust.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")
        self.assertEqual(cust.get(ADMIN_USERS_URL).status_code, 403)

    def test_admin_can_list_users(self):
        res = self.client.get(ADMIN_USERS_URL)
        self.assertEqual(res.status_code, 200)
        emails = [u["email"] for u in res.data["results"]]
        self.assertIn("cust@example.com", emails)

    def test_admin_can_create_any_role_verified_without_otp(self):
        res = self.client.post(
            ADMIN_USERS_URL,
            {"email": "m@example.com", "password": _password(), "role": User.Role.MERCHANT},
            format="json",
        )
        self.assertEqual(res.status_code, 201, res.data)
        user = User.objects.get(email="m@example.com")
        self.assertEqual(user.role, User.Role.MERCHANT)
        self.assertTrue(user.is_email_verified)

    def test_admin_can_change_role_and_deactivate(self):
        url = f"{ADMIN_USERS_URL}{self.customer.id}/"
        res = self.client.patch(url, {"role": User.Role.DELIVERY_AGENT}, format="json")
        self.assertEqual(res.status_code, 200)
        self.customer.refresh_from_db()
        self.assertEqual(self.customer.role, User.Role.DELIVERY_AGENT)
        res = self.client.patch(url, {"is_active": False}, format="json")
        self.assertEqual(res.status_code, 200)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_active)
