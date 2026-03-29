from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import BreathingSessionViewSet

router = DefaultRouter()
router.register(r"sessions", BreathingSessionViewSet, basename="sessions")

urlpatterns = [
    path("", include(router.urls)),
]
