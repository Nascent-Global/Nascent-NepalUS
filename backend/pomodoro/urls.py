from django.urls import include, path
from rest_framework import routers

from .views import PomodoroSessionViewSet

router = routers.DefaultRouter()
router.register(r"sessions", PomodoroSessionViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
