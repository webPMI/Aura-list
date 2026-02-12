import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/services/guide_synergy_service.dart';

/// Widget que visualiza la "Constelación del Usuario": una red de guías
/// que el usuario ha usado o explorado, con líneas conectando aquellos
/// que tienen sinergia.
///
/// Diseño tipo grafo simple con colores basados en nivel de afinidad.
/// Los guías se distribuyen en círculo para una visualización clara.
class UserConstellationWidget extends ConsumerStatefulWidget {
  const UserConstellationWidget({
    super.key,
    this.userGuideIds = const [],
    this.onGuideSelected,
    this.showOnlyActiveGuide = false,
  });

  /// IDs de guías que el usuario ha utilizado.
  /// Si está vacío, muestra el guía activo y sus aliados.
  final List<String> userGuideIds;

  /// Callback cuando se selecciona un guía.
  final void Function(Guide)? onGuideSelected;

  /// Si es true, solo muestra el guía activo y sus aliados directos.
  final bool showOnlyActiveGuide;

  @override
  ConsumerState<UserConstellationWidget> createState() =>
      _UserConstellationWidgetState();
}

class _UserConstellationWidgetState
    extends ConsumerState<UserConstellationWidget> {
  Guide? _selectedGuide;

  @override
  Widget build(BuildContext context) {
    final activeGuide = ref.watch(activeGuideProvider);
    final synergyService = GuideSynergyService.instance;

    // Determinar qué guías mostrar
    List<Guide> displayGuides;

    if (widget.showOnlyActiveGuide && activeGuide != null) {
      // Solo el guía activo y sus aliados
      final allies = synergyService.getRecommendedAllies(activeGuide.id);
      displayGuides = [activeGuide, ...allies];
    } else if (widget.userGuideIds.isNotEmpty) {
      // Guías especificados por el usuario
      displayGuides = widget.userGuideIds
          .map((id) => getGuideById(id))
          .whereType<Guide>()
          .toList();
    } else if (activeGuide != null) {
      // Fallback: guía activo y aliados
      final allies = synergyService.getRecommendedAllies(activeGuide.id);
      displayGuides = [activeGuide, ...allies];
    } else {
      // Sin guías para mostrar
      displayGuides = [];
    }

    if (displayGuides.isEmpty) {
      return _EmptyState();
    }

    return _ConstellationContent(
      guides: displayGuides,
      activeGuide: activeGuide,
      selectedGuide: _selectedGuide,
      onGuideSelected: (guide) {
        setState(() => _selectedGuide = guide);
        widget.onGuideSelected?.call(guide);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu constelación está vacía',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un guía celestial para comenzar tu jornada',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstellationContent extends StatelessWidget {
  const _ConstellationContent({
    required this.guides,
    required this.activeGuide,
    required this.selectedGuide,
    required this.onGuideSelected,
  });

  final List<Guide> guides;
  final Guide? activeGuide;
  final Guide? selectedGuide;
  final void Function(Guide) onGuideSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ConstellationPainter(
              guides: guides,
              activeGuide: activeGuide,
              selectedGuide: selectedGuide,
            ),
            child: _GuideNodes(
              guides: guides,
              activeGuide: activeGuide,
              selectedGuide: selectedGuide,
              onGuideSelected: onGuideSelected,
            ),
          ),
        );
      },
    );
  }
}

class _GuideNodes extends StatelessWidget {
  const _GuideNodes({
    required this.guides,
    required this.activeGuide,
    required this.selectedGuide,
    required this.onGuideSelected,
  });

  final List<Guide> guides;
  final Guide? activeGuide;
  final Guide? selectedGuide;
  final void Function(Guide) onGuideSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;

