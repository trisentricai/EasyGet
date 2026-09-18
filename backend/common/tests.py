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
