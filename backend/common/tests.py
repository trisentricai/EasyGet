from unittest import mock

from django.test import TestCase


class HealthEndpointTests(TestCase):
    def test_health_endpoint_returns_ok(self):
        response = self.client.get("/api/v1/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "ok")

    def test_health_endpoint_allows_customer_web_origin(self):
        response = self.client.get(
            "/api/v1/health/", HTTP_ORIGIN="http://localhost:5173"
        )
        self.assertEqual(response["access-control-allow-origin"], "http://localhost:5173")

    def test_health_endpoint_does_not_allow_unknown_origin(self):
        response = self.client.get(
            "/api/v1/health/", HTTP_ORIGIN="https://untrusted.example"
        )
        self.assertNotIn("access-control-allow-origin", response)


class PincodeLookupTests(TestCase):
    """Live pincode check: format guard, API lookup, offline fallback."""

    def setUp(self):
        from common.views import _PINCODE_CACHE

        _PINCODE_CACHE.clear()
        self.cache = _PINCODE_CACHE

    def test_bad_format_rejected(self):
        res = self.client.get("/api/v1/pincode/12345/")
        self.assertEqual(res.status_code, 400)
        res = self.client.get("/api/v1/pincode/abcdef/")
        self.assertEqual(res.status_code, 400)

    def test_api_lookup_same_state_two_day_eta(self):
        from stores.models import Store
        from decimal import Decimal

        Store.objects.create(
            name="Pina Store", city="Chennai", state="Tamil Nadu",
            postal_code="600001", latitude=Decimal("13.0827"),
            longitude=Decimal("80.2707"), is_active=True,
        )
        fake = [
            {
                "Status": "Success",
                "PostOffice": [{"District": "Chennai", "State": "Tamil Nadu"}],
            }
        ]
        with mock.patch("requests.get") as get:
            get.return_value.json.return_value = fake
            res = self.client.get("/api/v1/pincode/600001/")
        self.assertEqual(res.status_code, 200, res.data)
        self.assertTrue(res.data["valid"])
        self.assertEqual(res.data["city"], "Chennai")
        self.assertEqual(res.data["source"], "api")
        self.assertEqual(res.data["eta_days"], 2)
        self.assertEqual(res.data["delivery_fee"], "29.00")

    def test_api_lookup_other_state_four_day_eta(self):
        from stores.models import Store
        from decimal import Decimal

        Store.objects.create(
            name="Pina Store 2", city="Chennai", state="Tamil Nadu",
            postal_code="600001", latitude=Decimal("13.0827"),
            longitude=Decimal("80.2707"), is_active=True,
        )
        fake = [
            {
                "Status": "Success",
                "PostOffice": [{"District": "Pune", "State": "Maharashtra"}],
            }
        ]
        with mock.patch("requests.get") as get:
            get.return_value.json.return_value = fake
            res = self.client.get("/api/v1/pincode/411001/")
        self.assertEqual(res.status_code, 200, res.data)
        self.assertEqual(res.data["eta_days"], 4)

    def test_unknown_pincode_404(self):
        fake = [{"Status": "Error", "PostOffice": None}]
        with mock.patch("requests.get") as get:
            get.return_value.json.return_value = fake
            res = self.client.get("/api/v1/pincode/000000/")
        self.assertEqual(res.status_code, 404)
        self.assertFalse(res.data["valid"])

    def test_network_down_falls_back_to_heuristic(self):
        with mock.patch("requests.get") as get:
            get.side_effect = OSError("network down")
            res = self.client.get("/api/v1/pincode/560001/")
        self.assertEqual(res.status_code, 200, res.data)
        self.assertTrue(res.data["valid"])
        self.assertEqual(res.data["source"], "fallback")
        self.assertEqual(res.data["eta_days"], 4)


class PincodeStateAliasTests(TestCase):
    """Store 'TN' must match postal API 'Tamil Nadu' for the 2-day ETA."""

    def setUp(self):
        from common.views import _PINCODE_CACHE

        _PINCODE_CACHE.clear()

    def test_two_letter_store_state_matches_full_name(self):
        from decimal import Decimal

        from stores.models import Store

        Store.objects.create(
            name="Alias Store", city="Chennai", state="TN",
            postal_code="600001", latitude=Decimal("13.0827"),
            longitude=Decimal("80.2707"), is_active=True,
        )
        fake = [
            {
                "Status": "Success",
                "PostOffice": [{"District": "Chennai", "State": "Tamil Nadu"}],
            }
        ]
        with mock.patch("requests.get") as get:
            get.return_value.json.return_value = fake
            res = self.client.get("/api/v1/pincode/600001/")
        self.assertEqual(res.status_code, 200, res.data)
        self.assertEqual(res.data["eta_days"], 2)


class PincodeStoreStateTests(TestCase):
    """_store_state must skip the platform (EASYGET) row created by migration."""

    def setUp(self):
        from common.views import _PINCODE_CACHE

        _PINCODE_CACHE.clear()

    def test_store_state_ignores_platform_store(self):
        from decimal import Decimal

        from common.views import _store_state
        from stores.models import Store

        Store.objects.create(
            name="Demo TN", city="Chennai", state="Tamil Nadu",
            postal_code="600001", latitude=Decimal("13.0827"),
            longitude=Decimal("80.2707"), is_active=True,
        )
        # The migration's platform store (Karnataka) is older; it must not win.
        self.assertEqual(_store_state(), "Tamil Nadu")
