import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';

class DateHeader extends ConsumerWidget {
  final String type;

  const DateHeader({super.key, required this.type});

  // Helper para calcular el número de semana ISO 8601
  int _getWeekNumber(DateTime date) {
    // ISO 8601: La semana 1 es la primera semana con jueves
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final firstThursday = DateTime(thursday.year, 1, 1).add(
      Duration(days: (11 - DateTime(thursday.year, 1, 1).weekday) % 7),
    );
    final weekNumber = ((thursday.difference(firstThursday).inDays / 7).floor() + 1);
    return weekNumber;
  }

  // Helper para obtener el trimestre actual
  String _getQuarter(DateTime date) {
    final month = date.month;
    if (month <= 3) return 'Q1';
    if (month <= 6) return 'Q2';
    if (month <= 9) return 'Q3';
    return 'Q4';
  }

  // Obtener el nombre del día en español
  String _getDayName(int weekday) {
    const days = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO'
    ];
    return days[weekday - 1];
  }

  // Obtener el nombre del mes en español
  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return months[month - 1];
  }

  // Obtener la etiqueta de progreso según el tipo
  String _getProgressLabel(String type) {
    switch (type) {
      case 'daily':
        return 'del día';
      case 'weekly':
        return 'de la semana';
      case 'monthly':
        return 'del mes';
      case 'yearly':
        return 'del año';
      case 'once':
        return 'únicas';
      default:
        return '';
    }
  }

  // Obtener mensaje motivacional según el progreso
  String _getMotivationalMessage(double progress, int completed, int total) {
    if (total == 0) {
      return '¡Añade tu primera tarea y empieza a conquistar el día! 🌟';
    }
    if (progress == 0) {
      return '¡Vamos! El primer paso es el más importante 🚀';
    }
    if (progress < 0.25) {
      return '¡Buen comienzo! Sigue así 💪';
    }
    if (progress < 0.5) {
      return '¡Vas por buen camino! Ya casi la mitad 🔥';
    }
    if (progress < 0.75) {
      return '¡Increíble progreso! Ya pasaste la mitad 🌟';
    }
    if (progress < 1.0) {
      return '¡Casi lo logras! Un último empujón 🏁';
    }
    return '🎉 ¡FELICIDADES! ¡Completaste todas las tareas! 🏆';
  }

  // Obtener el texto del encabezado según el tipo
  String _getHeaderText(String type, DateTime date) {
    switch (type) {
      case 'yearly':
        return '${date.year}';
      case 'once':
        return 'Tareas sin repetición';
      default:
        return _getDayName(date.weekday);
    }
  }

  // Obtener el texto del subtítulo según el tipo
  String _getSubtitleText(String type, DateTime date) {
    switch (type) {
      case 'yearly':
        return 'Año ${date.year}';
      case 'once':
        return 'Completa estas tareas una sola vez';
      default:
        final dayNumber = date.day;
        final monthName = _getMonthName(date.month);
        final year = date.year;
        return '$dayNumber $monthName $year';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final tasks = ref.watch(tasksProvider(type));

    // Calcular progreso
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // Textos dinámicos según el tipo
    final headerText = _getHeaderText(type, now);
    final subtitleText = _getSubtitleText(type, now);
    final progressLabel = _getProgressLabel(type);

    // Número de semana o trimestre (solo para ciertos tipos)
    final weekNumber = _getWeekNumber(now);
    final quarter = _getQuarter(now);
    final showPeriodBadge = type != 'once';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado dinámico
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onPrimaryContainer,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtítulo dinámico
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badge de número de semana o trimestre (oculto para 'once')
              if (showPeriodBadge)
                Flexible(
                  flex: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type == 'yearly' ? 'TRIMESTRE' : 'SEMANA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type == 'yearly' ? quarter : '$weekNumber',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Información de progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$completedTasks de $totalTasks tareas $progressLabel completadas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
          // Mensaje motivacional
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  progress == 1.0 ? '🏆' : '💡',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMotivationalMessage(progress, completedTasks, totalTasks),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: progress == 1.0 ? FontWeight.bold : FontWeight.w500,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
