import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class CalendarView extends ConsumerStatefulWidget {
  final void Function(DateTime date)? onDateSelected;
  final void Function(Task task)? onTaskTap;

  const CalendarView({super.key, this.onDateSelected, this.onTaskTap});

  @override
  ConsumerState<CalendarView> createState() => CalendarViewState();
}

class CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  /// Jumps to today's date, updating both the current month and selected date.
  void jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
    widget.onDateSelected?.call(now);
  }

  // Genera los días del mes actual
  List<DateTime?> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday; // 1=Lun, 7=Dom

    final List<DateTime?> days = [];

    // Días vacíos antes del primer día
    for (int i = 1; i < startWeekday; i++) {
      days.add(null);
    }

    // Días del mes
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  // Obtiene tareas para una fecha específica
  List<Task> _getTasksForDate(DateTime date, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
             task.dueDate!.month == date.month &&
             task.dueDate!.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener TODAS las tareas de todos los tipos
    final dailyTasks = ref.watch(tasksProvider('daily'));
    final weeklyTasks = ref.watch(tasksProvider('weekly'));
    final monthlyTasks = ref.watch(tasksProvider('monthly'));
    final yearlyTasks = ref.watch(tasksProvider('yearly'));
    final onceTasks = ref.watch(tasksProvider('once'));

    final allTasks = [...dailyTasks, ...weeklyTasks, ...monthlyTasks, ...yearlyTasks, ...onceTasks];

    final colorScheme = Theme.of(context).colorScheme;
    final days = _getDaysInMonth();
    final now = DateTime.now();
    final horizontalPadding = context.horizontalPadding;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con navegación de mes
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Mes anterior',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  }),
                ),
              ),
              Semantics(
                label: '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                header: true,
                child: Text(
                  '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Semantics(
                label: 'Mes siguiente',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  }),
                ),
              ),
            ],
          ),
        ),

        // Días de la semana
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) =>
              Expanded(
                child: Center(
                  child: Text(day, style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  )),
                ),
              ),
            ).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Grid de días
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();

              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
              final tasksForDay = _getTasksForDate(date, allTasks);
              final hasTask = tasksForDay.isNotEmpty;
              final completedCount = tasksForDay.where((t) => t.isCompleted).length;

              // Build semantic label for the day cell
              String semanticLabel = 'Seleccionar ${date.day} de ${_getMonthName(_currentMonth.month)}';
              if (isToday) {
                semanticLabel += ', hoy';
              }
              if (isSelected) {
                semanticLabel += ', seleccionado';
              }
              if (hasTask) {
                final pendingCount = tasksForDay.length - completedCount;
                if (completedCount == tasksForDay.length) {
                  semanticLabel += ', ${tasksForDay.length} tareas completadas';
                } else if (pendingCount == tasksForDay.length) {
                  semanticLabel += ', ${tasksForDay.length} tareas pendientes';
                } else {
                  semanticLabel += ', $completedCount de ${tasksForDay.length} tareas completadas';
                }
              }

              return Semantics(
                label: semanticLabel,
                button: true,
                selected: isSelected,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    widget.onDateSelected?.call(date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected ? Border.all(color: colorScheme.primary, width: 2) : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? colorScheme.onPrimary : null,
                            fontWeight: isToday || isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        if (hasTask)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: completedCount == tasksForDay.length
                                        ? Colors.green
                                        : colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (tasksForDay.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      '${tasksForDay.length}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Lista de tareas del día seleccionado
        if (_selectedDate != null) ...[
          const Divider(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                Text(
                  'Tareas del ${_selectedDate!.day}/${_selectedDate!.month}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._getTasksForDate(_selectedDate!, allTasks).map((task) =>
            Semantics(
              label: '${task.title}, ${task.isCompleted ? "completada" : "pendiente"}, tipo ${task.typeLabel}',
              button: true,
              child: ListTile(
                leading: Semantics(
                  label: task.isCompleted ? 'Tarea completada' : 'Tarea pendiente',
                  child: Icon(
                    task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : colorScheme.primary,
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(task.typeLabel),
                onTap: () => widget.onTaskTap?.call(task),
              ),
            ),
          ),
          if (_getTasksForDate(_selectedDate!, allTasks).isEmpty)
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Text(
                'No hay tareas para este día',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ),
        ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }
}
