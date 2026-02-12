import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/models/guide_model.dart';

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
              child: Text(
                'Elige tu guía celestial',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sortedFamilies.length,
                itemBuilder: (context, index) {
                  final family = sortedFamilies[index];
                  final familyGuides = groupedGuides[family]!;
                  final isExpanded = _expandedFamilies.contains(family);

                  return _FamilySection(
                    familyName: family,
                    guides: familyGuides,
                    isExpanded: isExpanded,
                    activeGuideId: activeId,
                    onToggle: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedFamilies.remove(family);
                        } else {
                          _expandedFamilies.add(family);
                        }
                      });
                    },
                    onGuideSelected: (guide) {
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

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.guide,
    required this.isSelected,
    required this.onTap,
  });

  final Guide guide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guideColor =
        parseHexColor(guide.themeAccentHex ?? guide.themePrimaryHex) ??
            theme.colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: GuideAvatar(guide: guide, size: 48, showBorder: isSelected),
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
          if (guide.descriptionShort != null &&
              guide.descriptionShort!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
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
      isThreeLine: guide.descriptionShort != null &&
          guide.descriptionShort!.isNotEmpty,
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
