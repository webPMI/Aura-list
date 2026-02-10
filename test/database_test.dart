import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/models/task_history.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/models/sync_metadata.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/error_handler.dart';

void main() {
  group('Database Tests', () {
    late DatabaseService dbService;
    late ErrorHandler errorHandler;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NoteAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TaskHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(SyncMetadataAdapter());
      }
    });

    setUp(() async {
      errorHandler = ErrorHandler();
      dbService = DatabaseService(errorHandler);
      await dbService.init();
    });

    tearDown(() async {
      // Clean up test data
      await dbService.clearAllLocalData();
    });

    test('Database initialization', () async {
      expect(dbService, isNotNull);
    });

    test('Create and retrieve task', () async {
      final task = Task(
        title: 'Test Task',
        type: 'daily',
        createdAt: DateTime.now(),
        category: 'Personal',
        priority: 1,
      );

      await dbService.saveTaskLocally(task);
      final tasks = await dbService.getLocalTasks('daily');

      expect(tasks.length, greaterThan(0));
      expect(tasks.first.title, 'Test Task');
    });

    test('Create and retrieve note', () async {
      final note = Note(
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: DateTime.now(),
      );

      await dbService.saveNoteLocally(note);
      final notes = await dbService.getIndependentNotes();

      expect(notes.length, greaterThan(0));
      expect(notes.first.title, 'Test Note');
    });

    test('Update task', () async {
      final task = Task(
        title: 'Original Title',
        type: 'daily',
        createdAt: DateTime.now(),
      );

      await dbService.saveTaskLocally(task);

      task.updateInPlace(title: 'Updated Title');
      await task.save();

      final tasks = await dbService.getLocalTasks('daily');
      expect(tasks.first.title, 'Updated Title');
    });

    test('Soft delete task', () async {
      final task = Task(
        title: 'Task to Delete',
        type: 'daily',
        createdAt: DateTime.now(),
      );

      await dbService.saveTaskLocally(task);
      await dbService.softDeleteTask(task, '');

      final tasks = await dbService.getLocalTasks('daily');
      expect(tasks.length, 0); // Should not appear in regular queries
    });

    test('User preferences', () async {
      final prefs = await dbService.getUserPreferences();
      expect(prefs, isNotNull);
      expect(prefs.odId, 'default');
    });

    test('Task history tracking', () async {
      final task = Task(
        title: 'Task with History',
        type: 'daily',
        createdAt: DateTime.now(),
      );

      await dbService.saveTaskLocally(task);
      final taskId = task.key.toString();

      // Record completion
      await dbService.recordTaskCompletion(taskId, true);

      // Get history
      final history = await dbService.getTaskHistory(taskId);
      expect(history.length, greaterThan(0));
      expect(history.first.wasCompleted, true);
    });

    test('Streak calculation', () async {
      final task = Task(
        title: 'Streak Task',
        type: 'daily',
        createdAt: DateTime.now(),
      );

      await dbService.saveTaskLocally(task);
      final taskId = task.key.toString();

      // Record 3 consecutive days
      for (int i = 0; i < 3; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        await dbService.recordTaskCompletion(taskId, true, date: date);
      }

      final streak = await dbService.getCurrentStreak(taskId);
      expect(streak, equals(3));
    });
  });
}
