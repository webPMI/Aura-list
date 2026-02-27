/// Overdue tasks banner widget for dashboard.
///
/// Displays a prominent warning banner when tasks are overdue.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_providers.dart';

class OverdueTasksBanner extends ConsumerWidget {
  const OverdueTasksBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueAsync = ref.watch(overdueTasksStreamProvider);

    return overdueAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildBanner(context, tasks);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context, List<Task> overdueTasks) {
    final theme = Theme.of(context);
    final count = overdueTasks.length;
    final visibleTasks = overdueTasks.take(3).toList();
    final hasMore = overdueTasks.length > 3;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900,
            Colors.red.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to overdue tasks view
            _showOverdueTasksDialog(context, overdueTasks);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count == 1 ? 'Tarea vencida' : '$count tareas vencidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Requieren tu atención inmediata',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),

                // Task list
                ...visibleTasks.map((task) => _buildTaskItem(context, task)),

                // More indicator
                if (hasMore) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Y ${overdueTasks.length - 3} más...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final now = DateTime.now();
    final deadline = task.deadline!;
    final daysOverdue = now.difference(deadline).inDays;
    final overdueText = daysOverdue == 0
        ? 'Hoy'
        : daysOverdue == 1
            ? 'Ayer'
            : 'Hace $daysOverdue días';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            task.priority == 2
                ? Icons.priority_high
                : Icons.fiber_manual_record,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  overdueText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.category,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverdueTasksDialog(BuildContext context, List<Task> tasks) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            const Text('Tareas Vencidas'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final deadline = task.deadline!;
              final now = DateTime.now();
              final daysOverdue = now.difference(deadline).inDays;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  task.typeIcon,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(task.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha límite: ${dateFormat.format(deadline)}'),
                    Text(
                      daysOverdue == 0
                          ? 'Vence hoy'
                          : daysOverdue == 1
                              ? 'Venció ayer'
                              : 'Venció hace $daysOverdue días',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Chip(
                  label: Text(task.category),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
