import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/models/app_alert.dart';
import '../data/models/burnout_task.dart';
import '../data/repository/burnout_repository.dart';
import '../data/repository/local_burnout_repository.dart';
import '../domain/entities/dashboard_snapshot.dart';
import '../domain/services/burnout_engine.dart';
import '../domain/services/reminder_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final burnoutRepositoryProvider = Provider<BurnoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalBurnoutRepository(db);
});

final burnoutEngineProvider = Provider<BurnoutEngine>((ref) {
  final repository = ref.watch(burnoutRepositoryProvider);
  return BurnoutEngine(repository);
});

final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  return ReminderService(plugin);
});

final refreshTickProvider = NotifierProvider<RefreshTickNotifier, int>(
  RefreshTickNotifier.new,
);

class RefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((
  ref,
) async {
  ref.watch(refreshTickProvider);
  final engine = ref.watch(burnoutEngineProvider);
  return engine.getDashboardSnapshot();
});

final todayTasksProvider = FutureProvider<List<BurnoutTask>>((ref) async {
  ref.watch(refreshTickProvider);
  final repository = ref.watch(burnoutRepositoryProvider);
  return repository.getTasksByDate(DateTime.now().toUtc());
});

final alertsProvider = FutureProvider<List<AppAlert>>((ref) async {
  ref.watch(refreshTickProvider);
  final repository = ref.watch(burnoutRepositoryProvider);
  return repository.getAlerts(limit: 50);
});
