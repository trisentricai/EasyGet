from django.conf import settings
from django.core.mail import send_mail


def send_otp_email(user, code, purpose="verify your email"):
    """Send the OTP. Dev uses the console email backend (code prints to console)."""
    subject = f"EASYGET — OTP to {purpose}"
    body = (
        f"Hi {user.first_name or user.email},\n\n"
        f"Your EASYGET verification code is: {code}\n\n"
        "This code expires in 10 minutes. If you did not request it, ignore this email."
    )
    send_mail(subject, body, settings.DEFAULT_FROM_EMAIL, [user.email])