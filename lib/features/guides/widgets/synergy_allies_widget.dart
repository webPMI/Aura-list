import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/services/guide_synergy_service.dart';

/// Widget que muestra los guías aliados recomendados del guía activo.
///
/// Diseño horizontal compacto con 2-3 avatares pequeños, nombres y nivel de afinidad.
/// Al hacer tap en un aliado, se puede ver más detalles o cambiar al guía.
class SynergyAlliesWidget extends ConsumerWidget {
  const SynergyAlliesWidget({
    super.key,
    this.onAllyTap,
    this.maxAllies = 3,
  });

  /// Callback cuando se hace tap en un aliado.
  /// Si es null, no hace nada.
  final void Function(Guide ally)? onAllyTap;

  /// Número máximo de aliados a mostrar.
  final int maxAllies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGuide = ref.watch(activeGuideProvider);

    if (activeGuide == null) {
      return const SizedBox.shrink();
    }

    final synergyService = GuideSynergyService.instance;
    final allies = synergyService.getRecommendedAllies(activeGuide.id);

    if (allies.isEmpty) {
      return const SizedBox.shrink();
    }

    // Limitar número de aliados mostrados
    final displayAllies = allies.take(maxAllies).toList();

    return _AlliesContent(
      activeGuide: activeGuide,
      allies: displayAllies,
      onAllyTap: onAllyTap,
    );
  }
}

class _AlliesContent extends StatelessWidget {
  const _AlliesContent({
    required this.activeGuide,
    required this.allies,
    required this.onAllyTap,
  });

  final Guide activeGuide;
  final List<Guide> allies;
  final void Function(Guide)? onAllyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final synergyService = GuideSynergyService.instance;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.group_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Aliados de ${activeGuide.name}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista horizontal de aliados
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allies.map((ally) {
                final affinity = synergyService.calculateAffinityLevel(
                  activeGuide.id,
                  ally.id,
                );
                return _AllyCard(
                  ally: ally,
                  affinity: affinity,
                  onTap: onAllyTap != null ? () => onAllyTap!(ally) : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllyCard extends StatelessWidget {
  const _AllyCard({
    required this.ally,
    required this.affinity,
    required this.onTap,
  });

  final Guide ally;
  final double affinity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allyColor = parseHexColor(ally.themeAccentHex ?? ally.themePrimaryHex) ??
        theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: allyColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: allyColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              GuideAvatar(
                guide: ally,
                size: 40,
                showBorder: true,
              ),
              const SizedBox(height: 6),
              // Nombre
              Text(
                ally.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: allyColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Indicador de afinidad
              _AffinityIndicator(
                affinity: affinity,
                color: allyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffinityIndicator extends StatelessWidget {
  const _AffinityIndicator({
    required this.affinity,
    required this.color,
  });

  final double affinity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Convertir afinidad a estrellas (0.0 = 0 estrellas, 1.0 = 3 estrellas)
    final stars = (affinity * 3).round().clamp(0, 3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < stars;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          size: 12,
          color: isFilled ? color : theme.colorScheme.outlineVariant,
        );
      }),
    );
  }
}

/// Variant compacto: solo muestra avatares sin tarjetas.
class SynergyAlliesAvatarRow extends ConsumerWidget {
  const SynergyAlliesAvatarRow({
    super.key,
    this.onAllyTap,
    this.maxAllies = 3,
    this.size = 32,
  });

  final void Function(Guide ally)? onAllyTap;
  final int maxAllies;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGuide = ref.watch(activeGuideProvider);

    if (activeGuide == null) {
      return const SizedBox.shrink();
    }

    final synergyService = GuideSynergyService.instance;
    final allies = synergyService.getRecommendedAllies(activeGuide.id);

    if (allies.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayAllies = allies.take(maxAllies).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayAllies.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
            child: GestureDetector(
              onTap: onAllyTap != null
                  ? () {
                      HapticFeedback.lightImpact();
                      onAllyTap!(displayAllies[i]);
                    }
                  : null,
              child: GuideAvatar(
                guide: displayAllies[i],
                size: size,
                showBorder: true,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dialog que muestra información detallada de la sinergia entre dos guías.
class SynergyInfoDialog extends StatelessWidget {
  const SynergyInfoDialog({
    super.key,
    required this.guide1,
    required this.guide2,
    this.onActivateGuide,
  });

  final Guide guide1;
  final Guide guide2;
  final void Function(Guide)? onActivateGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final synergyService = GuideSynergyService.instance;

    final description = synergyService.getSynergyDescription(guide1, guide2);
    final affinity = synergyService.calculateAffinityLevel(guide1.id, guide2.id);
    final bonus = synergyService.calculateSynergyBonus(guide1.id, guide2.id);

    final color1 = parseHexColor(guide1.themeAccentHex ?? guide1.themePrimaryHex) ??
        theme.colorScheme.primary;
    final color2 = parseHexColor(guide2.themeAccentHex ?? guide2.themePrimaryHex) ??
        theme.colorScheme.secondary;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatares de ambos guías
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    GuideAvatar(guide: guide1, size: 64, showBorder: true),
                    const SizedBox(height: 8),
                    Text(
                      guide1.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.link,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                Column(
                  children: [
                    GuideAvatar(guide: guide2, size: 64, showBorder: true),
                    const SizedBox(height: 8),
                    Text(
                      guide2.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nivel de afinidad
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final stars = (affinity * 3).round();
                final isFilled = index < stars;
                return Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFilled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                );
              }),
            ),
            const SizedBox(height: 16),
            // Descripción de sinergia
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (bonus > 1.0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bonus de sinergia: ${((bonus - 1) * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
                if (onActivateGuide != null) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      onActivateGuide!(guide2);
                      Navigator.of(context).pop();
                    },
                    child: Text('Activar ${guide2.name}'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Método helper para mostrar el dialog.
  static void show(
    BuildContext context, {
    required Guide guide1,
    required Guide guide2,
    void Function(Guide)? onActivateGuide,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => SynergyInfoDialog(
        guide1: guide1,
        guide2: guide2,
        onActivateGuide: onActivateGuide,
      ),
    );
  }
}
