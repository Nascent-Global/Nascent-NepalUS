import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../data/models/pomodoro_session.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const List<String> _labelPresets = <String>[
    'Deep Work',
    'Study',
    'Coding',
    'Writing',
    'Reading',
  ];

  static const List<int> _durationPresets = <int>[15, 25, 45, 60];

  final TextEditingController _customLabelController = TextEditingController();

  PomodoroSession? _activeSession;
  List<PomodoroSession> _todaySessions = const <PomodoroSession>[];
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  bool _loading = true;
  bool _working = false;
  int _selectedDuration = AppConstants.defaultPomodoroMinutes;
  String _selectedLabel = _labelPresets.first;

  @override
  void initState() {
    super.initState();
    unawaited(_loadState());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final repository = ref.read(burnoutRepositoryProvider);
    final now = DateTime.now().toUtc();
    final active = await repository.getActivePomodoroSession();
    final today = await repository.getPomodoroByDate(now);

    if (!mounted) return;
    setState(() {
      _activeSession = active;
      _todaySessions = today;
      _loading = false;
    });
    _refreshTicker();
  }

  void _refreshTicker() {
    _ticker?.cancel();
    final active = _activeSession;
    if (active == null) {
      if (mounted) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }

    _updateRemaining(active);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining(active);
    });
  }

  void _updateRemaining(PomodoroSession active) {
    final plannedMinutes = active.duration <= 0
        ? AppConstants.defaultPomodoroMinutes
        : active.duration;
    final planned = Duration(minutes: plannedMinutes);
    final elapsed = DateTime.now().toUtc().difference(active.startTime);
    final remainingSeconds = planned.inSeconds - elapsed.inSeconds;
    final next = Duration(seconds: math.max(0, remainingSeconds));

    if (!mounted) return;
    setState(() => _remaining = next);
    if (remainingSeconds <= 0) {
      _ticker?.cancel();
    }
  }

  String? _resolvedTaskLabel() {
    final custom = _customLabelController.text.trim();
    if (custom.isNotEmpty) return custom;
    final selected = _selectedLabel.trim();
    return selected.isEmpty ? null : selected;
  }

  Future<void> _startPomodoro() async {
    if (_working || _activeSession != null) return;
    setState(() => _working = true);
    final engine = ref.read(burnoutEngineProvider);
    try {
      await engine.startPomodoro(
        minutes: _selectedDuration,
        taskLabel: _resolvedTaskLabel(),
      );
      ref.read(refreshTickProvider.notifier).bump();
      await _loadState();
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _finishPomodoro({required bool completed}) async {
    final active = _activeSession;
    if (_working || active == null) return;

    setState(() => _working = true);
    final engine = ref.read(burnoutEngineProvider);
    try {
      await engine.endPomodoro(id: active.id, completed: completed);
      ref.read(refreshTickProvider.notifier).bump();
      await _loadState();
      if (!mounted) return;
      final message = completed
          ? 'Pomodoro completed and logged.'
          : 'Pomodoro stopped.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  double get _activeProgress {
    final active = _activeSession;
    if (active == null) return 0;
    final plannedMinutes = active.duration <= 0
        ? AppConstants.defaultPomodoroMinutes
        : active.duration;
    final planned = Duration(minutes: plannedMinutes).inSeconds;
    final elapsed = DateTime.now()
        .toUtc()
        .difference(active.startTime)
        .inSeconds;
    return (elapsed / planned).clamp(0.0, 1.0);
  }

  String _formatClock(Duration value) {
    final mins = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    if (hours > 0) {
      return '$hours:$mins:$secs';
    }
    return '$mins:$secs';
  }

  String _formatTime(DateTime value) {
    final time = TimeOfDay.fromDateTime(value.toLocal());
    return time.format(context);
  }

  String _sessionSummary(PomodoroSession session) {
    final started = _formatTime(session.startTime);
    final end = session.endTime == null
        ? 'running'
        : _formatTime(session.endTime!);
    return '$started - $end';
  }

  int _sessionMinutes(PomodoroSession session) {
    final end = session.endTime;
    if (end == null) return session.duration;
    final mins = end.difference(session.startTime).inMinutes;
    return math.max(1, mins);
  }

  Widget _buildLabelSection() {
    return GlassCard(
      variant: GlassCardVariant.secondary,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -6,
            right: -4,
            child: _CardSpark(icon: Icons.auto_stories_rounded),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'What are you focusing on?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _labelPresets.map((label) {
                  return ChoiceChip(
                    label: Text(label),
                    selected:
                        _selectedLabel == label &&
                        _customLabelController.text.trim().isEmpty,
                    onSelected: _activeSession != null
                        ? null
                        : (_) {
                            setState(() {
                              _selectedLabel = label;
                              _customLabelController.clear();
                            });
                          },
                    selectedColor: AppTheme.secondary,
                    labelStyle: TextStyle(
                      color:
                          (_selectedLabel == label &&
                              _customLabelController.text.trim().isEmpty)
                          ? AppTheme.secondaryDark
                          : AppTheme.ink.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customLabelController,
                enabled: _activeSession == null,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Or write custom label (e.g. System design)',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.24),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Duration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durationPresets.map((minutes) {
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _selectedDuration == minutes,
                    onSelected: _activeSession != null
                        ? null
                        : (_) => setState(() => _selectedDuration = minutes),
                    selectedColor: AppTheme.secondary,
                    labelStyle: TextStyle(
                      color: _selectedDuration == minutes
                          ? AppTheme.secondaryDark
                          : AppTheme.ink.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTimerCard() {
    final active = _activeSession;
    final isActive = active != null;
    final label = active?.taskLabel?.trim();
    final effectiveLabel = (label == null || label.isEmpty)
        ? 'Focused Work'
        : label;

    return GlassCard(
      variant: GlassCardVariant.primary,
      padding: const EdgeInsets.all(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -6,
            right: -4,
            child: _CardSpark(icon: Icons.rocket_launch_rounded),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Focus Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? effectiveLabel
                    : 'Pick a label and start your next sprint.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      isActive
                          ? _formatClock(_remaining)
                          : '${_selectedDuration.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive
                          ? (_remaining.inSeconds == 0
                                ? 'Time is up. Mark complete when done.'
                                : 'Stay on one thing until the timer ends.')
                          : 'Ready to enter deep focus mode.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: isActive ? _activeProgress : 0,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: Colors.white.withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _working || isActive ? null : _startPomodoro,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _working || !isActive
                          ? null
                          : () => _finishPomodoro(completed: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Complete'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _working || !isActive
                        ? null
                        : () => _finishPomodoro(completed: false),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLogCard() {
    final sessions = _todaySessions;
    return GlassCard(
      variant: GlassCardVariant.frosted,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -2,
            right: 2,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppTheme.warning.withValues(alpha: 0.78),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Today\'s Focus Log',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No sessions yet. Start one to build your streak.',
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ...sessions.take(8).map((session) {
                  final isRunning = session.endTime == null;
                  final label = (session.taskLabel ?? '').trim();
                  final title = label.isEmpty ? 'Unlabeled focus' : label;
                  final status = isRunning
                      ? 'Running'
                      : (session.completed ? 'Completed' : 'Stopped');
                  final statusColor = isRunning
                      ? AppTheme.primary
                      : (session.completed
                            ? AppTheme.secondaryDark
                            : AppTheme.warning);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 5,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_sessionMinutes(session)} min • ${_sessionSummary(session)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.ink.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadState,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          _buildFocusTimerCard(),
          const SizedBox(height: 14),
          _buildLabelSection(),
          const SizedBox(height: 14),
          _buildSessionLogCard(),
        ],
      ),
    );
  }
}

class _CardSpark extends StatelessWidget {
  const _CardSpark({required this.icon});

  final IconData icon;

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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
