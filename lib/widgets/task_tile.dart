import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:checklist_app/features/guides/guides.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/streak_provider.dart';
import '../core/constants/task_constants.dart';
import '../core/utils/time_utils.dart';
import 'shared/blessing_feedback.dart';
import 'shared/celebration_overlay.dart';
import 'streak_celebration_widget.dart';
import 'task_stats.dart';

class TaskTile extends ConsumerWidget {
  final Task task;
  final void Function(Task task)? onEdit;
  final void Function(String message)? onFeedback;

  const TaskTile({super.key, required this.task, this.onEdit, this.onFeedback});

  bool _isDueDatePast(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  /// Shows a celebration overlay when a task is completed (usa color del guia activo si hay).
  void _showCelebrationOverlay(BuildContext context, WidgetRef ref) {
    final color = ref.read(guideAccentColorProvider);
    CelebrationOverlay.show(context, color: color);
  }

  /// Verifica y muestra celebracion de racha si corresponde.
  void _checkAndShowStreakCelebration(BuildContext context, WidgetRef ref) async {
    // Actualizar racha y verificar si alcanzamos un hito
    final newStreak = await ref.read(checkStreakProvider)();
    if (newStreak != null && isStreakMilestone(newStreak) && context.mounted) {
      // Delay para no solaparse con otras celebraciones
      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          showStreakCelebration(context, newStreak);
        }
      });
    }
  }

  /// Evalua y muestra feedback de bendicion si corresponde.
  /// Retorna true si se activo una bendicion.
  bool _checkAndShowBlessingFeedback(BuildContext context, WidgetRef ref) {
    final guide = ref.read(activeGuideProvider);
    if (guide == null) return false;

    final service = ref.read(blessingTriggerServiceProvider);
    final result = service.evaluateTaskCompletion(
      task: task,
      activeGuide: guide,
    );

    if (result.triggered && result.blessing != null) {
      // Haptic diferenciado para la bendicion
      service.executeHapticFeedback(result.blessing!);

      // Mostrar feedback visual despues de un pequeno delay
      // para no solaparse con la celebracion principal
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) {
          final guideColor = ref.read(guideAccentColorProvider);
          BlessingFeedback.show(
            context,
            message: result.message ?? 'Bendicion activada!',
            blessing: result.blessing!,
            guideColor: guideColor,
          );
        }
      });

      return true;
    }

    return false;
  }

  /// Verifica y muestra logros recien obtenidos.
  void _checkAndShowAchievements(BuildContext context, WidgetRef ref) async {
    final activeGuide = ref.read(activeGuideProvider);
    if (activeGuide == null) return;

    final currentStreak = ref.read(streakProvider).currentStreak;

    // Verificar logros (simplificado - en produccion se necesita mas contexto)
    final newAchievements = await ref
        .read(guideAchievementsProvider.notifier)
        .checkAndAwardAchievements(
          activeGuideId: activeGuide.id,
          lastCompletedTask: task,
          currentStreak: currentStreak,
          totalTasksCompletedToday: 0, // TODO: obtener del provider de stats
          totalTasksWithGuide: 0, // TODO: obtener del provider de affinity
          categoriesCompletedToday: {}, // TODO: obtener del provider de stats
          totalRecurrentTasks: 0, // TODO: obtener del provider de tasks
          allTasksCompleted: false, // TODO: verificar si todas las tareas estan completadas
          daysWithGuide: 0, // TODO: obtener del provider de affinity
        );

    // Mostrar logros obtenidos con delay para no solaparse
    if (newAchievements.isNotEmpty && context.mounted) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (context.mounted) {
          for (final achievement in newAchievements) {
            AchievementEarnedWidget.show(context, achievement);
          }
        }
      });
    }
  }

  /// Incrementa el contador de afinidad con el guia activo.
  /// Muestra el modal de subida de nivel si corresponde.
  void _incrementGuideAffinity(BuildContext context, WidgetRef ref) async {
    try {
      final newLevel = await ref.read(incrementTaskCountProvider)();
      if (newLevel != null && context.mounted) {
        // Subio de nivel - mostrar celebracion especial
        final guide = ref.read(activeGuideProvider);
        if (guide != null) {
          // Delay para no solaparse con otras celebraciones
          // (bendicion ~400ms, racha ~800ms, logros ~1200ms)
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (context.mounted) {
              AffinityLevelUpWidget.show(
                context,
                newLevel: newLevel,
                guide: guide,
              );
            }
          });
        }
      }
    } catch (e) {
      // Silently fail - no queremos interrumpir el flujo del usuario
    }
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
                // Task completed - show celebration (con color del guia activo)
                HapticFeedback.heavyImpact();
                if (context.mounted) {
                  _showCelebrationOverlay(context, ref);
                  // Verificar y mostrar bendicion si hay guia activo
                  _checkAndShowBlessingFeedback(context, ref);
                  // Verificar y actualizar racha de dias
                  _checkAndShowStreakCelebration(context, ref);
                  // Incrementar contador de afinidad con el guia activo
                  _incrementGuideAffinity(context, ref);
                  // Verificar y mostrar logros obtenidos
                  _checkAndShowAchievements(context, ref);
                }
                onFeedback?.call('Tarea completada');
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
                : TaskConstants.getPriorityColor(task.priority).withValues(alpha:0.3),
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
                        _showCelebrationOverlay(context, ref);
                        // Verificar y mostrar bendicion si hay guia activo
                        _checkAndShowBlessingFeedback(context, ref);
                        // Verificar y actualizar racha de dias
                        _checkAndShowStreakCelebration(context, ref);
                        // Incrementar contador de afinidad con el guia activo
                        _incrementGuideAffinity(context, ref);
                        // Verificar y mostrar logros obtenidos
                        _checkAndShowAchievements(context, ref);
                      }
                      onFeedback?.call('Tarea completada');
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
                      label: 'Prioridad ${TaskConstants.getPriorityLabel(task.priority)}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TaskConstants.getPriorityColor(task.priority).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          TaskConstants.getPriorityLabel(task.priority),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: TaskConstants.getPriorityColor(task.priority),
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
                        label: 'Hora programada ${TimeUtils.formatMinutes(task.dueTimeMinutes!)}',
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
                                TimeUtils.formatMinutes(task.dueTimeMinutes!),
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
