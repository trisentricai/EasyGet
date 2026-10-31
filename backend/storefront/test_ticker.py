"""Ticker tests: defaults, custom config, privacy gate, bad data."""

from django.test import TestCase

from admin_panel.models import SystemConfig
from storefront.ticker import DEFAULT_TICKER, get_ticker_config, sanitize_ticker


class TickerConfigTests(TestCase):
    def test_defaults_when_missing(self):
        ticker = get_ticker_config()
        self.assertEqual(ticker["items"], DEFAULT_TICKER["items"])
        self.assertEqual(ticker["speed"], 26)

    def test_custom_public_config_returned(self):
        SystemConfig.objects.create(
            key="ticker",
            value='{"items": ["Hello", "World"], "speed": 10, "color": "#123456"}',
            config_type=SystemConfig.ConfigType.JSON,
            is_public=True,
        )
        ticker = get_ticker_config()
        self.assertEqual(ticker["items"], ["Hello", "World"])
        self.assertEqual(ticker["speed"], 10)
        self.assertEqual(ticker["color"], "#123456")

    def test_private_config_ignored(self):
        SystemConfig.objects.create(
            key="ticker",
            value='{"items": ["Secret"]}',
            config_type=SystemConfig.ConfigType.JSON,
            is_public=False,
        )
        self.assertEqual(get_ticker_config()["items"], DEFAULT_TICKER["items"])

    def test_malformed_config_falls_back(self):
        self.assertEqual(sanitize_ticker(None)["items"], DEFAULT_TICKER["items"])
        self.assertEqual(sanitize_ticker("not-a-dict")["items"], DEFAULT_TICKER["items"])
        self.assertEqual(
            sanitize_ticker({"items": [], "speed": "fast"})["speed"],
            DEFAULT_TICKER["speed"],
        )
        ticker = sanitize_ticker({"items": ["  ", "OK"], "color": "nope"})
        self.assertEqual(ticker["items"], ["OK"])
        self.assertEqual(ticker["color"], DEFAULT_TICKER["color"])
