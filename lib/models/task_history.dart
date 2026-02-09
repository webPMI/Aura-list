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

  TaskHistory({
    required this.taskId,
    required this.date,
    this.wasCompleted = false,
    this.completedAt,
  });

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
}
