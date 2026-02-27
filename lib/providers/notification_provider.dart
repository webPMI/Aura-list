/// Notification providers for deadline reminders.
///
/// Provides:
/// - Notification service singleton
/// - Task deadline watcher that auto-schedules/cancels notifications
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/deadline_notification_service.dart';
import '../models/task_model.dart';
import '../models/user_preferences.dart';
import 'user_preferences_provider.dart';
import 'task_providers.dart';
import '../services/logger_service.dart';

// ==================== SERVICE PROVIDER ====================

/// Provider for deadline notification service singleton
final notificationServiceProvider = Provider<DeadlineNotificationService>((ref) {
  final service = DeadlineNotificationService();

  // Initialize on first access
  service.initialize().catchError((e) {
    final logger = LoggerService();
    logger.error(
      'NotificationProvider',
      'Failed to initialize notification service',
      metadata: {'error': e.toString()},
    );
  });

  return service;
});

// ==================== TASK DEADLINE WATCHER ====================

/// Provider that watches all tasks and auto-schedules/cancels deadline notifications
final taskDeadlineWatcherProvider = Provider<TaskDeadlineWatcher>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final watcher = TaskDeadlineWatcher(ref, service);

  // Start watching on creation
  watcher.startWatching();

  ref.onDispose(() {
    watcher.dispose();
  });

  return watcher;
});

/// Task deadline watcher
class TaskDeadlineWatcher {
  final Ref _ref;
  final DeadlineNotificationService _notificationService;
  final _logger = LoggerService();

  bool _isWatching = false;
  UserPreferences? _lastPrefs;
  final Map<String, Task> _lastTaskStates = {};

  TaskDeadlineWatcher(this._ref, this._notificationService);

  /// Start watching for task changes
  void startWatching() {
    if (_isWatching) return;
    _isWatching = true;

    _logger.info('TaskDeadlineWatcher', 'Started watching for deadline changes');

    // Watch user preferences
    _ref.listen<AsyncValue<UserPreferences>>(
      userPreferencesProvider,
      (previous, next) {
        next.whenData((prefs) {
          _handlePreferencesChange(prefs);
        });
      },
    );

    // Watch all task types
    final taskTypes = ['daily', 'weekly', 'monthly', 'yearly', 'once'];

    for (final type in taskTypes) {
      _ref.listen<AsyncValue<List<Task>>>(
        tasksByTypeProvider(type),
        (previous, next) {
          next.whenData((tasks) {
            _handleTasksChange(tasks);
          });
        },
      );
    }
  }

  /// Handle preferences change
  void _handlePreferencesChange(UserPreferences prefs) {
    final previousPrefs = _lastPrefs;
    _lastPrefs = prefs;

    // Check if notification settings changed
    if (previousPrefs != null) {
      final settingsChanged = previousPrefs.notificationsEnabled != prefs.notificationsEnabled ||
          previousPrefs.notificationDeadlineReminders != prefs.notificationDeadlineReminders ||
          previousPrefs.notificationQuietHourStart != prefs.notificationQuietHourStart ||
          previousPrefs.notificationQuietHourEnd != prefs.notificationQuietHourEnd ||
          previousPrefs.notificationHighPriorityOnly != prefs.notificationHighPriorityOnly ||
          previousPrefs.notificationSound != prefs.notificationSound ||
          previousPrefs.notificationVibration != prefs.notificationVibration ||
          _escalationDaysChanged(previousPrefs, prefs);

      if (settingsChanged) {
        _logger.info('TaskDeadlineWatcher', 'Notification settings changed, rescheduling all');
        _rescheduleAllTasks(prefs);
      }
    }
  }

  /// Handle tasks change
  void _handleTasksChange(List<Task> tasks) {
    final prefs = _lastPrefs;
    if (prefs == null) return;

    for (final task in tasks) {
      final taskId = '${task.type}_${task.key}';
      final lastState = _lastTaskStates[taskId];

      if (lastState == null) {
        // New task
        _scheduleTaskNotifications(task, prefs);
        _lastTaskStates[taskId] = task;
      } else {
        // Check if relevant fields changed
        final deadlineChanged = lastState.deadline != task.deadline;
        final completedChanged = lastState.isCompleted != task.isCompleted;
        final deletedChanged = lastState.deleted != task.deleted;
        final priorityChanged = lastState.priority != task.priority;

        if (deadlineChanged || completedChanged || deletedChanged || priorityChanged) {
          _logger.info(
            'TaskDeadlineWatcher',
            'Task ${task.title} changed, rescheduling notifications',
            metadata: {
              'deadlineChanged': deadlineChanged,
              'completedChanged': completedChanged,
              'deletedChanged': deletedChanged,
              'priorityChanged': priorityChanged,
            },
          );
          _scheduleTaskNotifications(task, prefs);
          _lastTaskStates[taskId] = task;
        }
      }
    }
  }

  /// Schedule notifications for a task
  void _scheduleTaskNotifications(Task task, UserPreferences prefs) {
    _notificationService.scheduleDeadlineNotifications(task, prefs).catchError((e) {
      _logger.error(
        'TaskDeadlineWatcher',
        'Failed to schedule notifications for task ${task.title}',
        metadata: {'error': e.toString()},
      );
    });
  }

  /// Reschedule all tasks
  void _rescheduleAllTasks(UserPreferences prefs) {
    final taskTypes = ['daily', 'weekly', 'monthly', 'yearly', 'once'];
    final allTasks = <Task>[];

    for (final type in taskTypes) {
      final tasksAsync = _ref.read(tasksByTypeProvider(type));
      tasksAsync.whenData((tasks) {
        allTasks.addAll(tasks);
      });
    }

    if (allTasks.isNotEmpty) {
      _notificationService.rescheduleAllTaskNotifications(allTasks, prefs).catchError((e) {
        _logger.error(
          'TaskDeadlineWatcher',
          'Failed to reschedule all tasks',
          metadata: {'error': e.toString()},
        );
      });

      // Clear cache to force refresh
      _lastTaskStates.clear();
    }
  }

  /// Check if escalation days changed
  bool _escalationDaysChanged(UserPreferences prev, UserPreferences current) {
    if (prev.notificationEscalationDays.length != current.notificationEscalationDays.length) {
      return true;
    }

    for (int i = 0; i < prev.notificationEscalationDays.length; i++) {
      if (prev.notificationEscalationDays[i] != current.notificationEscalationDays[i]) {
        return true;
      }
    }

    return false;
  }

  void dispose() {
    _isWatching = false;
    _lastTaskStates.clear();
    _logger.info('TaskDeadlineWatcher', 'Disposed');
  }
}

// ==================== UTILITY PROVIDERS ====================

/// Provider to get pending notification count
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final pending = await service.getPendingNotifications();
  return pending.length;
});

/// Provider to check if system notifications are enabled
final systemNotificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.areNotificationsEnabled();
});
