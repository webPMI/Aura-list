import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/models/guide_achievement_model.dart';
import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/features/guides/providers/guide_theme_provider.dart';

/// Muestra un modal celebrando un logro recién obtenido.
///
/// Filosofía: Celebración sin presión. El mensaje del guía es personal
/// y reconoce el logro sin compararlo con objetivos futuros.
class AchievementEarnedWidget extends ConsumerWidget {
  final GuideAchievement achievement;
  final VoidCallback? onDismiss;

  const AchievementEarnedWidget({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  /// Muestra el modal de logro obtenido
  static void show(
    BuildContext context,
    GuideAchievement achievement, {
    VoidCallback? onDismiss,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AchievementEarnedWidget(
        achievement: achievement,
        onDismiss: onDismiss,
      ),
    );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final guide = getGuideById(achievement.guideId);
    final guideColor = ref.watch(guideAccentColorProvider) ?? colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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

          // Título "Logro Obtenido"
          Text(
            'Logro Obtenido',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Ícono central con animación
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        guideColor.withValues(alpha: 0.2),
                        guideColor.withValues(alpha: 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: guideColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(achievement.category),
                    size: 48,
                    color: guideColor,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Título del logro
          Text(
            achievement.titleEs,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: guideColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Nombre del guía
          if (guide != null)
            Text(
              'Otorgado por ${guide.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 20),

          // Descripción del logro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              achievement.description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Mensaje del guía
          if (achievement.guideMessage != null &&
              achievement.guideMessage!.isNotEmpty)
            Container(
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
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 20,
                    color: guideColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      achievement.guideMessage!,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Categoría badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getCategoryColor(achievement.category)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _getCategoryColor(achievement.category).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(achievement.category),
                  size: 16,
                  color: _getCategoryColor(achievement.category),
                ),
                const SizedBox(width: 6),
                Text(
                  achievement.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(achievement.category),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón de cerrar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: guideColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
