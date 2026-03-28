import uuid

from django.db import models


# Tasks
class Task(models.Model):
    TASK_USER = "user"
    TASK_RECOVERY = "recovery"
    TASK_TYPE_CHOICES = [(TASK_USER, "user"), (TASK_RECOVERY, "recovery")]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField()
    title = models.TextField()
    deadline = models.DateTimeField(null=True, blank=True)
    priority = models.IntegerField(null=True, blank=True)
    completed = models.BooleanField(default=False)
    task_type = models.CharField(
        max_length=20, choices=TASK_TYPE_CHOICES, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    synced = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=["date"], name="idx_tasks_date"),
            models.Index(fields=["task_type"], name="idx_tasks_type"),
        ]
        ordering = ["-date"]

    def __str__(self):
        return f"Task({self.title} - {self.date})"
