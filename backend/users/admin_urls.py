from django.urls import path

from . import views

urlpatterns = [
    path("only/", views.AdminOnlyView.as_view(), name="admin-only"),
]