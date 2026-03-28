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

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(refreshTickProvider.notifier).bump();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Burnout Score',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          label: Text(classification.toUpperCase()),
                          backgroundColor: _classificationColor(classification),
                        ),
                        const Spacer(),
                        Text(
                          snapshot.direction,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.cobalt,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burnout Trend',
                      style: Theme.of(context).textTheme.titleMedium,
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
                    Text(
                      'Detected Causes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.causes.isEmpty)
                      const Text('No causes detected yet.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.causes
                            .map(
                              (cause) => Chip(
                                label: Text(cause),
                                backgroundColor: AppTheme.cobalt.withValues(
                                  alpha: 0.12,
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
                    Text(
                      'Today\'s Tasks',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.todayTasks.isEmpty)
                      const Text('No tasks for today yet.')
                    else
                      ...snapshot.todayTasks
                          .take(4)
                          .map(
                            (task) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                task.completed
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(task.title),
                              subtitle: Text(
                                'Priority ${task.priority} • ${task.taskType}',
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
        return Colors.redAccent.withValues(alpha: 0.22);
      case 'medium':
        return Colors.orange.withValues(alpha: 0.24);
      default:
        return Colors.green.withValues(alpha: 0.2);
    }
  }
}
