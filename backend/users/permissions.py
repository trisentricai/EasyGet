from rest_framework.permissions import BasePermission

from .models import User


class IsVerifiedEmail(BasePermission):
    message = "Email verification required."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.is_email_verified
        )


def role_required(*allowed_roles):
    allowed = set(allowed_roles)

    class RoleRequired(BasePermission):
        message = "Forbidden."

        def has_permission(self, request, view):
            return bool(
                request.user
                and request.user.is_authenticated
                and request.user.role in allowed
            )

    return RoleRequired


IsAdminOnly = role_required(User.Role.ADMIN)