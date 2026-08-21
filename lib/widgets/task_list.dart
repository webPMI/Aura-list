import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'task_tile.dart';

/// Filtros principales disponibles para la vista inteligente de tareas.
enum TaskViewFilter {
  all,
  today,
  highPriority,
  pending,
  completed,
}

class TaskList extends ConsumerStatefulWidget {
  final String type; // 'all', 'daily', 'weekly', 'monthly', 'yearly', 'once'
  final void Function(Task task)? onEditTask;
  final void Function(String message)? onFeedback;
  final List<Task>? filteredTasks;
  final bool isSearching;
  final String? searchQuery;

  const TaskList({
    super.key,
    this.type = 'all',
    this.onEditTask,
    this.onFeedback,
    this.filteredTasks,
    this.isSearching = false,
    this.searchQuery,
  });

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  TaskViewFilter _activeFilter = TaskViewFilter.all;
  String? _selectedTypeFilter; // null = todos los tipos
  bool _showCompleted = false;

  bool _isSameDay(DateTime? date, DateTime target) {
    if (date == null) return false;
    return date.year == target.year &&
        date.month == target.month &&
        date.day == target.day;
  }

  bool _isBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    return due.isBefore(today);
  }

  bool _isWithinNext7Days(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    final check = DateTime(date.year, date.month, date.day);
    return check.isAfter(today) && (check.isBefore(nextWeek) || check.isAtSameMomentAs(nextWeek));
  }

  List<Task> _applyFilters(List<Task> tasks) {
    List<Task> result = tasks;

    // Filtro por tipo específico si está seleccionado
    if (_selectedTypeFilter != null) {
      result = result.where((t) => t.type == _selectedTypeFilter).toList();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_activeFilter) {
      case TaskViewFilter.all:
        return result;
      case TaskViewFilter.today:
        return result.where((t) {
          if (t.isCompleted) return false;
          return t.type == 'daily' ||
              _isSameDay(t.dueDate, today) ||
              _isSameDay(t.deadline, today) ||
              (t.dueDate != null && _isBeforeToday(t.dueDate!));
        }).toList();
      case TaskViewFilter.highPriority:
        return result.where((t) => !t.isCompleted && t.priority == 2).toList();
      case TaskViewFilter.pending:
        return result.where((t) => !t.isCompleted).toList();
      case TaskViewFilter.completed:
        return result.where((t) => t.isCompleted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Obtener la lista base de tareas
    final List<Task> allTasks = widget.filteredTasks ??
        (widget.type == 'all'
            ? ref.watch(unifiedAllTasksProvider)
            : ref.watch(tasksProvider(widget.type)));

    // Si estamos en modo búsqueda de texto, renderizar directamente los resultados
    if (widget.isSearching) {
      return _buildSearchListView(context, allTasks, colorScheme);
    }

    final List<Task> filteredTasks = _applyFilters(allTasks);

    return Column(
      children: [
        // Barra de filtros rápidos modernos
        _SmartFilterBar(
          allTasks: allTasks,
          activeFilter: _activeFilter,
          selectedTypeFilter: _selectedTypeFilter,
          onFilterChanged: (filter) {
            setState(() {
              _activeFilter = filter;
            });
          },
          onTypeFilterChanged: (type) {
            setState(() {
              _selectedTypeFilter = type;
            });
          },
        ),

        // Lista de tareas agrupada o vacía
        Expanded(
          child: filteredTasks.isEmpty
              ? _buildEmptyState(context, colorScheme)
              : _buildGroupedOrFlatListView(context, filteredTasks, colorScheme),
        ),
      ],
    );
  }

  Widget _buildSearchListView(
    BuildContext context,
    List<Task> tasks,
    ColorScheme colorScheme,
  ) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'No se encontraron tareas para "${widget.searchQuery}"',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
          onEdit: widget.onEditTask,
          onFeedback: widget.onFeedback,
        );
      },
    );
  }

  Widget _buildGroupedOrFlatListView(
    BuildContext context,
    List<Task> tasks,
    ColorScheme colorScheme,
  ) {
    final horizontalPadding = context.horizontalPadding;

    // Si hay un filtro específico activo (excepto "Todas" o "Pendientes"), mostrar lista plana
    if (_activeFilter == TaskViewFilter.today ||
        _activeFilter == TaskViewFilter.highPriority ||
        _activeFilter == TaskViewFilter.completed) {
      return ListView.builder(
        itemCount: tasks.length,
        padding: EdgeInsets.only(
          top: 8,
          bottom: 80,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return TaskTile(
            task: tasks[index],
            onEdit: widget.onEditTask,
            onFeedback: widget.onFeedback,
          );
        },
      );
    }

    // Vista inteligente agrupada por secciones
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdue = <Task>[];
    final forToday = <Task>[];
    final upcoming = <Task>[];
    final later = <Task>[];
    final completed = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted) {
        completed.add(task);
        continue;
      }

      if (task.isOverdue || (task.dueDate != null && _isBeforeToday(task.dueDate!))) {
        overdue.add(task);
      } else if (task.type == 'daily' ||
          _isSameDay(task.dueDate, today) ||
          _isSameDay(task.deadline, today)) {
        forToday.add(task);
      } else if (task.type == 'weekly' || _isWithinNext7Days(task.dueDate)) {
        upcoming.add(task);
      } else {
        later.add(task);
      }
    }

    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 80,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Sección Vencidas (si hay)
        if (overdue.isNotEmpty) ...[
          _SectionHeaderTile(
            title: 'Vencidas',
            icon: Icons.error_outline_rounded,
            count: overdue.length,
            accentColor: Colors.redAccent,
          ),
          ...overdue.map(
            (t) => TaskTile(
              task: t,
              onEdit: widget.onEditTask,
              onFeedback: widget.onFeedback,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. Sección Para Hoy
        if (forToday.isNotEmpty) ...[
          _SectionHeaderTile(
            title: 'Para Hoy',
            icon: Icons.wb_sunny_outlined,
            count: forToday.length,
            accentColor: Colors.orangeAccent,
          ),
          ...forToday.map(
            (t) => TaskTile(
              task: t,
              onEdit: widget.onEditTask,
              onFeedback: widget.onFeedback,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Sección Próximas / Esta Semana
        if (upcoming.isNotEmpty) ...[
          _SectionHeaderTile(
            title: 'Próximas / Esta Semana',
            icon: Icons.calendar_view_week_outlined,
            count: upcoming.length,
            accentColor: Colors.blueAccent,
          ),
          ...upcoming.map(
            (t) => TaskTile(
              task: t,
              onEdit: widget.onEditTask,
              onFeedback: widget.onFeedback,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Sección Más Adelante / Otras
        if (later.isNotEmpty) ...[
          _SectionHeaderTile(
            title: 'Más Adelante',
            icon: Icons.inbox_outlined,
            count: later.length,
            accentColor: Colors.teal,
          ),
          ...later.map(
            (t) => TaskTile(
              task: t,
              onEdit: widget.onEditTask,
              onFeedback: widget.onFeedback,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Sección Completadas (Colapsable)
        if (completed.isNotEmpty && _activeFilter != TaskViewFilter.pending) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _showCompleted
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Completadas (${completed.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCompleted) ...[
            const SizedBox(height: 4),
            ...completed.map(
              (t) => TaskTile(
                task: t,
                onEdit: widget.onEditTask,
                onFeedback: widget.onFeedback,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    String title = 'Sin tareas';
    String subtitle = '¡Toca el botón + para crear una nueva tarea!';
    IconData icon = Icons.checklist_rtl_rounded;

    switch (_activeFilter) {
      case TaskViewFilter.today:
        title = '¡Todo listo por hoy!';
        subtitle = 'No tienes tareas pendientes para el día de hoy.';
        icon = Icons.wb_sunny_rounded;
        break;
      case TaskViewFilter.highPriority:
        title = 'Sin tareas de alta prioridad';
        subtitle = 'Excelente, no hay urgencias pendientes.';
        icon = Icons.done_all_rounded;
        break;
      case TaskViewFilter.pending:
        title = '¡Sin tareas pendientes!';
        subtitle = 'Has completado todas tus tareas pendientes.';
        icon = Icons.celebration_rounded;
        break;
      case TaskViewFilter.completed:
        title = 'Sin tareas completadas aún';
        subtitle = 'Marca tareas como listas para verlas aquí.';
        icon = Icons.check_circle_outline_rounded;
        break;
      case TaskViewFilter.all:
        title = 'Tu lista de tareas está vacía';
        subtitle = 'Comienza agregando tu primera tarea con el botón +';
        icon = Icons.assignment_add;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado visual para cada sección cronológica
class _SectionHeaderTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Color accentColor;

  const _SectionHeaderTile({
    required this.title,
    required this.icon,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra horizontal de filtros rápidos con chips modernos
class _SmartFilterBar extends StatelessWidget {
  final List<Task> allTasks;
  final TaskViewFilter activeFilter;
  final String? selectedTypeFilter;
  final ValueChanged<TaskViewFilter> onFilterChanged;
  final ValueChanged<String?> onTypeFilterChanged;

  const _SmartFilterBar({
    required this.allTasks,
    required this.activeFilter,
    required this.selectedTypeFilter,
    required this.onFilterChanged,
    required this.onTypeFilterChanged,
  });

  int get _todayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return allTasks.where((t) {
      if (t.isCompleted) return false;
      return t.type == 'daily' ||
          (t.dueDate != null &&
              t.dueDate!.year == today.year &&
              t.dueDate!.month == today.month &&
              t.dueDate!.day == today.day) ||
          (t.dueDate != null && t.dueDate!.isBefore(today));
    }).length;
  }

  int get _highPriorityCount =>
      allTasks.where((t) => !t.isCompleted && t.priority == 2).length;

  int get _pendingCount => allTasks.where((t) => !t.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. Todas
            _FilterChipButton(
              label: 'Todas',
              icon: Icons.all_inclusive_rounded,
              count: allTasks.length,
              isSelected: activeFilter == TaskViewFilter.all && selectedTypeFilter == null,
              accentColor: colorScheme.primary,
              onTap: () {
                onTypeFilterChanged(null);
                onFilterChanged(TaskViewFilter.all);
              },
            ),
            const SizedBox(width: 8),

            // 2. Hoy
            _FilterChipButton(
              label: 'Hoy',
              icon: Icons.wb_sunny_rounded,
              count: _todayCount,
              isSelected: activeFilter == TaskViewFilter.today,
              accentColor: Colors.orangeAccent,
              onTap: () => onFilterChanged(TaskViewFilter.today),
            ),
            const SizedBox(width: 8),

            // 3. Alta Prioridad
            _FilterChipButton(
              label: 'Alta',
              icon: Icons.keyboard_double_arrow_up_rounded,
              count: _highPriorityCount,
              isSelected: activeFilter == TaskViewFilter.highPriority,
              accentColor: Colors.redAccent,
              onTap: () => onFilterChanged(TaskViewFilter.highPriority),
            ),
            const SizedBox(width: 8),

            // 4. Pendientes
            _FilterChipButton(
              label: 'Pendientes',
              icon: Icons.radio_button_unchecked_rounded,
              count: _pendingCount,
              isSelected: activeFilter == TaskViewFilter.pending,
              accentColor: Colors.amber.shade700,
              onTap: () => onFilterChanged(TaskViewFilter.pending),
            ),
            const SizedBox(width: 8),

            // 5. Selector por Tipo de Frecuencia
            PopupMenuButton<String?>(
              tooltip: 'Filtrar por frecuencia',
              onSelected: onTypeFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem<String?>(
                  value: null,
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Todas las frecuencias'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'daily',
                  child: ListTile(
                    leading: Icon(Icons.wb_sunny_outlined),
                    title: Text('Diarias'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'weekly',
                  child: ListTile(
                    leading: Icon(Icons.calendar_view_week_outlined),
                    title: Text('Semanales'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'monthly',
                  child: ListTile(
                    leading: Icon(Icons.calendar_month_outlined),
                    title: Text('Mensuales'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'yearly',
                  child: ListTile(
                    leading: Icon(Icons.event_outlined),
                    title: Text('Anuales'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'once',
                  child: ListTile(
                    leading: Icon(Icons.push_pin_outlined),
                    title: Text('Únicas'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: selectedTypeFilter != null
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedTypeFilter != null
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: selectedTypeFilter != null
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedTypeFilter != null
                          ? _getTypeLabel(selectedTypeFilter!)
                          : 'Frecuencia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selectedTypeFilter != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedTypeFilter != null
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: selectedTypeFilter != null
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    return switch (type) {
      'daily' => 'Diarias',
      'weekly' => 'Semanales',
      'monthly' => 'Mensuales',
      'yearly' => 'Anuales',
      'once' => 'Únicas',
      _ => type,
    };
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accentColor : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.25)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
