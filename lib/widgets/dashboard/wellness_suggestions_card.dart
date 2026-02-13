import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/constants/wellness_catalog.dart';
import '../../models/wellness_suggestion.dart';
import '../../providers/task_provider.dart';
import '../../providers/wellness_provider.dart';
import '../../screens/wellness_catalog_screen.dart';
import '../shared/celebration_overlay.dart';

/// Extension para obtener propiedades de display de categorias
extension WellnessCategoryDisplay on String {
  IconData get categoryIcon {
    switch (this) {
      case 'physical':
        return Icons.fitness_center;
      case 'mental':
        return Icons.psychology;
      case 'social':
        return Icons.people;
      case 'nutrition':
        return Icons.restaurant;
      case 'sleep':
        return Icons.bedtime;
      case 'productivity':
        return Icons.rocket_launch;
      default:
        return Icons.favorite;
    }
  }

  List<Color> get categoryGradient {
    switch (this) {
      case 'physical':
        return [const Color(0xFF2196F3), const Color(0xFF03A9F4)];
      case 'mental':
        return [const Color(0xFF9C27B0), const Color(0xFFE040FB)];
      case 'social':
        return [const Color(0xFFE91E63), const Color(0xFFF06292)];
      case 'nutrition':
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
      case 'sleep':
        return [const Color(0xFF3F51B5), const Color(0xFF7986CB)];
      case 'productivity':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      default:
        return [const Color(0xFF607D8B), const Color(0xFF90A4AE)];
    }
  }
}

/// Calcula el periodo de 4 horas al que pertenece la hora actual.
/// Retorna un valor de 0 a 5, donde:
///   0 = 00:00-03:59, 1 = 04:00-07:59, 2 = 08:00-11:59,
///   3 = 12:00-15:59, 4 = 16:00-19:59, 5 = 20:00-23:59
int _currentFourHourPeriod() {
  return DateTime.now().hour ~/ 4;
}

/// Provider para sugerencias diarias (6 sugerencias variadas).
/// Las sugerencias rotan cada 4 horas y priorizan las no probadas/agregadas.
final dailyWellnessSuggestionsProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
  final wellnessState = ref.watch(wellnessProvider);
  final usedIds = wellnessState.triedSuggestionIds
      .union(wellnessState.addedSuggestionIds);

  final now = DateTime.now();
  final period = _currentFourHourPeriod();
  // La semilla combina fecha y periodo de 4 horas para rotar las sugerencias
  final seed =
      now.year * 1000000 + now.month * 10000 + now.day * 100 + period;
  final random = Random(seed);

  // Construir un pool candidato de una sugerencia por categoria
  final categories = WellnessCategory.all;
  final allCandidates = <WellnessSuggestion>[];

  for (final category in categories) {
    final categorySuggestions = WellnessCatalog.getByCategory(category);
    if (categorySuggestions.isNotEmpty) {
      allCandidates.add(
        categorySuggestions[random.nextInt(categorySuggestions.length)],
      );
    }
  }

  // Mezclar con la misma semilla para obtener orden determinista
  allCandidates.shuffle(random);

  // Separar en no usadas y ya usadas para priorizar las no usadas
  final untried =
      allCandidates.where((s) => !usedIds.contains(s.id)).toList();
  final tried =
      allCandidates.where((s) => usedIds.contains(s.id)).toList();

  // Combinar: primero las no usadas, luego las ya usadas como relleno
  final ordered = [...untried, ...tried];

  // Si no alcanzamos 6 con el pool por categorias, rellenar con el catalogo
  if (ordered.length < 6) {
    final alreadyIncluded = ordered.map((s) => s.id).toSet();
    final extra = WellnessCatalog.allSuggestions
        .where((s) => !alreadyIncluded.contains(s.id))
        .toList()
      ..shuffle(random);

    // Primero los no usados del catalogo completo, luego los usados
    final extraUntried = extra.where((s) => !usedIds.contains(s.id)).toList();
    final extraTried = extra.where((s) => usedIds.contains(s.id)).toList();
    ordered.addAll([...extraUntried, ...extraTried]);
  }

  return ordered.take(6).toList();
});

