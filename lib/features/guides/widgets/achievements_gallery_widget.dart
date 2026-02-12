import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/models/guide_achievement_model.dart';
import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/features/guides/constants/guide_colors.dart';
import 'package:checklist_app/features/guides/providers/guide_achievements_provider.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/providers/guide_theme_provider.dart';

// ---------------------------------------------------------------------------
// Constantes de cadenas de texto
// ---------------------------------------------------------------------------
const _labelObtenidos = 'Obtenidos';
const _labelDelGuia = 'Del guía';
const _labelTotales = 'Totales';
const _labelTodos = 'Todos';
const _labelNoLogros = 'No hay logros disponibles';
const _labelOtorgadoPor = 'Otorgado por ';
const _labelLogroDe = 'Logro de ';
const _labelObtenidoEl = 'Obtenido el ';
const _labelLogros = 'Logros';

/// Galería de logros del usuario.
///
/// Muestra logros obtenidos (brillantes) y pendientes (en gris) del guía activo.
/// Al tocar un logro, muestra detalles y mensaje del guía.
///
/// Filosofía del Guardián:
/// - Los pendientes son descubribles pero NO presionan
/// - NUNCA mostrar "te falta X para conseguir Y"
/// - Celebrar lo obtenido sin comparar con lo que falta
class AchievementsGalleryWidget extends ConsumerStatefulWidget {
  const AchievementsGalleryWidget({super.key});

  @override
  ConsumerState<AchievementsGalleryWidget> createState() =>
      _AchievementsGalleryWidgetState();
}

class _AchievementsGalleryWidgetState
    extends ConsumerState<AchievementsGalleryWidget> {
  String _selectedFilter = 'active'; // 'active', 'all', 'category'
  String? _selectedCategory;

  void _showAchievementDetail(GuideAchievement achievement) {
    final guide = getGuideById(achievement.guideId);
    final colorScheme = Theme.of(context).colorScheme;
    final guideColor = ref.read(guideAccentColorProvider) ?? colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Ícono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: achievement.isEarned
                      ? [
                          guideColor.withValues(alpha: 0.2),
                          guideColor.withValues(alpha: 0.1),
                        ]
                      : [
                          Colors.grey.withValues(alpha: 0.2),
                          Colors.grey.withValues(alpha: 0.1),
                        ],
                ),
              ),
              child: Icon(
                GuideColors.iconForCategory(achievement.category),
                size: 40,
                color: achievement.isEarned ? guideColor : Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // Título
            Text(
              achievement.titleEs,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: achievement.isEarned
                    ? guideColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Guía
            if (guide != null)
              Text(
                achievement.isEarned
                    ? '$_labelOtorgadoPor${guide.name}'
                    : '$_labelLogroDe${guide.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 20),

            // Descripción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Mensaje del guía (solo si está obtenido)
            if (achievement.isEarned &&
                achievement.guideMessage != null &&
                achievement.guideMessage!.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Fecha de obtención
            if (achievement.isEarned && achievement.earnedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                '$_labelObtenidoEl${achievement.earnedAt!.day}/${achievement.earnedAt!.month}/${achievement.earnedAt!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeGuide = ref.watch(activeGuideProvider);
    final guideColor = ref.watch(guideAccentColorProvider) ?? colorScheme.primary;

    List<GuideAchievement> achievements;
    if (_selectedFilter == 'active' && activeGuide != null) {
      achievements = ref.watch(activeGuideAchievementsProvider);
    } else {
      achievements = ref.watch(guideAchievementsProvider);
    }

    if (_selectedCategory != null) {
      achievements = achievements
          .where((a) => a.category == _selectedCategory)
          .toList();
    }

    final earnedCount = achievements.where((a) => a.isEarned).length;
    final totalCount = achievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(_labelLogros),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Estadísticas
          Semantics(
            label: '$earnedCount $_labelObtenidos de $totalCount ${activeGuide != null ? _labelDelGuia : _labelTotales}',
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
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
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$earnedCount',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: guideColor,
                          ),
                        ),
                        const Text(
                          _labelObtenidos,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    Column(
                      children: [
                        Text(
                          '$totalCount',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          activeGuide != null ? _labelDelGuia : _labelTotales,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(activeGuide?.name ?? 'Guía activo'),
                    selected: _selectedFilter == 'active',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'active';
                        _selectedCategory = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text(_labelTodos),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = 'all';
                        _selectedCategory = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._buildCategoryFilters(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grid de logros
          Expanded(
            child: achievements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _labelNoLogros,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      final categoryColor =
                          GuideColors.forCategory(achievement.category);
                      final categoryLabel =
                          GuideColors.labelForCategory(achievement.category);

                      return Semantics(
                        button: true,
                        label: achievement.isEarned
                            ? 'Logro obtenido: ${achievement.titleEs}, categoría $categoryLabel'
                            : 'Logro pendiente: ${achievement.titleEs}, categoría $categoryLabel',
                        onTap: () => _showAchievementDetail(achievement),
                        child: InkWell(
                          onTap: () => _showAchievementDetail(achievement),
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
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: achievement.isEarned
                                    ? categoryColor.withValues(alpha: 0.3)
                                    : colorScheme.onSurface.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Ícono
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: achievement.isEarned
                                          ? categoryColor.withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      GuideColors.iconForCategory(achievement.category),
                                      size: 30,
                                      color: achievement.isEarned
                                          ? categoryColor
                                          : Colors.grey.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Título
                                  Text(
                                    achievement.titleEs,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: achievement.isEarned
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Badge de categoría
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: achievement.isEarned
                                          ? categoryColor.withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      categoryLabel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: achievement.isEarned
                                            ? categoryColor
                                            : Colors.grey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  /// Construye los chips de filtro por categoría.
  List<Widget> _buildCategoryFilters() {
    const categories = [
      ('constancia', 'Constancia'),
      ('accion', 'Acción'),
      ('equilibrio', 'Equilibrio'),
      ('progreso', 'Progreso'),
      ('descubrimiento', 'Descubrimiento'),
    ];

    return categories.expand<Widget>((entry) {
      final (key, label) = entry;
      return [
        FilterChip(
          label: Text(label),
          selected: _selectedCategory == key,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = selected ? key : null;
            });
          },
        ),
        const SizedBox(width: 8),
      ];
    }).toList();
  }
}
