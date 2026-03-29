enum BurnoutCauseType {
  lowSleep,
  highWorkload,
  lowMood,
  lowExercise,
  risingTrend,
}

extension BurnoutCauseTypeX on BurnoutCauseType {
  String get key {
    switch (this) {
      case BurnoutCauseType.lowSleep:
        return 'LOW_SLEEP';
      case BurnoutCauseType.highWorkload:
        return 'HIGH_WORKLOAD';
      case BurnoutCauseType.lowMood:
        return 'LOW_MOOD';
      case BurnoutCauseType.lowExercise:
        return 'LOW_EXERCISE';
      case BurnoutCauseType.risingTrend:
        return 'RISING_TREND';
    }
  }

  String get title {
    switch (this) {
      case BurnoutCauseType.lowSleep:
        return 'Low sleep quality';
      case BurnoutCauseType.highWorkload:
        return 'Workload is high';
      case BurnoutCauseType.lowMood:
        return 'Mood has dropped';
      case BurnoutCauseType.lowExercise:
        return 'Exercise is too low';
      case BurnoutCauseType.risingTrend:
        return 'Burnout trend is rising';
    }
  }
}
