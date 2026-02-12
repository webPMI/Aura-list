import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/features/guides/widgets/guide_intro_modal.dart';
import 'package:checklist_app/features/guides/widgets/affinity_level_indicator.dart';
import 'package:checklist_app/features/guides/widgets/synergy_allies_widget.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/services/guide_synergy_service.dart';

/// Orden de las familias para mostrar en el selector.
const _familyOrder = [
  'Cónclave del Ímpetu',
  'Arquitectos del Ciclo',
  'Oráculos del Reposo',
  'Oráculos del Cambio',
  'Oráculos del Umbral',
];

/// Muestra un bottom sheet para elegir el guía activo.
/// Reutilizable desde drawer, configuración o cualquier pantalla.
void showGuideSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _GuideSelectorSheet(),
  );
}

class _GuideSelectorSheet extends ConsumerStatefulWidget {
  const _GuideSelectorSheet();

  @override
  ConsumerState<_GuideSelectorSheet> createState() => _GuideSelectorSheetState();
}

class _GuideSelectorSheetState extends ConsumerState<_GuideSelectorSheet> {
  /// Familias expandidas. Por defecto, todas expandidas.
  final Set<String> _expandedFamilies = {..._familyOrder};

  @override
  Widget build(BuildContext context) {
    final guides = ref.watch(availableGuidesProvider);
    final activeId = ref.watch(activeGuideIdProvider);
    final activeGuide = ref.watch(activeGuideProvider);

    // Agrupar guías por classFamily
    final groupedGuides = <String, List<Guide>>{};
    for (final guide in guides) {
      final family = guide.classFamily.isNotEmpty ? guide.classFamily : 'Otros';
      groupedGuides.putIfAbsent(family, () => []).add(guide);
    }

    // Ordenar familias según _familyOrder, poniendo las desconocidas al final
    final sortedFamilies = groupedGuides.keys.toList()
      ..sort((a, b) {
        final indexA = _familyOrder.indexOf(a);
        final indexB = _familyOrder.indexOf(b);
        // Si no está en la lista, va al final
        final effectiveA = indexA == -1 ? 999 : indexA;
        final effectiveB = indexB == -1 ? 999 : indexB;
        return effectiveA.compareTo(effectiveB);
      });

    // Obtener aliados con sinergia si hay guía activo
    final synergyAllies = activeGuide != null
        ? GuideSynergyService.instance.getRecommendedAllies(activeGuide.id)
        : <Guide>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle visual
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Elige tu guía celestial',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: '¿Qué es un Guía Celestial?',
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Reabrir el intro modal
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          showGuideIntroModal(context, ref);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sortedFamilies.length + (synergyAllies.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // Si hay aliados con sinergia, mostrar sección arriba
                  if (synergyAllies.isNotEmpty && index == 0) {
                    return _SynergyAlliesSection(
                      activeGuide: activeGuide!,
                      allies: synergyAllies,
                      onAllySelected: (guide) {
                        HapticFeedback.mediumImpact();
                        // Mostrar dialog de sinergia
                        SynergyInfoDialog.show(
                          context,
                          guide1: activeGuide,
                          guide2: guide,
                          onActivateGuide: (selectedGuide) {
                            HapticFeedback.mediumImpact();
                            ref.read(activeGuideIdProvider.notifier)
                                .setActiveGuide(selectedGuide.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  }

                  // Ajustar índice si hay sección de aliados
                  final familyIndex = synergyAllies.isNotEmpty ? index - 1 : index;
                  final family = sortedFamilies[familyIndex];
                  final familyGuides = groupedGuides[family]!;
                  final isExpanded = _expandedFamilies.contains(family);

                  return _FamilySection(
                    familyName: family,
                    guides: familyGuides,
                    isExpanded: isExpanded,
                    activeGuideId: activeId,
                    onToggle: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isExpanded) {
                          _expandedFamilies.remove(family);
                        } else {
                          _expandedFamilies.add(family);
                        }
                      });
                    },
                    onGuideSelected: (guide) {
                      HapticFeedback.mediumImpact();
                      ref.read(activeGuideIdProvider.notifier).setActiveGuide(guide.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sección colapsable para una familia de guías.
class _FamilySection extends StatelessWidget {
  const _FamilySection({
    required this.familyName,
    required this.guides,
    required this.isExpanded,
    required this.activeGuideId,
    required this.onToggle,
    required this.onGuideSelected,
  });

  final String familyName;
  final List<Guide> guides;
  final bool isExpanded;
  final String? activeGuideId;
  final VoidCallback onToggle;
  final void Function(Guide) onGuideSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveGuide = guides.any((g) => g.id == activeGuideId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sección (colapsable)
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    familyName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasActiveGuide
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Indicador de cantidad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${guides.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Lista de guías (animada)
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: guides.map((guide) {
              final isSelected = activeGuideId == guide.id;
              return _GuideTile(
                guide: guide,
                isSelected: isSelected,
                onTap: () => onGuideSelected(guide),
              );
            }).toList(),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (isExpanded) const Divider(height: 1),
      ],
    );
  }
}

/// Sección que muestra los aliados con sinergia del guía activo.
class _SynergyAlliesSection extends ConsumerWidget {
  const _SynergyAlliesSection({
    required this.activeGuide,
    required this.allies,
    required this.onAllySelected,
  });

  final Guide activeGuide;
  final List<Guide> allies;
  final void Function(Guide) onAllySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeColor =
        parseHexColor(activeGuide.themeAccentHex ?? activeGuide.themePrimaryHex) ??
            theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: activeColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aliados de ${activeGuide.name}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estos guías comparten sinergia con tu elección actual',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allies.map((ally) {
                return _SynergyAllyCard(
                  ally: ally,
                  activeGuide: activeGuide,
                  onTap: () => onAllySelected(ally),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta compacta de un aliado con sinergia.
class _SynergyAllyCard extends StatelessWidget {
  const _SynergyAllyCard({
    required this.ally,
    required this.activeGuide,
    required this.onTap,
  });

  final Guide ally;
  final Guide activeGuide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allyColor =
        parseHexColor(ally.themeAccentHex ?? ally.themePrimaryHex) ??
            theme.colorScheme.primary;

    final synergyService = GuideSynergyService.instance;
    final affinity = synergyService.calculateAffinityLevel(
      activeGuide.id,
      ally.id,
    );
    final stars = (affinity * 3).round().clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: allyColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: allyColor.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GuideAvatar(guide: ally, size: 44, showBorder: true),
              const SizedBox(height: 6),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 10,
                    color: i < stars
                        ? allyColor
                        : theme.colorScheme.outlineVariant,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideTile extends ConsumerWidget {
  const _GuideTile({
    required this.guide,
    required this.isSelected,
    required this.onTap,
  });

  final Guide guide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guideColor =
        parseHexColor(guide.themeAccentHex ?? guide.themePrimaryHex) ??
            theme.colorScheme.primary;

    final activeGuide = ref.watch(activeGuideProvider);
    final synergyService = GuideSynergyService.instance;

    // Verificar si hay sinergia con el guía activo
    final hasSynergyWithActive = activeGuide != null &&
        activeGuide.id != guide.id &&
        synergyService.hasSynergy(activeGuide.id, guide.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          GuideAvatar(guide: guide, size: 48, showBorder: isSelected),
          if (hasSynergyWithActive)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        guide.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${guide.title} • ${guide.affinity}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: guideColor,
            ),
          ),
          // Mostrar indicador de afinidad
          const SizedBox(height: 4),
          AffinityLevelIndicator(
            guide: guide,
            size: AffinityIndicatorSize.small,
            showLabel: false,
            showProgress: false,
          ),
          if (guide.descriptionShort != null &&
              guide.descriptionShort!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                guide.descriptionShort!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: guideColor)
          : Icon(
              Icons.circle_outlined,
              color: theme.colorScheme.outlineVariant,
            ),
      selected: isSelected,
      selectedTileColor: guideColor.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}
