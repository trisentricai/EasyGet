from django.apps import AppConfig


class RealtimeConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "realtime"
    verbose_name = "Real-time"

    def ready(self):
        # Import consumers to register signal handlers
        try:
            import realtime.signals  # noqa: F401
        except ImportError:
            pass