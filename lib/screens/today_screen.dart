import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../providers/task_providers.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/task_tile.dart';
import '../widgets/dialogs/task_form_dialog.dart';

/// Focus Mode / Today View.
///
/// Aggregates ALL tasks due today across every type (daily, weekly, monthly,
/// yearly, once). Sorted by urgency then priority. Shows a real-time
/// progress bar (X/Y completed).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayAsync = ref.watch(todaySmartTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modo Enfoque',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              DateFormat('EEEE, d MMM', 'es_ES').format(DateTime.now()),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error al cargar tareas: $e'),
        ),
        data: (allTasks) {
          final sorted = _sortedTasks(allTasks);
          final completed = allTasks.where((t) => t.isCompleted).length;
          final total = allTasks.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodayProgressHeader(completed: completed, total: total),
              const Divider(height: 1),
              Expanded(
                child: total == 0
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: 12,
                          bottom: 80,
                          left: context.horizontalPadding,
                          right: context.horizontalPadding,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) => TaskTile(
                          task: sorted[i],
                          onEdit: (task) => _openEdit(context, ref, task),
                          onFeedback: (msg) => _showFeedback(context, msg),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Sorts tasks: incomplete first (overdue → urgent → high priority),
  /// then completed tasks at the bottom.
  List<Task> _sortedTasks(List<Task> tasks) {
    final incomplete = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
        return b.priority.compareTo(a.priority);
      });
    final complete = tasks.where((t) => t.isCompleted).toList();
    return [...incomplete, ...complete];
  }

  void _openEdit(BuildContext context, WidgetRef ref, Task task) {
    showTaskFormDialog(context: context, ref: ref, taskType: task.type, task: task);
  }

  void _showFeedback(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 72,
            color: colorScheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin tareas para hoy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tómate un descanso o\nagrega nuevas tareas.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TodayProgressHeader extends StatelessWidget {
  final int completed;
  final int total;

  const _TodayProgressHeader({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = total > 0 && completed == total;

    final String message;
    final Color accent;
    if (total == 0) {
      message = 'Listo para empezar';
      accent = colorScheme.primary;
    } else if (allDone) {
      message = '¡Todo listo! Excelente trabajo hoy.';
      accent = Colors.green;
    } else if (completed == 0) {
      final pending = total;
      message = 'Tienes $pending tarea${pending == 1 ? '' : 's'} por completar.';
      accent = colorScheme.primary;
    } else {
      final remaining = total - completed;
      message = '$remaining tarea${remaining == 1 ? '' : 's'} restante${remaining == 1 ? '' : 's'}.';
      accent = colorScheme.tertiary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
              ),
              if (total > 0)
                Text(
                  '$completed/$total',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  allDone ? Colors.green : colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
