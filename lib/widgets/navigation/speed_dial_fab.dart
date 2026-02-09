import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/navigation_provider.dart';

class SpeedDialFab extends StatefulWidget {
  final void Function(String taskType)? onAddTask;
  final void Function()? onAddNote;

  const SpeedDialFab({
    super.key,
    this.onAddTask,
    this.onAddNote,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _controller.reverse();
    }
  }

  void _onItemTap(String type) {
    HapticFeedback.selectionClick();
    _close();
    widget.onAddTask?.call(type);
  }

  void _onNoteTap() {
    HapticFeedback.selectionClick();
    _close();
    widget.onAddNote?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) => Container(
                  color: Colors.black
                      .withValues(alpha: 0.3 * _expandAnimation.value),
                ),
              ),
            ),
          ),

        // Speed dial items
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Note option
            _SpeedDialItem(
              animation: _expandAnimation,
              index: 5,
              icon: Icons.note_add_outlined,
              label: 'Nueva Nota',
              color: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              onTap: _onNoteTap,
            ),

            // Task type options
            ...TaskTypes.all.reversed.map((typeInfo) {
              final index = TaskTypes.all.indexOf(typeInfo);
              return _SpeedDialItem(
                animation: _expandAnimation,
                index: 4 - index,
                icon: _getIcon(typeInfo.icon),
                label: 'Tarea ${typeInfo.label}',
                color: colorScheme.secondaryContainer,
                iconColor: colorScheme.onSecondaryContainer,
                onTap: () => _onItemTap(typeInfo.type),
              );
            }),

            const SizedBox(height: 8),

            // Main FAB
            FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) => Transform.rotate(
                  angle: _expandAnimation.value * 0.75 * 3.14159,
                  child: Icon(
                    _isOpen ? Icons.close : Icons.add,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

class _SpeedDialItem extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.animation,
    required this.index,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delay = index * 0.1;
        final itemAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
          ),
        );

        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Material(
              color: colorScheme.surface,
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Mini FAB
            FloatingActionButton.small(
              heroTag: 'speed_dial_$index',
              onPressed: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              backgroundColor: color,
              foregroundColor: iconColor,
              elevation: 2,
              child: Icon(icon, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple FAB for single action (when speed dial not needed)
class SimpleFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  const SimpleFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
