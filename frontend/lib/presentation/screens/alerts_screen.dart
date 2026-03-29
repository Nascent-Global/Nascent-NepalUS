import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _reminderEnabled = false;
  bool _loadingReminder = true;

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final service = ref.read(reminderServiceProvider);
    final enabled = await service.isDailyReminderEnabled();
    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        _loadingReminder = false;
      });
    }
  }

  Future<void> _toggleReminder(bool value) async {
    final service = ref.read(reminderServiceProvider);
    setState(() => _loadingReminder = true);
    if (value) {
      await service.enableDailyReminder();
    } else {
      await service.disableDailyReminder();
    }
    if (mounted) {
      setState(() {
        _reminderEnabled = value;
        _loadingReminder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Daily reminder enabled' : 'Daily reminder disabled',
          ),
        ),
      );
    }
  }

  Future<void> _sendSmartNudgeNow() async {
    final engine = ref.read(burnoutEngineProvider);
    final reminderService = ref.read(reminderServiceProvider);
    final snapshot = await engine.getDashboardSnapshot();
    final latest = snapshot.latestScore;
    if (latest == null) {
      await reminderService.sendPreviewNotification();
    } else {
      await reminderService.showBurnoutInsightNotification(
        score: latest.score,
        classification: latest.classification,
        causes: snapshot.causes,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent to status bar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);

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
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alerts & Nudges',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _reminderEnabled,
                    title: Text(
                      'Daily reminder and habit support',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Enable notification-bar reminders and burnout nudges.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onChanged: _loadingReminder ? null : _toggleReminder,
                    activeThumbColor: AppTheme.secondary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sendSmartNudgeNow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.2),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded),
                      label: Text(
                        _loadingReminder
                            ? 'Updating Reminder...'
                            : 'Send Smart Nudge Now',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load alerts: $e'),
          data: (alerts) => GlassCard(
            variant: GlassCardVariant.frosted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 18,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Alerts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  Text(
                    'No alerts yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  ...alerts.map(
                    (alert) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _accentForType(
                            alert.type,
                          ).withValues(alpha: 0.32),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _accentForType(
                                alert.type,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _iconForType(alert.type),
                              color: _accentForType(alert.type),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.type,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: AppTheme.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alert.message,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.78,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _accentForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('high') || normalized.contains('critical')) {
      return AppTheme.danger;
    }
    if (normalized.contains('medium') || normalized.contains('warning')) {
      return AppTheme.warning;
    }
    return AppTheme.primary;
  }

  IconData _iconForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('habit') || normalized.contains('daily')) {
      return Icons.event_repeat_rounded;
    }
    if (normalized.contains('insight') || normalized.contains('score')) {
      return Icons.insights_rounded;
    }
    return Icons.warning_rounded;
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
        child: const Icon(Icons.bolt_rounded, color: Colors.white),
      ),
    );
  }
}
