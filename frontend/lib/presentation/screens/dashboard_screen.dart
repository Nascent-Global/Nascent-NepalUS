import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Failed to load dashboard: $err')),
      data: (snapshot) {
        final score = snapshot.latestScore?.score ?? 0;
        final classification = snapshot.latestScore?.classification ?? 'low';
        final classificationColor = _classificationColor(classification);

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(refreshTickProvider.notifier).bump();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              GlassCard(
                variant: GlassCardVariant.primary,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -6,
                      right: -4,
                      child: _HeroAccent(icon: Icons.bolt_rounded),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current Burnout Score',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                snapshot.direction,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: classificationColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            classification.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
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
                variant: GlassCardVariant.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.timeline_rounded,
                      label: 'Burnout Trend',
                      tint: AppTheme.secondaryDark,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track momentum over recent check-ins.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryDark.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TrendChart(scores: snapshot.trend),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.psychology_alt_rounded,
                      label: 'Detected Causes',
                      tint: AppTheme.ink,
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.causes.isEmpty)
                      Text(
                        'No causes detected yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.causes
                            .map(
                              (cause) => Chip(
                                label: Text(cause),
                                backgroundColor: AppTheme.primarySoft
                                    .withValues(alpha: 0.3),
                                side: BorderSide(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.today_rounded,
                      label: 'Today\'s Tasks',
                      tint: AppTheme.ink,
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.todayTasks.isEmpty)
                      Text(
                        'No tasks for today yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ...snapshot.todayTasks
                          .take(4)
                          .map(
                            (task) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                leading: Icon(
                                  task.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: task.completed
                                      ? AppTheme.secondaryDark
                                      : AppTheme.primaryDark,
                                ),
                                title: Text(task.title),
                                subtitle: Text(
                                  'Priority ${task.priority} • ${task.taskType}',
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _classificationColor(String classification) {
    switch (classification) {
      case 'high':
        return AppTheme.danger;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.secondaryDark;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: tint),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: tint,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroAccent extends StatelessWidget {
  const _HeroAccent({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
