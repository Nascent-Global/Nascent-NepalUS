import uuid

from django.db import models


class BreathingSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    started_at = models.DateTimeField(null=True, blank=True)
    duration = models.IntegerField(null=True, blank=True)  # seconds
    completed = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    def __str__(self):
        return f"Breathing({self.started_at} - {self.duration}s)"
