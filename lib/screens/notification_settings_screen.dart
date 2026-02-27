/// Notification settings screen for configuring deadline reminders.
///
/// Allows users to:
/// - Enable/disable notifications
/// - Configure quiet hours
/// - Set high priority filter
/// - Configure sound and vibration
/// - Customize escalation schedule
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../services/database_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Notificaciones'),
        elevation: 0,
      ),
      body: prefsAsync.when(
        data: (prefs) => _buildSettings(context, theme, prefs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    ThemeData theme,
    prefs,
  ) {
    return ListView(
      children: [
        // Enable notifications
        SwitchListTile(
          title: const Text('Habilitar notificaciones'),
          subtitle: const Text('Permite que la app envíe notificaciones'),
          value: prefs.notificationsEnabled,
          onChanged: (value) async {
            if (value) {
              // Request permissions first
              await _requestNotificationPermissions();
            } else {
              // Just disable
              await _updatePreference(
                notificationsEnabled: false,
              );
            }
          },
        ),

        const Divider(),

        // Deadline reminders section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recordatorios de Fecha Límite',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SwitchListTile(
          title: const Text('Recordatorios de fechas límite'),
          subtitle: const Text('Notificar antes de vencer una tarea'),
          value: prefs.notificationDeadlineReminders,
          onChanged: prefs.notificationsEnabled
              ? (value) => _updatePreference(
                    notificationDeadlineReminders: value,
                  )
              : null,
        ),

        SwitchListTile(
          title: const Text('Solo tareas de alta prioridad'),
          subtitle: const Text('Notificar únicamente tareas importantes'),
          value: prefs.notificationHighPriorityOnly,
          onChanged: prefs.notificationsEnabled
              ? (value) => _updatePreference(
                    notificationHighPriorityOnly: value,
                  )
              : null,
        ),

        const Divider(),

        // Alert preferences
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Preferencias de Alerta',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SwitchListTile(
          title: const Text('Sonido'),
          subtitle: const Text('Reproducir sonido de notificación'),
          value: prefs.notificationSound,
          onChanged: prefs.notificationsEnabled
              ? (value) => _updatePreference(
                    notificationSound: value,
                  )
              : null,
        ),

        SwitchListTile(
          title: const Text('Vibración'),
          subtitle: const Text('Vibrar al recibir notificación'),
          value: prefs.notificationVibration,
          onChanged: prefs.notificationsEnabled
              ? (value) => _updatePreference(
                    notificationVibration: value,
                  )
              : null,
        ),

        const Divider(),

        // Quiet hours
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Horas Silenciosas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListTile(
          title: const Text('Inicio de horas silenciosas'),
          subtitle: Text(_formatHour(prefs.notificationQuietHourStart)),
          trailing: const Icon(Icons.access_time),
          enabled: prefs.notificationsEnabled,
          onTap: () => _selectQuietHourStart(prefs),
        ),

        ListTile(
          title: const Text('Fin de horas silenciosas'),
          subtitle: Text(_formatHour(prefs.notificationQuietHourEnd)),
          trailing: const Icon(Icons.access_time),
          enabled: prefs.notificationsEnabled,
          onTap: () => _selectQuietHourEnd(prefs),
        ),

        const Divider(),

        // Escalation schedule
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Calendario de Recordatorios',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListTile(
          title: const Text('Días de notificación'),
          subtitle: Text(_formatEscalationDays(prefs.notificationEscalationDays)),
          trailing: const Icon(Icons.edit),
          enabled: prefs.notificationsEnabled,
          onTap: () => _editEscalationDays(prefs),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Días antes de la fecha límite para enviar recordatorios.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),

        const Divider(),

        // Debug info
        if (prefs.notificationsEnabled) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Información',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDebugInfo(),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDebugInfo() {
    final pendingAsync = ref.watch(pendingNotificationCountProvider);
    final systemEnabledAsync = ref.watch(systemNotificationsEnabledProvider);

    return Column(
      children: [
        ListTile(
          title: const Text('Notificaciones pendientes'),
          trailing: pendingAsync.when(
            data: (count) => Text('$count'),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('Error'),
          ),
        ),
        ListTile(
          title: const Text('Estado del sistema'),
          trailing: systemEnabledAsync.when(
            data: (enabled) => Icon(
              enabled ? Icons.check_circle : Icons.error,
              color: enabled ? Colors.green : Colors.red,
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      final granted = await notificationService.requestPermissions();

      if (granted) {
        await _updatePreference(notificationsEnabled: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de notificación concedidos'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de notificación denegados'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error already handled above
    }
  }

  Future<void> _updatePreference({
    bool? notificationsEnabled,
    bool? notificationDeadlineReminders,
    bool? notificationHighPriorityOnly,
    bool? notificationSound,
    bool? notificationVibration,
    int? notificationQuietHourStart,
    int? notificationQuietHourEnd,
    List<int>? notificationEscalationDays,
  }) async {
    final db = ref.read(databaseServiceProvider);
    final currentPrefs = await db.getUserPreferences();

    final updatedPrefs = currentPrefs.copyWith(
      notificationsEnabled: notificationsEnabled,
      notificationDeadlineReminders: notificationDeadlineReminders,
      notificationHighPriorityOnly: notificationHighPriorityOnly,
      notificationSound: notificationSound,
      notificationVibration: notificationVibration,
      notificationQuietHourStart: notificationQuietHourStart,
      notificationQuietHourEnd: notificationQuietHourEnd,
      notificationEscalationDays: notificationEscalationDays,
    );

    await db.updateUserPreferences(updatedPrefs);
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  String _formatEscalationDays(List<int> days) {
    if (days.isEmpty) return 'Ninguno';
    final sorted = List<int>.from(days)..sort((a, b) => b.compareTo(a));
    return sorted.map((d) => d == 0 ? 'El día' : '$d días antes').join(', ');
  }

  Future<void> _selectQuietHourStart(prefs) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.notificationQuietHourStart, minute: 0),
      helpText: 'Seleccionar inicio de horas silenciosas',
    );

    if (time != null) {
      await _updatePreference(notificationQuietHourStart: time.hour);
    }
  }

  Future<void> _selectQuietHourEnd(prefs) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.notificationQuietHourEnd, minute: 0),
      helpText: 'Seleccionar fin de horas silenciosas',
    );

    if (time != null) {
      await _updatePreference(notificationQuietHourEnd: time.hour);
    }
  }

  Future<void> _editEscalationDays(prefs) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => _EscalationDaysDialog(
        currentDays: prefs.notificationEscalationDays,
      ),
    );

    if (result != null) {
      await _updatePreference(notificationEscalationDays: result);
    }
  }
}

class _EscalationDaysDialog extends StatefulWidget {
  final List<int> currentDays;

  const _EscalationDaysDialog({required this.currentDays});

  @override
  State<_EscalationDaysDialog> createState() => _EscalationDaysDialogState();
}

class _EscalationDaysDialogState extends State<_EscalationDaysDialog> {
  late Set<int> selectedDays;

  final availableDays = [0, 1, 2, 3, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    selectedDays = Set<int>.from(widget.currentDays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Días de Notificación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableDays.map((day) {
            return CheckboxListTile(
              title: Text(_getDayLabel(day)),
              value: selectedDays.contains(day),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    selectedDays.add(day);
                  } else {
                    selectedDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final result = selectedDays.toList()..sort((a, b) => b.compareTo(a));
            Navigator.pop(context, result);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _getDayLabel(int day) {
    if (day == 0) return 'El día de la fecha límite';
    if (day == 1) return '1 día antes';
    return '$day días antes';
  }
}
