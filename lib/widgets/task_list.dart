import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'task_tile.dart';

/// Filtros disponibles para la lista de tareas.
enum _TaskFilter { alta, pendientes, urgentes }

class TaskList extends ConsumerStatefulWidget {
  final String type;
  final void Function(Task task)? onEditTask;
  final void Function(String message)? onFeedback;
  final List<Task>? filteredTasks;
  final bool isSearching;
  final String? searchQuery;

  const TaskList({
    super.key,
    required this.type,
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
  final Set<_TaskFilter> _activeFilters = {};

  /// Aplica los filtros activos a la lista de tareas.
  List<Task> _applyFilters(List<Task> tasks) {
    if (_activeFilters.isEmpty) return tasks;
    return tasks.where((task) {
      if (_activeFilters.contains(_TaskFilter.alta) && task.priority != 2) {
        return false;
      }
      if (_activeFilters.contains(_TaskFilter.pendientes) && task.isCompleted) {
        return false;
      }
      if (_activeFilters.contains(_TaskFilter.urgentes) &&
          !(task.isOverdue || task.isUrgent)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _toggleFilter(_TaskFilter filter) {
    setState(() {
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
      } else {
        _activeFilters.add(filter);
      }
    });
  }

  void _clearFilters() {
    setState(() => _activeFilters.clear());
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> allTasks =
        widget.filteredTasks ?? ref.watch(tasksProvider(widget.type));
    final colorScheme = Theme.of(context).colorScheme;

    // When searching, bypass the filter bar and use the provided list directly.
    if (widget.isSearching) {
      return _buildTaskListView(context, allTasks, colorScheme, showSearch: true);
    }

    final List<Task> visibleTasks = _applyFilters(allTasks);
    final bool filtersActive = _activeFilters.isNotEmpty;

    return Column(
      children: [
        // Filter bar — only shown when there are tasks to filter
        if (allTasks.isNotEmpty)
          _TaskFilterBar(
            allTasks: allTasks,
            activeFilters: _activeFilters,
            onToggle: _toggleFilter,
            onClear: _clearFilters,
          ),

        // Task list or empty state
        Expanded(
          child: visibleTasks.isEmpty
              ? _buildEmptyState(context, colorScheme, filtersActive)
              : _buildTaskListView(context, visibleTasks, colorScheme),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    bool filtersActive,
  ) {
    if (filtersActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin tareas con este filtro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Quitar filtros'),
            ),
          ],
        ),
      );
    }

    if (widget.isSearching &&
        widget.searchQuery != null &&
        widget.searchQuery!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron tareas para "${widget.searchQuery}"',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rtl_rounded,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin tareas ${widget.type == 'daily'
                ? 'diarias'
                : widget.type == 'weekly'
                ? 'semanales'
                : 'mensuales'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Toca el botón + para empezar!',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView(
    BuildContext context,
    List<Task> tasks,
    ColorScheme colorScheme, {
    bool showSearch = false,
  }) {
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
}

/// Barra horizontal de chips para filtrar tareas.
class _TaskFilterBar extends StatelessWidget {
  final List<Task> allTasks;
  final Set<_TaskFilter> activeFilters;
  final void Function(_TaskFilter) onToggle;
  final VoidCallback onClear;

  const _TaskFilterBar({
    required this.allTasks,
    required this.activeFilters,
    required this.onToggle,
    required this.onClear,
  });

  int _count(_TaskFilter filter) {
    return allTasks.where((t) {
      switch (filter) {
        case _TaskFilter.alta:
          return t.priority == 2;
        case _TaskFilter.pendientes:
          return !t.isCompleted;
        case _TaskFilter.urgentes:
          return t.isOverdue || t.isUrgent;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtersActive = activeFilters.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "Todas" chip — active when no filter is selected
            _FilterChipItem(
              label: 'Todas',
              icon: Icons.format_list_bulleted,
              count: allTasks.length,
              selected: !filtersActive,
              selectedColor: colorScheme.primary,
              onSelected: (_) => onClear(),
            ),
            const SizedBox(width: 8),
            _FilterChipItem(
              label: 'Alta',
              icon: Icons.keyboard_double_arrow_up_rounded,
              count: _count(_TaskFilter.alta),
              selected: activeFilters.contains(_TaskFilter.alta),
              selectedColor: Colors.redAccent,
              onSelected: (_) => onToggle(_TaskFilter.alta),
            ),
            const SizedBox(width: 8),
            _FilterChipItem(
              label: 'Pendientes',
              icon: Icons.radio_button_unchecked,
              count: _count(_TaskFilter.pendientes),
              selected: activeFilters.contains(_TaskFilter.pendientes),
              selectedColor: Colors.orange,
              onSelected: (_) => onToggle(_TaskFilter.pendientes),
            ),
            const SizedBox(width: 8),
            _FilterChipItem(
              label: 'Urgentes',
              icon: Icons.alarm_rounded,
              count: _count(_TaskFilter.urgentes),
              selected: activeFilters.contains(_TaskFilter.urgentes),
              selectedColor: Colors.amber.shade700,
              onSelected: (_) => onToggle(_TaskFilter.urgentes),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final Color selectedColor;
  final void Function(bool) onSelected;

  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.3)
                  : colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : selectedColor,
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
