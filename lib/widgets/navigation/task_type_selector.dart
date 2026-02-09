import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';

class TaskTypeSelector extends ConsumerWidget {
  final bool showLabels;
  final bool scrollable;

  const TaskTypeSelector({
    super.key,
    this.showLabels = true,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedTaskTypeProvider);

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: TaskTypes.all.map((typeInfo) {
            final isSelected = selectedType == typeInfo.type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TypeChip(
                typeInfo: typeInfo,
                isSelected: isSelected,
                showLabel: showLabels,
                onTap: () {
                  ref.read(selectedTaskTypeProvider.notifier).state =
                      typeInfo.type;
                },
              ),
            );
          }).toList(),
        ),
      );
    }

    return SegmentedButton<String>(
      segments: TaskTypes.all.map((typeInfo) {
        return ButtonSegment(
          value: typeInfo.type,
          label: showLabels ? Text(typeInfo.shortLabel) : null,
          icon: Icon(_getIcon(typeInfo.icon), size: 18),
          tooltip: typeInfo.label,
        );
      }).toList(),
      selected: {selectedType},
      onSelectionChanged: (set) {
        ref.read(selectedTaskTypeProvider.notifier).state = set.first;
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  IconData _getIcon(String iconName) {
    return switch (iconName) {
      'wb_sunny' => Icons.wb_sunny_outlined,
      'calendar_view_week' => Icons.calendar_view_week_outlined,
      'calendar_month' => Icons.calendar_month_outlined,
      'event' => Icons.event_outlined,
      'push_pin' => Icons.push_pin_outlined,
      _ => Icons.task_outlined,
    };
  }
}

class _TypeChip extends StatelessWidget {
  final TaskTypeInfo typeInfo;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  const _TypeChip({
    required this.typeInfo,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
  });

  IconData _getIcon(String iconName) {
    return switch (iconName) {
      'wb_sunny' => Icons.wb_sunny_outlined,
      'calendar_view_week' => Icons.calendar_view_week_outlined,
      'calendar_month' => Icons.calendar_month_outlined,
      'event' => Icons.event_outlined,
      'push_pin' => Icons.push_pin_outlined,
      _ => Icons.task_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        _getIcon(typeInfo.icon),
        size: 18,
        color: isSelected ? colorScheme.onPrimaryContainer : null,
      ),
      label: showLabel ? Text(typeInfo.label) : const SizedBox.shrink(),
      labelPadding: showLabel ? null : EdgeInsets.zero,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Vertical task type selector for tablet/desktop sidebar
class TaskTypeSelectorVertical extends ConsumerWidget {
  const TaskTypeSelectorVertical({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedTaskTypeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TIPO DE TAREA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        ...TaskTypes.all.map((typeInfo) {
          final isSelected = selectedType == typeInfo.type;
          return _VerticalTypeItem(
            typeInfo: typeInfo,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedTaskTypeProvider.notifier).state = typeInfo.type;
            },
          );
        }),
      ],
    );
  }
}

class _VerticalTypeItem extends StatelessWidget {
  final TaskTypeInfo typeInfo;
  final bool isSelected;
  final VoidCallback onTap;

  const _VerticalTypeItem({
    required this.typeInfo,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIcon(String iconName) {
    return switch (iconName) {
      'wb_sunny' => Icons.wb_sunny_outlined,
      'calendar_view_week' => Icons.calendar_view_week_outlined,
      'calendar_month' => Icons.calendar_month_outlined,
      'event' => Icons.event_outlined,
      'push_pin' => Icons.push_pin_outlined,
      _ => Icons.task_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _getIcon(typeInfo.icon),
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    typeInfo.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
