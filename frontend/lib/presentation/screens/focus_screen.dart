import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../widgets/glass_card.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  String? _activePomodoroId;
  bool _working = false;

  Future<void> _startPomodoro() async {
    setState(() => _working = true);
    final id = await ref.read(burnoutEngineProvider).startPomodoro();
    if (mounted) {
      setState(() {
        _activePomodoroId = id;
        _working = false;
      });
    }
  }

  Future<void> _finishPomodoro() async {
    final id = _activePomodoroId;
    if (id == null) return;

    setState(() => _working = true);
    await ref.read(burnoutEngineProvider).endPomodoro(id: id, completed: true);
    ref.read(refreshTickProvider.notifier).bump();
    if (mounted) {
      setState(() {
        _activePomodoroId = null;
        _working = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pomodoro session completed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Focus Session',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Use ${AppConstants.defaultPomodoroMinutes}-minute pomodoro blocks for healthier productivity.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _working || _activePomodoroId != null
                        ? null
                        : _startPomodoro,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Pomodoro'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _working || _activePomodoroId == null
                        ? null
                        : _finishPomodoro,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Complete'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _activePomodoroId == null
                    ? 'No active session'
                    : 'Pomodoro running. Finish after your focus block.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
