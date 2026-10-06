from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "users"

    def ready(self):
        # Surface malformed Firebase credentials at boot (loud warning, never
        # a crash): silent when unconfigured so local dev needs no Firebase.
        from .firebase_auth import firebase_app

        firebase_app()
