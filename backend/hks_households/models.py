import qrcode
import uuid
import base64
from io import BytesIO
from django.db import models
from hks_users.models import HKSUser
from hks_wards.models import Ward

class Household(models.Model):
    user = models.OneToOneField(HKSUser, on_delete=models.CASCADE, related_name='household_profile', null=True, blank=True)
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=15, blank=True, null=True)
    ward = models.ForeignKey('hks_wards.Ward', on_delete=models.SET_NULL, null=True, blank=True, related_name='households')
    address = models.TextField(blank=True, null=True)
    qr_code = models.CharField(max_length=100, unique=True, blank=True)
    qr_image = models.ImageField(upload_to='qr_codes/', blank=True, null=True)
    monthly_fee = models.DecimalField(max_digits=8, decimal_places=2, default=100.00)
    upi_id = models.CharField(max_length=100, blank=True, null=True, help_text='Household UPI ID for payment')
    preferred_payment = models.CharField(max_length=10, choices=[('cash','Cash'),('upi','UPI')], default='cash')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)


    def save(self, *args, **kwargs):
        if not self.qr_code:
            self.qr_code = f"HKS-{uuid.uuid4().hex[:10].upper()}"
        super().save(*args, **kwargs)
        # Generate QR image
        if not self.qr_image:
            self._generate_qr_image()

    def _generate_qr_image(self):
        qr = qrcode.QRCode(version=1, box_size=10, border=4)
        qr.add_data(self.qr_code)
        qr.make(fit=True)
        img = qr.make_image(fill='black', back_color='white')
        buffer = BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        filename = f"qr_{self.qr_code}.png"
        self.qr_image.save(filename, buffer, save=True)

    def get_qr_base64(self):
        try:
            qr = qrcode.QRCode(version=1, box_size=10, border=4)
            qr.add_data(self.qr_code)
            qr.make(fit=True)
            img = qr.make_image(fill='black', back_color='white')
            buffer = BytesIO()
            img.save(buffer, format='PNG')
            return base64.b64encode(buffer.getvalue()).decode()
        except:
            return ""

    def __str__(self):
        return f"{self.name} - {self.ward}"
