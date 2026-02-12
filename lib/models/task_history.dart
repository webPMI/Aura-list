import 'package:hive/hive.dart';

part 'task_history.g.dart';

@HiveType(typeId: 3)
class TaskHistory extends HiveObject {
  @HiveField(0)
  late String taskId; // Reference to task (using task.key as string)

  @HiveField(1)
  late DateTime date; // The date this record is for (normalized to midnight)

  @HiveField(2)
  late bool wasCompleted;

  @HiveField(3)
  DateTime? completedAt; // Exact timestamp when completed

  @HiveField(4)
  late String firestoreId; // Firestore document ID for cloud sync

  @HiveField(5)
  DateTime? lastUpdatedAt; // For conflict resolution

  @HiveField(6)
  bool deleted; // Soft delete flag

  @HiveField(7)
  DateTime? deletedAt; // When it was deleted

  TaskHistory({
    required this.taskId,
    required this.date,
    this.wasCompleted = false,
    this.completedAt,
    String? firestoreId,
    this.lastUpdatedAt,
    this.deleted = false,
    this.deletedAt,
  }) : firestoreId = firestoreId ?? '';

  /// Creates a unique key for this history entry based on taskId and date
  String get historyKey => '${taskId}_${date.year}_${date.month}_${date.day}';

  /// Normalizes a DateTime to midnight for consistent date comparison
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Creates a TaskHistory entry for today
  factory TaskHistory.forToday({
    required String taskId,
    bool wasCompleted = false,
    DateTime? completedAt,
  }) {
    return TaskHistory(
      taskId: taskId,
      date: normalizeDate(DateTime.now()),
      wasCompleted: wasCompleted,
      completedAt: completedAt,
    );
  }

  @override
  String toString() {
    return 'TaskHistory(taskId: $taskId, date: $date, wasCompleted: $wasCompleted, completedAt: $completedAt)';
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'date': date.toIso8601String(),
      'wasCompleted': wasCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdatedAt': (lastUpdatedAt ?? DateTime.now()).toIso8601String(),
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// Create from Firestore document
  factory TaskHistory.fromFirestore(String docId, Map<String, dynamic> data) {
    return TaskHistory(
      taskId: data['taskId'] as String? ?? '',
      date: data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : DateTime.now(),
      wasCompleted: data['wasCompleted'] as bool? ?? false,
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
      firestoreId: docId,
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.parse(data['lastUpdatedAt'] as String)
          : null,
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.parse(data['deletedAt'] as String)
          : null,
    );
  }

  /// Create a copy with updated values
  TaskHistory copyWith({
    String? taskId,
    DateTime? date,
    bool? wasCompleted,
    DateTime? completedAt,
    String? firestoreId,
    DateTime? lastUpdatedAt,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return TaskHistory(
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      completedAt: completedAt ?? this.completedAt,
      firestoreId: firestoreId ?? this.firestoreId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Mark as completed
  void markCompleted() {
    wasCompleted = true;
    completedAt = DateTime.now();
    lastUpdatedAt = DateTime.now();
  }

  /// Mark as incomplete
  void markIncomplete() {
    wasCompleted = false;
    completedAt = null;
    lastUpdatedAt = DateTime.now();
  }

  /// Soft delete this history entry
  void softDelete() {
    deleted = true;
    deletedAt = DateTime.now();
    lastUpdatedAt = DateTime.now();
  }
}
