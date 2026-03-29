import uuid

from django.db import models


class PomodoroSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    duration = models.IntegerField(null=True, blank=True)  # seconds
    completed = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    class Meta:
        indexes = [models.Index(fields=["start_time"], name="idx_pomodoro_start")]
        ordering = ["-start_time"]

    def __str__(self):
        return f"Pomodoro({self.start_time} - {self.duration}s)"
