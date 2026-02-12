import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/task_history.dart';

void main() {
  group('TaskHistory Model Tests', () {
    test('TaskHistory creation with required fields', () {
      final date = DateTime(2024, 1, 1);
      final history = TaskHistory(
        taskId: 'task-123',
        date: date,
        wasCompleted: true,
      );

      expect(history.taskId, 'task-123');
      expect(history.date, date);
      expect(history.wasCompleted, true);
      expect(history.completedAt, isNull);
    });

    test('historyKey generation', () {
      final date = DateTime(2024, 5, 15);
      final history = TaskHistory(taskId: 'task-123', date: date);

      expect(history.historyKey, 'task-123_2024_5_15');
    });

    test('normalizeDate works correctly', () {
      final original = DateTime(2024, 5, 15, 14, 30, 45);
      final normalized = TaskHistory.normalizeDate(original);

      expect(normalized.year, 2024);
      expect(normalized.month, 5);
      expect(normalized.day, 15);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
    });

    test('TaskHistory.forToday factory creates entry for current date', () {
      final history = TaskHistory.forToday(taskId: 'task-123');
      final now = DateTime.now();

      expect(history.taskId, 'task-123');
      expect(history.date.year, now.year);
      expect(history.date.month, now.month);
      expect(history.date.day, now.day);
      expect(history.wasCompleted, false);
    });

    test('toString returns expected format', () {
      final date = DateTime(2024, 1, 1);
      final history = TaskHistory(
        taskId: 'task-123',
        date: date,
        wasCompleted: true,
      );

      expect(history.toString(), contains('taskId: task-123'));
      expect(history.toString(), contains('wasCompleted: true'));
    });
  });
}
