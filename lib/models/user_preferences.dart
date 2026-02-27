import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 4)
class UserPreferences extends HiveObject {
  @HiveField(0)
  late String odId; // Local identifier

  @HiveField(1)
  late bool hasAcceptedTerms;

  @HiveField(2)
  late bool hasAcceptedPrivacy;

  @HiveField(3)
  DateTime? termsAcceptedAt;

  @HiveField(4)
  DateTime? privacyAcceptedAt;

  @HiveField(5)
  late bool notificationsEnabled;

  @HiveField(6)
  late bool calendarSyncEnabled;

  @HiveField(7)
  DateTime? lastSyncTimestamp;

  @HiveField(8)
  late Map<String, String> collectionLastSync; // Per-collection sync timestamps as ISO strings

  @HiveField(9)
  late bool syncOnMobileData;

  @HiveField(10)
  late int syncDebounceMs;

  @HiveField(11)
  late bool cloudSyncEnabled;

  @HiveField(12)
  late String firestoreId; // Firestore document ID for cloud sync

  @HiveField(13)
  DateTime? lastUpdatedAt; // For conflict resolution

  /// Day of week designated as rest day (1=Monday, 7=Sunday, null=none)
  /// On rest days, tasks are optional and streaks won't break if nothing is completed
  @HiveField(14)
  int? restDayOfWeek;

  /// Enable deadline reminders for tasks
  @HiveField(15, defaultValue: true)
  late bool notificationDeadlineReminders;

  /// Quiet hour start (hour 0-23, default 22 = 10PM)
  @HiveField(16, defaultValue: 22)
  late int notificationQuietHourStart;

  /// Quiet hour end (hour 0-23, default 8 = 8AM)
  @HiveField(17, defaultValue: 8)
  late int notificationQuietHourEnd;

  /// Only notify for high priority tasks
  @HiveField(18, defaultValue: false)
  late bool notificationHighPriorityOnly;

  /// Enable notification sound
  @HiveField(19, defaultValue: true)
  late bool notificationSound;

  /// Enable notification vibration
  @HiveField(20, defaultValue: true)
  late bool notificationVibration;

  /// Days before deadline to send escalating reminders (default: 7, 1, 0 days)
  @HiveField(21)
  late List<int> notificationEscalationDays;

  UserPreferences({
    this.odId = 'default',
    this.hasAcceptedTerms = false,
    this.hasAcceptedPrivacy = false,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.notificationsEnabled = false,
    this.calendarSyncEnabled = false,
    this.lastSyncTimestamp,
    Map<String, String>? collectionLastSync,
    this.syncOnMobileData = true,
    this.syncDebounceMs = 3000,
    this.cloudSyncEnabled = true, // Enable by default - sync requires auth anyway
    String? firestoreId,
    this.lastUpdatedAt,
    this.restDayOfWeek,
    this.notificationDeadlineReminders = true,
    this.notificationQuietHourStart = 22,
    this.notificationQuietHourEnd = 8,
    this.notificationHighPriorityOnly = false,
    this.notificationSound = true,
    this.notificationVibration = true,
    List<int>? notificationEscalationDays,
  })  : collectionLastSync = collectionLastSync ?? {},
        firestoreId = firestoreId ?? '',
        notificationEscalationDays = notificationEscalationDays ?? [7, 1, 0];

  // Check if user has accepted all legal requirements
  bool get hasAcceptedAll => hasAcceptedTerms && hasAcceptedPrivacy;

