from django.contrib.auth.models import AbstractUser
from django.db import models

class HKSUser(AbstractUser):
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('worker', 'Worker'),
        ('household', 'Household'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='household')
    phone = models.CharField(max_length=15, blank=True, null=True, unique=True)

    class Meta:
        verbose_name = 'HKS User'

    def __str__(self):
        return f"{self.username} ({self.role})"
