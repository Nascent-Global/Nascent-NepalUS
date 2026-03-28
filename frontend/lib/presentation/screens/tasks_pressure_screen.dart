import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
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
        .addUserTask(
          title: title,
          priority: _priority,
          deadline: DateTime.now().toUtc().add(const Duration(days: 1)),
        );

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
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Pressure Task',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Task title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Priority: $_priority'),
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (v) => setState(() => _priority = v.round()),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _addTask,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Add task'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Failed to load tasks: $e'),
          data: (tasks) => GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const Text('No tasks yet.')
                else
                  ...tasks.map(
                    (task) => CheckboxListTile(
                      value: task.completed,
                      title: Text(task.title),
                      subtitle: Text(
                        'Priority ${task.priority} • ${task.taskType}',
                      ),
                      contentPadding: EdgeInsets.zero,
                      onChanged: task.completed
                          ? null
                          : (_) => _completeTask(task.id),
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
