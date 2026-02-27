import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../core/constants/task_constants.dart';

/// Widget que muestra todas las tareas pospuestas en un card colapsable.
/// Las tareas se agrupan por fecha de posposición (Hoy, Mañana, Esta semana, Más tarde).
class DeferredTasksWidget extends ConsumerStatefulWidget {
  const DeferredTasksWidget({super.key});

  @override
  ConsumerState<DeferredTasksWidget> createState() => _DeferredTasksWidgetState();
}

class _DeferredTasksWidgetState extends ConsumerState<DeferredTasksWidget> {
  bool _isExpanded = true;

  /// Determina la categoría temporal de una fecha de posposición.
  String _getTimeCategory(DateTime deferredUntil) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final deferredDay = DateTime(deferredUntil.year, deferredUntil.month, deferredUntil.day);

    if (deferredDay.isAtSameMomentAs(today)) {
      return 'Hoy';
    } else if (deferredDay.isAtSameMomentAs(tomorrow)) {
      return 'Mañana';
    } else if (deferredDay.isBefore(nextWeek)) {
      return 'Esta semana';
    } else {
      return 'Más tarde';
    }
  }

  /// Agrupa las tareas por categoría temporal.
  Map<String, List<Task>> _groupTasksByTime(List<Task> tasks) {
    final groups = <String, List<Task>>{
      'Hoy': [],
      'Mañana': [],
      'Esta semana': [],
      'Más tarde': [],
    };

    for (final task in tasks) {
      if (task.deferredUntil != null) {
        final category = _getTimeCategory(task.deferredUntil!);
        groups[category]?.add(task);
      }
    }

    // Eliminar categorías vacías
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final deferredTasks = ref.watch(deferredTasksProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // No mostrar el widget si no hay tareas pospuestas
    if (deferredTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedTasks = _groupTasksByTime(deferredTasks);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header con badge de cantidad y botón de colapsar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Tareas Pospuestas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${deferredTasks.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tareas temporalmente ocultas',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Lista de tareas agrupadas (colapsable)
          if (_isExpanded)
            ...groupedTasks.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de grupo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Tareas del grupo
                  ...entry.value.map((task) => _DeferredTaskItem(task: task)),
                  const SizedBox(height: 8),
                ],
              );
            }),
        ],
      ),
    );
  }
}

/// Item individual de tarea pospuesta.
class _DeferredTaskItem extends ConsumerWidget {
  final Task task;

  const _DeferredTaskItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () async {
        // Mostrar opciones: Quitar posposición o Editar
        final result = await showModalBottomSheet<String>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_off),
                  title: const Text('Quitar posposición'),
                  subtitle: const Text('Mostrar tarea ahora'),
                  onTap: () => Navigator.of(ctx).pop('unsnooze'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Cambiar fecha'),
                  subtitle: const Text('Posponer para otro momento'),
                  onTap: () => Navigator.of(ctx).pop('reschedule'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );

        if (result == 'unsnooze' && context.mounted) {
          try {
            await ref.read(tasksProvider(task.type).notifier).unsnoozeTask(task);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Posposición quitada'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al quitar posposición'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else if (result == 'reschedule' && context.mounted) {
          _showReschedulePicker(context, ref);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Icono de tipo de tarea
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TaskConstants.getPriorityColor(task.priority)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.typeIcon,
                size: 16,
                color: TaskConstants.getPriorityColor(task.priority),
              ),
            ),
            const SizedBox(width: 12),
            // Título y detalles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        task.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(fontSize: 11)),
                      Icon(
                        Icons.alarm,
                        size: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        DateFormat('HH:mm').format(task.deferredUntil!),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Indicador de prioridad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TaskConstants.getPriorityColor(task.priority)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                TaskConstants.getPriorityLabel(task.priority),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: TaskConstants.getPriorityColor(task.priority),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo para reprogramar la posposición.
  Future<void> _showReschedulePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: task.deferredUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate != null && context.mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: task.deferredUntil != null
            ? TimeOfDay.fromDateTime(task.deferredUntil!)
            : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      );

      if (selectedTime != null && context.mounted) {
        final newDeferredUntil = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        try {
          await ref.read(tasksProvider(task.type).notifier).snoozeTask(task, newDeferredUntil);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tarea reprogramada'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al reprogramar'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }
}
