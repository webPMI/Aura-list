/// Deadline notification service for task deadline reminders.
///
/// This service manages local notifications for task deadlines with:
/// - Escalating urgency levels (normal, high, urgent, critical)
/// - Quiet hours support
/// - Priority filtering
/// - Sound and vibration settings
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';
import '../models/user_preferences.dart';
import 'logger_service.dart';

/// Urgency level for deadline notifications
enum UrgencyLevel {
  normal, // 7 days before
  high, // 1 day before
  urgent, // Day of deadline
  critical, // Overdue
}

/// Deadline notification service
class DeadlineNotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final _logger = LoggerService();
  bool _initialized = false;

  DeadlineNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notifications = notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Get local timezone
      final locationName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
      } catch (e) {
        // Fallback to UTC if timezone not found
        _logger.warning(
          'DeadlineNotificationService',
          'Could not set timezone $locationName, using UTC',
        );
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Don't request on init
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Linux initialization settings
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      _logger.info('DeadlineNotificationService', 'Initialized successfully');
    } catch (e, stack) {
      _logger.error(
        'DeadlineNotificationService',
        'Failed to initialize',
        metadata: {'error': e.toString(), 'stack': stack.toString()},
      );
      rethrow;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info(
      'DeadlineNotificationService',
      'Notification tapped',
      metadata: {'payload': response.payload},
    );
    // TODO: Navigate to task detail screen when tapped
  }

  /// Request notification permissions (call from settings screen)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Request exact alarm permission for Android 13+
        final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();

        // Request notification permission for Android 13+
        final notificationGranted = await androidPlugin.requestNotificationsPermission();

        return exactAlarmGranted == true && notificationGranted == true;
      }
      return true; // For older Android versions
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted == true;
      }
    } else if (Platform.isMacOS) {
      final macOSPlugin = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();

      if (macOSPlugin != null) {
        final granted = await macOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted == true;
      }
    }
    return true; // For other platforms
  }

  /// Schedule deadline notifications for a task
  Future<void> scheduleDeadlineNotifications(
    Task task,
    UserPreferences prefs,
  ) async {
    if (!_initialized) {
      _logger.warning(
        'DeadlineNotificationService',
        'Cannot schedule notification: service not initialized',
      );
      return;
    }

    // Check if notifications are enabled
    if (!prefs.notificationsEnabled || !prefs.notificationDeadlineReminders) {
      return;
    }

    // Check if task has a deadline
    if (task.deadline == null) {
      return;
    }

    // Check if task is completed or deleted
    if (task.isCompleted || task.deleted) {
      await cancelTaskNotifications(task);
      return;
    }

    // Check priority filter
    if (prefs.notificationHighPriorityOnly && task.priority < 2) {
      return;
    }

    try {
      // Cancel existing notifications for this task
      await cancelTaskNotifications(task);

      final deadline = task.deadline!;
      final now = DateTime.now();

      // Schedule notifications for each escalation day
      for (final daysBeforeDeadline in prefs.notificationEscalationDays) {
        final notificationDate = deadline.subtract(Duration(days: daysBeforeDeadline));

        // Skip if notification date is in the past
        if (notificationDate.isBefore(now)) {
          continue;
        }

        // Adjust for quiet hours
        final adjustedDate = _adjustForQuietHours(notificationDate, prefs);

        // Calculate urgency level
        final urgencyLevel = _getUrgencyLevel(daysBeforeDeadline);

        // Generate notification ID (task key + days before)
        final notificationId = _generateNotificationId(task, daysBeforeDeadline);

        // Schedule notification
        await _scheduleNotification(
          id: notificationId,
          task: task,
          scheduledDate: adjustedDate,
          urgencyLevel: urgencyLevel,
          daysRemaining: daysBeforeDeadline,
          prefs: prefs,
        );

        _logger.info(
          'DeadlineNotificationService',
          'Scheduled notification for task ${task.title}',
          metadata: {
            'notificationId': notificationId,
            'scheduledDate': adjustedDate.toIso8601String(),
            'urgencyLevel': urgencyLevel.name,
          },
        );
      }

      // Schedule overdue notification if deadline has passed
      if (deadline.isBefore(now) && !task.isCompleted) {
        final notificationId = _generateNotificationId(task, -1);
        await _scheduleNotification(
          id: notificationId,
          task: task,
          scheduledDate: now.add(const Duration(seconds: 5)), // Schedule 5 seconds from now
          urgencyLevel: UrgencyLevel.critical,
          daysRemaining: -1,
          prefs: prefs,
        );
      }
    } catch (e, stack) {
      _logger.error(
        'DeadlineNotificationService',
        'Failed to schedule notifications for task ${task.title}',
        metadata: {'error': e.toString(), 'stack': stack.toString()},
      );
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required Task task,
    required DateTime scheduledDate,
    required UrgencyLevel urgencyLevel,
    required int daysRemaining,
    required UserPreferences prefs,
  }) async {
    final title = _getNotificationTitle(urgencyLevel, daysRemaining);
    final body = task.title;

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'deadline_reminders',
      'Recordatorios de fecha límite',
      channelDescription: 'Notificaciones para fechas límite de tareas',
      importance: _getAndroidImportance(urgencyLevel),
      priority: _getAndroidPriority(urgencyLevel),
      color: _getUrgencyColor(urgencyLevel),
      playSound: prefs.notificationSound,
      enableVibration: prefs.notificationVibration,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: prefs.notificationSound,
      sound: prefs.notificationSound ? 'default' : null,
    );

    // Linux notification details
    const linuxDetails = LinuxNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    // Convert to TZDateTime
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Schedule notification
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task_${task.key}',
    );
  }

  /// Cancel all notifications for a task
  Future<void> cancelTaskNotifications(Task task) async {
    if (!_initialized) return;

    try {
      // Cancel notifications for all possible escalation days
      final allPossibleDays = [-1, 0, 1, 2, 3, 7, 14, 30];

      for (final days in allPossibleDays) {
        final notificationId = _generateNotificationId(task, days);
        await _notifications.cancel(notificationId);
      }

      _logger.info(
        'DeadlineNotificationService',
        'Cancelled notifications for task ${task.title}',
      );
    } catch (e) {
      _logger.error(
        'DeadlineNotificationService',
        'Failed to cancel notifications for task ${task.title}',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    try {
      await _notifications.cancelAll();
      _logger.info('DeadlineNotificationService', 'Cancelled all notifications');
    } catch (e) {
      _logger.error(
        'DeadlineNotificationService',
        'Failed to cancel all notifications',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Reschedule notifications for all tasks
  Future<void> rescheduleAllTaskNotifications(
    List<Task> tasks,
    UserPreferences prefs,
  ) async {
    if (!_initialized) return;

    _logger.info(
      'DeadlineNotificationService',
      'Rescheduling notifications for ${tasks.length} tasks',
    );

    // Cancel all existing notifications first
    await cancelAllNotifications();

    // Schedule notifications for each task
    for (final task in tasks) {
      if (task.deadline != null && !task.isCompleted && !task.deleted) {
        await scheduleDeadlineNotifications(task, prefs);
      }
    }
  }

  /// Adjust notification time for quiet hours
  DateTime _adjustForQuietHours(DateTime date, UserPreferences prefs) {
    final hour = date.hour;
    final quietStart = prefs.notificationQuietHourStart;
    final quietEnd = prefs.notificationQuietHourEnd;

    // Check if in quiet hours
    bool inQuietHours;
    if (quietStart < quietEnd) {
      // Normal range (e.g., 22:00 to 08:00 next day is represented as 22 to 8)
      // But since we're comparing hours, we need to handle the day boundary
      inQuietHours = hour >= quietStart || hour < quietEnd;
    } else {
      // Range spans midnight (e.g., 08:00 to 22:00 would be represented as 8 to 22)
      inQuietHours = hour >= quietStart && hour < quietEnd;
    }

    if (inQuietHours) {
      // Move notification to end of quiet hours
      return DateTime(
        date.year,
        date.month,
        date.day,
        quietEnd,
        0,
      );
    }

    return date;
  }

  /// Get urgency level based on days remaining
  UrgencyLevel _getUrgencyLevel(int daysRemaining) {
    if (daysRemaining < 0) return UrgencyLevel.critical;
    if (daysRemaining == 0) return UrgencyLevel.urgent;
    if (daysRemaining == 1) return UrgencyLevel.high;
    return UrgencyLevel.normal;
  }

  /// Get notification title based on urgency
  String _getNotificationTitle(UrgencyLevel level, int daysRemaining) {
    switch (level) {
      case UrgencyLevel.critical:
        return '🚨 ¡Fecha límite vencida!';
      case UrgencyLevel.urgent:
        return '⚠️ ¡Fecha límite HOY!';
      case UrgencyLevel.high:
        return '⏰ Fecha límite mañana';
      case UrgencyLevel.normal:
        if (daysRemaining == 7) {
          return '📅 Fecha límite en 1 semana';
        }
        return '📅 Fecha límite en $daysRemaining días';
    }
  }

  /// Get urgency color
  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
        return Colors.red.shade900;
      case UrgencyLevel.urgent:
        return Colors.red.shade700;
      case UrgencyLevel.high:
        return Colors.orange.shade700;
      case UrgencyLevel.normal:
        return Colors.blue.shade700;
    }
  }

  /// Get Android importance level
  Importance _getAndroidImportance(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
      case UrgencyLevel.urgent:
        return Importance.max;
      case UrgencyLevel.high:
        return Importance.high;
      case UrgencyLevel.normal:
        return Importance.defaultImportance;
    }
  }

  /// Get Android priority
  Priority _getAndroidPriority(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical:
      case UrgencyLevel.urgent:
        return Priority.max;
      case UrgencyLevel.high:
        return Priority.high;
      case UrgencyLevel.normal:
        return Priority.defaultPriority;
    }
  }

  /// Generate unique notification ID for a task and escalation day
  int _generateNotificationId(Task task, int daysBeforeDeadline) {
    // Use task key (Hive index) and days to generate unique ID
    // Format: KKKKKKDD where K is task key (6 digits) and D is days (2 digits)
    final taskKey = task.key ?? 0;
    final daysOffset = daysBeforeDeadline + 50; // Add 50 to handle negative days
    return (taskKey * 100) + daysOffset;
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled at system level
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS/macOS don't have a reliable way to check this
      return true;
    }

    return true;
  }
}
