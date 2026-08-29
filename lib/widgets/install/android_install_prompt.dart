import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Banner flotante para ofrecer la instalación directa de la PWA
class AndroidInstallPrompt extends StatefulWidget {
  final Widget? child;

  const AndroidInstallPrompt({
    super.key,
    this.child,
  });

  @override
  State<AndroidInstallPrompt> createState() => _AndroidInstallPromptState();
}

class _AndroidInstallPromptState extends State<AndroidInstallPrompt> {
  bool _isVisible = false;
  static const String _prefDismissKey = 'android_install_prompt_dismissed_at';

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    if (!kIsWeb) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissed = prefs.getInt(_prefDismissKey);
      if (lastDismissed != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastDismissed);
        final difference = DateTime.now().difference(lastDate).inDays;
        if (difference < 7) {
          return;
        }
      }

      if (mounted) {
        setState(() => _isVisible = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    }
  }

  Future<void> _dismissPrompt() async {
    setState(() => _isVisible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefDismissKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _handlePwaInstall() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.install_mobile_rounded, color: Colors.indigo, size: 40),
        title: const Text(
          'Instalar AuraList',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instala la aplicación directamente en tu pantalla de inicio sin descargas pesadas:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildInstallStep(
              number: '1',
              title: 'Abre el menú del navegador',
              desc: 'Toca los tres puntos (⋮) en Android o el botón Compartir (⎙) en iPhone.',
            ),
            const SizedBox(height: 12),
            _buildInstallStep(
              number: '2',
              title: 'Añadir a pantalla de inicio',
              desc: 'Selecciona "Instalar aplicación" o "Añadir a pantalla de inicio".',
            ),
            const SizedBox(height: 12),
            _buildInstallStep(
              number: '3',
              title: '¡Listo para usar!',
              desc: 'Tendrás AuraList con icono propio, pantalla completa y modo 100% offline.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _dismissPrompt();
            },
            child: const Text('¡Entendido!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallStep({
    required String number,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.indigo.shade900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return widget.child ?? const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surfaceContainerHighest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instala AuraList en tu pantalla de inicio',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Acceso instantáneo, pantalla completa y modo 100% offline.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        onPressed: _dismissPrompt,
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _dismissPrompt,
                        child: const Text('Ahora no', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _handlePwaInstall,
                        icon: const Icon(Icons.install_mobile_rounded, size: 14),
                        label: const Text('Instalar App Gratis', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
