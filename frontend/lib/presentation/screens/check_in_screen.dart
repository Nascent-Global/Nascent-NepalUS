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
  final _formKey = GlobalKey<FormState>();
  static const _defaultSleep = 7.0;
  static const _defaultWork = 8.0;
  static const _defaultMood = 3;
  static const _defaultExercise = 20;

  double _sleep = _defaultSleep;
  double _work = _defaultWork;
  int _mood = _defaultMood;
  int _exercise = _defaultExercise;
  bool _submitting = false;
  bool _syncingHealth = false;
  bool _healthConnected = false;
  bool _healthUsingFallback = true;
  String _healthMessage = 'Using fallback values until Health Connect sync.';
  DateTime? _healthSyncedAt;
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
      _healthMessage = 'Using fallback values until Health Connect sync.';
      _healthSyncedAt = null;
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
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

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
      _healthMessage = snapshot.message;
      _healthSyncedAt = snapshot.syncedAt.toLocal();
      _syncingHealth = false;
    });

    if (!silent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snapshot.message)));
    }
  }

  String get _moodLabel {
    switch (_mood) {
      case 1:
        return 'Exhausted';
      case 2:
        return 'Low';
      case 3:
        return 'Balanced';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Balanced';
    }
  }

  String get _healthStatusText {
    final syncedAt = _healthSyncedAt;
    if (syncedAt == null) return _healthMessage;
    final timeOfDay = TimeOfDay.fromDateTime(syncedAt).format(context);
    return '$_healthMessage Last sync: $timeOfDay';
  }

  Widget _buildHealthConnectSection() {
    final statusColor = _healthConnected ? AppTheme.primary : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            statusColor.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.26),
          width: 1.1,
        ),
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
                  color: statusColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  size: 16,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Health Connect Signals',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                _healthConnected ? Icons.verified_rounded : Icons.info_outline,
                color: statusColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              if (_healthUsingFallback)
                _HealthValueChip(
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
          OutlinedButton.icon(
            onPressed: _syncingHealth
                ? null
                : () => _syncHealthSignals(requestPermissions: true),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: statusColor.withValues(alpha: 0.65)),
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
                    _healthConnected ? Icons.sync_rounded : Icons.link_rounded,
                  ),
            label: Text(
              _healthConnected
                  ? 'Refresh Health Data'
                  : 'Connect Health Connect',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSection({
    required String title,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
    String? helperText,
    Color tint = AppTheme.secondary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.26), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: tint == AppTheme.secondary
                            ? AppTheme.secondaryDark
                            : AppTheme.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                helperText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.ink.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tint,
              inactiveTrackColor: tint.withValues(alpha: 0.24),
              thumbColor: tint == AppTheme.secondary
                  ? AppTheme.secondaryDark
                  : AppTheme.primaryDark,
              overlayColor: tint.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
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
                    'Sleep and exercise sync from Health Connect. Add your mood and manual work to complete today\'s check-in.',
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
          child: Form(
            key: _formKey,
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
                _buildMetricSection(
                  title: 'Manual work',
                  valueLabel: '${_work.toStringAsFixed(1)} h',
                  value: _work,
                  min: 0,
                  max: 14,
                  divisions: 28,
                  icon: Icons.construction_rounded,
                  onChanged: (v) => setState(() => _work = v),
                  tint: AppTheme.primary,
                ),
                _buildMetricSection(
                  title: 'Mood',
                  valueLabel: '$_mood / 5',
                  value: _mood.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  helperText: _moodLabel,
                  onChanged: (v) => setState(() => _mood = v.round()),
                  tint: AppTheme.warning,
                ),
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
