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
  static const List<String> _defaultLabelPresets = <String>[
    'Deep Work',
    'Study',
    'Coding',
    'Writing',
    'Reading',
  ];
  static const List<int> _durationPresets = <int>[15, 25, 45, 60];
  static const String _createLabelSentinel = '__create_new_label__';

  late List<String> _labelOptions;
  PomodoroSession? _activeSession;
  List<PomodoroSession> _todaySessions = const <PomodoroSession>[];
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  bool _loading = true;
  bool _working = false;
  int _selectedDuration = AppConstants.defaultPomodoroMinutes;
  String _selectedLabel = _defaultLabelPresets.first;

  @override
  void initState() {
    super.initState();
    _labelOptions = List<String>.from(_defaultLabelPresets);
    unawaited(_loadState());
  }

  @override
  void dispose() {
    _ticker?.cancel();
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

  Future<void> _onLabelSelected(String? value) async {
    if (value == null) return;
    if (value == _createLabelSentinel) {
      await _createNewLabel();
      return;
    }
    setState(() => _selectedLabel = value);
  }

  Future<void> _createNewLabel() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create focus label'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. API design'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final next = label?.trim() ?? '';
    if (next.isEmpty) return;
    if (!_labelOptions.contains(next)) {
      setState(() => _labelOptions = <String>[..._labelOptions, next]);
    }
    setState(() => _selectedLabel = next);
  }

  Future<void> _openDurationSettingsDialog() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        var pending = _selectedDuration;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Focus duration presets'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durationPresets.map((minutes) {
                  return ChoiceChip(
                    label: Text('$minutes min'),
                    selected: pending == minutes,
                    onSelected: (_) => setDialogState(() => pending = minutes),
                    selectedColor: AppTheme.secondary,
                    labelStyle: TextStyle(
                      color: pending == minutes
                          ? AppTheme.secondaryDark
                          : AppTheme.ink.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(pending),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() => _selectedDuration = selected);
  }

  Future<void> _openSessionLogDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Today\'s Focus Log'),
          content: SizedBox(width: 360, child: _buildSessionLogList()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Focus Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openDurationSettingsDialog,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                ),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Duration settings',
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _openSessionLogDialog,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                ),
                icon: const Icon(Icons.history_rounded),
                tooltip: 'View log',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isActive ? effectiveLabel : 'Pick a label and start your sprint.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
                tooltip: 'Stop',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    return GlassCard(
      variant: GlassCardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Session Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _labelOptions.contains(_selectedLabel)
                ? _selectedLabel
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Label',
              prefixIcon: const Icon(Icons.local_offer_outlined),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
            ),
            items: <DropdownMenuItem<String>>[
              ..._labelOptions.map(
                (label) =>
                    DropdownMenuItem<String>(value: label, child: Text(label)),
              ),
              const DropdownMenuItem<String>(
                value: _createLabelSentinel,
                child: Text('+ Create new label'),
              ),
            ],
            onChanged: _activeSession != null ? null : _onLabelSelected,
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.32),
              ),
            ),
            child: Text(
              'Duration: $_selectedDuration min',
              style: const TextStyle(
                color: AppTheme.secondaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLogList() {
    final sessions = _todaySessions;
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No sessions yet. Start one to build your streak.',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: ListView.builder(
        itemCount: math.min(12, sessions.length),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isRunning = session.endTime == null;
          final label = (session.taskLabel ?? '').trim();
          final title = label.isEmpty ? 'Unlabeled focus' : label;
          final status = isRunning
              ? 'Running'
              : (session.completed ? 'Completed' : 'Stopped');
          final statusColor = isRunning
              ? AppTheme.primary
              : (session.completed ? AppTheme.secondaryDark : AppTheme.warning);

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
        },
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
          _buildControlsCard(),
        ],
      ),
    );
  }
}
