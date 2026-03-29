from django.urls import include, path
from rest_framework import routers

from .views import (
    BurnoutCauseViewSet,
    BurnoutScoreViewSet,
    DailyEntryViewSet,
    ScoreLogViewSet,
)

# Router and URL patterns
router = routers.DefaultRouter()
router.register(r"daily_entries", DailyEntryViewSet, basename="dailyentry")
router.register(r"burnout_scores", BurnoutScoreViewSet, basename="burnoutscore")
router.register(r"burnout_causes", BurnoutCauseViewSet, basename="burnoutcause")
router.register(r"score_logs", ScoreLogViewSet, basename="scorelog")

urlpatterns = [path("", include(router.urls))]
