from django.contrib import admin

from .models import Payment, PaymentMethod, Refund


@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = ("user", "type", "is_default", "card_last4", "upi_id", "is_active", "created_at")
    list_filter = ("type", "is_default", "is_active")
    search_fields = ("user__email", "card_last4", "upi_id", "gateway_token")
    readonly_fields = ("created_at", "updated_at")
    list_per_page = 25


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ("payment_id", "order", "user", "gateway", "status", "amount", "created_at")
    list_filter = ("gateway", "status", "created_at")
    search_fields = ("payment_id", "order__order_number", "user__email", "gateway_payment_id")
    readonly_fields = (
        "payment_id",
        "order",
        "user",
        "payment_method",
        "gateway",
        "amount",
        "currency",
        "gateway_payment_id",
        "gateway_order_id",
        "gateway_response",
        "failure_reason",
        "refunded_amount",
        "processed_at",
        "created_at",
        "updated_at",
    )
    list_per_page = 25


@admin.register(Refund)
class RefundAdmin(admin.ModelAdmin):
    list_display = ("refund_id", "payment", "amount", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("refund_id", "payment__payment_id", "gateway_refund_id")
    readonly_fields = (
        "refund_id",
        "payment",
        "amount",
        "reason",
        "gateway_refund_id",
        "gateway_response",
        "processed_at",
        "created_at",
        "updated_at",
    )
    list_per_page = 25