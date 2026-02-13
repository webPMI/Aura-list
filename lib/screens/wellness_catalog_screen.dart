import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wellness_provider.dart';
import '../providers/task_provider.dart';
import '../core/constants/wellness_catalog.dart';
import '../models/wellness_suggestion.dart';
import '../widgets/dashboard/wellness_suggestions_card.dart';
import '../widgets/shared/celebration_overlay.dart';

/// Pantalla que muestra el catalogo completo de 300 sugerencias de bienestar,
/// organizadas por categoria con filtros, estadisticas y acciones.
class WellnessCatalogScreen extends ConsumerStatefulWidget {
  const WellnessCatalogScreen({super.key});

  @override
  ConsumerState<WellnessCatalogScreen> createState() =>
      _WellnessCatalogScreenState();
}

class _WellnessCatalogScreenState extends ConsumerState<WellnessCatalogScreen>
    with SingleTickerProviderStateMixin {
  /// Categoria seleccionada actualmente; null significa "Todas"
  String? _selectedCategory;

  late TabController _tabController;

  /// Categorias disponibles con "todas" al principio
  static const List<String?> _categories = [
    null, // Todas
    'physical',
    'mental',
    'social',
    'nutrition',
    'sleep',
    'productivity',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = _categories[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Obtiene la lista de sugerencias filtrada y ordenada:
  /// no usadas primero (ni probadas ni agregadas), luego por categoria.
  List<WellnessSuggestion> _getFilteredSuggestions(
    WellnessState wellnessState,
  ) {
    List<WellnessSuggestion> suggestions;

    if (_selectedCategory == null) {
      suggestions = List<WellnessSuggestion>.from(
        WellnessCatalog.allSuggestions,
      );
    } else {
      suggestions = WellnessCatalog.getByCategory(_selectedCategory!);
    }

    // Ordenar: no usadas primero (ni probadas ni agregadas), luego por categoria
    suggestions.sort((a, b) {
      final aUsed = wellnessState.hasBeenUsed(a.id);
      final bUsed = wellnessState.hasBeenUsed(b.id);

      if (!aUsed && bUsed) return -1;
      if (aUsed && !bUsed) return 1;

      // Mismo estado: ordenar por categoria
      final catComp = a.category.compareTo(b.category);
      if (catComp != 0) return catComp;

      return a.title.compareTo(b.title);
    });

    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final wellnessState = ref.watch(wellnessProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final totalSuggestions = WellnessCatalog.totalSuggestions;
    final totalUsed = wellnessState.totalUsed;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Catalogo de Bienestar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _CategoryTabBar(
            tabController: _tabController,
            categories: _categories,
            wellnessState: wellnessState,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de estadisticas en la parte superior
          _StatsHeader(
            totalSuggestions: totalSuggestions,
            totalUsed: totalUsed,
          ),
          // Lista principal de sugerencias
          Expanded(
            child: _SuggestionsList(
              suggestions: _getFilteredSuggestions(wellnessState),
              wellnessState: wellnessState,
              onMarkDone: _handleMarkDone,
              onAddToList: _handleAddToList,
              onTapCard: _showSuggestionDetails,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDetails(WellnessSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _SuggestionDetailSheetWrapper(suggestion: suggestion),
    );
  }

  void _handleMarkDone(WellnessSuggestion suggestion) {
    HapticFeedback.mediumImpact();
    ref.read(wellnessProvider.notifier).markAsTried(suggestion.id);
    CelebrationOverlay.show(
      context,
      color: suggestion.category.categoryGradient.first,
      icon: Icons.favorite,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('${suggestion.title} completado')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: suggestion.category.categoryGradient.first,
      ),
    );
  }

  Future<void> _handleAddToList(WellnessSuggestion suggestion) async {
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(tasksProvider('daily').notifier)
          .addTask(
            suggestion.title,
            category: 'Bienestar',
            priority: 1,
            motivation: suggestion.motivation,
          );
      // Marcar la sugerencia como agregada para que no aparezca de nuevo
      ref.read(wellnessProvider.notifier).markAsAdded(suggestion.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.add_task, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('"${suggestion.title}" agregado a tareas'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: suggestion.category.categoryGradient.first,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al agregar tarea'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Barra de tabs de categoria
// ---------------------------------------------------------------------------

class _CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String?> categories;
  final WellnessState wellnessState;

  const _CategoryTabBar({
    required this.tabController,
    required this.categories,
    required this.wellnessState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      tabs: categories.map((cat) {
        if (cat == null) {
          final total = WellnessCatalog.totalSuggestions;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.grid_view, size: 16),
                const SizedBox(width: 6),
                Text('Todas ($total)'),
              ],
            ),
          );
        }
        final icon = cat.categoryIcon;
        final label = WellnessCatalog.categoryNames[cat] ?? cat;
        final count = WellnessCatalog.getByCategory(cat).length;
        final tried = wellnessState.triedSuggestionIds
            .where((id) => id.startsWith(cat))
            .length;

        // Use shorter labels on narrow screens
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final displayLabel = isMobile && label.length > 8
            ? '${label.substring(0, label.length > 6 ? 6 : label.length)}.'
            : label;

        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text('$displayLabel ($tried/$count)'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabecera de estadisticas
// ---------------------------------------------------------------------------

class _StatsHeader extends StatelessWidget {
  final int totalSuggestions;
  final int totalUsed;

  const _StatsHeader({
    required this.totalSuggestions,
    required this.totalUsed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalSuggestions > 0 ? totalUsed / totalSuggestions : 0.0;
    final percent = (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.2),
                      colorScheme.tertiary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalUsed de $totalSuggestions completadas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$percent% del catalogo explorado',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de porcentaje
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de sugerencias
// ---------------------------------------------------------------------------

class _SuggestionsList extends StatelessWidget {
  final List<WellnessSuggestion> suggestions;
  final WellnessState wellnessState;
  final void Function(WellnessSuggestion) onMarkDone;
  final Future<void> Function(WellnessSuggestion) onAddToList;
  final void Function(WellnessSuggestion) onTapCard;

  const _SuggestionsList({
    required this.suggestions,
    required this.wellnessState,
    required this.onMarkDone,
    required this.onAddToList,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sugerencias',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        final isUsed = wellnessState.hasBeenUsed(suggestion.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CatalogSuggestionCard(
            suggestion: suggestion,
            isUsed: isUsed,
            onTap: () => onTapCard(suggestion),
            onMarkDone: () => onMarkDone(suggestion),
            onAddToList: () => onAddToList(suggestion),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card individual del catalogo
// ---------------------------------------------------------------------------

class _CatalogSuggestionCard extends StatelessWidget {
  final WellnessSuggestion suggestion;
  final bool isUsed;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;
  final VoidCallback onAddToList;

  const _CatalogSuggestionCard({
    required this.suggestion,
    required this.isUsed,
    required this.onTap,
    required this.onMarkDone,
    required this.onAddToList,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = suggestion.category.categoryGradient;
    final categoryIcon = suggestion.category.categoryIcon;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUsed
              ? Colors.green.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isUsed ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila de cabecera: icono + titulo + badge de estado + duracion
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono de categoria con gradiente
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoryIcon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  // Titulo y categoria
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradientColors.first.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                suggestion.categoryLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: gradientColors.first,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              suggestion.durationLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Indicador visual de estado
                  if (isUsed)
                    Tooltip(
                      message: 'Completada',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Descripcion corta
              Text(
                suggestion.description,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Botones de accion
              Row(
                children: [
                  // Boton "Ya lo hice"
                  Expanded(
                    child: _CardActionButton(
                      icon: isUsed ? Icons.favorite : Icons.favorite_border,
                      label: isUsed ? 'Completada' : 'Ya lo hice',
                      gradientColors: isUsed
                          ? [Colors.green, Colors.lightGreen]
                          : [Colors.pink, Colors.pinkAccent],
                      onTap: isUsed ? null : onMarkDone,
                      isDisabled: isUsed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Boton "Agregar"
                  Expanded(
                    child: _CardActionButton(
                      icon: Icons.add_task,
                      label: 'Agregar',
                      gradientColors: gradientColors,
                      onTap: onAddToList,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boton de accion en el card
// ---------------------------------------------------------------------------

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors = isDisabled
        ? [Colors.grey.shade400, Colors.grey.shade300]
        : gradientColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: effectiveColors),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wrapper que muestra el _SuggestionDetailSheet de wellness_suggestions_card
// ---------------------------------------------------------------------------

/// Wrapper publico para mostrar el detail sheet reutilizando la implementacion
/// interna de [wellness_suggestions_card.dart].
///
/// Dado que [_SuggestionDetailSheet] es privado, se duplica aqui la logica
/// del sheet respetando el mismo estilo visual y usando los mismos providers.
class _SuggestionDetailSheetWrapper extends ConsumerWidget {
  final WellnessSuggestion suggestion;

  const _SuggestionDetailSheetWrapper({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = suggestion.category.categoryGradient;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Cabecera con gradiente
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    suggestion.category.categoryIcon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              suggestion.categoryLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                suggestion.durationLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenido scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetSection(
                    icon: Icons.description_outlined,
                    title: 'Descripcion',
                    content: suggestion.description,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  _SheetSection(
                    icon: Icons.lightbulb_outline,
                    title: 'Por que es importante',
                    content: suggestion.motivation,
                    color: gradientColors.first,
                    highlighted: true,
                  ),
                  const SizedBox(height: 20),
                  if (suggestion.recommendations.isNotEmpty) ...[
                    Text(
                      'Formas de hacerlo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...suggestion.recommendations.map(
                      (rec) => _SheetBulletItem(
                        text: rec,
                        color: gradientColors.first,
                        isCheck: false,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Beneficios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...suggestion.benefits.map(
                    (benefit) => _SheetBulletItem(
                      text: benefit,
                      color: gradientColors.first,
                      isCheck: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Botones de accion
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SheetActionBtn(
                    icon: Icons.favorite,
                    label: 'Ya lo hice',
                    gradientColors: [Colors.pink, Colors.pinkAccent],
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(wellnessProvider.notifier)
                          .markAsTried(suggestion.id);
                      Navigator.pop(context);
                      CelebrationOverlay.show(
                        context,
                        color: Colors.pink,
                        icon: Icons.favorite,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${suggestion.title} completado'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.pink,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetActionBtn(
                    icon: Icons.add_task,
                    label: 'Agregar a Tareas',
                    gradientColors: gradientColors,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      try {
                        await ref
                            .read(tasksProvider('daily').notifier)
                            .addTask(
                              suggestion.title,
                              category: 'Bienestar',
                              priority: 1,
                              motivation: suggestion.motivation,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${suggestion.title}" agregado'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: gradientColors.first,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al agregar')),
                          );
                        }
                      }
                    },
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

// ---------------------------------------------------------------------------
// Widgets auxiliares del detail sheet
// ---------------------------------------------------------------------------

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final bool highlighted;

  const _SheetSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: highlighted ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: highlighted ? color : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBulletItem extends StatelessWidget {
  final String text;
  final Color color;
  final bool isCheck;

  const _SheetBulletItem({
    required this.text,
    required this.color,
    required this.isCheck,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCheck)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 12, color: color),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _SheetActionBtn({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 100),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
