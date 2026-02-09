import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'task_tile.dart';

class TaskList extends ConsumerWidget {
  final String type;
  final void Function(Task task)? onEditTask;
  final void Function(String message)? onFeedback;

  const TaskList({super.key, required this.type, this.onEditTask, this.onFeedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider(type));
    final colorScheme = Theme.of(context).colorScheme;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rtl_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha:0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin tareas ${type == 'daily'
                  ? 'diarias'
                  : type == 'weekly'
                  ? 'semanales'
                  : 'mensuales'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha:0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Toca el botón + para empezar!',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha:0.65),
              ),
            ),
          ],
        ),
      );
    }

    final horizontalPadding = context.horizontalPadding;

    return ListView.builder(
      itemCount: tasks.length,
      padding: EdgeInsets.only(
        top: 12,
        bottom: 80,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return TaskTile(
          task: tasks[index],
          onEdit: onEditTask,
          onFeedback: onFeedback,
        );
      },
    );
  }
}
