# AuraList - Technical Features Documentation

**Version 2.0 - Productivity Features Suite**

This document provides technical details about the three major productivity features implemented in AuraList v2.0.

---

## Table of Contents

1. [PROD-3: Smart Snooze/Deferral](#prod-3-smart-snoozedeferral)
2. [PROD-2: Task Templates](#prod-2-task-templates)
3. [PROD-1: Push Notifications & Deadline Enforcement](#prod-1-push-notifications--deadline-enforcement)
4. [Integration Points](#integration-points)
5. [Performance Considerations](#performance-considerations)

---

## PROD-3: Smart Snooze/Deferral

### Overview

Allows users to temporarily hide tasks until a specified date/time. Deferred tasks are automatically filtered from main views and reappear when the deferral period expires.

### Architecture

```
User Action (Snooze) → TaskProvider.snoozeTask()
                     ↓
            Task.updateInPlace(deferredUntil)
                     ↓
            Hive.save() (local)
                     ↓
            Firebase.sync() (async)
                     ↓
            Stream updates → activeTasksProvider
                     ↓
            UI refreshes (task hidden)
```

### Data Model

**File:** `lib/models/task_model.dart`

```dart
@HiveField(24)
DateTime? deferredUntil;

// Computed properties
bool get isDeferred =>
    deferredUntil != null && DateTime.now().isBefore(deferredUntil!);

bool get isDeferralExpired =>
    deferredUntil != null && DateTime.now().isAfter(deferredUntil!);

String get deferralStatusText {
  if (deferredUntil == null) return '';
  return 'Pospuesta hasta ${DateFormat('dd/MM HH:mm').format(deferredUntil!)}';
}
```

### Providers

**File:** `lib/providers/task_provider.dart`

```dart
// Returns non-deferred tasks for a specific type
final activeTasksProvider = Provider.autoDispose.family<List<Task>, String>(
  (ref, type) {
    final tasks = ref.watch(tasksProvider(type));
    return tasks.where((task) => !task.isDeferred).toList();
  },
);

// Returns all deferred tasks across all types
final deferredTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final allDeferred = <Task>[];
  for (final type in ['daily', 'weekly', 'monthly', 'yearly', 'once']) {
    final tasks = ref.watch(tasksProvider(type));
    allDeferred.addAll(tasks.where((t) => t.isDeferred));
  }
  allDeferred.sort((a, b) => a.deferredUntil!.compareTo(b.deferredUntil!));
  return allDeferred;
});
```

### Key Methods

**Snooze a task:**
```dart
Future<void> snoozeTask(Task task, DateTime deferredUntil) async {
  // Find original task in state
  Task? original = _findTaskInState(task);

  if (original != null && original.isInBox) {
    original.updateInPlace(
      deferredUntil: deferredUntil,
      lastUpdatedAt: DateTime.now(),
    );
    await original.save();

    // Sync to cloud
    final user = _auth.currentUser;
    if (user != null) {
      await _db.syncTaskToCloudDebounced(original, user.uid);
    }
  }
}
```

**Unsnooze a task:**
```dart
Future<void> unsnoozeTask(Task task) async {
  Task? original = _findTaskInState(task);

  if (original != null && original.isInBox) {
    original.updateInPlace(
      clearDeferredUntil: true,
      lastUpdatedAt: DateTime.now(),
    );
    await original.save();

    final user = _auth.currentUser;
    if (user != null) {
      await _db.syncTaskToCloudDebounced(original, user.uid);
    }
  }
}
```

### UI Components

**Snooze Menu:** `lib/widgets/task_tile.dart`
- Long-press menu with 6 quick options
- Custom date/time picker for flexible scheduling
- Shows current deferral status in task subtitle

**Deferred Tasks Widget:** `lib/widgets/deferred_tasks_widget.dart`
- Collapsible card showing all deferred tasks
- Groups by time category (Hoy, Mañana, Esta semana, Más tarde)
- One-tap unsnooze functionality

### Firebase Sync

**Firestore Field:**
```json
{
  "deferredUntil": "2026-03-15T14:30:00.000Z"
}
```

**Security Rules:**
```
// Existing task rules already cover deferredUntil
match /users/{userId}/tasks/{taskId} {
  allow read, write: if request.auth.uid == userId;
}
```

### Platform Support

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ Web
- ✅ Linux
- ✅ macOS

---

## PROD-2: Task Templates

### Overview

Allows users to save task configurations as reusable templates. Templates support all task fields including finance data, and track usage statistics.

### Architecture

```
User creates template → TemplateNotifier.createTemplate()
                     ↓
            TaskTemplate saved to Hive (typeId: 30)
                     ↓
            Firebase sync (users/{uid}/task_templates)
                     ↓
            Stream updates → templatesProvider
                     ↓
            UI shows in templates list

User applies template → TaskTemplate.toTask()
                     ↓
            Pre-fills task form
                     ↓
            User saves → TaskProvider.addTask()
                     ↓
            Template.usageCount++
```

### Data Model

**File:** `lib/models/task_template.dart`

```dart
@HiveType(typeId: 30)
class TaskTemplate extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String description;
  @HiveField(3) late String taskType;
  @HiveField(4) late String title;
  @HiveField(5) late String category;
  @HiveField(6) late int priority;
  @HiveField(7) String? motivation;
  @HiveField(8) String? reward;
  @HiveField(9) int? dueTimeMinutes;
  @HiveField(10) int? daysOffset; // For "once" tasks
  @HiveField(11) int? recurrenceDay;
  @HiveField(12) double? financialCost;
  @HiveField(13) double? financialBenefit;
  @HiveField(14) String? financialCategoryId;
  @HiveField(15) String? financialNote;
  @HiveField(16) late bool autoGenerateTransaction;
  @HiveField(17) String? linkedRecurringTransactionId;
  @HiveField(18) late DateTime createdAt;
  @HiveField(19) DateTime? lastUsedAt;
  @HiveField(20) late int usageCount;
  @HiveField(21) late String firestoreId;
  @HiveField(22) DateTime? lastUpdatedAt;
  @HiveField(23, defaultValue: false) late bool isPinned;
  @HiveField(24) List<String>? tags;

  Task toTask() {
    DateTime? calculatedDueDate;
    if (daysOffset != null && taskType == 'once') {
      calculatedDueDate = DateTime.now().add(Duration(days: daysOffset!));
    }

    return Task(
      title: title,
      type: taskType,
      category: category,
      priority: priority,
      motivation: motivation,
      reward: reward,
      dueTimeMinutes: dueTimeMinutes,
      dueDate: calculatedDueDate,
      recurrenceDay: recurrenceDay,
      financialCost: financialCost,
      financialBenefit: financialBenefit,
      financialCategoryId: financialCategoryId,
      financialNote: financialNote,
      autoGenerateTransaction: autoGenerateTransaction,
      linkedRecurringTransactionId: linkedRecurringTransactionId,
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }
}
```

### Providers

**File:** `lib/providers/template_provider.dart`

```dart
// All templates
final templatesProvider = StateNotifierProvider<TemplateNotifier, List<TaskTemplate>>(
  (ref) {
    final service = ref.read(templateServiceProvider);
    return TemplateNotifier(service, ref);
  },
);

// Filtered by task type
final templatesByTypeProvider = Provider.family<List<TaskTemplate>, String>(
  (ref, type) {
    final all = ref.watch(templatesProvider);
    return all.where((t) => t.taskType == type).toList();
  },
);

// Search results with sorting
final filteredTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final all = ref.watch(templatesProvider);
  final query = ref.watch(templateSearchQueryProvider).toLowerCase();

  var filtered = query.isEmpty
    ? all
    : all.where((t) => t.matchesQuery(query)).toList();

  // Sort: Pinned → Most Used → Recently Used
  filtered.sort((a, b) {
    if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
    if (a.usageCount != b.usageCount) return b.usageCount.compareTo(a.usageCount);
    return b.createdAt.compareTo(a.createdAt);
  });

  return filtered;
});
```

### Key Methods

**Create template:**
```dart
Future<void> createTemplate(TaskTemplate template) async {
  template.id = const Uuid().v4();
  template.createdAt = DateTime.now();
  template.lastUpdatedAt = DateTime.now();
  template.usageCount = 0;
  template.firestoreId = '';

  await _service.saveTemplate(template);
  await _syncToCloud(template);

  state = [...state, template];
}
```

**Use template:**
```dart
Future<Task> useTemplate(TaskTemplate template) async {
  // Increment usage count
  template.usageCount++;
  template.lastUsedAt = DateTime.now();
  template.lastUpdatedAt = DateTime.now();
  await template.save();

  // Sync updated usage count
  await _syncToCloud(template);

  // Convert to task
  return template.toTask();
}
```

### UI Components

**Templates Screen:** `lib/screens/templates_screen.dart`
- Search bar for filtering
- Template cards with metadata (type, category, usage count, pin status)
- Actions: Use, Edit, Delete, Pin/Unpin
- Empty states for no templates / no search results

**Template Form Dialog:** `lib/widgets/dialogs/template_form_dialog.dart`
- Full task configuration form
- Template name and description fields
- Finance section integration
- Create/Update modes

**Save As Template Dialog:** `lib/widgets/dialogs/save_as_template_dialog.dart`
- Quick-save after task completion
- Pre-fills from completed task data
- Smart triggering (only for interesting tasks, 33% probability)

### Firebase Sync

**Firestore Collection:**
```
users/{userId}/task_templates/{templateId}
```

**Document Structure:**
```json
{
  "name": "Weekly Groceries",
  "description": "Weekly grocery shopping",
  "taskType": "weekly",
  "title": "Go grocery shopping",
  "category": "Personal",
  "priority": 1,
  "motivation": "To have fresh food all week",
  "reward": "Cook my favorite meal",
  "dueTimeMinutes": 600,
  "financialCost": 150.0,
  "financialCategoryId": "food_groceries",
  "autoGenerateTransaction": true,
  "createdAt": "2026-02-20T10:00:00.000Z",
  "lastUsedAt": "2026-02-27T09:30:00.000Z",
  "usageCount": 12,
  "lastUpdatedAt": "2026-02-27T09:30:00.000Z",
  "isPinned": true,
  "tags": ["weekly", "essentials"]
}
```

**Security Rules:**
```
match /users/{userId}/task_templates/{templateId} {
  allow read, write: if request.auth.uid == userId;
}
```

### Platform Support

- ✅ All platforms (Hive + Firebase supported everywhere)

---

## PROD-1: Push Notifications & Deadline Enforcement

### Overview

Local push notification system that reminds users of approaching deadlines with escalating urgency levels. Includes quiet hours, priority filtering, and customizable escalation schedules.

### Architecture

```
Task with deadline created → TaskDeadlineWatcher listens
                          ↓
            DeadlineNotificationService.scheduleDeadlineNotifications()
                          ↓
            Calculate notification times (7d, 1d, 0d, overdue)
                          ↓
            Adjust for quiet hours
                          ↓
            Schedule with flutter_local_notifications
                          ↓
            [Time passes]
                          ↓
            System triggers notification at scheduled time
                          ↓
            User taps → Opens AuraList to task

Task completed → Notifications cancelled automatically
Task deleted → Notifications cancelled automatically
Deadline changed → Notifications rescheduled
```

### Data Model

**File:** `lib/models/user_preferences.dart`

```dart
@HiveField(15, defaultValue: true)
late bool notificationDeadlineReminders;

@HiveField(16, defaultValue: 22)
late int notificationQuietHourStart; // 10 PM

@HiveField(17, defaultValue: 8)
late int notificationQuietHourEnd; // 8 AM

@HiveField(18, defaultValue: false)
late bool notificationHighPriorityOnly;

@HiveField(19, defaultValue: true)
late bool notificationSound;

@HiveField(20, defaultValue: true)
late bool notificationVibration;

@HiveField(21, defaultValue: [7, 1, 0])
late List<int> notificationEscalationDays;
```

### Service

**File:** `lib/services/deadline_notification_service.dart`

```dart
class DeadlineNotificationService {
  final FlutterLocalNotificationsPlugin _notifications;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _initializeTimezones();
  }

  Future<void> scheduleDeadlineNotifications(
    Task task,
    UserPreferences prefs,
  ) async {
    if (task.deadline == null) return;
    if (!prefs.notificationDeadlineReminders) return;
    if (prefs.notificationHighPriorityOnly && task.priority != 2) return;

    // Cancel existing notifications
    await cancelTaskNotifications(task);

    final now = DateTime.now();
    final deadline = task.deadline!;

    // Schedule notifications for each escalation day
    for (final daysOffset in prefs.notificationEscalationDays) {
      final notifTime = deadline.subtract(Duration(days: daysOffset));

      if (notifTime.isAfter(now)) {
        final adjustedTime = _adjustForQuietHours(notifTime, prefs);
        final urgency = _getUrgencyLevel(daysOffset);

        await _scheduleNotification(
          id: _getNotificationId(task, daysOffset),
          title: _getNotificationTitle(urgency, daysOffset),
          body: '${task.title}\nVence el ${DateFormat('dd MMM').format(deadline)}',
          scheduledTime: adjustedTime,
          task: task,
          urgency: urgency,
        );
      }
    }

    // Schedule overdue notification (2 hours after deadline)
    final overdueTime = deadline.add(const Duration(hours: 2));
    if (overdueTime.isAfter(now)) {
      await _scheduleNotification(
        id: _getNotificationId(task, -1),
        title: '🚨 ¡Fecha límite vencida!',
        body: '${task.title}\nVenció ${_formatRelativeTime(deadline)}',
        scheduledTime: overdueTime,
        task: task,
        urgency: UrgencyLevel.critical,
      );
    }
  }

  int _getNotificationId(Task task, int daysOffset) {
    // Format: KKKKKKDD where K = task key, D = days offset
    final taskKey = task.key ?? task.createdAt.millisecondsSinceEpoch;
    return (taskKey * 100) + (daysOffset + 50);
  }

  DateTime _adjustForQuietHours(DateTime time, UserPreferences prefs) {
    final hour = time.hour;
    final quietStart = prefs.notificationQuietHourStart;
    final quietEnd = prefs.notificationQuietHourEnd;

    bool isInQuietHours = quietStart > quietEnd
      ? (hour >= quietStart || hour < quietEnd) // Spans midnight
      : (hour >= quietStart && hour < quietEnd); // Same day

    if (isInQuietHours) {
      return DateTime(time.year, time.month, time.day, quietEnd, 0);
    }

    return time;
  }

  UrgencyLevel _getUrgencyLevel(int daysRemaining) {
    if (daysRemaining < 0) return UrgencyLevel.critical;
    if (daysRemaining == 0) return UrgencyLevel.urgent;
    if (daysRemaining == 1) return UrgencyLevel.high;
    return UrgencyLevel.normal;
  }
}

enum UrgencyLevel { normal, high, urgent, critical }
```

### Providers

**File:** `lib/providers/notification_provider.dart`

```dart
final notificationServiceProvider = Provider<DeadlineNotificationService>((ref) {
  return DeadlineNotificationService();
});

final taskDeadlineWatcherProvider = Provider.autoDispose((ref) {
  final service = ref.read(notificationServiceProvider);
  final prefs = ref.watch(userPreferencesProvider);

  // Watch all task types and reschedule notifications on changes
  for (final type in ['daily', 'weekly', 'monthly', 'yearly', 'once']) {
    ref.listen<List<Task>>(
      tasksProvider(type),
      (previous, next) {
        _handleTaskChanges(service, previous ?? [], next, prefs);
      },
    );
  }

  // Watch preferences and reschedule all when changed
  ref.listen<UserPreferences>(
    userPreferencesProvider,
    (previous, next) {
      if (previous != null && _notificationSettingsChanged(previous, next)) {
        _rescheduleAllNotifications(service, next);
      }
    },
  );
});

final overdueTasksStreamProvider = Provider.autoDispose<List<Task>>((ref) {
  final allOverdue = <Task>[];

  for (final type in ['daily', 'weekly', 'monthly', 'yearly', 'once']) {
    final tasks = ref.watch(tasksProvider(type));
    allOverdue.addAll(tasks.where((t) => t.isOverdue && !t.isCompleted));
  }

  allOverdue.sort((a, b) => a.deadline!.compareTo(b.deadline!));
  return allOverdue;
});
```

### UI Components

**Notification Settings Screen:** `lib/screens/notification_settings_screen.dart`
- Permission request button
- Deadline reminders toggle
- Quiet hours time pickers
- High priority only filter
- Sound/vibration toggles
- Escalation schedule selector
- Debug info panel

**Overdue Tasks Banner:** `lib/widgets/dashboard/overdue_tasks_banner.dart`
- Red gradient warning banner
- Shows first 3 overdue tasks
- "X more..." indicator
- Tap to show full dialog
- Auto-hides when no overdue tasks

### Platform Configuration

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
    </intent-filter>
</receiver>
```

**Android:** `android/app/build.gradle.kts`
```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

**iOS:** `ios/Runner/AppDelegate.swift`
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
}
```

### Dependencies

**File:** `pubspec.yaml`
```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
```

### Notification Channels (Android)

```dart
const androidDetails = AndroidNotificationDetails(
  'deadline_reminders',
  'Deadline Reminders',
  channelDescription: 'Notifications for approaching task deadlines',
  importance: Importance.high,
  priority: Priority.high,
  sound: RawResourceAndroidNotificationSound('notification'),
  enableVibration: true,
);
```

### Platform Support

- ✅ Android (API 26+, Android 8.0+)
  - Exact alarm support for Android 12+
  - Notification channels
  - Boot receiver for rescheduling
- ✅ iOS (10+)
  - UNUserNotificationCenter
  - Badge and sound support
- ✅ Windows (10+)
  - Native toast notifications
- ✅ Linux
  - D-Bus notifications
- ✅ macOS
  - NSUserNotificationCenter

---

## Integration Points

### Cross-Feature Integration

1. **Templates + Finance:**
   - Templates save finance fields (cost, benefit, category)
   - Applying template populates finance section in task form

2. **Snooze + Notifications:**
   - Deferred tasks' notifications are NOT cancelled
   - Notifications appear even if task is deferred
   - Tapping notification unsnoozes the task

3. **Templates + Notifications:**
   - Templates can include default deadlines via daysOffset
   - Using template with deadline auto-schedules notifications

### Existing Feature Integration

**Task Finance Integration:**
- All three features support finance fields
- Snooze preserves financial data
- Templates save/restore financial configurations
- Notifications show financial impact in body (future enhancement)

**Sync System:**
- Snooze: deferredUntil syncs to Firebase
- Templates: Full document sync to Firebase
- Notifications: Preferences sync to Firebase, notifications are local-only

**Offline Mode:**
- Snooze: Works fully offline, syncs when online
- Templates: Works offline, syncs when online
- Notifications: Fully local, no network required

---

## Performance Considerations

### Database Operations

**Snooze:**
- Single field update (deferredUntil)
- In-place mutation avoids object recreation
- Debounced Firebase sync (max 1 write/second)

**Templates:**
- Separate Hive box (task_templates)
- Lazy loading (only when templates screen opened)
- Indexed by usage count for fast sorting

**Notifications:**
- Batch scheduling (all notifications for a task at once)
- Efficient ID generation (task key * 100 + offset)
- Cancel operations batched by task

### Memory Usage

**Snooze:**
- No additional memory overhead
- deferredTasksProvider filters existing task lists

**Templates:**
- ~2KB per template in memory
- Typical usage: 10-20 templates = ~40KB
- Stream-based loading prevents excessive memory use

**Notifications:**
- System-managed, not in app memory
- Notification plugin uses native APIs
- Minimal overhead (~100KB for service)

### Network Usage

**Snooze:**
- ~100 bytes per sync (single DateTime field)
- Batched with other task updates

**Templates:**
- ~1KB per template sync
- Only syncs on create/update/delete
- Batch downloads on app start

**Notifications:**
- Zero network usage (fully local)
- Preferences sync with existing user data

---

## Testing

### Unit Tests

**Snooze:**
- `task_model_test.dart`: isDeferred, isDeferralExpired getters
- `task_provider_test.dart`: snoozeTask(), unsnoozeTask() methods

**Templates:**
- `task_template_test.dart`: toTask() conversion, matchesQuery()
- `template_provider_test.dart`: CRUD operations, sorting

**Notifications:**
- `deadline_notification_service_test.dart`: Scheduling logic, quiet hours, urgency calculation

### Widget Tests

**Snooze:**
- `task_tile_test.dart`: Snooze menu, deferral status display
- `deferred_tasks_widget_test.dart`: Grouping, unsnooze action

**Templates:**
- `templates_screen_test.dart`: Template list, search, actions
- `template_form_dialog_test.dart`: Form validation, save

**Notifications:**
- `notification_settings_screen_test.dart`: Settings UI, permission request
- `overdue_tasks_banner_test.dart`: Banner display, tap action

### Integration Tests

- Task creation with all three features combined
- Offline/online sync scenarios
- Permission grant/deny flows
- Multi-device sync scenarios

---

**Version:** 2.0
**Last Updated:** February 2026
**Authors:** Multi-Agent Implementation Team