/// Comportamiento de scroll personalizado que habilita arrastre con mouse en web.
class _WebDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// Constantes de diseno para tarjetas de sugerencias
class _WellnessCardConstants {
  static const double minCardWidth = 280.0;
  static const double cardHeightMobile = 260.0;
  static const double cardHeightDesktop = 240.0;
  static const double pageViewportFraction = 0.92;
  static const double compactPageViewportFraction = 0.88;
}

/// Wellness Suggestions Card para el Dashboard
class WellnessSuggestionsCard extends ConsumerStatefulWidget {
  const WellnessSuggestionsCard({super.key});

  @override
  ConsumerState<WellnessSuggestionsCard> createState() =>
      _WellnessSuggestionsCardState();
}

class _WellnessSuggestionsCardState extends ConsumerState<WellnessSuggestionsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  PageController _getPageController(double width) {
    // Ajustar viewport fraction segun el ancho disponible
    final viewportFraction = width < _WellnessCardConstants.minCardWidth * 1.5
        ? _WellnessCardConstants.compactPageViewportFraction
        : _WellnessCardConstants.pageViewportFraction;

    if (_pageController == null ||
        _pageController!.viewportFraction != viewportFraction) {
      _pageController?.dispose();
      _pageController = PageController(viewportFraction: viewportFraction);
    }
    return _pageController!;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _showSuggestionDetails(BuildContext context, WellnessSuggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SuggestionDetailSheet(suggestion: suggestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(dailyWellnessSuggestionsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final isCompact = availableWidth < _WellnessCardConstants.minCardWidth * 1.2;
          final cardHeight = isMobile
              ? _WellnessCardConstants.cardHeightMobile
              : _WellnessCardConstants.cardHeightDesktop;

          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: _WellnessCardConstants.minCardWidth,
            ),
            child: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 12 : 16,
                      isCompact ? 12 : 16,
                      isCompact ? 12 : 16,
                      8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompact ? 6 : 8),
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
                            size: isCompact ? 18 : 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sugerencias para Ti',
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${suggestions.length} actividades de bienestar',
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Page indicator - ocultar en pantallas muy pequenas
                        if (!isCompact) ...[
                          _PageIndicator(
                            count: suggestions.length,
                            currentIndex: _currentIndex,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              // Navigate to the full catalog screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const WellnessCatalogScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chevron_right, size: 18),
                            label: const Text(
                              'Ver catalogo',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Page indicator compacto debajo del header si es necesario
                  if (isCompact)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Center(
                        child: _PageIndicator(
                          count: suggestions.length,
                          currentIndex: _currentIndex,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  // Suggestion cards
                  SizedBox(
                    height: cardHeight,
                    child: ScrollConfiguration(
                      behavior: _WebDragScrollBehavior(),
                      child: PageView.builder(
                        controller: _getPageController(availableWidth),
                        itemCount: suggestions.length,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final suggestion = suggestions[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 2 : 4,
                              vertical: isCompact ? 4 : 8,
                            ),
                            child: _SuggestionCard(
                              suggestion: suggestion,
                              isCompact: isCompact,
                              onTap: () => _showSuggestionDetails(context, suggestion),
                              onMarkDone: () => _markAsDone(suggestion),
                              onAddToList: () => _addToList(suggestion),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _markAsDone(WellnessSuggestion suggestion) {
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

  void _addToList(WellnessSuggestion suggestion) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(tasksProvider('daily').notifier).addTask(
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
                Expanded(child: Text('"${suggestion.title}" agregado a tareas')),
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

/// Tarjeta individual de sugerencia
class _SuggestionCard extends StatelessWidget {
  final WellnessSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;
  final VoidCallback onAddToList;
  final bool isCompact;

  const _SuggestionCard({
    required this.suggestion,
    required this.onTap,
    required this.onMarkDone,
    required this.onAddToList,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = suggestion.category.categoryGradient;

    // Valores responsivos
    final contentPadding = isCompact ? 12.0 : 16.0;
    final iconContainerPadding = isCompact ? 6.0 : 8.0;
    final categoryIconSize = isCompact ? 16.0 : 20.0;
    final titleFontSize = isCompact ? 14.0 : 16.0;
    final categoryFontSize = isCompact ? 10.0 : 11.0;
    final descriptionFontSize = isCompact ? 12.0 : 13.0;
    final motivationFontSize = isCompact ? 10.0 : 11.0;
    final backgroundIconSize = isCompact ? 80.0 : 120.0;

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: _WellnessCardConstants.minCardWidth,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  suggestion.category.categoryIcon,
                  size: backgroundIconSize,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(iconContainerPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            suggestion.category.categoryIcon,
                            size: categoryIconSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isCompact ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                suggestion.categoryLabel,
                                style: TextStyle(
                                  fontSize: categoryFontSize,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Duration badge - flexible para pantallas pequenas
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 6 : 10,
                              vertical: isCompact ? 3 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: isCompact ? 12 : 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                SizedBox(width: isCompact ? 2 : 4),
                                Flexible(
                                  child: Text(
                                    suggestion.durationLabel,
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    // Description
                    Expanded(
                      child: Text(
                        suggestion.description,
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                        maxLines: isCompact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Motivation preview
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: isCompact ? 14 : 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          SizedBox(width: isCompact ? 6 : 8),
                          Expanded(
                            child: Text(
                              suggestion.motivation,
                              style: TextStyle(
                                fontSize: motivationFontSize,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.favorite_border,
                            label: isCompact ? 'Hecho' : 'Ya lo hice',
                            onTap: onMarkDone,
                            isCompact: isCompact,
                          ),
                        ),
                        SizedBox(width: isCompact ? 6 : 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_task,
                            label: 'Agregar',
                            onTap: onAddToList,
                            isPrimary: true,
                            isCompact: isCompact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boton de accion en la tarjeta
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isCompact;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final verticalPadding = isCompact ? 8.0 : 10.0;
    final horizontalPadding = isCompact ? 8.0 : 12.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final fontSize = isCompact ? 11.0 : 12.0;
    final spacing = isCompact ? 4.0 : 6.0;

    return Material(
      color: isPrimary
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: Colors.white),
              SizedBox(width: spacing),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
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
    );
  }
}

/// Indicador de pagina
class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color color;

  const _PageIndicator({
    required this.count,
    required this.currentIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Bottom sheet con detalles de la sugerencia
class _SuggestionDetailSheet extends ConsumerWidget {
  final WellnessSuggestion suggestion;

  const _SuggestionDetailSheet({required this.suggestion});

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
          // Header with gradient
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      suggestion.durationLabel,
                                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _DetailSection(
                    icon: Icons.description_outlined,
                    title: 'Descripcion',
                    content: suggestion.description,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  // Motivation
                  _DetailSection(
                    icon: Icons.lightbulb_outline,
                    title: 'Por que es importante',
                    content: suggestion.motivation,
                    color: gradientColors.first,
                    highlighted: true,
                  ),
                  const SizedBox(height: 20),
                  // Recommendations
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
                    ...suggestion.recommendations.map((rec) => _RecommendationItem(
                      recommendation: rec,
                      color: gradientColors.first,
                    )),
                    const SizedBox(height: 20),
                  ],
                  // Benefits
                  Text(
                    'Beneficios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...suggestion.benefits.map((benefit) => _BenefitItem(
                    benefit: benefit,
                    color: gradientColors.first,
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SheetActionButton(
                    icon: Icons.favorite,
                    label: 'Ya lo hice',
                    gradientColors: [Colors.pink, Colors.pinkAccent],
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(wellnessProvider.notifier).markAsTried(suggestion.id);
                      Navigator.pop(context);
                      CelebrationOverlay.show(context, color: Colors.pink, icon: Icons.favorite);
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
                  child: _SheetActionButton(
                    icon: Icons.add_task,
                    label: 'Agregar a Tareas',
                    gradientColors: gradientColors,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      try {
                        await ref.read(tasksProvider('daily').notifier).addTask(
                          suggestion.title,
                          category: 'Bienestar',
                          priority: 1,
                          motivation: suggestion.motivation,
                        );
                        // Marcar la sugerencia como agregada
                        ref.read(wellnessProvider.notifier).markAsAdded(suggestion.id);
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

/// Seccion de detalle
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final bool highlighted;

  const _DetailSection({
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

/// Item de recomendacion
class _RecommendationItem extends StatelessWidget {
  final String recommendation;
  final Color color;

  const _RecommendationItem({
    required this.recommendation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
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

/// Item de beneficio
class _BenefitItem extends StatelessWidget {
  final String benefit;
  final Color color;

  const _BenefitItem({
    required this.benefit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 12, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
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

/// Boton de accion en el sheet
class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _SheetActionButton({
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
