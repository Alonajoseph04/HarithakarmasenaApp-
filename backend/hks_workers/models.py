from django.db import models
from hks_users.models import HKSUser
from hks_wards.models import Ward

class Worker(models.Model):
    user = models.OneToOneField(HKSUser, on_delete=models.CASCADE, related_name='worker_profile')
    worker_id = models.CharField(max_length=20, unique=True)
    ward = models.ForeignKey(Ward, on_delete=models.SET_NULL, null=True, blank=True, related_name='workers')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.worker_id} - {self.user.get_full_name()}"
