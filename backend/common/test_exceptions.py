"""Tests for the standardized error envelope (backend/common/exceptions.py).

The UI renders error.message verbatim: a Python repr must never reach it.
"""

from django.test import TestCase
from rest_framework.exceptions import AuthenticationFailed, ValidationError
from rest_framework.test import APIRequestFactory

from common.exceptions import custom_exception_handler


def _handle(exc):
    factory = APIRequestFactory()
    return custom_exception_handler(exc, {"request": factory.get("/"), "view": None})


class ExceptionHandlerTests(TestCase):
    def test_validation_error_message_is_human(self):
        exc = ValidationError(
            {"password": ["This password is too common.", "This password is entirely numeric."]}
        )
        res = _handle(exc)
        self.assertEqual(res.status_code, 400)
        message = res.data["error"]["message"]
        self.assertNotIn("ErrorDetail", message)
        self.assertIn("This password is too common.", message)
        self.assertIn("This password is entirely numeric.", message)
        # Structured details stay intact for clients that want fields.
        self.assertEqual(
            list(res.data["error"]["details"].keys()), ["password"]
        )

    def test_nested_and_list_details_flatten(self):
        exc = ValidationError(
            {"user": {"email": ["Enter a valid email address."]}, "non_field_errors": ["Bad combo."]}
        )
        res = _handle(exc)
        message = res.data["error"]["message"]
        self.assertNotIn("ErrorDetail", message)
        self.assertIn("Enter a valid email address.", message)
        self.assertIn("Bad combo.", message)

    def test_plain_string_detail_stays_clean(self):
        exc = AuthenticationFailed("No active account found with the given credentials")
        res = _handle(exc)
        self.assertEqual(res.status_code, 401)
        self.assertNotIn("ErrorDetail", res.data["error"]["message"])
