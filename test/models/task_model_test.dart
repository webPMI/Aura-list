import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/task_model.dart';

void main() {
  group('Task Model Unit Tests', () {
    final now = DateTime.now();

    test('Task creation and defaults', () {
      final task = Task(title: 'New Task', type: 'daily', createdAt: now);

      expect(task.title, 'New Task');
      expect(task.type, 'daily');
      expect(task.isCompleted, false);
      expect(task.category, 'Personal');
      expect(task.priority, 1);
      expect(task.deleted, false);
    });

    test('toJson / fromJson serialization (Firestore)', () {
      final task = Task(
        title: 'Serialize Me',
        type: 'weekly',
        createdAt: now,
        priority: 2,
        category: 'Work',
      );

      final json = task.toFirestore();
      final restored = Task.fromFirestore('test-id', json);

      expect(restored.firestoreId, 'test-id');
      expect(restored.title, task.title);
      expect(restored.type, task.type);
      expect(restored.priority, task.priority);
      expect(restored.category, task.category);
      expect(
        restored.createdAt.toIso8601String(),
        task.createdAt.toIso8601String(),
      );
    });

    test('copyWith creates independent copy', () {
      final task = Task(title: 'Original', type: 'daily', createdAt: now);

      final copy = task.copyWith(title: 'Updated');

      expect(copy.title, 'Updated');
      expect(task.title, 'Original');
      expect(copy.createdAt, task.createdAt);
      expect(copy, isNot(same(task)));
    });

    test('updateInPlace modifies existing instance', () {
      final task = Task(title: 'In-Place', type: 'daily', createdAt: now);

      task.updateInPlace(title: 'Modified', isCompleted: true);

      expect(task.title, 'Modified');
      expect(task.isCompleted, true);
    });

    test('typeLabel returns correct Spanish labels', () {
      expect(
        Task(title: 'T', type: 'daily', createdAt: now).typeLabel,
        'Diaria',
      );
      expect(
        Task(title: 'T', type: 'weekly', createdAt: now).typeLabel,
        'Semanal',
      );
      expect(
        Task(title: 'T', type: 'monthly', createdAt: now).typeLabel,
        'Mensual',
      );
      expect(
        Task(title: 'T', type: 'yearly', createdAt: now).typeLabel,
        'Anual',
      );
      expect(Task(title: 'T', type: 'once', createdAt: now).typeLabel, 'Única');
    });

    test('isOverdue and isUrgent logic', () {
      final past = now.subtract(const Duration(days: 1));
      final soon = now.add(const Duration(hours: 5));
      final far = now.add(const Duration(days: 5));

      final overdueTask = Task(
        title: 'T',
        type: 'd',
        createdAt: now,
        deadline: past,
      );
      final urgentTask = Task(
        title: 'T',
        type: 'd',
        createdAt: now,
        deadline: soon,
      );
      final futureTask = Task(
        title: 'T',
        type: 'd',
        createdAt: now,
        deadline: far,
      );

      expect(overdueTask.isOverdue, true);
      expect(urgentTask.isUrgent, true);
      expect(futureTask.isOverdue, false);
      expect(futureTask.isUrgent, false);
    });
  });
}
