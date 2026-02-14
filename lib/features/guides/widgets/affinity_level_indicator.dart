import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/guide_affinity_provider.dart';
import 'package:checklist_app/models/guide_affinity_model.dart';
import 'package:checklist_app/models/guide_model.dart';

/// Widget que muestra el nivel de afinidad con un guía.
/// Incluye indicador visual, progreso y animaciones.
class AffinityLevelIndicator extends ConsumerStatefulWidget {
  const AffinityLevelIndicator({
    super.key,
    required this.guide,
    this.size = AffinityIndicatorSize.medium,
    this.showLabel = true,
    this.showProgress = true,
    this.onTap,
  });

  final Guide guide;
  final AffinityIndicatorSize size;
  final bool showLabel;
  final bool showProgress;

  /// Callback opcional al tocar el indicador (ej. para abrir detalles).
  /// Cuando se proporciona, dispara HapticFeedback.lightImpact().
  final VoidCallback? onTap;

  @override
  ConsumerState<AffinityLevelIndicator> createState() =>
      _AffinityLevelIndicatorState();
}

class _AffinityLevelIndicatorState
    extends ConsumerState<AffinityLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _previousLevel;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkForLevelUp(GuideAffinity? affinity) {
    if (affinity == null) return;

    if (_previousLevel != null && affinity.connectionLevel > _previousLevel!) {
      // Subió de nivel - animar y feedback háptico
      HapticFeedback.heavyImpact();
      _animationController.forward(from: 0.0);
    }

    _previousLevel = affinity.connectionLevel;
  }

  @override
  Widget build(BuildContext context) {
    final affinityAsync = ref.watch(guideAffinityProvider(widget.guide.id));

    return affinityAsync.when(
      data: (affinity) {
        _checkForLevelUp(affinity);

        final level = affinity?.connectionLevel ?? 0;
        final progress = affinity?.progressToNextLevel ?? 0.0;
        final levelName = affinity?.levelName ?? 'Extraño';
        final isMaxLevel = affinity?.isMaxLevel ?? false;

        final guideColor =
            parseHexColor(widget.guide.themeAccentHex ?? widget.guide.themePrimaryHex) ??
                Theme.of(context).colorScheme.primary;

        final indicator = AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _buildIndicator(
            context,
            level: level,
            progress: progress,
            levelName: levelName,
            isMaxLevel: isMaxLevel,
            guideColor: guideColor,
            affinity: affinity,
          ),
        );

        if (widget.onTap != null) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
            child: indicator,
          );
        }

        return indicator;
      },
      loading: () => _buildIndicator(
        context,
        level: 0,
        progress: 0.0,
        levelName: 'Cargando...',
        isMaxLevel: false,
        guideColor: Theme.of(context).colorScheme.primary,
      ),
      error: (_, __) => _buildIndicator(
        context,
        level: 0,
        progress: 0.0,
        levelName: 'Error',
        isMaxLevel: false,
        guideColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context, {
    required int level,
    required double progress,
    required String levelName,
    required bool isMaxLevel,
    required Color guideColor,
    GuideAffinity? affinity,
  }) {
    final theme = Theme.of(context);
    final sizeConfig = widget.size.config;

    switch (widget.size) {
      case AffinityIndicatorSize.small:
        return _buildCompactIndicator(
          theme,
          level: level,
          guideColor: guideColor,
          sizeConfig: sizeConfig,
        );
      case AffinityIndicatorSize.medium:
        return _buildMediumIndicator(
          theme,
          level: level,
          progress: progress,
          levelName: levelName,
          isMaxLevel: isMaxLevel,
          guideColor: guideColor,
          sizeConfig: sizeConfig,
        );
      case AffinityIndicatorSize.large:
        return _buildLargeIndicator(
          theme,
          level: level,
          progress: progress,
          levelName: levelName,
          isMaxLevel: isMaxLevel,
          guideColor: guideColor,
          sizeConfig: sizeConfig,
          affinity: affinity,
        );
    }
  }

  /// Indicador compacto - solo muestra el nivel con estrellas.
  Widget _buildCompactIndicator(
    ThemeData theme, {
    required int level,
    required Color guideColor,
    required SizeConfig sizeConfig,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              index < level ? Icons.star : Icons.star_border,
              size: sizeConfig.iconSize,
              color: index < level ? guideColor : theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  /// Indicador mediano - nivel + etiqueta + barra de progreso opcional.
  Widget _buildMediumIndicator(
    ThemeData theme, {
    required int level,
    required double progress,
    required String levelName,
    required bool isMaxLevel,
    required Color guideColor,
    required SizeConfig sizeConfig,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  index < level ? Icons.star : Icons.star_border,
                  size: sizeConfig.iconSize,
                  color: index < level ? guideColor : theme.colorScheme.outline,
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 8),
              Text(
                levelName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: guideColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (widget.showProgress && !isMaxLevel) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: sizeConfig.progressBarWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(guideColor),
                minHeight: sizeConfig.progressBarHeight,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Indicador grande - información completa con estadísticas.
  Widget _buildLargeIndicator(
    ThemeData theme, {
    required int level,
    required double progress,
    required String levelName,
    required bool isMaxLevel,
    required Color guideColor,
    required SizeConfig sizeConfig,
    GuideAffinity? affinity,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: guideColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: guideColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    index < level ? Icons.star : Icons.star_border,
                    size: sizeConfig.iconSize,
                    color: index < level ? guideColor : theme.colorScheme.outline,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                levelName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: guideColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (affinity != null) ...[
            const SizedBox(height: 8),
            Text(
              affinity.levelDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              theme,
              icon: Icons.task_alt,
              label: 'Tareas completadas',
              value: '${affinity.tasksCompletedWithGuide}',
              guideColor: guideColor,
            ),
            const SizedBox(height: 6),
            _buildStatRow(
              theme,
              icon: Icons.calendar_today,
              label: 'Días juntos',
              value: '${affinity.daysWithGuide}',
              guideColor: guideColor,
            ),
            if (!isMaxLevel) ...[
              const SizedBox(height: 12),
              _buildSeparateProgressBars(theme, affinity: affinity, guideColor: guideColor),
            ],
            if (isMaxLevel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: guideColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nivel máximo alcanzado',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: guideColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Muestra dos barras de progreso independientes: una para tareas y otra para días.
  /// Cada barra indica cuánto falta en lugar de totales acumulados.
  Widget _buildSeparateProgressBars(
    ThemeData theme, {
    required GuideAffinity affinity,
    required Color guideColor,
  }) {
    final tasksRequired = affinity.tasksRequiredForNextLevel;
    final daysRequired = affinity.daysRequiredForNextLevel;
    final tasksDone = affinity.tasksCompletedWithGuide;
    final daysDone = affinity.daysWithGuide;

    final taskProgress = tasksRequired > 0
        ? (tasksDone / tasksRequired).clamp(0.0, 1.0)
        : 1.0;
    final dayProgress = daysRequired > 0
        ? (daysDone / daysRequired).clamp(0.0, 1.0)
        : 1.0;

    final tasksCompleted = tasksDone >= tasksRequired;
    final daysCompleted = daysDone >= daysRequired;

    final tasksRemaining = (tasksRequired - tasksDone).clamp(0, tasksRequired);
    final daysRemaining = (daysRequired - daysDone).clamp(0, daysRequired);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso al siguiente nivel',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Barra de tareas
        _buildProgressBar(
          theme,
          icon: tasksCompleted ? Icons.check_circle : Icons.task_alt,
          label: tasksCompleted
              ? 'Tareas completadas'
              : '$tasksRemaining tarea${tasksRemaining == 1 ? '' : 's'} más',
          progress: taskProgress,
          current: tasksDone,
          required: tasksRequired,
          guideColor: guideColor,
          isDone: tasksCompleted,
        ),
        const SizedBox(height: 8),
        // Barra de días
        _buildProgressBar(
          theme,
          icon: daysCompleted ? Icons.check_circle : Icons.calendar_today,
          label: daysCompleted
              ? 'Días alcanzados'
              : '$daysRemaining día${daysRemaining == 1 ? '' : 's'} más',
          progress: dayProgress,
          current: daysDone,
          required: daysRequired,
          guideColor: guideColor,
          isDone: daysCompleted,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required double progress,
    required int current,
    required int required,
    required Color guideColor,
    required bool isDone,
  }) {
    final barColor = isDone ? guideColor : guideColor.withValues(alpha: 0.8);
    final textColor = isDone
        ? guideColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: barColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: textColor),
              ),
            ),
            Text(
              '$current/$required',
              style: theme.textTheme.labelSmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color guideColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: guideColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: guideColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Tamaños predefinidos para el indicador de afinidad.
enum AffinityIndicatorSize {
  small,
  medium,
  large;

  SizeConfig get config {
    switch (this) {
      case AffinityIndicatorSize.small:
        return const SizeConfig(
          iconSize: 14,
          progressBarHeight: 3,
          progressBarWidth: 60,
        );
      case AffinityIndicatorSize.medium:
        return const SizeConfig(
          iconSize: 18,
          progressBarHeight: 4,
          progressBarWidth: 100,
        );
      case AffinityIndicatorSize.large:
        return const SizeConfig(
          iconSize: 24,
          progressBarHeight: 6,
          progressBarWidth: 200,
        );
    }
  }
}

/// Configuración de tamaños para el indicador.
class SizeConfig {
  const SizeConfig({
    required this.iconSize,
    required this.progressBarHeight,
    required this.progressBarWidth,
  });

  final double iconSize;
  final double progressBarHeight;
  final double progressBarWidth;
}

/// Mostrar un diálogo con información detallada de afinidad.
void showAffinityDetailsDialog(
  BuildContext context,
  Guide guide,
  GuideAffinity? affinity,
) {
  showDialog(
    context: context,
    builder: (context) => _AffinityDetailsDialog(
      guide: guide,
      affinity: affinity,
    ),
  );
}

class _AffinityDetailsDialog extends StatelessWidget {
  const _AffinityDetailsDialog({
    required this.guide,
    required this.affinity,
  });

  final Guide guide;
  final GuideAffinity? affinity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideColor = parseHexColor(guide.themeAccentHex ?? guide.themePrimaryHex) ??
        theme.colorScheme.primary;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.stars, color: guideColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Afinidad con ${guide.name}'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AffinityLevelIndicator(
              guide: guide,
              size: AffinityIndicatorSize.large,
              showLabel: true,
              showProgress: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Sistema de Desbloqueos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildUnlockItem(
              theme,
              level: 1,
              title: 'Avatar Coloreado',
              description: 'El avatar del guía se muestra a color',
              isUnlocked: (affinity?.connectionLevel ?? 0) >= 1,
              guideColor: guideColor,
            ),
            _buildUnlockItem(
              theme,
              level: 2,
              title: 'Sentencia de Poder',
              description: 'La frase icónica del guía aparece en el dashboard',
              isUnlocked: (affinity?.connectionLevel ?? 0) >= 2,
              guideColor: guideColor,
            ),
            _buildUnlockItem(
              theme,
              level: 3,
              title: 'Diálogos Especiales',
              description: 'Mensajes exclusivos y personalizados',
              isUnlocked: (affinity?.connectionLevel ?? 0) >= 3,
              guideColor: guideColor,
            ),
            _buildUnlockItem(
              theme,
              level: 4,
              title: 'Bendiciones Mejoradas',
              description: 'Mayor frecuencia de activación de bendiciones',
              isUnlocked: (affinity?.connectionLevel ?? 0) >= 4,
              guideColor: guideColor,
            ),
            _buildUnlockItem(
              theme,
              level: 5,
              title: 'Ritual de Sincronización',
              description: 'Ritual diario especial con el guía',
              isUnlocked: (affinity?.connectionLevel ?? 0) >= 5,
              guideColor: guideColor,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildUnlockItem(
    ThemeData theme, {
    required int level,
    required String title,
    required String description,
    required bool isUnlocked,
    required Color guideColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            size: 20,
            color: isUnlocked ? guideColor : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? guideColor
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(Nivel $level)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
