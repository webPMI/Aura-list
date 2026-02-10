import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/responsive/breakpoints.dart';
import '../core/constants/motivational_messages.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/layouts/dashboard_layout.dart';
import '../widgets/navigation/drawer_menu_button.dart';
import '../widgets/dashboard/wellness_suggestions_card.dart';
import '../widgets/dashboard/user_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: _GreetingHeader(),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _TaskSearchDelegate(ref),
              );
            },
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: DashboardLayout(
        cards: [
          const UserCard(),
          _TodayProgressCard(),
          _TodayTasksCard(),
          const WellnessSuggestionsCard(),
          _UpcomingDeadlinesCard(),
          _WeeklyProgressCard(),
          _QuickNotesCard(),
          _StatsOverviewCard(),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final greeting = MotivationalMessages.getTimeBasedGreeting();
    final dateFormat = DateFormat('EEEE d MMMM', 'es');

    // Responsive font sizes
    final isMobile = context.isMobile;
    final titleFontSize = isMobile ? 20.0 : 24.0;
    final subtitleFontSize = isMobile ? 12.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          dateFormat.format(DateTime.now()),
          style: TextStyle(
            fontSize: subtitleFontSize,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _TodayProgressCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTasks = ref.watch(tasksProvider('daily'));
    final completed = dailyTasks.where((t) => t.isCompleted).length;
    final total = dailyTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return QuickStatsCard(
      title: 'Tareas de Hoy',
      value: '$completed/$total',
      subtitle: _getProgressMessage(progress, total),
      icon: Icons.wb_sunny,
      progress: progress,
      color: Colors.orange,
      onTap: () {
        ref.read(selectedTaskTypeProvider.notifier).state = 'daily';
        ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
      },
    );
  }

  String _getProgressMessage(double progress, int total) {
    if (total == 0) return MotivationalMessages.randomEmptyTaskList;
    if (progress == 0) return MotivationalMessages.randomMorningMotivation;
    if (progress < 0.5) return 'Buen comienzo, sigue asi';
    if (progress < 1) return 'Casi lo logras, tu puedes';
    return MotivationalMessages.randomTaskCompleted;
  }
}

class _TodayTasksCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTasks = ref.watch(tasksProvider('daily'));
    final pendingTasks = dailyTasks.where((t) => !t.isCompleted).take(3).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Pendientes de Hoy',
      icon: Icons.checklist,
      onMoreTap: () {
        ref.read(selectedTaskTypeProvider.notifier).state = 'daily';
        ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
      },
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: pendingTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 40,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todo completado',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingTasks.length,
              itemBuilder: (context, index) {
                final task = pendingTasks[index];
                return _CompactTaskTile(task: task);
              },
            ),
    );
  }
}

class _CompactTaskTile extends ConsumerStatefulWidget {
  final dynamic task;

  const _CompactTaskTile({required this.task});

  @override
  ConsumerState<_CompactTaskTile> createState() => _CompactTaskTileState();
}

class _CompactTaskTileState extends ConsumerState<_CompactTaskTile> {
  final priorityColors = [Colors.blue, Colors.orange, Colors.red];

  void _showCelebrationOverlay() {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 4,
        height: 32,
        decoration: BoxDecoration(
          color: priorityColors[widget.task.priority],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        widget.task.title,
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Checkbox(
        value: widget.task.isCompleted,
        onChanged: (_) async {
          final wasCompleted = widget.task.isCompleted;
          try {
            await ref.read(tasksProvider(widget.task.type).notifier).toggleTask(widget.task);
            if (mounted) {
              if (!wasCompleted) {
                _showCelebrationOverlay();
                _showSnackBar(MotivationalMessages.randomTaskCompletedWithEmoji);
              } else {
                _showSnackBar('Tarea marcada como pendiente');
              }
            }
          } catch (e) {
            if (mounted) {
              _showSnackBar('Error al actualizar');
            }
          }
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _UpcomingDeadlinesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect tasks with deadlines from all types
    final allTasks = [
      ...ref.watch(tasksProvider('daily')),
      ...ref.watch(tasksProvider('weekly')),
      ...ref.watch(tasksProvider('monthly')),
      ...ref.watch(tasksProvider('yearly')),
      ...ref.watch(tasksProvider('once')),
    ];

    final now = DateTime.now();
    final upcomingTasks = allTasks
        .where((t) =>
            !t.isCompleted &&
            t.deadline != null &&
            t.deadline!.isAfter(now) &&
            t.deadline!.difference(now).inDays <= 7)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

    final urgentCount = upcomingTasks.where((t) => t.isUrgent).length;
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Proximos Vencimientos',
      icon: Icons.alarm,
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: upcomingTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 40,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin vencimientos proximos',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (urgentCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$urgentCount urgente${urgentCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: upcomingTasks.take(3).length,
                    itemBuilder: (context, index) {
                      final task = upcomingTasks[index];
                      final daysLeft =
                          task.deadline!.difference(now).inDays;
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          task.title,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          daysLeft == 0
                              ? 'Hoy'
                              : daysLeft == 1
                                  ? 'Manana'
                                  : '$daysLeft dias',
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isUrgent ? Colors.red : null,
                            fontWeight:
                                task.isUrgent ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _WeeklyProgressCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyTasks = ref.watch(tasksProvider('weekly'));
    final completed = weeklyTasks.where((t) => t.isCompleted).length;
    final total = weeklyTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return QuickStatsCard(
      title: 'Tareas Semanales',
      value: '$completed/$total',
      subtitle: 'Esta semana',
      icon: Icons.calendar_view_week,
      progress: progress,
      color: Colors.blue,
      onTap: () {
        ref.read(selectedTaskTypeProvider.notifier).state = 'weekly';
        ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
      },
    );
  }
}

class _QuickNotesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(independentNotesProvider);
    final recentNotes = notes.take(3).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Notas Recientes',
      icon: Icons.note,
      onMoreTap: () {
        ref.read(selectedRouteProvider.notifier).state = AppRoute.notes;
      },
      height: 160,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: recentNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 40,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin notas',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: recentNotes.length,
              itemBuilder: (context, index) {
                final note = recentNotes[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(note.color.replaceFirst('#', '0xFF')),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline),
                    ),
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
    );
  }
}

class _StatsOverviewCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyTasks = ref.watch(tasksProvider('monthly'));
    final yearlyTasks = ref.watch(tasksProvider('yearly'));
    final onceTasks = ref.watch(tasksProvider('once'));

