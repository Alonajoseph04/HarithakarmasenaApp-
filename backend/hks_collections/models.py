from django.db import models
from django.utils import timezone
from hks_households.models import Household
from hks_workers.models import Worker

WASTE_TYPES = [
    ('plastic', 'Plastic'),
    ('ewaste', 'E-Waste'),
    ('organic', 'Organic'),
    ('mixed', 'Mixed'),
    ('paper', 'Paper'),
    ('glass', 'Glass'),
    ('metal', 'Metal'),
]

PAYMENT_METHODS = [
    ('cash', 'Cash'),
    ('upi', 'UPI'),
    ('pending', 'Pending'),
]

class Collection(models.Model):
    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='collections')
    worker = models.ForeignKey(Worker, on_delete=models.CASCADE, related_name='collections')
    date = models.DateField()
    waste_type = models.CharField(max_length=20, choices=WASTE_TYPES)
    weight = models.DecimalField(max_digits=6, decimal_places=2, help_text='Weight in kg')
    rate = models.DecimalField(max_digits=6, decimal_places=2, help_text='Rate per kg in INR')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    cleanliness = models.IntegerField(choices=[(i, i) for i in range(1, 6)], default=3, help_text='1=Poor,5=Excellent')
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHODS, default='cash')
    payment_status = models.CharField(max_length=20, choices=[('paid','Paid'),('pending','Pending')], default='paid')
    notes = models.TextField(blank=True)
    # Household feedback on worker
    worker_rating = models.IntegerField(null=True, blank=True, choices=[(i, i) for i in range(1, 5)], help_text='1-4: Poor/Average/Good/Excellent')
    worker_feedback = models.TextField(blank=True, null=True, help_text='Optional feedback text from household')
    # Structured feedback (each 1=Poor 2=Average 3=Good 4=Excellent)
    feedback_punctuality = models.IntegerField(null=True, blank=True, choices=[(1,'Poor'),(2,'Average'),(3,'Good'),(4,'Excellent')])
    feedback_cleanliness = models.IntegerField(null=True, blank=True, choices=[(1,'Poor'),(2,'Average'),(3,'Good'),(4,'Excellent')])
    feedback_attitude    = models.IntegerField(null=True, blank=True, choices=[(1,'Poor'),(2,'Average'),(3,'Good'),(4,'Excellent')])
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.amount:
            self.amount = self.weight * self.rate
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Collection at {self.household.name} on {self.date}"

    class Meta:
        ordering = ['-date', '-created_at']


class SkipRequest(models.Model):
    """Household sends this when they want to skip collection for a day."""
    STATUS_CHOICES = [('pending', 'Pending'), ('acknowledged', 'Acknowledged')]
    household = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='skip_requests')
    date = models.DateField(help_text='Date for which collection is to be skipped')
    reason = models.TextField(blank=True)
    payment_action = models.CharField(
        max_length=20,
        choices=[('defer', 'Defer to next month'), ('waive', 'Waive')],
        default='defer'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    acknowledged_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Skip request by {self.household.name} on {self.date}"

    class Meta:
        ordering = ['-date']


RATING_LABELS = {1: 'Poor', 2: 'Average', 3: 'Good', 4: 'Excellent'}
RATING_LABELS_ML = {1: 'മോശം', 2: 'ശരാശരി', 3: 'നല്ലത്', 4: 'മികച്ചത്'}


class ExtraPickupRequest(models.Model):
    """Household requests an extra waste type to be collected on the same day."""
    STATUS_CHOICES = [
        ('pending',  'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    household   = models.ForeignKey(Household, on_delete=models.CASCADE, related_name='extra_pickup_requests')
    waste_type  = models.CharField(max_length=20, choices=WASTE_TYPES)
    date        = models.DateField(default=timezone.localdate)
    notes       = models.TextField(blank=True)
    status      = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reviewed_by = models.ForeignKey(Worker, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_pickup_requests')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at  = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Extra {self.waste_type} pickup for {self.household.name} on {self.date} [{self.status}]"

    class Meta:
        ordering = ['-created_at']
