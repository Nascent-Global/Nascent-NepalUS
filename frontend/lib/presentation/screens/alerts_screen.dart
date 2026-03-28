import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../widgets/glass_card.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _reminderEnabled = false;

  Future<void> _toggleReminder(bool value) async {
    final service = ref.read(reminderServiceProvider);
    if (value) {
      await service.enableDailyReminder();
    } else {
      await service.disableDailyReminder();
    }
    if (mounted) {
      setState(() => _reminderEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Daily reminder enabled' : 'Daily reminder disabled',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);

    return ListView(
      children: [
        GlassCard(
          child: SwitchListTile(
            value: _reminderEnabled,
            title: const Text('Daily reminder and habit support'),
            subtitle: const Text('Enable local notification reminders.'),
            contentPadding: EdgeInsets.zero,
            onChanged: _toggleReminder,
          ),
        ),
        const SizedBox(height: 12),
        alertsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load alerts: $e'),
          data: (alerts) => GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  const Text('No alerts yet.')
                else
                  ...alerts.map(
                    (alert) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning_rounded),
                      title: Text(alert.type),
                      subtitle: Text(alert.message),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
