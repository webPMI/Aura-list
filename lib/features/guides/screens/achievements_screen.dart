import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/models/guide_achievement_model.dart';
import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/features/guides/providers/guide_achievements_provider.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/providers/guide_theme_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';

/// Pantalla completa de galería de logros.
///
/// Accesible desde Settings y Perfil. Muestra tres tabs:
/// "Obtenidos", "Por Obtener" y "Todos", con un grid de logros
/// y un modal de detalle al tocar cada uno.
///
/// Filosofía del Guardián:
/// - Celebrar lo obtenido sin presionar por lo pendiente
/// - NUNCA mostrar "te falta X para conseguir Y"
/// - Los pendientes son descubribles, no objetivos
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'constancia':
        return Colors.blue;
      case 'accion':
        return Colors.orange;
      case 'equilibrio':
        return Colors.green;
      case 'progreso':
        return Colors.purple;
      case 'descubrimiento':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'constancia':
        return Icons.repeat;
      case 'accion':
        return Icons.flash_on;
      case 'equilibrio':
        return Icons.balance;
      case 'progreso':
        return Icons.trending_up;
      case 'descubrimiento':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }

  void _showAchievementDetail(
    BuildContext context,
    GuideAchievement achievement,
    Color guideColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final guide = getGuideById(achievement.guideId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icono principal con animacion
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: achievement.isEarned
                              ? [
                                  guideColor.withValues(alpha: 0.25),
                                  guideColor.withValues(alpha: 0.10),
                                ]
                              : [
                                  Colors.grey.withValues(alpha: 0.2),
                                  Colors.grey.withValues(alpha: 0.1),
                                ],
                        ),
                        boxShadow: achievement.isEarned
                            ? [
                                BoxShadow(
                                  color: guideColor.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _getCategoryIcon(achievement.category),
                        size: 40,
                        color: achievement.isEarned ? guideColor : Colors.grey,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Titulo del logro
              Text(
                achievement.titleEs,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: achievement.isEarned
                      ? guideColor
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Nombre del guia
              if (guide != null)
                Text(
                  achievement.isEarned
                      ? 'Otorgado por ${guide.name}'
                      : 'Logro de ${guide.name}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 6),

              // Badge de categoria
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(achievement.category)
                      .withValues(alpha: achievement.isEarned ? 0.15 : 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCategoryColor(achievement.category)
                        .withValues(alpha: achievement.isEarned ? 0.35 : 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(achievement.category),
                      size: 13,
                      color: achievement.isEarned
                          ? _getCategoryColor(achievement.category)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      achievement.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: achievement.isEarned
                            ? _getCategoryColor(achievement.category)
                            : Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Descripcion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Mensaje del guia (solo si esta obtenido)
              if (achievement.isEarned &&
                  achievement.guideMessage != null &&
                  achievement.guideMessage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        guideColor.withValues(alpha: 0.15),
                        guideColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: guideColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 18,
                        color: guideColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          achievement.guideMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Fecha de obtencion
              if (achievement.isEarned && achievement.earnedAt != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Obtenido el ${achievement.earnedAt!.day}/${achievement.earnedAt!.month}/${achievement.earnedAt!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Boton cerrar
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: achievement.isEarned ? guideColor : colorScheme.surfaceContainerHighest,
                    foregroundColor: achievement.isEarned
                        ? Colors.white
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeGuide = ref.watch(activeGuideProvider);
    final guideColor = ref.watch(guideAccentColorProvider) ?? colorScheme.primary;
    final allAchievements = ref.watch(guideAchievementsProvider);
    final earnedAchievements = ref.watch(earnedAchievementsProvider);
    final pendingAchievements = ref.watch(pendingAchievementsProvider);

    final earnedCount = earnedAchievements.length;
    final totalCount = allAchievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        centerTitle: true,
        actions: [
          if (activeGuide != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GuideAvatar(size: 36, showBorder: true),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: guideColor,
          labelColor: guideColor,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 16),
                  const SizedBox(width: 6),
                  Text('Obtenidos ($earnedCount)'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Por obtener (${totalCount - earnedCount})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grid_view, size: 16),
                  const SizedBox(width: 6),
                  const Text('Todos'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tarjeta de estadisticas
          _StatsCard(
            earnedCount: earnedCount,
            totalCount: totalCount,
            guideColor: guideColor,
            colorScheme: colorScheme,
          ),

          // Grid por tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Obtenidos
                _AchievementsGrid(
                  achievements: earnedAchievements,
                  guideColor: guideColor,
                  emptyMessage: 'Aun no has obtenido logros',
                  emptySubMessage: 'Completa tareas para desbloquearlos',
                  onTap: (achievement) =>
                      _showAchievementDetail(context, achievement, guideColor),
                  getCategoryColor: _getCategoryColor,
                  getCategoryIcon: _getCategoryIcon,
                ),

                // Tab 2: Por obtener
                _AchievementsGrid(
                  achievements: pendingAchievements,
                  guideColor: guideColor,
                  emptyMessage: 'Has obtenido todos los logros',
                  emptySubMessage: 'Increible! Eres un maestro',
                  onTap: (achievement) =>
                      _showAchievementDetail(context, achievement, guideColor),
                  getCategoryColor: _getCategoryColor,
                  getCategoryIcon: _getCategoryIcon,
                ),

                // Tab 3: Todos
                _AchievementsGrid(
                  achievements: allAchievements,
                  guideColor: guideColor,
                  emptyMessage: 'No hay logros disponibles',
                  emptySubMessage: 'Selecciona un guia celestial primero',
                  onTap: (achievement) =>
                      _showAchievementDetail(context, achievement, guideColor),
                  getCategoryColor: _getCategoryColor,
                  getCategoryIcon: _getCategoryIcon,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de estadisticas en la parte superior
class _StatsCard extends StatelessWidget {
  final int earnedCount;
  final int totalCount;
  final Color guideColor;
  final ColorScheme colorScheme;

  const _StatsCard({
    required this.earnedCount,
    required this.totalCount,
    required this.guideColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = totalCount > 0 ? earnedCount / totalCount : 0.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - animValue)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              guideColor.withValues(alpha: 0.15),
              guideColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: guideColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Contador principal
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$earnedCount',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: guideColor,
                        ),
                      ),
                      TextSpan(
                        text: ' / $totalCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Logros desbloqueados',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // Barra de progreso circular
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: guideColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      tween: Tween(begin: 0.0, end: progressValue),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                          color: guideColor,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid de logros con animacion escalonada
class _AchievementsGrid extends StatelessWidget {
  final List<GuideAchievement> achievements;
  final Color guideColor;
  final String emptyMessage;
  final String emptySubMessage;
  final void Function(GuideAchievement) onTap;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;

  const _AchievementsGrid({
    required this.achievements,
    required this.guideColor,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.onTap,
    required this.getCategoryColor,
    required this.getCategoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _AchievementCard(
          achievement: achievement,
          index: index,
          getCategoryColor: getCategoryColor,
          getCategoryIcon: getCategoryIcon,
          onTap: () => onTap(achievement),
        );
      },
    );
  }
}

/// Tarjeta individual de logro con animacion de entrada
class _AchievementCard extends StatelessWidget {
  final GuideAchievement achievement;
  final int index;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.achievement,
    required this.index,
    required this.getCategoryColor,
    required this.getCategoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getCategoryColor(achievement.category);
    final categoryIcon = getCategoryIcon(achievement.category);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: achievement.isEarned
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withValues(alpha: 0.15),
                      categoryColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: achievement.isEarned
                ? null
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: achievement.isEarned
                  ? categoryColor.withValues(alpha: 0.35)
                  : colorScheme.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con circulo de fondo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: achievement.isEarned
                      ? categoryColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.08),
                  boxShadow: achievement.isEarned
                      ? [
                          BoxShadow(
                            color: categoryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  categoryIcon,
                  size: 30,
                  color: achievement.isEarned
                      ? categoryColor
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              ),

              const SizedBox(height: 12),

              // Titulo
              Text(
                achievement.titleEs,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: achievement.isEarned
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.35),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Badge de categoria
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: achievement.isEarned
                      ? categoryColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  achievement.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: achievement.isEarned ? categoryColor : Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Indicador de estado
              if (achievement.isEarned) ...[
                const SizedBox(height: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: categoryColor.withValues(alpha: 0.8),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Colors.grey.withValues(alpha: 0.35),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
