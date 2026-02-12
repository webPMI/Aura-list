import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/task_model.dart';

void main() {
  group('Task Model Tests', () {
    test('Task creation with required fields', () {
      final now = DateTime(2024, 1, 1);
      final task = Task(title: 'Test Task', type: 'daily', createdAt: now);

      expect(task.title, 'Test Task');
      expect(task.type, 'daily');
      expect(task.createdAt, now);
      expect(task.isCompleted, false);
      expect(task.category, 'Personal');
      expect(task.priority, 1);
    });

    test('typeLabel and typeIcon return correct values', () {
      final daily = Task(title: 'T', type: 'daily', createdAt: DateTime.now());
      final weekly = Task(
        title: 'T',
        type: 'weekly',
        createdAt: DateTime.now(),
      );
      final once = Task(title: 'T', type: 'once', createdAt: DateTime.now());

      expect(daily.typeLabel, 'Diaria');
      expect(daily.typeIcon, Icons.wb_sunny_outlined);
      expect(weekly.typeLabel, 'Semanal');
      expect(once.typeLabel, 'Única');
    });

    test('dueTime and dueDateTimeComplete', () {
      final date = DateTime(2024, 5, 20);
      final task = Task(
        title: 'T',
        type: 'once',
        createdAt: DateTime.now(),
        dueDate: date,
        dueTimeMinutes: 630, // 10:30 AM
      );

      expect(task.dueTime, const TimeOfDay(hour: 10, minute: 30));
      expect(task.dueDateTimeComplete, DateTime(2024, 5, 20, 10, 30));
    });

    test('copyWith creates updated instance', () {
      final task = Task(
        title: 'Original',
        type: 'daily',
        createdAt: DateTime.now(),
        priority: 1,
      );

      final copy = task.copyWith(title: 'Updated', priority: 2);

      expect(copy.title, 'Updated');
      expect(copy.priority, 2);
      expect(copy.type, 'daily');
    });

    test('updateInPlace modifies existing instance', () {
      final task = Task(
        title: 'Original',
        type: 'daily',
        createdAt: DateTime.now(),
      );

      task.updateInPlace(title: 'Modified', isCompleted: true);

      expect(task.title, 'Modified');
      expect(task.isCompleted, true);
    });

    test('motivationText returns custom or default', () {
      final task1 = Task(
        title: 'T',
        type: 'd',
        createdAt: DateTime.now(),
        motivation: 'Custom',
      );
      final task2 = Task(title: 'T', type: 'd', createdAt: DateTime.now());

      expect(task1.motivationText, 'Custom');
      expect(task2.motivationText, isNotEmpty);
    });

    test('isOverdue and isUrgent', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final soon = DateTime.now().add(const Duration(hours: 2));

      final taskOverdue = Task(
        title: 'T',
        type: 'd',
        createdAt: DateTime.now(),
        deadline: past,
      );
      final taskUrgent = Task(
        title: 'T',
        type: 'd',
        createdAt: DateTime.now(),
        deadline: soon,
      );

      expect(taskOverdue.isOverdue, true);
      expect(taskUrgent.isUrgent, true);
    });

    test('toFirestore and fromFirestore work correctly', () {
      final original = Task(
        firestoreId: 'fs-123',
        title: 'Test Task',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        isCompleted: true,
        priority: 2,
        category: 'Work',
      );

      final firestore = original.toFirestore();
      final restored = Task.fromFirestore('fs-123', firestore);

      expect(restored.title, original.title);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
    });
  });
}
