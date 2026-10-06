from django.urls import path

from . import views

urlpatterns = [
    path("only/", views.AdminOnlyView.as_view(), name="admin-only"),
    path("users/", views.AdminUserListCreateView.as_view(), name="admin-users"),
    path("users/<int:pk>/", views.AdminUserUpdateView.as_view(), name="admin-user-detail"),
]