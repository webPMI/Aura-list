import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'error_handler.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  /// Request notification permission with explanation dialog
  /// Shows a friendly dialog explaining why we need the permission
  Future<bool> requestNotificationPermission(BuildContext context) async {
    // First check if already granted
    final currentStatus = await Permission.notification.status;
    if (currentStatus.isGranted) return true;

    // Show explanation dialog before system popup
    final shouldRequest = await _showPermissionDialog(
      // ignore: use_build_context_synchronously
      context,
      title: 'Notificaciones',
      description:
          'AuraList puede enviarte recordatorios para tus tareas y celebrar '
          'tus logros. Las notificaciones te ayudan a mantener el enfoque '
          'sin tener que abrir la app constantemente.',
      icon: Icons.notifications_outlined,
      benefitsList: [
        'Recordatorios de tareas pendientes',
        'Celebraciones al completar metas',
        'Avisos de fechas limite',
      ],
    );

    if (shouldRequest != true) return false;

    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.unknown,
        severity: ErrorSeverity.warning,
        message: 'PermissionService.requestNotificationPermission',
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Request calendar permission with explanation dialog
  Future<bool> requestCalendarPermission(BuildContext context) async {
    // First check if already granted
    final currentStatus = await Permission.calendarFullAccess.status;
    if (currentStatus.isGranted) return true;

    // Show explanation dialog
    final shouldRequest = await _showPermissionDialog(
      // ignore: use_build_context_synchronously
      context,
      title: 'Calendario',
      description:
          'Sincroniza tus tareas con el calendario de tu dispositivo '
          'para tener una vista completa de tu agenda en un solo lugar.',
      icon: Icons.calendar_today_outlined,
      benefitsList: [
        'Ver tareas junto con tus eventos',
        'Evitar conflictos de horarios',
        'Mejor planificacion del dia',
      ],
    );

    if (shouldRequest != true) return false;

    try {
      final status = await Permission.calendarFullAccess.request();
      return status.isGranted;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.unknown,
        severity: ErrorSeverity.warning,
        message: 'PermissionService.requestCalendarPermission',
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Check if notification permission is granted
  Future<bool> get hasNotificationPermission async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if calendar permission is granted
  Future<bool> get hasCalendarPermission async {
    final status = await Permission.calendarFullAccess.status;
    return status.isGranted;
  }

  /// Open app settings for manual permission granting
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Show permission explanation dialog
  Future<bool?> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<String> benefitsList,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 48, color: colorScheme.primary),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              'Beneficios:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...benefitsList.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(benefit, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when permission is permanently denied
  Future<bool?> showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.block_outlined, size: 48, color: Colors.orange),
        title: const Text('Permiso denegado'),
        content: Text(
          'El permiso de $permissionName fue denegado. '
          'Puedes habilitarlo manualmente en la configuracion de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await openSettings();
            },
            child: const Text('Ir a configuracion'),
          ),
        ],
      ),
    );
  }
}
