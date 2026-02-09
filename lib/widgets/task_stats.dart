import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

/// Widget to display task completion statistics
class TaskStatsWidget extends ConsumerWidget {
  final String taskId;
  final bool compact; // If true, shows a minimal version

  const TaskStatsWidget({
    super.key,
    required this.taskId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(taskStatsProvider(taskId));

    return statsAsync.when(
      data: (stats) => compact
          ? _CompactStatsView(stats: stats)
          : _FullStatsView(stats: stats),
      loading: () => const _StatsLoadingView(),
      error: (e, st) => const _StatsErrorView(),
    );
  }
}

/// Compact version showing just streak and weekly dots
class _CompactStatsView extends StatelessWidget {
  final TaskStats stats;

  const _CompactStatsView({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streak indicator
          _StreakBadge(streak: stats.currentStreak, compact: true),
          const SizedBox(width: 8),
          // Weekly dots - wrap in Flexible to allow shrinking
          Flexible(
            child: _WeeklyDots(last7Days: stats.last7Days, compact: true),
          ),
        ],
      ),
    );
  }
}

/// Full version with all stats
class _FullStatsView extends StatelessWidget {
  final TaskStats stats;

  const _FullStatsView({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with streak
          Row(
            children: [
              _StreakBadge(streak: stats.currentStreak, compact: false),
              const Spacer(),
              if (stats.longestStreak > 0)
                _BestStreakIndicator(longestStreak: stats.longestStreak),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly progress
          Text(
            'Esta semana',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          _WeeklyDots(last7Days: stats.last7Days, compact: false),
          const SizedBox(height: 8),

          // Weekly/Monthly stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Semana',
                  value: '${stats.completedThisWeek}/${stats.totalThisWeek}',
                  percentage: stats.completionRateWeek,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Mes',
                  value: '${stats.completedThisMonth}/${stats.totalThisMonth}',
                  percentage: stats.completionRateMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Motivational message
          _MotivationalMessage(message: stats.motivationalMessage),
        ],
      ),
    );
  }
}

/// Streak badge with fire icon
class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool compact;

  const _StreakBadge({required this.streak, required this.compact});

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.purple;
    if (streak >= 21) return Colors.deepOrange;
    if (streak >= 14) return Colors.orange;
    if (streak >= 7) return Colors.amber;
    if (streak >= 3) return Colors.yellow.shade700;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStreakColor(streak);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak > 0 ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            size: 16,
            color: streak > 0 ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: streak > 0 ? color : Colors.grey,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            streak > 0 ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$streak ${streak == 1 ? 'dia' : 'dias'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Best streak indicator
class _BestStreakIndicator extends StatelessWidget {
  final int longestStreak;

  const _BestStreakIndicator({required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.emoji_events_outlined,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Mejor: $longestStreak',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Weekly dots showing completion status for each day
class _WeeklyDots extends StatelessWidget {
  final List<bool?> last7Days;
  final bool compact;

  const _WeeklyDots({required this.last7Days, required this.compact});

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday - 1; // 0-indexed

    final dotsRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isCompleted = last7Days.length > index ? last7Days[index] : null;
        final isToday = index == today;
        final isFuture = index > today;

        Color dotColor;
        IconData? icon;

        if (isFuture) {
          dotColor = colorScheme.outline.withValues(alpha: 0.2);
        } else if (isCompleted == true) {
          dotColor = Colors.green;
          icon = Icons.check;
        } else if (isCompleted == false) {
          dotColor = Colors.red.withValues(alpha: 0.6);
          icon = Icons.close;
        } else {
          dotColor = colorScheme.outline.withValues(alpha: 0.3);
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _dayLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              Container(
                width: compact ? 8 : 24,
                height: compact ? 8 : 24,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: colorScheme.primary, width: compact ? 1.5 : 2)
                      : null,
                ),
                child: icon != null && !compact
                    ? Icon(icon, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        );
      }),
    );

    // In compact mode, clip overflow to prevent layout issues
    if (compact) {
      return ClipRect(child: dotsRow);
    }
    return dotsRow;
  }
}

/// Stat card for weekly/monthly completion
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;

  const _StatCard({
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentageInt = (percentage * 100).round();

    Color progressColor;
    if (percentage >= 0.8) {
      progressColor = Colors.green;
    } else if (percentage >= 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.withValues(alpha: 0.7);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentageInt%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(progressColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Motivational message display
class _MotivationalMessage extends StatelessWidget {
  final String message;

  const _MotivationalMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state view
class _StatsLoadingView extends StatelessWidget {
  const _StatsLoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Error state view
class _StatsErrorView extends StatelessWidget {
  const _StatsErrorView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Error al cargar estadisticas',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable stats section for use in TaskTile
class ExpandableStatsSection extends ConsumerStatefulWidget {
  final String taskId;
  final bool initiallyExpanded;

  const ExpandableStatsSection({
    super.key,
    required this.taskId,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<ExpandableStatsSection> createState() => _ExpandableStatsSectionState();
}

class _ExpandableStatsSectionState extends ConsumerState<ExpandableStatsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(taskStatsProvider(widget.taskId));

    return Column(
      children: [
        // Toggle button with compact preview
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Estadisticas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                // Show compact stats when collapsed
                if (!_isExpanded)
                  Flexible(
                    child: statsAsync.when(
                      data: (stats) => _CompactStatsView(stats: stats),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expandable content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TaskStatsWidget(taskId: widget.taskId, compact: false),
          ),
        ),
      ],
    );
  }
}
