import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/guide_theme_provider.dart';
import 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
import 'package:checklist_app/models/guide_affinity_model.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/services/guide_voice_service.dart';

/// Modal celebrando una subida de nivel de afinidad con el guía.
///
/// Filosofía: Un hito importante merece una celebración memorable.
/// El vínculo forjado entre usuario y guía es un logro genuino.
class AffinityLevelUpWidget extends ConsumerStatefulWidget {
  final int newLevel;
  final Guide guide;
  final VoidCallback? onDismiss;

  const AffinityLevelUpWidget({
    super.key,
    required this.newLevel,
    required this.guide,
    this.onDismiss,
  });

  /// Muestra el modal de subida de nivel de afinidad.
  static void show(
    BuildContext context, {
    required int newLevel,
    required Guide guide,
    VoidCallback? onDismiss,
  }) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => AffinityLevelUpWidget(
        newLevel: newLevel,
        guide: guide,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  ConsumerState<AffinityLevelUpWidget> createState() =>
      _AffinityLevelUpWidgetState();
}

class _AffinityLevelUpWidgetState extends ConsumerState<AffinityLevelUpWidget>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final AnimationController _starsController;
  late final AnimationController _particlesController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _starsAnimation;

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _starsAnimation = CurvedAnimation(
      parent: _starsController,
      curve: Curves.easeOutBack,
    );

