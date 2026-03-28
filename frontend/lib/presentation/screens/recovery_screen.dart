import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../widgets/glass_card.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  String? _activeBreathingId;
  bool _loading = false;

  Future<void> _startBreathing() async {
    setState(() => _loading = true);
    final id = await ref.read(burnoutEngineProvider).startBreathing();
    if (mounted) {
      setState(() {
        _activeBreathingId = id;
        _loading = false;
      });
    }
  }

  Future<void> _completeBreathing() async {
    final id = _activeBreathingId;
    if (id == null) return;
    setState(() => _loading = true);
    await ref.read(burnoutEngineProvider).endBreathing(id: id, completed: true);
    ref.read(refreshTickProvider.notifier).bump();
    if (mounted) {
      setState(() {
        _activeBreathingId = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Breathing session completed.')),
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
                'Recovery Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Use these quick tools to lower burnout in the moment.',
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.air_rounded),
                title: const Text('Guided breathing session'),
                subtitle: Text(
                  '${AppConstants.defaultBreathingMinutes}-minute reset',
                ),
              ),
              Row(
                children: [
                  FilledButton(
                    onPressed: _loading || _activeBreathingId != null
                        ? null
                        : _startBreathing,
                    child: const Text('Start Breathing'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _loading || _activeBreathingId == null
                        ? null
                        : _completeBreathing,
                    child: const Text('Mark Complete'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.free_breakfast_rounded),
                title: Text('Micro break suggestion'),
                subtitle: Text(
                  'Take a 5-minute break after your current task.',
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.nightlight_round),
                title: Text('Sleep protection'),
                subtitle: Text(
                  'Set a fixed lights-off time and avoid late tasks.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