        return Stack(
          children: [
            for (int i = 0; i < guides.length; i++)
              _buildGuideNode(
                context,
                guides[i],
                i,
                guides.length,
                center,
                radius,
              ),
          ],
        );
      },
    );
  }

  Widget _buildGuideNode(
    BuildContext context,
    Guide guide,
    int index,
    int total,
    Offset center,
    double radius,
  ) {
    // Calcular posición en círculo
    final angle = (2 * math.pi * index / total) - (math.pi / 2);
    final x = center.dx + radius * math.cos(angle) - 28; // 28 = half of node size
    final y = center.dy + radius * math.sin(angle) - 28;

    final isActive = guide.id == activeGuide?.id;
    final isSelected = guide.id == selectedGuide?.id;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onGuideSelected(guide);
        },
        child: _GuideNode(
          guide: guide,
          isActive: isActive,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

class _GuideNode extends StatelessWidget {
  const _GuideNode({
    required this.guide,
    required this.isActive,
    required this.isSelected,
  });

  final Guide guide;
  final bool isActive;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(guide.themeAccentHex ?? guide.themePrimaryHex) ??
        theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (isActive || isSelected)
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: GuideAvatar(
            guide: guide,
            size: 56,
            showBorder: isActive || isSelected,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: color, width: 1.5)
                : null,
          ),
          child: Text(
            guide.name,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive || isSelected
                  ? color
                  : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.guides,
    required this.activeGuide,
    required this.selectedGuide,
  });

  final List<Guide> guides;
  final Guide? activeGuide;
  final Guide? selectedGuide;

  @override
  void paint(Canvas canvas, Size size) {
    final synergyService = GuideSynergyService.instance;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    // Calcular posiciones de los nodos
    final positions = <String, Offset>{};
    for (int i = 0; i < guides.length; i++) {
      final angle = (2 * math.pi * i / guides.length) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      positions[guides[i].id] = Offset(x, y);
    }

    // Dibujar líneas de sinergia
    for (int i = 0; i < guides.length; i++) {
      for (int j = i + 1; j < guides.length; j++) {
        final guide1 = guides[i];
        final guide2 = guides[j];

        if (synergyService.hasSynergy(guide1.id, guide2.id)) {
          final affinity = synergyService.calculateAffinityLevel(
            guide1.id,
            guide2.id,
          );

          final pos1 = positions[guide1.id]!;
          final pos2 = positions[guide2.id]!;

          // Color y grosor basado en afinidad
          final color = _getAffinityColor(affinity);
          final strokeWidth = 1.0 + (affinity * 2);

          final paint = Paint()
            ..color = color.withValues(alpha: 0.4)
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke;

          canvas.drawLine(pos1, pos2, paint);

          // Dibujar estrellitas en la línea si hay sinergia alta
          if (affinity >= 0.8) {
            _drawStarsOnLine(canvas, pos1, pos2, color);
          }
        }
      }
    }
  }

  Color _getAffinityColor(double affinity) {
    if (affinity >= 1.0) {
      return const Color(0xFFFFD700); // Dorado para sinergia máxima
    } else if (affinity >= 0.6) {
      return const Color(0xFF64B5F6); // Azul para sinergia media-alta
    } else {
      return const Color(0xFF90A4AE); // Gris para sinergia baja
    }
  }

  void _drawStarsOnLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Dibujar pequeña estrella en el punto medio
    _drawStar(canvas, midPoint, 4, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final angleStep = math.pi / points;

    for (int i = 0; i < points * 2; i++) {
      final angle = i * angleStep - math.pi / 2;
      final r = i.isEven ? size : size / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) {
    return oldDelegate.guides != guides ||
        oldDelegate.activeGuide != activeGuide ||
        oldDelegate.selectedGuide != selectedGuide;
  }
}

/// Widget simplificado que muestra solo las conexiones sin los avatares.
class ConstellationLinesOnly extends StatelessWidget {
  const ConstellationLinesOnly({
    super.key,
    required this.guides,
    this.size = 200,
  });

  final List<Guide> guides;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ConstellationPainter(
          guides: guides,
          activeGuide: null,
          selectedGuide: null,
        ),
      ),
    );
  }
}