    final monthlyCompleted = monthlyTasks.where((t) => t.isCompleted).length;
    final yearlyCompleted = yearlyTasks.where((t) => t.isCompleted).length;
    final onceCompleted = onceTasks.where((t) => t.isCompleted).length;

    return DashboardCard(
      title: 'Resumen',
      icon: Icons.analytics,
      height: 160,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _StatItem(
              label: 'Mes',
              value: '$monthlyCompleted/${monthlyTasks.length}',
              icon: Icons.calendar_month,
              onTap: () {
                ref.read(selectedTaskTypeProvider.notifier).state = 'monthly';
                ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
              },
            ),
          ),
          Flexible(
            child: _StatItem(
              label: 'Ano',
              value: '$yearlyCompleted/${yearlyTasks.length}',
              icon: Icons.event,
              onTap: () {
                ref.read(selectedTaskTypeProvider.notifier).state = 'yearly';
                ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
              },
            ),
          ),
          Flexible(
            child: _StatItem(
              label: 'Unicas',
              value: '$onceCompleted/${onceTasks.length}',
              icon: Icons.push_pin,
              onTap: () {
                ref.read(selectedTaskTypeProvider.notifier).state = 'once';
                ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebration overlay widget that shows a checkmark animation
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
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
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
            final x = distance *
                (0.5 + 0.5 * (i.isEven ? 1 : -1)) *
                (i % 3 == 0 ? 1.2 : 0.8) *
                (angle > 3.14 ? -1 : 1);
            final y = distance *
                (0.5 + 0.5 * (i.isOdd ? 1 : -1)) *
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
                      borderRadius:
                          i.isEven ? null : BorderRadius.circular(2),
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

/// Search delegate for searching tasks across all task types
class _TaskSearchDelegate extends SearchDelegate<Task?> {
  final WidgetRef ref;
  static const _taskTypes = ['daily', 'weekly', 'monthly', 'yearly', 'once'];
  static const _priorityColors = [Colors.blue, Colors.orange, Colors.red];
  static const _priorityLabels = ['Baja', 'Media', 'Alta'];

  _TaskSearchDelegate(this.ref)
      : super(
          searchFieldLabel: 'Buscar tareas...',
          textInputAction: TextInputAction.search,
        );

  /// Get all tasks from all task types
  List<Task> _getAllTasks() {
    final allTasks = <Task>[];
    for (final type in _taskTypes) {
      allTasks.addAll(ref.read(tasksProvider(type)));
    }
    return allTasks;
  }

  /// Filter tasks based on search query
  List<Task> _filterTasks(String query) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final allTasks = _getAllTasks();

    return allTasks.where((task) {
      // Search in title
      if (task.title.toLowerCase().contains(queryLower)) return true;
      // Search in category
      if (task.category.toLowerCase().contains(queryLower)) return true;
      // Search in motivation
      if (task.motivation?.toLowerCase().contains(queryLower) ?? false) {
        return true;
      }
      // Search in reward
      if (task.reward?.toLowerCase().contains(queryLower) ?? false) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Limpiar',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Volver',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = _filterTasks(query);
    final colorScheme = Theme.of(context).colorScheme;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar tareas',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca por titulo, categoria o motivacion',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron tareas para "$query"',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return _SearchResultTile(
          task: task,
          query: query,
          priorityColors: _priorityColors,
          priorityLabels: _priorityLabels,
          onTap: () {
            // Navigate to the task's type list
            ref.read(selectedTaskTypeProvider.notifier).state = task.type;
            ref.read(selectedRouteProvider.notifier).state = AppRoute.tasks;
            close(context, task);
          },
        );
      },
    );
  }
}

/// A tile showing a search result with highlighted matching text
class _SearchResultTile extends StatelessWidget {
  final Task task;
  final String query;
  final List<Color> priorityColors;
  final List<String> priorityLabels;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.task,
    required this.query,
    required this.priorityColors,
    required this.priorityLabels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColor = priorityColors[task.priority.clamp(0, 2)];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedText(
                      text: task.title,
                      query: query,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      highlightColor: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          task.typeIcon,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Completion status
              Icon(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isCompleted
                    ? Colors.green
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to highlight matching text in search results
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final startIndex = textLower.indexOf(queryLower);

    if (startIndex == -1) {
      return Text(text, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final endIndex = startIndex + query.length;
    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final afterMatch = text.substring(endIndex);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: style.copyWith(
              backgroundColor: highlightColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}
