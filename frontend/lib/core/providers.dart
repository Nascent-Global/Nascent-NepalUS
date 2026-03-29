import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'auth_providers.dart';
import '../data/local/app_database.dart';
import '../data/models/app_alert.dart';
import '../data/models/burnout_task.dart';
import '../data/remote/burnout_sync_api_client.dart';
import '../data/repository/burnout_repository.dart';
import '../data/repository/local_burnout_repository.dart';
import '../domain/entities/dashboard_snapshot.dart';
import '../domain/services/burnout_engine.dart';
import '../domain/services/health_connect_service.dart';
import '../domain/services/reminder_service.dart';
import '../domain/services/sync_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final burnoutRepositoryProvider = Provider<BurnoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalBurnoutRepository(db);
});

final burnoutEngineProvider = Provider<BurnoutEngine>((ref) {
  final repository = ref.watch(burnoutRepositoryProvider);
  final reminderService = ref.watch(reminderServiceProvider);
  return BurnoutEngine(repository, reminderService: reminderService);
});

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  return HealthConnectService();
});

final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  return ReminderService(plugin);
});

final reminderBootstrapProvider = Provider<void>((ref) {
  final reminderService = ref.watch(reminderServiceProvider);

  Future<void> bootstrap() async {
    try {
      await reminderService.initialize();
      await reminderService.enableDailyReminder();
    } catch (_) {
      // Keep app startup non-blocking if notification setup fails.
    }
  }

  unawaited(bootstrap());
});

final burnoutSyncApiClientProvider = Provider<BurnoutSyncApiClient>((ref) {
  return BurnoutSyncApiClient(baseUrl: AppConfig.apiBaseUrl);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    database: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(burnoutSyncApiClientProvider),
  );
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

final syncBootstrapProvider = Provider<void>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  Timer? timer;
  var inFlight = false;

  Future<void> runSync() async {
    if (inFlight) return;
    final session = ref.read(authControllerProvider).session;
    if (session == null) return;

    inFlight = true;
    try {
      final report = await syncService.syncNow(session: session);
      if (report.hasChanges) {
        ref.read(refreshTickProvider.notifier).bump();
      }
    } on SyncApiException catch (_) {
      // Offline or backend unavailable: keep the app local-first and retry later.
    } catch (_) {
      // Never block UI from sync failures.
    } finally {
      inFlight = false;
    }
  }

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    final hasNewSession = previous?.session == null && next.session != null;
    if (hasNewSession) {
      unawaited(runSync());
    }
  });

  timer = Timer.periodic(const Duration(minutes: 2), (_) {
    unawaited(runSync());
  });

  unawaited(runSync());
  ref.onDispose(() => timer?.cancel());
});
