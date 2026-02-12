import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/features/guides/guides.dart';
import 'package:checklist_app/providers/day_cycle_provider.dart';

/// Widget que muestra un mensaje de despedida del guia al final del dia.
///
/// Aparece como un overlay calmante con animacion suave.
/// Se cierra automaticamente despues de 5 segundos o al tocar.
class GuideFarewellWidget extends ConsumerStatefulWidget {
  /// Callback opcional cuando se cierra el mensaje.
  final VoidCallback? onDismiss;

  const GuideFarewellWidget({
    super.key,
    this.onDismiss,
  });

  @override
  ConsumerState<GuideFarewellWidget> createState() =>
      _GuideFarewellWidgetState();
}

class _GuideFarewellWidgetState extends ConsumerState<GuideFarewellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  static const _autoDismissSeconds = 5;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Iniciar animacion de entrada
    _animationController.forward();

    // Iniciar timer de auto-cierre
    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer = Timer(
      const Duration(seconds: _autoDismissSeconds),
      _dismiss,
    );
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();

    // Animar salida
    await _animationController.reverse();

    // Marcar como mostrado
    await ref.read(farewellVisibilityProvider.notifier).dismiss();

    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(activeGuideProvider);
    final message = ref.watch(guideMessageProvider(GuideVoiceMoment.endOfDay));
    final guideColor = ref.watch(guidePrimaryColorProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = guideColor ?? colorScheme.primary;

    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
              child: SafeArea(
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildContent(
                        context,
                        guide: guide,
                        message: message,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Guide? guide,
    required String? message,
    required Color primaryColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(32),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            colorScheme.surface,
            colorScheme.surface,
            primaryColor.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de luna/estrellas para indicar noche
          _buildNightIcon(primaryColor),
          const SizedBox(height: 24),

          // Avatar del guia si existe
          if (guide != null) ...[
            GuideAvatar(
              guide: guide,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              guide.name,
              style: textTheme.titleMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Mensaje de despedida
          Text(
            message ?? 'Descansa bien. Manana sera un nuevo dia.',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Mensaje adicional calmante
          Text(
            'Buenas noches',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Indicador de toque para cerrar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Text(
                'Toca para cerrar',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNightIcon(Color primaryColor) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Luna
          Icon(
            Icons.nightlight_round,
            size: 48,
            color: primaryColor.withValues(alpha: 0.8),
          ),
          // Estrellas decorativas
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.star,
              size: 16,
              color: primaryColor.withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            top: 8,
            left: 4,
            child: Icon(
              Icons.star,
              size: 12,
              color: primaryColor.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.star,
              size: 10,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra el overlay de despedida del guia si las condiciones lo permiten.
///
/// Uso:
/// ```dart
/// await showGuideFarewellOverlay(context: context, ref: ref);
/// ```
Future<void> showGuideFarewellOverlay({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final shouldShow = await ref.read(shouldShowFarewellProvider.future);

  if (!shouldShow) return;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => const GuideFarewellWidget(),
  );
}

/// Widget listener que detecta cuando mostrar el mensaje de despedida.
///
/// Envuelve el contenido de la app y escucha los triggers de despedida.
///
/// Uso:
/// ```dart
/// GuideFarewellListener(
///   child: MyAppContent(),
/// )
/// ```
class GuideFarewellListener extends ConsumerStatefulWidget {
  final Widget child;

  const GuideFarewellListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GuideFarewellListener> createState() =>
      _GuideFarewellListenerState();
}

class _GuideFarewellListenerState extends ConsumerState<GuideFarewellListener> {
  @override
  void initState() {
    super.initState();
    // Verificar al iniciar si debemos mostrar el farewell
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialFarewell();
    });
  }

  Future<void> _checkInitialFarewell() async {
    final service = ref.read(dayCycleServiceProvider);
    await service.checkAndTriggerFarewell();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar triggers de despedida
    ref.listen<AsyncValue<void>>(farewellTriggerProvider, (previous, next) {
      next.whenData((_) {
        _showFarewell();
      });
    });

    // Escuchar cambios en visibilidad (para testing manual)
    final isVisible = ref.watch(farewellVisibilityProvider);

    return Stack(
      children: [
        widget.child,
        if (isVisible)
          Positioned.fill(
            child: GuideFarewellWidget(
              onDismiss: () {
                // Ya se maneja en el widget
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showFarewell() async {
    await ref.read(farewellVisibilityProvider.notifier).showIfAllowed();
  }
}
