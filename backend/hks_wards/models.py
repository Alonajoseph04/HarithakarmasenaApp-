from django.db import models

class Ward(models.Model):
    name = models.CharField(max_length=100)
    total_houses = models.IntegerField(default=0)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
