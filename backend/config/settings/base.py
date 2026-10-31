import mimetypes
import os
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parents[3]
env = environ.Env(DJANGO_DEBUG=(bool, False))
environ.Env.read_env(BASE_DIR / ".env")

DEBUG = env("DJANGO_DEBUG")
SECRET_KEY = env("DJANGO_SECRET_KEY", default="")
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = "easyget-local-development-only-not-for-production"
    else:
        raise RuntimeError("DJANGO_SECRET_KEY must be set when DJANGO_DEBUG is false")

ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "drf_spectacular",
    "django_ratelimit",
    "common",
    "users",
    "tenants",
    "stores",
    "categories",
    "products",
    "inventory",
    "storefront",
    "cart",
    "orders",
    "payments",
    "delivery",
    "notifications",
    "search",
    "analytics",
    "channels",
    "realtime",
    "admin_panel",
    "webhooks",
    "pwa",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    # Serves collectstatic output in production (Render has no separate
    # web server); must come right after SecurityMiddleware.
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [],
    "APP_DIRS": True,
    "OPTIONS": {"context_processors": [
        "django.template.context_processors.request",
        "django.contrib.auth.context_processors.auth",
        "django.contrib.messages.context_processors.messages",
    ]},
}]
WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

DATABASES = {"default": env.db("DATABASE_URL", default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}")}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 10},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]
LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kolkata"
USE_I18N = True
USE_TZ = True
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
# Windows' mimetypes registry often lacks .webp → static serve would fall
# back to application/octet-stream.
mimetypes.add_type("image/webp", ".webp", True)
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedStaticFilesStorage"},
}

# Supabase Storage (S3 interop) for media — used when the S3 env vars are
# present (Render); local dev falls back to the filesystem above.
if env("SUPABASE_S3_ENDPOINT", default=""):
    STORAGES["default"] = {
        "BACKEND": "storages.backends.s3.S3Storage",
        "OPTIONS": {
            "endpoint_url": env("SUPABASE_S3_ENDPOINT"),
            "region_name": env("SUPABASE_S3_REGION", default="us-east-1"),
            "access_key": env("SUPABASE_S3_ACCESS_KEY_ID"),
            "secret_key": env("SUPABASE_S3_SECRET_ACCESS_KEY"),
            "bucket_name": env("SUPABASE_S3_BUCKET", default="easyget-media"),
            # Public URLs go through /storage/v1/object/public/<bucket>/...
            # (the S3 endpoint itself is for API calls only).
            "custom_domain": env("SUPABASE_S3_PUBLIC_HOST", default=""),
            "file_overwrite": False,
            "querystring_auth": False,
        },
    }
    # Media are absolute Supabase URLs from here on.
    MEDIA_URL = env("SUPABASE_S3_PUBLIC_URL_PREFIX", default="/media/")

# Uploads switch: serve MEDIA_ROOT from Django when no object storage is
# configured, so uploads display instead of 404ing with zero setup. Default
# ON (uploads must work out of the box); auto-disabled the moment
# SUPABASE_S3_* keys land. WARNING: on ephemeral disks (Render free) files
# vanish on every deploy — treat those uploads as test data and re-upload
# after the S3 cutover (dead /media/ rows need cleanup then).
SERVE_MEDIA_EPHEMERAL = env.bool("SERVE_MEDIA_EPHEMERAL", default=True) and not bool(
    env("SUPABASE_S3_ENDPOINT", default="")
)

CORS_ALLOWED_ORIGINS = env.list(
    "DJANGO_CORS_ALLOWED_ORIGINS",
    default=[
        "http://localhost:5173",
        "http://localhost:5174",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8181",
        "http://127.0.0.1:8181",
    ],
)

# Caching
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": env("REDIS_URL", default="redis://localhost:6379/0"),
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
            # Fail soft: if Redis is unreachable (local dev has no Docker),
            # cache reads/writes degrade to cache-miss instead of raising.
            # Throttling/ratelimiting then allow traffic rather than 500-ing.
            "IGNORE_EXCEPTIONS": True,
            # RESP2: redis-py 8 handshakes with HELLO (RESP3), which older
            # Redis servers reject — without this every cache write silently
            # fails and ALL rate limiting silently disables itself.
            "CONNECTION_POOL_KWARGS": {"protocol": 2},
        },
    },
}

# Rate limiting
RATELIMIT_USE_CACHE = "default"

REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
        # Applies only to views that declare a `throttle_scope`; views without
        # one are untouched. login/register/otp scopes are set on auth views.
        "rest_framework.throttling.ScopedRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "100/minute",
        "user": "1000/minute",
        "login": "5/minute",
        # Firebase token exchange gets its own budget: ID tokens are
        # cryptographically signed (not brute-forceable like passwords), and
        # sharing the login bucket would let one channel starve the other.
        "firebase": "30/minute",
        "register": "3/minute",
        "otp": "10/minute",
        "password_reset": "2/hour",
    },
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_PAGINATION_CLASS": "common.pagination.Max20PagePagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "common.exceptions.custom_exception_handler",
}

SPECTACULAR_SETTINGS = {
    "TITLE": "EasyGet API",
    "DESCRIPTION": "Q-Commerce Platform API Documentation",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    "COMPONENT_SPLIT_REQUEST": True,
    "SORT_OPERATIONS": False,
    "TAGS_SORTER": "alpha",
    "OPERATIONS_SORTER": "alpha",
    "SCHEMA_PATH_PREFIX": "/api/v1",
    "SERVE_PERMISSIONS": ["rest_framework.permissions.IsAdminUser"],
    "SECURITY": [{"BearerAuth": []}],
    "COMPONENTS": {
        "securitySchemes": {
            "BearerAuth": {
                "type": "http",
                "scheme": "bearer",
                "bearerFormat": "JWT",
            },
        },
    },
}

AUTH_USER_MODEL = "users.User"

SIMPLE_JWT = {
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": True,
}

EMAIL_BACKEND = env(
    "DJANGO_EMAIL_BACKEND", default="django.core.mail.backends.console.EmailBackend"
)
DEFAULT_FROM_EMAIL = env("DJANGO_DEFAULT_FROM_EMAIL", default="noreply@easyget.app")
# SMTP (production): set DJANGO_EMAIL_BACKEND to the smtp backend plus these.
# Console default above means local dev needs nothing; Render needs all five
# (Gmail: HOST=smtp.gmail.com, PORT=587, TLS on, USER=address, PASSWORD=app
# password — NOT the account password).
EMAIL_HOST = env("DJANGO_EMAIL_HOST", default="")
EMAIL_PORT = env.int("DJANGO_EMAIL_PORT", default=587)
EMAIL_HOST_USER = env("DJANGO_EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env("DJANGO_EMAIL_HOST_PASSWORD", default="")
EMAIL_USE_TLS = env.bool("DJANGO_EMAIL_USE_TLS", default=True)

REDIS_URL = env("REDIS_URL", default="redis://localhost:6379/0")
CELERY_BROKER_URL = env("CELERY_BROKER_URL", default="redis://localhost:6379/1")
CELERY_RESULT_BACKEND = env("CELERY_RESULT_BACKEND", default="redis://localhost:6379/2")
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 300
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = TIME_ZONE
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"

# Channels
ASGI_APPLICATION = "config.asgi.application"
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [env("REDIS_URL", default="redis://localhost:6379/0")],
        },
    },
}

# Test settings override
import sys
if "test" in sys.argv:
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        },
    }

# Security headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"

if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    # Render terminates TLS at its proxy — without this Django sees plain
    # HTTP on every request and SECURE_SSL_REDIRECT loops forever.
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Origins allowed to POST session/CSRF-protected forms (Django admin, DRF
# browsable bits). JWT API calls only need CORS_ALLOWED_ORIGINS above.
CSRF_TRUSTED_ORIGINS = env.list("DJANGO_CSRF_TRUSTED_ORIGINS", default=[])

# Logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
        "json": {
            "()": "pythonjsonlogger.jsonlogger.JsonFormatter",
            "format": "%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
        "django.request": {
            "handlers": ["console"],
            "level": "ERROR",
            "propagate": False,
        },
        "celery": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}

# Health checks
HEALTH_CHECK = {
    "DISK_USAGE_MAX": 90,  # percent
    "MEMORY_MIN": 100,  # MB
}

# Prometheus metrics
PROMETHEUS_EXPORT_MIGRATIONS = False

# Google sign-in WITHOUT Firebase (GIS button on web, google_sign_in on app).
# Comma-separated OAuth client IDs whose ID tokens we accept (web client +
# Android client from google-services.json). Empty locally: /auth/google/
# answers 503 while everything else works.
GOOGLE_OAUTH_CLIENT_IDS = env("GOOGLE_OAUTH_CLIENT_IDS", default="")
