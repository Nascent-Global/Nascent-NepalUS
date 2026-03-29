import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class TasksPressureScreen extends ConsumerStatefulWidget {
  const TasksPressureScreen({super.key});

  @override
  ConsumerState<TasksPressureScreen> createState() =>
      _TasksPressureScreenState();
}

class _TasksPressureScreenState extends ConsumerState<TasksPressureScreen> {
  final _titleController = TextEditingController();
  int _priority = 3;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref
        .read(burnoutEngineProvider)
        .addUserTask(title: title, priority: _priority, deadline: null);

    _titleController.clear();
    ref.read(refreshTickProvider.notifier).bump();
  }

  Future<void> _completeTask(String taskId) async {
    await ref.read(burnoutEngineProvider).completeTask(taskId);
    ref.read(refreshTickProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        GlassCard(
          variant: GlassCardVariant.primary,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Positioned(top: -6, right: -4, child: _HeroAccent()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Capture Task Pressure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add what is on your plate and rank urgency so your pressure profile stays accurate.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTask(),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.44),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonFormField<int>(
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      dropdownColor: AppTheme.primaryDark,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      items: List<DropdownMenuItem<int>>.generate(5, (index) {
                        final value = index + 1;
                        final label = switch (value) {
                          1 => 'Low',
                          2 => 'Steady',
                          3 => 'Moderate',
                          4 => 'High',
                          _ => 'Critical',
                        };
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value • $label'),
                        );
                      }),
                      selectedItemBuilder: (context) {
                        return List<Widget>.generate(5, (index) {
                          final value = index + 1;
                          final label = switch (value) {
                            1 => 'Low',
                            2 => 'Steady',
                            3 => 'Moderate',
                            4 => 'High',
                            _ => 'Critical',
                          };
                          return Text(
                            'Priority $value • $label',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        });
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _priority = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _addTask,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => GlassCard(
            child: Text(
              'Failed to load tasks: $e',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          data: (tasks) => GlassCard(
            variant: GlassCardVariant.frosted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.secondaryDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Today\'s Tasks',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${tasks.length} total',
                        style: const TextStyle(
                          color: AppTheme.secondaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (tasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Text(
                      'No tasks yet. Add one above to track today\'s pressure.',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Checkbox(
                            value: task.completed,
                            activeColor: AppTheme.secondary,
                            checkColor: AppTheme.secondaryDark,
                            onChanged: task.completed
                                ? null
                                : (_) => _completeTask(task.id),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w700,
                                    decoration: task.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Priority ${task.priority} • ${task.taskType}',
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontSize: 12,
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
        child: const Icon(Icons.flag_circle_rounded, color: Colors.white),
      ),
    );
  }
}
