import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants.dart';

class ReminderService {
  ReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _timezoneInitialized = false;
  bool? _permissionGranted;

  static const _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const _insightNotificationId = 9101;
  static const _previewNotificationId = 9102;
  static const _quotes = <String>[
    'Small steady steps beat burnout over time.',
    'Rest is productive when it protects your consistency.',
    'Progress does not require perfect days.',
    'Protect energy first, then scale effort.',
    'A short reset now prevents a long crash later.',
  ];

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);
    await _initializeTimezone();
    _initialized = true;
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Keep local fallback even when timezone lookup fails.
    }
    _timezoneInitialized = true;
  }

  Future<bool> _ensureNotificationPermission() async {
    await initialize();
    if (_permissionGranted != null) {
      return _permissionGranted!;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission() ?? true;
    _permissionGranted = granted;
    return granted;
  }

  Future<void> enableDailyReminder() async {
    if (!await _ensureNotificationPermission()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.reminderChannelId,
        AppConstants.reminderChannelName,
        channelDescription: AppConstants.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.cancel(id: AppConstants.reminderNotificationId);
    await _plugin.zonedSchedule(
      id: AppConstants.reminderNotificationId,
      title: 'Morning burnout check-in',
      body:
          'Sync sleep/exercise, log mood/work, and stay ahead today. ${_quotes[_quoteIndexFromNow()]}',
      scheduledDate: _nextMorningTime(hour: 8, minute: 0),
      notificationDetails: details,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, true);
  }

  Future<void> disableDailyReminder() async {
    await _plugin.cancel(id: AppConstants.reminderNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, false);
  }

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyReminderEnabledKey) ?? false;
  }

  Future<void> showBurnoutInsightNotification({
    required int score,
    required String classification,
    required List<String> causes,
  }) async {
    if (!await _ensureNotificationPermission()) return;

    final level = classification.toUpperCase();
    final suggestion = _buildSuggestion(causes, score);
    final quote = _quotes[_quoteIndexFromNow()];

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.reminderChannelId,
        AppConstants.reminderChannelName,
        channelDescription: AppConstants.reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      id: _insightNotificationId,
      title: 'Burnout Radar: $level risk ($score)',
      body: '$suggestion  "$quote"',
      notificationDetails: details,
    );
  }

  Future<void> sendPreviewNotification() async {
    if (!await _ensureNotificationPermission()) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.reminderChannelId,
        AppConstants.reminderChannelName,
        channelDescription: AppConstants.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(
      id: _previewNotificationId,
      title: 'Burnout Radar reminder',
      body: _quotes[_quoteIndexFromNow()],
      notificationDetails: details,
    );
  }

  String _buildSuggestion(List<String> causes, int score) {
    if (causes.contains('LOW_SLEEP')) {
      return 'Prioritize sleep tonight and close screens earlier.';
    }
    if (causes.contains('HIGH_WORKLOAD')) {
      return 'Trim one low-value task and focus on essentials.';
    }
    if (causes.contains('LOW_MOOD')) {
      return 'Take a short reset walk or breathing break.';
    }
    if (causes.contains('LOW_EXERCISE')) {
      return 'Add 15-20 minutes of light exercise today.';
    }
    if (score >= AppConstants.highAlertThreshold) {
      return 'Take a recovery block now before continuing deep work.';
    }
    return 'Keep momentum with one focused block and one short break.';
  }

  int _quoteIndexFromNow() {
    return DateTime.now().millisecondsSinceEpoch % _quotes.length;
  }

  tz.TZDateTime _nextMorningTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
