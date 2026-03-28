import uuid

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


# Daily entries (sleep, work, mood)
class DailyEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField()
    sleep_hours = models.FloatField(null=True, blank=True)
    work_hours = models.FloatField(null=True, blank=True)
    mood = models.PositiveSmallIntegerField(
        null=True, blank=True, validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    was_ok = models.BooleanField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    class Meta:
        indexes = [models.Index(fields=["date"], name="idx_daily_entries_date")]
        ordering = ["-date"]

    def __str__(self):
        return f"DailyEntry({self.date})"


# Burnout scoring / analytics
class BurnoutScore(models.Model):
    CLASS_LOW = "low"
    CLASS_MEDIUM = "medium"
    CLASS_HIGH = "high"
    CLASSIFICATION_CHOICES = [
        (CLASS_LOW, "low"),
        (CLASS_MEDIUM, "medium"),
        (CLASS_HIGH, "high"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField()
    score = models.PositiveSmallIntegerField(
        null=True, blank=True, validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    classification = models.CharField(
        max_length=10, choices=CLASSIFICATION_CHOICES, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=["date"], name="idx_burnout_scores_date"),
            models.Index(fields=["created_at"], name="idx_burnout_scores_created"),
        ]
        ordering = ["-created_at"]

    def __str__(self):
        return f"BurnoutScore({self.date} -> {self.score})"


class BurnoutCause(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    score = models.ForeignKey(
        BurnoutScore, on_delete=models.CASCADE, related_name="causes"
    )
    cause_type = models.TextField()

    def __str__(self):
        return f"Cause({self.cause_type})"


# Score change logs
class ScoreLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    score = models.ForeignKey(
        BurnoutScore, on_delete=models.CASCADE, related_name="logs"
    )
    change_amount = models.IntegerField()
    reason = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    def __str__(self):
        return f"ScoreLog({self.change_amount} for {self.score_id})"
