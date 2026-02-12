import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist_app/features/guides/guides.dart';

/// Key para almacenar la ultima fecha en que se mostro el saludo
const _kLastGreetingDateKey = 'last_guide_greeting_date';

/// Widget overlay que muestra un saludo del guia activo al abrir la app.
/// Se muestra una vez al dia por sesion.
class GuideGreetingWidget extends ConsumerStatefulWidget {
  const GuideGreetingWidget({super.key});

  @override
  ConsumerState<GuideGreetingWidget> createState() => _GuideGreetingWidgetState();
}

class _GuideGreetingWidgetState extends ConsumerState<GuideGreetingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isVisible = false;
  bool _hasCheckedToday = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _checkAndShowGreeting();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Verifica si se debe mostrar el saludo hoy
  Future<void> _checkAndShowGreeting() async {
    if (_hasCheckedToday) return;
    _hasCheckedToday = true;

    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_kLastGreetingDateKey);
    final today = _formatDate(DateTime.now());

    // Si ya se mostro hoy, no mostrar de nuevo
    if (lastDateStr == today) {
      return;
    }

    // Verificar si hay un guia activo
    final guide = ref.read(activeGuideProvider);
    if (guide == null) {
      return;
    }

    // Marcar como mostrado hoy
    await prefs.setString(_kLastGreetingDateKey, today);

    // Mostrar el saludo
    if (mounted) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();

      // Auto-dismiss despues de 4 segundos
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _isVisible) {
          _dismiss();
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final guide = ref.watch(activeGuideProvider);
    final message = ref.watch(guideMessageProvider(GuideVoiceMoment.appOpening));

    if (guide == null || message == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final guideColor = ref.watch(guideAccentColorProvider) ?? colorScheme.primary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerHigh,
                  shadowColor: guideColor.withValues(alpha: 0.3),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: guideColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar del guia
                        GuideAvatar(
                          guide: guide,
                          size: 48,
                          showBorder: true,
                        ),
                        const SizedBox(width: 12),
                        // Mensaje del guia
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                guide.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: guideColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Boton de cerrar
                        IconButton(
                          onPressed: _dismiss,
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra el saludo del guia como un overlay.
/// Debe ser llamado desde un widget que tenga acceso al context del Navigator.
void showGuideGreeting(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _GuideGreetingOverlay(
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

/// Widget interno para el overlay del saludo
class _GuideGreetingOverlay extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const _GuideGreetingOverlay({required this.onDismiss});

  @override
  ConsumerState<_GuideGreetingOverlay> createState() => _GuideGreetingOverlayState();
}

class _GuideGreetingOverlayState extends ConsumerState<_GuideGreetingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-dismiss despues de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(activeGuideProvider);
    final message = ref.watch(guideMessageProvider(GuideVoiceMoment.appOpening));

    if (guide == null || message == null) {
      // Si no hay guia o mensaje, remover inmediatamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDismiss();
      });
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final guideColor = ref.watch(guideAccentColorProvider) ?? colorScheme.primary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerHigh,
                  shadowColor: guideColor.withValues(alpha: 0.3),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: guideColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar del guia
                        GuideAvatar(
                          guide: guide,
                          size: 48,
                          showBorder: true,
                        ),
                        const SizedBox(width: 12),
                        // Mensaje del guia
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                guide.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: guideColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Boton de cerrar
                        IconButton(
                          onPressed: _dismiss,
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Funcion helper para verificar si se debe mostrar el saludo y mostrarlo
/// Retorna true si se mostro el saludo, false si no
Future<bool> checkAndShowGuideGreeting(BuildContext context, WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final lastDateStr = prefs.getString(_kLastGreetingDateKey);
  final today = _formatDateHelper(DateTime.now());

  // Si ya se mostro hoy, no mostrar de nuevo
  if (lastDateStr == today) {
    return false;
  }

  // Verificar si hay un guia activo
  final guide = ref.read(activeGuideProvider);
  if (guide == null) {
    return false;
  }

  // Marcar como mostrado hoy
  await prefs.setString(_kLastGreetingDateKey, today);

  // Mostrar el saludo
  if (context.mounted) {
    showGuideGreeting(context);
    return true;
  }

  return false;
}

String _formatDateHelper(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
