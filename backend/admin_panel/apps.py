from django.apps import AppConfig


class AdminPanelConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "admin_panel"
    verbose_name = "Admin Panel"

    def ready(self):
        from . import signals  # noqa: F401 — registers cache invalidation