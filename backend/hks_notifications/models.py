from django.db import models
from hks_users.models import HKSUser

NOTIFICATION_TYPES = [
    ('collection', 'Collection Confirmation'),
    ('payment', 'Payment Confirmation'),
    ('reminder', 'Collection Reminder'),
    ('broadcast', 'Admin Broadcast'),
    ('pickup', 'Extra Pickup Request'),
    ('feedback', 'Worker Feedback'),
    ('general', 'General'),
]

class Notification(models.Model):
    recipient = models.ForeignKey(HKSUser, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    message_ml = models.TextField(blank=True, default='', help_text='Malayalam translation of message')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES, default='general')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.notification_type} for {self.recipient.username}"
