import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../widgets/glass_card.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  double _sleep = 7;
  double _work = 8;
  int _mood = 3;
  int _exercise = 20;
  bool _includePomodoroWork = false;
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _submitting = true);
    final engine = ref.read(burnoutEngineProvider);

    await engine.submitDailyCheckIn(
      sleepHours: _sleep,
      workHours: _work,
      mood: _mood,
      exerciseMinutes: _exercise,
      includePomodoroWork: _includePomodoroWork,
    );

    ref.read(refreshTickProvider.notifier).bump();
    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in saved and score updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Check-in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text('Sleep hours: ${_sleep.toStringAsFixed(1)}'),
                Slider(
                  value: _sleep,
                  min: 2,
                  max: 11,
                  divisions: 18,
                  onChanged: (v) => setState(() => _sleep = v),
                ),
                const SizedBox(height: 8),
                Text('Manual work hours: ${_work.toStringAsFixed(1)}'),
                Slider(
                  value: _work,
                  min: 0,
                  max: 14,
                  divisions: 28,
                  onChanged: (v) => setState(() => _work = v),
                ),
                const SizedBox(height: 8),
                Text('Mood: $_mood / 5'),
                Slider(
                  value: _mood.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _mood = v.round()),
                ),
                const SizedBox(height: 8),
                Text('Exercise: $_exercise minutes'),
                Slider(
                  value: _exercise.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  onChanged: (v) => setState(() => _exercise = v.round()),
                ),
                SwitchListTile(
                  value: _includePomodoroWork,
                  title: const Text('Include completed pomodoro in work hours'),
                  subtitle: const Text(
                    'If on, burnout scoring adds today\'s completed pomodoro time to manual work hours.',
                  ),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _includePomodoroWork = v),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
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