    // Secuencia de animaciones de entrada
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _starsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _particlesController.repeat();
    });

    // Auto-dismiss después de 5 segundos
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _scaleController.dispose();
    _fadeController.dispose();
    _starsController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  String _getLevelUpTitle(int level) {
    switch (level) {
      case 1:
        return '¡Vínculo Iniciado!';
      case 2:
        return '¡Compañeros de Camino!';
      case 3:
        return '¡Alianza Forjada!';
      case 4:
        return '¡Vínculo Profundo!';
      case 5:
        return '¡Almas Gemelas!';
      default:
        return '¡Nuevo Nivel!';
    }
  }

  String _getLevelUpMessage(Guide guide, int newLevel) {
    final service = GuideVoiceService.instance;
    final message = service.getMessage(guide, GuideVoiceMoment.encouragement);
    if (message != null && message.isNotEmpty) return message;

    // Fallback con el nombre del guía
    switch (newLevel) {
      case 1:
        return '${guide.name} comienza a conocerte. El camino juntos apenas empieza.';
      case 2:
        return '${guide.name} y tú comparten experiencias. La confianza crece.';
      case 3:
        return '${guide.name} confía en ti. Una alianza verdadera se ha formado.';
      case 4:
        return 'El vínculo con ${guide.name} es profundo. Caminan juntos hacia lo importante.';
      case 5:
        return '${guide.name} y tú son almas gemelas. Un viaje de realización compartido.';
      default:
        return '${guide.name} celebra tu crecimiento contigo.';
    }
  }

  Color _getGuideColor() {
    final fromProvider = ref.read(guideAccentColorProvider);
    if (fromProvider != null) return fromProvider;
    return parseHexColor(widget.guide.themeAccentHex ?? widget.guide.themePrimaryHex) ??
        Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final guideColor = _getGuideColor();
    final affinityLevel = AffinityLevel.fromValue(widget.newLevel);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: guideColor.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 4,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Fondo con partículas sutiles
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: AnimatedBuilder(
                  animation: _particlesController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ParticlesPainter(
                        progress: _particlesController.value,
                        color: guideColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Contenido principal
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de arrastre
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Subtítulo "Vínculo Fortalecido"
                  Text(
                    'VÍNCULO FORTALECIDO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: guideColor.withValues(alpha: 0.8),
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Avatar del guía con glow animado
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _GlowingAvatar(
                      guide: widget.guide,
                      guideColor: guideColor,
                      size: 96,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título de la subida de nivel
                  Text(
                    _getLevelUpTitle(widget.newLevel),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: guideColor,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Nivel alcanzado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          guideColor.withValues(alpha: 0.2),
                          guideColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: guideColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Nivel ${widget.newLevel}: ${affinityLevel.label}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: guideColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estrellas de nivel
                  ScaleTransition(
                    scale: _starsAnimation,
                    child: _LevelStars(
                      currentLevel: widget.newLevel,
                      maxLevel: 5,
                      color: guideColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mensaje del guía
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          guideColor.withValues(alpha: 0.12),
                          guideColor.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: guideColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 20,
                          color: guideColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getLevelUpMessage(widget.guide, widget.newLevel),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '— ${widget.guide.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: guideColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Descripción del nivel
                  Text(
                    affinityLevel.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Botón Continuar
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _autoDismissTimer?.cancel();
                        Navigator.of(context).pop();
                        widget.onDismiss?.call();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: guideColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar del guía con efecto de glow pulsante.
class _GlowingAvatar extends StatefulWidget {
  final Guide guide;
  final Color guideColor;
  final double size;

  const _GlowingAvatar({
    required this.guide,
    required this.guideColor,
    required this.size,
  });

  @override
  State<_GlowingAvatar> createState() => _GlowingAvatarState();
}

class _GlowingAvatarState extends State<_GlowingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowRadius = 16.0 + (_glowAnimation.value * 14.0);
        final glowAlpha = 0.3 + (_glowAnimation.value * 0.2);
        return Container(
          width: widget.size + 16,
          height: widget.size + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.guideColor.withValues(alpha: glowAlpha),
                blurRadius: glowRadius,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: widget.guideColor.withValues(alpha: glowAlpha * 0.4),
                blurRadius: glowRadius * 2,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GuideAvatar(
        guide: widget.guide,
        size: widget.size,
        showBorder: true,
      ),
    );
  }
}

/// Estrellas representando el nivel de afinidad actual.
class _LevelStars extends StatelessWidget {
  final int currentLevel;
  final int maxLevel;
  final Color color;

  const _LevelStars({
    required this.currentLevel,
    required this.maxLevel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLevel, (index) {
        final isActive = index < currentLevel;
        final isNew = index == currentLevel - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _StarIcon(
            isActive: isActive,
            isNew: isNew,
            color: color,
            size: isNew ? 32 : 24,
          ),
        );
      }),
    );
  }
}

/// Icono de estrella individual con animación de pulso para la nueva.
class _StarIcon extends StatefulWidget {
  final bool isActive;
  final bool isNew;
  final Color color;
  final double size;

  const _StarIcon({
    required this.isActive,
    required this.isNew,
    required this.color,
    required this.size,
  });

  @override
  State<_StarIcon> createState() => _StarIconState();
}

class _StarIconState extends State<_StarIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isNew) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Icon(
          Icons.star_rounded,
          size: widget.size,
          color: widget.color,
          shadows: [
            Shadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 8,
            ),
          ],
        ),
      );
    }

    return Icon(
      widget.isActive ? Icons.star_rounded : Icons.star_outline_rounded,
      size: widget.size,
      color: widget.isActive
          ? widget.color.withValues(alpha: 0.7)
          : widget.color.withValues(alpha: 0.2),
    );
  }
}

/// CustomPainter para partículas sutiles de fondo.
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  static final List<_Particle> _particles = List.generate(
    16,
    (i) => _Particle(
      x: (i * 0.0625) + (math.sin(i * 1.3) * 0.08),
      baseY: 0.1 + (i % 5) * 0.18,
      size: 2.0 + (i % 4) * 1.5,
      speed: 0.3 + (i % 3) * 0.25,
      phase: i * (math.pi * 2 / 16),
    ),
  );

  const _ParticlesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in _particles) {
      final y = size.height *
          (particle.baseY -
              (progress * particle.speed * 0.4) +
              math.sin(progress * math.pi * 2 + particle.phase) * 0.03);

      if (y < 0 || y > size.height) continue;

      final x = size.width * particle.x +
          math.cos(progress * math.pi * 2 + particle.phase) * 6;

      final opacity = (math.sin(progress * math.pi * 2 + particle.phase) * 0.5 + 0.5) * 0.18;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double phase;

  const _Particle({
    required this.x,
    required this.baseY,
    required this.size,
    required this.speed,
    required this.phase,
  });
}
