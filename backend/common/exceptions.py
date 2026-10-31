import logging
from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.response import Response
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)


def _error_messages(detail):
    """Human sentences from a DRF error detail tree.

    str() on a ValidationError detail dict produces the Python repr
    ("{'password': [ErrorDetail(...]]}") — which must never reach a client.
    This flattens any nesting to plain message strings instead.
    """
    if isinstance(detail, dict):
        messages = []
        for value in detail.values():
            messages.extend(_error_messages(value))
        return messages
    if isinstance(detail, (list, tuple)):
        messages = []
        for value in detail:
            messages.extend(_error_messages(value))
        return messages
    text = str(detail).strip() if detail is not None else ""
    return [text] if text else []


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
        sentences = [m.rstrip(".") for m in _error_messages(exc.detail)]
        sentences = [s for s in sentences if s]
        if sentences:
            text = ". ".join(sentences)
            error_data["error"]["message"] = text if text[-1] in ".!?" else text + "."

    # Add request ID if available
    request = context.get("request")
    if request and hasattr(request, "id"):
        error_data["error"]["request_id"] = request.id

    response.data = error_data
    return response