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
                    'Use these quick tools to lower burnout in the moment.',
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
          child: Column(
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
                      Icons.favorite_rounded,
                      color: AppTheme.secondaryDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sustain Your Energy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _RecoveryTipTile(
                icon: Icons.free_breakfast_rounded,
                title: 'Micro break suggestion',
                subtitle: 'Take a 5-minute break after your current task.',
              ),
              const SizedBox(height: 8),
              _RecoveryTipTile(
                icon: Icons.nightlight_round,
                title: 'Sleep protection',
                subtitle: 'Set a fixed lights-off time and avoid late tasks.',
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
        child: const Icon(Icons.spa_rounded, color: Colors.white),
      ),
    );
  }
}

class _RecoveryTipTile extends StatelessWidget {
  const _RecoveryTipTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 8,
          top: -3,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppTheme.warning.withValues(alpha: 0.8),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
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
                child: Icon(icon, color: AppTheme.secondaryDark, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.ink.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
