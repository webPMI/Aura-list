import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/models/guide_model.dart';

/// Widget para destacar un guía en onboarding o pantallas de bienvenida.
/// Muestra el avatar grande, nombre, título, sentencia de poder y botón de acción.
class FeaturedGuideCard extends StatelessWidget {
  const FeaturedGuideCard({
    super.key,
    required this.guide,
    this.onSelect,
    this.showSelectButton = true,
  });

  final Guide guide;
  final VoidCallback? onSelect;
  final bool showSelectButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideColor = parseHexColor(guide.themeAccentHex ?? guide.themePrimaryHex) ??
        theme.colorScheme.primary;
    final primaryColor = parseHexColor(guide.themePrimaryHex) ?? guideColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.1),
            guideColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: guideColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar grande con efecto de brillo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: GuideAvatar(
              guide: guide,
              size: 120,
              showBorder: true,
            ),
          ),
          const SizedBox(height: 24),

          // Nombre del guía
          Text(
            guide.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: guideColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Título del guía
          Text(
            guide.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Afinidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: guideColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: guideColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: guideColor,
                ),
                const SizedBox(width: 8),
                Text(
                  guide.affinity,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: guideColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sentencia de poder (limitada a 3 líneas)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              guide.powerSentence,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Botón de selección
          if (showSelectButton && onSelect != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onSelect!();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Elegir este guía'),
              style: FilledButton.styleFrom(
                backgroundColor: guideColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
