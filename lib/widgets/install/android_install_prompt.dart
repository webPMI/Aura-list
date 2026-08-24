import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL de descarga de APK oficial o repositorio
const String kAndroidApkDownloadUrl = 'https://github.com/webPMI/Aura-list/releases';

/// Banner flotante para detectar usuarios en Android Web y ofrecer la instalación/descarga
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
    // Solo mostramos si está en la Web y desde un dispositivo Android
    if (!kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissed = prefs.getInt(_prefDismissKey);
      if (lastDismissed != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastDismissed);
        final difference = DateTime.now().difference(lastDate).inDays;
        // Si el usuario cerró el banner hace menos de 7 días, no mostramos
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
    // Mostrar diálogo explicativo o instrucciones nativas
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.install_mobile_rounded, color: Colors.green, size: 36),
        title: const Text('Instalar AuraList'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para instalar AuraList en tu pantalla de inicio en Android:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('Toca los tres puntos (⋮) en la esquina superior del navegador.'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('Selecciona "Instalar aplicación" o "Añadir a la pantalla de inicio".'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('¡Listo! Tendrás la app con icono nativo y modo offline.'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadApk() async {
    final uri = Uri.parse(kAndroidApkDownloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error al abrir URL de descarga APK: $e');
    }
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
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.android_rounded,
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
                              'Instala AuraList en tu Android',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Acceso rápido, modo 100% offline y pantalla completa.',
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
                      OutlinedButton.icon(
                        onPressed: _handleDownloadApk,
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: const Text('Descargar APK', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _handlePwaInstall,
                        icon: const Icon(Icons.install_mobile_rounded, size: 14),
                        label: const Text('Instalar App', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
