import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  static const List<_RecoveryTemplate> _templates = <_RecoveryTemplate>[
    _RecoveryTemplate(
      title: 'Go for a 15-minute walk',
      subtitle: 'Light movement to reset your stress baseline.',
      reason: 'exercise_recovery',
      priority: 4,
      icon: Icons.directions_walk_rounded,
    ),
    _RecoveryTemplate(
      title: 'Watch one comfort episode',
      subtitle: 'Intentional unwind without guilt.',
      reason: 'break',
      priority: 3,
      icon: Icons.movie_creation_outlined,
    ),
    _RecoveryTemplate(
      title: 'No-screen 20-minute reset',
      subtitle: 'Phone away, hydrate, and breathe slowly.',
      reason: 'general_recovery',
      priority: 4,
      icon: Icons.spa_outlined,
    ),
    _RecoveryTemplate(
      title: 'Sleep prep challenge',
      subtitle: 'Set lights-off alarm 30 minutes earlier tonight.',
      reason: 'sleep_recovery',
      priority: 5,
      icon: Icons.bedtime_rounded,
    ),
  ];

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

  Future<void> _addRecoveryChallenge(_RecoveryTemplate template) async {
    await ref
        .read(burnoutEngineProvider)
        .addRecoveryTaskFromTemplate(
          title: template.title,
          reason: template.reason,
          priority: template.priority,
        );
    ref.read(refreshTickProvider.notifier).bump();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added: ${template.title}')));
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        GlassCard(
          variant: GlassCardVariant.primary,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(top: -6, right: -4, child: _HeroAccent()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.self_improvement_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recovery Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quick tools and guided challenges to lower burnout now.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.air_rounded,
                            color: Colors.white,
                          ),
                          title: Text(
                            'Guided breathing session',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          subtitle: Text(
                            '${AppConstants.defaultBreathingMinutes}-minute reset',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ),
                        if (_activeBreathingId != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.22,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Session in progress',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    _loading || _activeBreathingId != null
                                    ? null
                                    : _startBreathing,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryDark,
                                ),
                                child: const Text('Start Breathing'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _loading || _activeBreathingId == null
                                    ? null
                                    : _completeBreathing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Text('Mark Complete'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          variant: GlassCardVariant.secondary,
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Failed to load tasks: $error'),
            data: (tasks) {
              final recoveryTitles = tasks
                  .where((task) => task.taskType == 'recovery')
                  .map((task) => task.title)
                  .toSet();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryDark.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_outlined,
                          color: AppTheme.secondaryDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recovery Challenges',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.secondaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._templates.map((template) {
                    final alreadyAdded = recoveryTitles.contains(
                      template.title,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecoveryTemplateTile(
                        template: template,
                        alreadyAdded: alreadyAdded,
                        onAdd: alreadyAdded
                            ? null
                            : () => _addRecoveryChallenge(template),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Text(
                    'Added challenges appear in Home -> Today\'s Tasks.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryDark.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
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
        child: const Icon(Icons.spa_rounded, color: Colors.white),
      ),
    );
  }
}

class _RecoveryTemplateTile extends StatelessWidget {
  const _RecoveryTemplateTile({
    required this.template,
    required this.alreadyAdded,
    required this.onAdd,
  });

  final _RecoveryTemplate template;
  final bool alreadyAdded;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(template.icon, color: AppTheme.secondaryDark, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  template.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(
              alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
              color: alreadyAdded
                  ? AppTheme.secondaryDark
                  : AppTheme.primaryDark,
            ),
            tooltip: alreadyAdded ? 'Already added' : 'Add to today tasks',
          ),
        ],
      ),
    );
  }
}

class _RecoveryTemplate {
  const _RecoveryTemplate({
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.priority,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String reason;
  final int priority;
  final IconData icon;
}
