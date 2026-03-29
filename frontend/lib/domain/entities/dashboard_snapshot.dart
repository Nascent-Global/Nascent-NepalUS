import '../../data/models/app_alert.dart';
import '../../data/models/burnout_score.dart';
import '../../data/models/burnout_task.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.latestScore,
    required this.causes,
    required this.todayTasks,
    required this.trend,
    required this.direction,
    required this.alerts,
  });

  final BurnoutScore? latestScore;
  final List<String> causes;
  final List<BurnoutTask> todayTasks;
  final List<BurnoutScore> trend;
  final String direction;
  final List<AppAlert> alerts;
}
