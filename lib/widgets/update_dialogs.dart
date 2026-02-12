import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_info.dart';
import '../services/logger_service.dart';

/// Widget to display update dialogs
class UpdateDialogs {
  /// Show a forced update dialog (cannot be dismissed)
  static Future<void> showForceUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
    String platform,
  ) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss
      builder: (context) => PopScope(
        canPop: false, // Prevent back button
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.red),
              SizedBox(width: 12),
              Text('Actualización Requerida'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  updateInfo.updateMessage ??
                      'Tu versión de AuraList está desactualizada. '
                          'Por favor actualiza a la última versión para continuar.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versión actual: ${updateInfo.currentVersion}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versión mínima requerida: ${updateInfo.minVersion}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () {
                final storeUrl = updateInfo.getStoreUrl(platform);
                if (storeUrl != null) {
                  _launchStore(storeUrl);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Actualizar Ahora'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show an optional update dialog (can be dismissed)
  static Future<void> showOptionalUpdateDialog(
    BuildContext context,
    UpdateInfo updateInfo,
    String platform,
  ) async {
    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.blue),
            SizedBox(width: 12),
            Text('Actualización Disponible'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                updateInfo.updateMessage ??
                    'Hay una nueva versión de AuraList disponible. '
                        'Actualiza para disfrutar de nuevas funciones y mejoras.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Versión actual: ${updateInfo.currentVersion}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nueva versión: ${updateInfo.latestVersion}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más Tarde'),
          ),
          FilledButton.icon(
            onPressed: () {
              final storeUrl = updateInfo.getStoreUrl(platform);
              if (storeUrl != null) {
                _launchStore(storeUrl);
              }
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.download),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  /// Launch the app store URL
  static Future<void> _launchStore(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      LoggerService().error('Widget', '[UpdateDialog] Error al abrir tienda: $e');
    }
  }

  /// Show a simple update notification (non-blocking)
  static void showUpdateSnackBar(
    BuildContext context,
    UpdateInfo updateInfo,
    String platform,
  ) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Nueva versión disponible: ${updateInfo.latestVersion}',
        ),
        action: SnackBarAction(
          label: 'Actualizar',
          onPressed: () {
            final storeUrl = updateInfo.getStoreUrl(platform);
            if (storeUrl != null) {
              _launchStore(storeUrl);
            }
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
