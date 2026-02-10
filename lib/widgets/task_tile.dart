import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/stats_provider.dart';
import 'task_stats.dart';

class TaskTile extends ConsumerWidget {
  final Task task;
  final void Function(Task task)? onEdit;
  final void Function(String message)? onFeedback;

  const TaskTile({super.key, required this.task, this.onEdit, this.onFeedback});

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.redAccent;
      case 1:
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 2:
        return 'Alta';
      case 1:
        return 'Media';
      default:
        return 'Baja';
    }
  }

  bool _isDueDatePast(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  /// Shows a celebration overlay when a task is completed
  void _showCelebrationOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CelebrationOverlay(
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Deslizar derecha para completar, izquierda para eliminar ${task.title}',
      child: Dismissible(
        key: Key('dismiss_${task.key ?? (task.firestoreId.isNotEmpty ? task.firestoreId : task.hashCode)}'),
        direction: DismissDirection.horizontal,
        // Swipe RIGHT to complete (green background)
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            label: task.isCompleted ? 'Desmarcar tarea' : 'Completar tarea',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  task.isCompleted ? 'Desmarcar' : 'Completar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Swipe LEFT to delete (red background)
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            label: 'Eliminar tarea',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Eliminar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.delete_outline, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe RIGHT: Complete/Toggle task
            final wasCompleted = task.isCompleted;

            // Haptic feedback
            HapticFeedback.mediumImpact();

            try {
              await ref.read(tasksProvider(task.type).notifier).toggleTask(task);

              // Record completion in history for daily tasks
              if (task.type == 'daily') {
                final taskId = task.key?.toString() ?? task.firestoreId;
                if (taskId.isNotEmpty) {
                  await ref.read(recordCompletionProvider)(taskId, !wasCompleted);
                }
              }

              if (!wasCompleted) {
                // Task completed - show celebration
                HapticFeedback.heavyImpact();
                if (context.mounted) {
                  _showCelebrationOverlay(context);
                }
                onFeedback?.call('🎉 ¡Excelente! Tarea completada');
              } else {
                onFeedback?.call('Tarea marcada como pendiente');
              }
            } catch (e) {
              onFeedback?.call('Error al actualizar');
            }

            return false; // Don't dismiss, just toggle
          } else {
            // Swipe LEFT: Delete - show confirmation
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Eliminar tarea'),
                content: Text('¿Estás seguro de que deseas eliminar "${task.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ?? false;
          }
        },
        onDismissed: (_) async {
          // Only delete triggers actual dismiss
          HapticFeedback.mediumImpact();
          try {
            await ref.read(tasksProvider(task.type).notifier).deleteTask(task);
            onFeedback?.call('Tarea eliminada');
          } catch (e) {
            onFeedback?.call('Error al eliminar');
          }
        },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha:0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: task.isCompleted
                ? Colors.transparent
                : _getPriorityColor(task.priority).withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Transform.scale(
            scale: 1.2,
            child: Semantics(
              label: task.isCompleted
                  ? 'Marcar ${task.title} como pendiente'
                  : 'Marcar ${task.title} como completada',
              checked: task.isCompleted,
              child: Checkbox(
                value: task.isCompleted,
                activeColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) async {
                  final wasCompleted = task.isCompleted;
                  HapticFeedback.mediumImpact();
                  try {
                    await ref.read(tasksProvider(task.type).notifier).toggleTask(task);
                    // Record completion in history for daily tasks
                    if (task.type == 'daily') {
                      final taskId = task.key?.toString() ?? task.firestoreId;
                      if (taskId.isNotEmpty) {
                        await ref.read(recordCompletionProvider)(taskId, !wasCompleted);
                      }
                    }
                    if (!wasCompleted) {
                      // Task completed! Show celebration
                      HapticFeedback.heavyImpact();
                      if (context.mounted) {
                        _showCelebrationOverlay(context);
                      }
                      onFeedback?.call('🎉 ¡Excelente! Tarea completada');
                    } else {
                      onFeedback?.call('Tarea marcada como pendiente');
                    }
                  } catch (e) {
                    onFeedback?.call('Error al actualizar');
                  }
                },
              ),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted
                  ? colorScheme.onSurface.withValues(alpha:0.5)
                  : colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row existente con prioridad, categoría, fecha, hora, deadline
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      label: 'Prioridad ${_getPriorityLabel(task.priority)}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getPriorityLabel(task.priority),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(task.priority),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Categoría ${task.category}',
                      child: Text(
                        task.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha:0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.dueDate != null)
                      Semantics(
                        label: 'Fecha de vencimiento ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}${_isDueDatePast(task.dueDate!) ? ", vencida" : ""}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 11,
                              color: _isDueDatePast(task.dueDate!)
                                  ? Colors.redAccent
                                  : colorScheme.onSurface.withValues(alpha:0.6),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                DateFormat('dd/MM').format(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isDueDatePast(task.dueDate!)
                                      ? Colors.redAccent
                                      : colorScheme.onSurface.withValues(alpha:0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (task.dueTimeMinutes != null)
                      Semantics(
                        label: 'Hora programada ${(task.dueTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(task.dueTimeMinutes! % 60).toString().padLeft(2, '0')}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 11,
                              color: colorScheme.onSurface.withValues(alpha:0.6),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${(task.dueTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(task.dueTimeMinutes! % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurface.withValues(alpha:0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Indicador de DEADLINE
                    if (task.deadline != null)
                      Semantics(
                        label: task.isOverdue
                            ? 'Fecha límite vencida'
                            : task.isUrgent
                                ? 'Tarea urgente, fecha límite próxima'
                                : 'Fecha límite ${task.deadline!.day}/${task.deadline!.month}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.isOverdue
                                ? Colors.red.withValues(alpha: 0.2)
                                : task.isUrgent
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.isOverdue ? Icons.warning : Icons.alarm,
                                size: 10,
                                color: task.isOverdue ? Colors.red : task.isUrgent ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  task.isOverdue
                                      ? '¡Vencida!'
                                      : task.isUrgent
                                          ? '¡Urgente!'
                                          : '${task.deadline!.day}/${task.deadline!.month}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: task.isOverdue ? Colors.red : task.isUrgent ? Colors.orange : Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Mensaje motivacional (solo si no está completada)
              if (!task.isCompleted) ...[
                const SizedBox(height: 6),
                Semantics(
                  label: 'Mensaje motivacional: ${task.motivationText}',
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.motivationText,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Recompensa (solo si completada y tiene reward)
              if (task.isCompleted && task.reward != null && task.reward!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Semantics(
                  label: 'Recompensa: ${task.reward}',
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${task.reward}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Expandable stats section (only for daily tasks)
              if (task.type == 'daily') ...[
                const SizedBox(height: 8),
                ExpandableStatsSection(
                  taskId: task.key?.toString() ?? task.firestoreId,
                ),
              ],
            ],
          ),
          onTap: onEdit != null ? () => onEdit!(task) : null,
        ),
      ),
    ),
    );
  }
}

/// Celebration overlay widget that shows a checkmark animation with confetti-like particles
class _CelebrationOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const _CelebrationOverlay({required this.onComplete});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Semi-transparent background
                Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Container(
                    color: Colors.green,
                  ),
                ),
                // Checkmark icon
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
                // Confetti particles
                ..._buildConfettiParticles(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildConfettiParticles() {
    final List<Widget> particles = [];
    final colors = [
      Colors.green,
      Colors.greenAccent,
      Colors.lightGreen,
      Colors.yellow,
      Colors.amber,
      Colors.white,
    ];

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      final color = colors[i % colors.length];

      particles.add(
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final distance = 80 + (progress * 120);
            final x = distance * (0.5 + 0.5 * (i.isEven ? 1 : -1)) *
                      (i % 3 == 0 ? 1.2 : 0.8) *
                      (angle > 3.14 ? -1 : 1);
            final y = distance * (0.5 + 0.5 * (i.isOdd ? 1 : -1)) *
                      (i % 2 == 0 ? 1.2 : 0.8) *
                      (angle > 1.57 && angle < 4.71 ? 1 : -1);

            return Transform.translate(
              offset: Offset(
                x * _scaleAnimation.value,
                y * _scaleAnimation.value,
              ),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.rotate(
                  angle: progress * 3.14159 * 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: i.isEven ? null : BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return particles;
  }
}
