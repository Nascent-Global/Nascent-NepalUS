enum BurnoutCauseType {
  lowSleep,
  highWorkload,
  lowMood,
  negativeCheckIn,
  deadlinePressure,
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
      case BurnoutCauseType.negativeCheckIn:
        return 'NEGATIVE_CHECKIN';
      case BurnoutCauseType.deadlinePressure:
        return 'DEADLINE_PRESSURE';
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
      case BurnoutCauseType.negativeCheckIn:
        return 'Self check-in was not okay';
      case BurnoutCauseType.deadlinePressure:
        return 'Deadline pressure is building';
      case BurnoutCauseType.risingTrend:
        return 'Burnout trend is rising';
    }
  }
}
