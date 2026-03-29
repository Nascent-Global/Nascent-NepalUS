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
  late String _activeDateKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeDateKey = AppDateUtils.todayUtcKey();
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
    });
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

  Widget _buildMetricSection({
    required String title,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: -4,
            right: -4,
            child: IgnorePointer(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
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
                  Container(
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
                      style: TextStyle(
                        color: tint == AppTheme.secondary
                            ? AppTheme.secondaryDark
                            : AppTheme.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
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
                    'Capture sleep, effort, mood, and movement to keep your burnout score grounded in today.',
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
                _buildMetricSection(
                  title: 'Sleep',
                  valueLabel: '${_sleep.toStringAsFixed(1)} h',
                  value: _sleep,
                  min: 2,
                  max: 11,
                  divisions: 18,
                  icon: Icons.bedtime_rounded,
                  onChanged: (v) => setState(() => _sleep = v),
                ),
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
                  valueLabel: '$_mood / 5 ($_moodLabel)',
                  value: _mood.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  onChanged: (v) => setState(() => _mood = v.round()),
                  tint: AppTheme.warning,
                ),
                _buildMetricSection(
                  title: 'Exercise',
                  valueLabel: '$_exercise min',
                  value: _exercise.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  icon: Icons.directions_run_rounded,
                  onChanged: (v) => setState(() => _exercise = v.round()),
                  tint: AppTheme.secondary,
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
