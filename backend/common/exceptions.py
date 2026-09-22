import logging
from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)


def custom_exception_handler(exc, context):
    """Custom exception handler with standardized error format."""
    response = exception_handler(exc, context)

    if response is None:
        logger.exception("Unhandled exception", exc_info=exc)
        return Response(
            {
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": "An unexpected error occurred",
                    "details": None,
                }
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    # Standardize error format
    error_data = {
        "error": {
            "code": getattr(exc, "default_code", "ERROR"),
            "message": str(exc.detail) if hasattr(exc, "detail") else str(exc),
            "details": None,
        }
    }

    if isinstance(exc, ValidationError):
        error_data["error"]["code"] = "VALIDATION_ERROR"
        error_data["error"]["details"] = exc.detail

    # Add request ID if available
    request = context.get("request")
    if request and hasattr(request, "id"):
        error_data["error"]["request_id"] = request.id

    response.data = error_data
    return response