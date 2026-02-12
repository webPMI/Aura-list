import 'package:flutter/material.dart';

import 'package:checklist_app/models/guide_model.dart';

/// Widget de overlay que muestra feedback visual cuando se activa una bendicion.
///
/// Es sutil y no intrusivo: aparece brevemente en la parte inferior de la pantalla.
/// Usa el color del guia activo para mantener coherencia visual.
class BlessingFeedback extends StatefulWidget {
  final String message;
  final BlessingDefinition blessing;
  final Color? guideColor;
  final VoidCallback onComplete;

  const BlessingFeedback({
    super.key,
    required this.message,
    required this.blessing,
    required this.onComplete,
    this.guideColor,
  });

  /// Muestra el feedback de bendicion como overlay.
  static void show(
    BuildContext context, {
    required String message,
    required BlessingDefinition blessing,
    Color? guideColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => BlessingFeedback(
        message: message,
        blessing: blessing,
        guideColor: guideColor,
        onComplete: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<BlessingFeedback> createState() => _BlessingFeedbackState();
}

class _BlessingFeedbackState extends State<BlessingFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Slide desde abajo
    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 100, end: 0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 100)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Opacidad
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    // Efecto de brillo pulsante
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.6),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.3),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.6),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _blessingColor => widget.guideColor ?? Colors.amber;

  IconData get _blessingIcon {
    final id = widget.blessing.id;
    if (id.contains('gracia')) return Icons.auto_awesome;
    if (id.contains('escudo')) return Icons.shield;
    if (id.contains('manto')) return Icons.nights_stay;
    if (id.contains('corona')) return Icons.emoji_events;
    if (id.contains('brote')) return Icons.eco;
    if (id.contains('nexo')) return Icons.hub;
    if (id.contains('chispa') || id.contains('mensajero')) return Icons.bolt;
    if (id.contains('flujo')) return Icons.water_drop;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100, // Encima de la barra de navegacion
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _blessingColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _blessingColor.withValues(alpha: _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono con brillo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _blessingColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _blessingIcon,
                          color: _blessingColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mensaje
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.blessing.name,
                              style: TextStyle(
                                color: _blessingColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
