import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_utils.dart';
import '../../core/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen>
    with WidgetsBindingObserver {
  static const _defaultSleep = 7.0;
  static const _defaultWork = 8.0;
  static const _defaultMood = 3;
  static const _defaultExercise = 20;

  static const List<double> _workQuickOptions = <double>[4, 6, 8, 10, 12];
  static const List<double> _sleepQuickOptions = <double>[
    5.5,
    6.5,
    7.0,
    8.0,
    9.0,
  ];
  static const List<int> _exerciseQuickOptions = <int>[10, 20, 30, 45, 60];

  static const List<({int value, String label, String emoji})> _moodOptions =
      <({int value, String label, String emoji})>[
        (value: 1, label: 'Exhausted', emoji: '😵'),
        (value: 2, label: 'Low', emoji: '😕'),
        (value: 3, label: 'Balanced', emoji: '🙂'),
        (value: 4, label: 'Good', emoji: '😌'),
        (value: 5, label: 'Great', emoji: '😄'),
      ];

  double _sleep = _defaultSleep;
  double _work = _defaultWork;
  int _mood = _defaultMood;
  int _exercise = _defaultExercise;

  bool _submitting = false;
  bool _syncingHealth = false;
  bool _healthConnected = false;
  bool _healthUsingFallback = true;
  bool _manualHealthOverride = false;

  String _healthMessage = 'Using fallback values until Health Connect sync.';
  DateTime? _healthSyncedAt;
  String? _manualPromptShownForDateKey;
  late String _activeDateKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeDateKey = AppDateUtils.todayUtcKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncHealthSignals(silent: true, requestPermissions: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetForNewDayIfNeeded();
    }
  }

  void _resetForNewDayIfNeeded() {
    final todayKey = AppDateUtils.todayUtcKey();
    if (todayKey == _activeDateKey) return;

    setState(() {
      _activeDateKey = todayKey;
      _sleep = _defaultSleep;
      _work = _defaultWork;
      _mood = _defaultMood;
      _exercise = _defaultExercise;
      _healthConnected = false;
      _healthUsingFallback = true;
      _manualHealthOverride = false;
      _healthMessage = 'Using fallback values until Health Connect sync.';
      _healthSyncedAt = null;
      _manualPromptShownForDateKey = null;
    });

    unawaited(_syncHealthSignals(silent: true, requestPermissions: false));
  }

  void _queueDayBoundaryCheck() {
    final todayKey = AppDateUtils.todayUtcKey();
    if (todayKey == _activeDateKey) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resetForNewDayIfNeeded();
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final engine = ref.read(burnoutEngineProvider);
    try {
      await engine.submitDailyCheckIn(
        sleepHours: _sleep,
        workHours: _work,
        mood: _mood,
        exerciseMinutes: _exercise,
      );

      ref.read(refreshTickProvider.notifier).bump();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in saved and score updated.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _syncHealthSignals({
    bool silent = false,
    bool requestPermissions = true,
  }) async {
    if (_syncingHealth) return;
    setState(() => _syncingHealth = true);

    final health = ref.read(healthConnectServiceProvider);
    final snapshot = await health.fetchTodaySignals(
      requestPermissions: requestPermissions,
    );

    if (!mounted) return;

    setState(() {
      _sleep = snapshot.sleepHours;
      _exercise = snapshot.exerciseMinutes;
      _healthConnected =
          snapshot.healthConnectAvailable && snapshot.permissionsGranted;
      _healthUsingFallback = snapshot.usedFallback;
      _manualHealthOverride = false;
      _healthMessage = snapshot.message;
      _healthSyncedAt = snapshot.syncedAt.toLocal();
      _syncingHealth = false;
    });

    if (!silent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snapshot.message)));
    }

    await _maybePromptForManualLogging();
  }

  Future<void> _maybePromptForManualLogging() async {
    if (_healthConnected || !mounted) return;

    final todayKey = AppDateUtils.todayUtcKey();
    if (_manualPromptShownForDateKey == todayKey) return;
    _manualPromptShownForDateKey = todayKey;

    final result = await showDialog<_ManualPromptAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log sleep and exercise manually?'),
          content: Text(
            'Health Connect is not connected right now. You can connect now or manually log today\'s sleep and exercise.',
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ManualPromptAction.later),
              child: const Text('Later'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ManualPromptAction.connect),
              child: const Text('Connect'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ManualPromptAction.manual),
              child: const Text('Log Manually'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == _ManualPromptAction.connect) {
      unawaited(_syncHealthSignals(silent: false, requestPermissions: true));
      return;
    }
    if (result == _ManualPromptAction.manual) {
      unawaited(_showManualHealthDialog());
    }
  }

  Future<void> _showManualHealthDialog() async {
    var manualSleep = _sleep;
    var manualExercise = _exercise;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manual health logging'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDialogMetricLabel(
                      title: 'Sleep',
                      value: '${manualSleep.toStringAsFixed(1)} h',
                      icon: Icons.bedtime_rounded,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sleepQuickOptions
                          .map(
                            (option) => _QuickValueChip(
                              label: '${option.toStringAsFixed(1)}h',
                              selected: (manualSleep - option).abs() < 0.001,
                              tint: AppTheme.secondary,
                              onTap: () =>
                                  setDialogState(() => manualSleep = option),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildDialogStepper(
                      onDecrease: () => setDialogState(() {
                        manualSleep = (manualSleep - 0.5).clamp(2.0, 11.0);
                      }),
                      onIncrease: () => setDialogState(() {
                        manualSleep = (manualSleep + 0.5).clamp(2.0, 11.0);
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogMetricLabel(
                      title: 'Exercise',
                      value: '$manualExercise min',
                      icon: Icons.directions_run_rounded,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exerciseQuickOptions
                          .map(
                            (option) => _QuickValueChip(
                              label: '${option}m',
                              selected: manualExercise == option,
                              tint: AppTheme.primary,
                              onTap: () =>
                                  setDialogState(() => manualExercise = option),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _buildDialogStepper(
                      onDecrease: () => setDialogState(() {
                        manualExercise = (manualExercise - 5).clamp(0, 180);
                      }),
                      onIncrease: () => setDialogState(() {
                        manualExercise = (manualExercise + 5).clamp(0, 180);
                      }),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;

    setState(() {
      _sleep = manualSleep;
      _exercise = manualExercise;
      _manualHealthOverride = true;
      _healthUsingFallback = false;
      _healthMessage = 'Manual sleep and exercise logged for today.';
      _healthSyncedAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual health metrics saved for today.')),
    );
  }

  Widget _buildDialogMetricLabel({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppTheme.primaryDark),
        const SizedBox(width: 8),
        Text(
          '$title: $value',
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogStepper({
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: onIncrease,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  String get _moodLabel {
    final option = _moodOptions.firstWhere(
      (item) => item.value == _mood,
      orElse: () => _moodOptions[2],
    );
    return option.label;
  }

  String get _healthStatusText {
    final syncedAt = _healthSyncedAt;
    if (syncedAt == null) return _healthMessage;
    final timeOfDay = TimeOfDay.fromDateTime(syncedAt).format(context);
    return '$_healthMessage Last sync: $timeOfDay';
  }

  Widget _buildSignalCard({
    required String title,
    required IconData icon,
    required Color tint,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.26), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: tint),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildHealthConnectSection() {
    final statusColor = _healthConnected ? AppTheme.primary : AppTheme.warning;

    return _buildSignalCard(
      title: 'Health Connect Signals',
      icon: Icons.monitor_heart_rounded,
      tint: statusColor,
      trailing: Icon(
        _healthConnected ? Icons.verified_rounded : Icons.info_outline,
        color: statusColor,
        size: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _HealthValueChip(
                label: 'Sleep',
                value: '${_sleep.toStringAsFixed(1)} h',
                tint: AppTheme.secondaryDark,
              ),
              _HealthValueChip(
                label: 'Exercise',
                value: '$_exercise min',
                tint: AppTheme.primaryDark,
              ),
              if (_manualHealthOverride)
                const _HealthValueChip(
                  label: 'Mode',
                  value: 'Manual',
                  tint: AppTheme.warning,
                )
              else if (_healthUsingFallback)
                const _HealthValueChip(
                  label: 'Mode',
                  value: 'Fallback',
                  tint: AppTheme.warning,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _healthStatusText,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _syncingHealth
                      ? null
                      : () => _syncHealthSignals(requestPermissions: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(
                      color: statusColor.withValues(alpha: 0.65),
                    ),
                    foregroundColor: statusColor,
                  ),
                  icon: _syncingHealth
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: statusColor,
                          ),
                        )
                      : Icon(
                          _healthConnected
                              ? Icons.sync_rounded
                              : Icons.link_rounded,
                        ),
                  label: Text(
                    _healthConnected
                        ? 'Refresh Health Data'
                        : 'Connect Health Connect',
                  ),
                ),
              ),
              if (!_healthConnected) ...<Widget>[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showManualHealthDialog,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: AppTheme.secondaryDark,
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Log Manually'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHoursSection() {
    return _buildSignalCard(
      title: 'Manual Work',
      icon: Icons.construction_rounded,
      tint: AppTheme.primary,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${_work.toStringAsFixed(1)} h',
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _workQuickOptions
                .map(
                  (option) => _QuickValueChip(
                    label: '${option.toInt()}h',
                    selected: (_work - option).abs() < 0.001,
                    tint: AppTheme.primary,
                    onTap: () => setState(() => _work = option),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _work = (_work - 0.5).clamp(0.0, 14.0);
                  });
                },
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _work = (_work + 0.5).clamp(0.0, 14.0);
                  });
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return _buildSignalCard(
      title: 'Mood',
      icon: Icons.sentiment_satisfied_alt_rounded,
      tint: AppTheme.warning,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$_mood / 5',
          style: const TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _moodLabel,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moodOptions
                .map(
                  (item) => _MoodChoicePill(
                    emoji: item.emoji,
                    label: item.label,
                    selected: _mood == item.value,
                    onTap: () => setState(() => _mood = item.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _queueDayBoundaryCheck();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        GlassCard(
          variant: GlassCardVariant.primary,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Positioned(top: -6, right: -4, child: _HeroAccent()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.self_improvement_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Daily Check-in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sleep and exercise sync from Health Connect. Add mood and manual work to complete today\'s check-in.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(
                      'Quick rhythm snapshot',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          variant: GlassCardVariant.frosted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Signals',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildHealthConnectSection(),
              _buildWorkHoursSection(),
              _buildMoodSection(),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save Check-in'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroAccent extends StatelessWidget {
  const _HeroAccent();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        ),
        child: const Icon(Icons.monitor_heart_rounded, color: Colors.white),
      ),
    );
  }
}

class _HealthValueChip extends StatelessWidget {
  const _HealthValueChip({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: tint,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QuickValueChip extends StatelessWidget {
  const _QuickValueChip({
    required this.label,
    required this.selected,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? tint.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? tint.withValues(alpha: 0.46)
                : tint.withValues(alpha: 0.24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? tint : AppTheme.ink.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MoodChoicePill extends StatelessWidget {
  const _MoodChoicePill({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? AppTheme.warning.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.84),
          border: Border.all(
            color: selected
                ? AppTheme.warning.withValues(alpha: 0.52)
                : AppTheme.warning.withValues(alpha: 0.26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: selected ? 0.96 : 0.82),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ManualPromptAction { later, connect, manual }
