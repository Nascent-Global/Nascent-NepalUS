import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants.dart';

class ReminderService {
  ReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> enableDailyReminder() async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.reminderChannelId,
        AppConstants.reminderChannelName,
        channelDescription: AppConstants.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.periodicallyShow(
      id: AppConstants.reminderNotificationId,
      title: 'Daily burnout check-in',
      body: 'Log your sleep, mood, and workload to stay ahead of burnout.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> disableDailyReminder() async {
    await _plugin.cancel(id: AppConstants.reminderNotificationId);
  }
}
