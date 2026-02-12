import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/guides.dart';
import 'package:checklist_app/providers/streak_provider.dart';

/// Widget de celebracion de racha que muestra cuando se alcanza un hito.
///
/// Muestra:
/// - Avatar del guia activo
/// - Mensaje celebratorio personalizado del guia
/// - Animacion con el color del tema del guia
/// - Auto-cierre despues de 5 segundos
class StreakCelebrationWidget extends ConsumerStatefulWidget {
  const StreakCelebrationWidget({
    super.key,
    required this.streakDays,
    this.onDismiss,
  });

  /// Dias de racha alcanzados
  final int streakDays;

  /// Callback cuando se cierra la celebracion
  final VoidCallback? onDismiss;

  @override
  ConsumerState<StreakCelebrationWidget> createState() =>
      _StreakCelebrationWidgetState();
}

class _StreakCelebrationWidgetState
    extends ConsumerState<StreakCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador de entrada/salida con fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Controlador de escala inicial
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Controlador de pulso continuo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Controlador de particulas
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Iniciar animaciones de entrada
    _fadeController.forward();
    _scaleController.forward();

    // Auto-cierre despues de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissCelebration();
      }
    });
  }

  void _dismissCelebration() async {
    await _fadeController.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(activeGuideProvider);
    final message = ref.watch(guideStreakMessageProvider(widget.streakDays));

    // Color del tema del guia o color por defecto
    final guideColor = parseHexColor(
          guide?.themePrimaryHex ?? guide?.themeAccentHex,
        ) ??
        Theme.of(context).colorScheme.primary;

    final accentColor = parseHexColor(guide?.themeAccentHex) ?? guideColor;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _dismissCelebration,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particulas animadas de fondo
                    _buildParticles(guideColor, accentColor),

                    // Tarjeta principal de celebracion
                    _buildCelebrationCard(
                      context,
                      guide,
                      message,
                      guideColor,
                      accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticles(Color primaryColor, Color accentColor) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(350, 350),
          painter: _ParticlePainter(
            progress: _particleController.value,
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
        );
      },
    );
  }

  Widget _buildCelebrationCard(
    BuildContext context,
    Guide? guide,
    String? message,
    Color guideColor,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? guideColor.withValues(alpha: 0.2)
                : guideColor.withValues(alpha: 0.1),
            isDark
                ? accentColor.withValues(alpha: 0.15)
                : accentColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: guideColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: guideColor.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de fuego/racha
          _buildStreakIcon(guideColor),
          const SizedBox(height: 16),

          // Contador de dias
          Text(
            '${widget.streakDays}',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: guideColor,
              shadows: [
                Shadow(
                  color: guideColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),

          // Label de dias
          Text(
            widget.streakDays == 1 ? 'DIA DE RACHA' : 'DIAS DE RACHA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar del guia
          if (guide != null) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: guideColor.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GuideAvatar(
                guide: guide,
                size: 64,
                showBorder: true,
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del guia
            Text(
              guide.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: guideColor,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Mensaje del guia
          Text(
            message ?? _getDefaultMessage(widget.streakDays),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Indicador de toque para cerrar
          Text(
            'Toca para continuar',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakIcon(Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        Icons.local_fire_department,
        color: Colors.white,
        size: 36,
      ),
    );
  }

  String _getDefaultMessage(int days) {
    if (days >= 30) {
      return 'Un mes de constancia! Tu dedicacion es inspiradora.';
    } else if (days >= 21) {
      return 'Tres semanas seguidas! El habito ya es parte de ti.';
    } else if (days >= 14) {
      return 'Dos semanas de compromiso! Sigue brillando.';
    } else if (days >= 7) {
      return 'Una semana completa! Tu constancia da frutos.';
    } else if (days >= 3) {
      return 'Tres dias seguidos! Estas construyendo algo grande.';
    }
    return 'Felicidades por tu racha de $days dias!';
  }
}

/// Pintor de particulas animadas para el efecto de celebracion
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42); // Seed fijo para consistencia

    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi + progress * 2 * math.pi;
      final baseRadius = 80 + random.nextDouble() * 80;
      final radiusVariation = math.sin(progress * math.pi * 2 + i) * 20;
      final radius = baseRadius + radiusVariation;

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      final particleSize = 3 + random.nextDouble() * 5;
      final opacity = 0.3 + 0.7 * math.sin((progress + i / 20) * math.pi);

      final color = i % 2 == 0 ? primaryColor : accentColor;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // Anillos concentricos pulsantes
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.33) % 1.0;
      final ringRadius = 60 + ringProgress * 100;
      final ringOpacity = (1.0 - ringProgress) * 0.3;

      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Funcion helper para mostrar la celebracion de racha como overlay
void showStreakCelebration(BuildContext context, int streakDays) {
  // Solo mostrar para hitos importantes
  if (!isStreakMilestone(streakDays)) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => StreakCelebrationWidget(
      streakDays: streakDays,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}