  // Get last sync for a specific collection
  DateTime? getCollectionLastSync(String collection) {
    final timestamp = collectionLastSync[collection];
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  // Set last sync for a specific collection
  void setCollectionLastSync(String collection, DateTime timestamp) {
    collectionLastSync[collection] = timestamp.toIso8601String();
  }

  // Accept terms
  void acceptTerms() {
    hasAcceptedTerms = true;
    termsAcceptedAt = DateTime.now();
  }

  // Accept privacy policy
  void acceptPrivacy() {
    hasAcceptedPrivacy = true;
    privacyAcceptedAt = DateTime.now();
  }

  // Accept all legal requirements
  void acceptAll() {
    acceptTerms();
    acceptPrivacy();
  }

  // Revoke all consents
  void revokeAll() {
    hasAcceptedTerms = false;
    hasAcceptedPrivacy = false;
    termsAcceptedAt = null;
    privacyAcceptedAt = null;
    notificationsEnabled = false;
    calendarSyncEnabled = false;
    cloudSyncEnabled = false;
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAcceptedTerms': hasAcceptedTerms,
      'hasAcceptedPrivacy': hasAcceptedPrivacy,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'privacyAcceptedAt': privacyAcceptedAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'calendarSyncEnabled': calendarSyncEnabled,
      'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
      'syncOnMobileData': syncOnMobileData,
      'syncDebounceMs': syncDebounceMs,
      'cloudSyncEnabled': cloudSyncEnabled,
      'restDayOfWeek': restDayOfWeek,
      'notificationDeadlineReminders': notificationDeadlineReminders,
      'notificationQuietHourStart': notificationQuietHourStart,
      'notificationQuietHourEnd': notificationQuietHourEnd,
      'notificationHighPriorityOnly': notificationHighPriorityOnly,
      'notificationSound': notificationSound,
      'notificationVibration': notificationVibration,
      'notificationEscalationDays': notificationEscalationDays,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'hasAcceptedTerms': hasAcceptedTerms,
      'hasAcceptedPrivacy': hasAcceptedPrivacy,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'privacyAcceptedAt': privacyAcceptedAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'calendarSyncEnabled': calendarSyncEnabled,
      'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
      'collectionLastSync': collectionLastSync,
      'syncOnMobileData': syncOnMobileData,
      'syncDebounceMs': syncDebounceMs,
      'cloudSyncEnabled': cloudSyncEnabled,
      'restDayOfWeek': restDayOfWeek,
      'notificationDeadlineReminders': notificationDeadlineReminders,
      'notificationQuietHourStart': notificationQuietHourStart,
      'notificationQuietHourEnd': notificationQuietHourEnd,
      'notificationHighPriorityOnly': notificationHighPriorityOnly,
      'notificationSound': notificationSound,
      'notificationVibration': notificationVibration,
      'notificationEscalationDays': notificationEscalationDays,
      'lastUpdatedAt': (lastUpdatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Create from Firestore document
  factory UserPreferences.fromFirestore(String docId, Map<String, dynamic> data) {
    return UserPreferences(
      odId: 'default',
      hasAcceptedTerms: data['hasAcceptedTerms'] as bool? ?? false,
      hasAcceptedPrivacy: data['hasAcceptedPrivacy'] as bool? ?? false,
      termsAcceptedAt: data['termsAcceptedAt'] != null
          ? DateTime.parse(data['termsAcceptedAt'] as String)
          : null,
      privacyAcceptedAt: data['privacyAcceptedAt'] != null
          ? DateTime.parse(data['privacyAcceptedAt'] as String)
          : null,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
      calendarSyncEnabled: data['calendarSyncEnabled'] as bool? ?? false,
      lastSyncTimestamp: data['lastSyncTimestamp'] != null
          ? DateTime.parse(data['lastSyncTimestamp'] as String)
          : null,
      collectionLastSync: data['collectionLastSync'] != null
          ? Map<String, String>.from(data['collectionLastSync'] as Map)
          : {},
      syncOnMobileData: data['syncOnMobileData'] as bool? ?? true,
      syncDebounceMs: data['syncDebounceMs'] as int? ?? 3000,
      cloudSyncEnabled: data['cloudSyncEnabled'] as bool? ?? false,
      restDayOfWeek: data['restDayOfWeek'] as int?,
      notificationDeadlineReminders: data['notificationDeadlineReminders'] as bool? ?? true,
      notificationQuietHourStart: data['notificationQuietHourStart'] as int? ?? 22,
      notificationQuietHourEnd: data['notificationQuietHourEnd'] as int? ?? 8,
      notificationHighPriorityOnly: data['notificationHighPriorityOnly'] as bool? ?? false,
      notificationSound: data['notificationSound'] as bool? ?? true,
      notificationVibration: data['notificationVibration'] as bool? ?? true,
      notificationEscalationDays: data['notificationEscalationDays'] != null
          ? List<int>.from(data['notificationEscalationDays'] as List)
          : [7, 1, 0],
      firestoreId: docId,
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.parse(data['lastUpdatedAt'] as String)
          : null,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> data) {
    return UserPreferences(
      hasAcceptedTerms: data['hasAcceptedTerms'] ?? false,
      hasAcceptedPrivacy: data['hasAcceptedPrivacy'] ?? false,
      termsAcceptedAt: data['termsAcceptedAt'] != null
          ? DateTime.parse(data['termsAcceptedAt'])
          : null,
      privacyAcceptedAt: data['privacyAcceptedAt'] != null
          ? DateTime.parse(data['privacyAcceptedAt'])
          : null,
      notificationsEnabled: data['notificationsEnabled'] ?? false,
      calendarSyncEnabled: data['calendarSyncEnabled'] ?? false,
      lastSyncTimestamp: data['lastSyncTimestamp'] != null
          ? DateTime.parse(data['lastSyncTimestamp'])
          : null,
      syncOnMobileData: data['syncOnMobileData'] ?? true,
      syncDebounceMs: data['syncDebounceMs'] ?? 3000,
      cloudSyncEnabled: data['cloudSyncEnabled'] ?? false,
      restDayOfWeek: data['restDayOfWeek'] as int?,
      notificationDeadlineReminders: data['notificationDeadlineReminders'] ?? true,
      notificationQuietHourStart: data['notificationQuietHourStart'] ?? 22,
      notificationQuietHourEnd: data['notificationQuietHourEnd'] ?? 8,
      notificationHighPriorityOnly: data['notificationHighPriorityOnly'] ?? false,
      notificationSound: data['notificationSound'] ?? true,
      notificationVibration: data['notificationVibration'] ?? true,
      notificationEscalationDays: data['notificationEscalationDays'] != null
          ? List<int>.from(data['notificationEscalationDays'])
          : [7, 1, 0],
    );
  }

  UserPreferences copyWith({
    bool? hasAcceptedTerms,
    bool? hasAcceptedPrivacy,
    DateTime? termsAcceptedAt,
    DateTime? privacyAcceptedAt,
    bool? notificationsEnabled,
    bool? calendarSyncEnabled,
    DateTime? lastSyncTimestamp,
    Map<String, String>? collectionLastSync,
    bool? syncOnMobileData,
    int? syncDebounceMs,
    bool? cloudSyncEnabled,
    String? firestoreId,
    DateTime? lastUpdatedAt,
    int? restDayOfWeek,
    bool? notificationDeadlineReminders,
    int? notificationQuietHourStart,
    int? notificationQuietHourEnd,
    bool? notificationHighPriorityOnly,
    bool? notificationSound,
    bool? notificationVibration,
    List<int>? notificationEscalationDays,
  }) {
    return UserPreferences(
      odId: odId,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      hasAcceptedPrivacy: hasAcceptedPrivacy ?? this.hasAcceptedPrivacy,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      privacyAcceptedAt: privacyAcceptedAt ?? this.privacyAcceptedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      collectionLastSync: collectionLastSync ?? Map.from(this.collectionLastSync),
      syncOnMobileData: syncOnMobileData ?? this.syncOnMobileData,
      syncDebounceMs: syncDebounceMs ?? this.syncDebounceMs,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      restDayOfWeek: restDayOfWeek ?? this.restDayOfWeek,
      notificationDeadlineReminders: notificationDeadlineReminders ?? this.notificationDeadlineReminders,
      notificationQuietHourStart: notificationQuietHourStart ?? this.notificationQuietHourStart,
      notificationQuietHourEnd: notificationQuietHourEnd ?? this.notificationQuietHourEnd,
      notificationHighPriorityOnly: notificationHighPriorityOnly ?? this.notificationHighPriorityOnly,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration: notificationVibration ?? this.notificationVibration,
      notificationEscalationDays: notificationEscalationDays ?? List.from(this.notificationEscalationDays),
      firestoreId: firestoreId ?? this.firestoreId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  /// Update lastUpdatedAt timestamp
  void touch() {
    lastUpdatedAt = DateTime.now();
  }
}
