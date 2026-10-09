from django.apps import AppConfig
from django.db.models.signals import post_migrate


class CommonConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "common"

    def ready(self):
        from . import cache_signals, image_signals  # noqa: F401  (register signals)
        from .rls import enable_supabase_rls

        # Deliberately connected WITHOUT a sender: `common` has no
        # models_module, so a sender-filtered post_migrate (sender=CommonConfig)
        # would never fire (django/core/management/sql.py skips such apps).
        # The handler is idempotent + guarded to run once per process.
        post_migrate.connect(
            enable_supabase_rls, dispatch_uid="common.enable_supabase_rls"
        )
