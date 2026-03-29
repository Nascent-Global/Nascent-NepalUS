import 'dart:io';

import 'package:health/health.dart';

class HealthSignalsSnapshot {
  const HealthSignalsSnapshot({
    required this.sleepHours,
    required this.exerciseMinutes,
    required this.healthConnectAvailable,
    required this.permissionsGranted,
    required this.usedFallback,
    required this.message,
    required this.syncedAt,
  });

  final double sleepHours;
  final int exerciseMinutes;
  final bool healthConnectAvailable;
  final bool permissionsGranted;
  final bool usedFallback;
  final String message;
  final DateTime syncedAt;
}

class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const double fallbackSleepHours = 7.0;
  static const int fallbackExerciseMinutes = 20;

  static const List<HealthDataType> _permissionTypes = <HealthDataType>[
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WORKOUT,
  ];

  static const List<HealthDataAccess> _permissions = <HealthDataAccess>[
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<HealthSignalsSnapshot> fetchTodaySignals({
    bool requestPermissions = true,
  }) async {
    final now = DateTime.now();

    try {
      await _ensureConfigured();
      if (!Platform.isAndroid) {
        return _fallback(
          now,
          'Health Connect sync is Android-only. Using fallback values.',
        );
      }

      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        return _fallback(
          now,
          'Health Connect app not available on this device.',
          healthConnectAvailable: false,
          permissionsGranted: false,
        );
      }

      final granted = await _ensureReadPermissions(
        requestPermissions: requestPermissions,
      );
      if (!granted) {
        return _fallback(
          now,
          'Health Connect permissions are required for sleep and exercise sync.',
          healthConnectAvailable: true,
          permissionsGranted: false,
        );
      }

      final dayStart = DateTime(now.year, now.month, now.day);
      final sleepWindowStart = now.subtract(const Duration(hours: 24));

      final sleepPoints = await _health.getHealthDataFromTypes(
        types: const <HealthDataType>[HealthDataType.SLEEP_SESSION],
        startTime: sleepWindowStart,
        endTime: now,
      );

      final workoutPoints = await _health.getHealthDataFromTypes(
        types: const <HealthDataType>[HealthDataType.WORKOUT],
        startTime: dayStart,
        endTime: now,
      );

      final sleepMinutes = _sumIntervalMinutes(
        points: sleepPoints,
        rangeStart: sleepWindowStart,
        rangeEnd: now,
      );
      final exerciseMinutes = _sumIntervalMinutes(
        points: workoutPoints,
        rangeStart: dayStart,
        rangeEnd: now,
      );

      final hasSleep = sleepMinutes > 0;
      final hasExercise = exerciseMinutes > 0;

      final resolvedSleep = hasSleep ? sleepMinutes / 60.0 : fallbackSleepHours;
      final resolvedExercise = hasExercise
          ? exerciseMinutes
          : fallbackExerciseMinutes;
      final usedFallback = !hasSleep || !hasExercise;

      final message = usedFallback
          ? 'Partial Health Connect data found. Missing values used safe defaults.'
          : 'Synced from Health Connect.';

      return HealthSignalsSnapshot(
        sleepHours: resolvedSleep,
        exerciseMinutes: resolvedExercise,
        healthConnectAvailable: true,
        permissionsGranted: true,
        usedFallback: usedFallback,
        message: message,
        syncedAt: DateTime.now(),
      );
    } catch (_) {
      return _fallback(
        now,
        'Could not read Health Connect data right now. Using fallback values.',
      );
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> _ensureReadPermissions({
    required bool requestPermissions,
  }) async {
    final hasPermissions =
        await _health.hasPermissions(
          _permissionTypes,
          permissions: _permissions,
        ) ??
        false;
    if (hasPermissions) return true;
    if (!requestPermissions) return false;
    return _health.requestAuthorization(
      _permissionTypes,
      permissions: _permissions,
    );
  }

  int _sumIntervalMinutes({
    required List<HealthDataPoint> points,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final intervals =
        points
            .map((point) {
              final start = point.dateFrom.toLocal();
              final end = point.dateTo.toLocal();
              final clampedStart = start.isBefore(rangeStart)
                  ? rangeStart
                  : start;
              final clampedEnd = end.isAfter(rangeEnd) ? rangeEnd : end;
              if (!clampedEnd.isAfter(clampedStart)) return null;
              return _DateRange(start: clampedStart, end: clampedEnd);
            })
            .whereType<_DateRange>()
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (intervals.isEmpty) return 0;

    final merged = <_DateRange>[];
    for (final interval in intervals) {
      if (merged.isEmpty) {
        merged.add(interval);
        continue;
      }

      final last = merged.last;
      if (!interval.start.isAfter(last.end)) {
        merged[merged.length - 1] = _DateRange(
          start: last.start,
          end: interval.end.isAfter(last.end) ? interval.end : last.end,
        );
        continue;
      }

      merged.add(interval);
    }

    return merged.fold<int>(
      0,
      (sum, interval) =>
          sum + interval.end.difference(interval.start).inMinutes,
    );
  }

  HealthSignalsSnapshot _fallback(
    DateTime now,
    String message, {
    bool healthConnectAvailable = true,
    bool permissionsGranted = true,
  }) {
    return HealthSignalsSnapshot(
      sleepHours: fallbackSleepHours,
      exerciseMinutes: fallbackExerciseMinutes,
      healthConnectAvailable: healthConnectAvailable,
      permissionsGranted: permissionsGranted,
      usedFallback: true,
      message: message,
      syncedAt: now,
    );
  }
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
