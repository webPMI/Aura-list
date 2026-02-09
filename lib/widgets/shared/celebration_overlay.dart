import 'package:flutter/material.dart';

/// Widget de overlay animado que muestra una celebracion al completar tareas.
/// Incluye un checkmark animado con confeti.
class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Color? color;
  final IconData icon;

  const CelebrationOverlay({
    super.key,
    required this.onComplete,
    this.color,
    this.icon = Icons.check,
  });

  /// Muestra el overlay de celebracion sobre el contexto actual.
  static void show(BuildContext context, {Color? color, IconData? icon}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        onComplete: () => overlayEntry.remove(),
        color: color,
        icon: icon ?? Icons.check,
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
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

  Color get _celebrationColor => widget.color ?? Colors.green;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Semi-transparent background
                Opacity(
                  opacity: _opacityAnimation.value * 0.3,
                  child: Container(color: _celebrationColor),
                ),
                // Icon
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _celebrationColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _celebrationColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
                // Confetti particles
                ..._buildConfettiParticles(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildConfettiParticles() {
    final List<Widget> particles = [];
    final colors = [
      _celebrationColor,
      _celebrationColor.withValues(alpha: 0.8),
      Colors.white,
      Colors.yellow,
      Colors.amber,
      Colors.lightGreenAccent,
    ];

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159;
      final color = colors[i % colors.length];

      particles.add(
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            final distance = 80 + (progress * 120);
            final x = distance *
                (0.5 + 0.5 * (i.isEven ? 1 : -1)) *
                (i % 3 == 0 ? 1.2 : 0.8) *
                (angle > 3.14 ? -1 : 1);
            final y = distance *
                (0.5 + 0.5 * (i.isOdd ? 1 : -1)) *
                (i % 2 == 0 ? 1.2 : 0.8) *
                (angle > 1.57 && angle < 4.71 ? 1 : -1);

            return Transform.translate(
              offset: Offset(
                x * _scaleAnimation.value,
                y * _scaleAnimation.value,
              ),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.rotate(
                  angle: progress * 3.14159 * 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: i.isEven ? null : BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return particles;
  }
}
