import uuid

from django.db import models


class UserProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.TextField()
    avatar = models.TextField(blank=True)
    timezone = models.TextField(default="UTC")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username
