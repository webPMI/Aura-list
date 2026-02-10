import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/models/task_history.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/models/sync_metadata.dart';

void main() {
  group('Database Model Tests', () {
    late Directory testDirectory;

    setUpAll(() async {
      // Create a temporary directory for testing
      testDirectory = Directory.systemTemp.createTempSync('hive_test_');

      // Initialize Hive with the temp directory
      Hive.init(testDirectory.path);

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

    tearDownAll(() async {
      // Clean up Hive and test directory
      await Hive.close();
      if (testDirectory.existsSync()) {
        testDirectory.deleteSync(recursive: true);
      }
    });

    test('Hive adapters registered correctly', () {
      expect(Hive.isAdapterRegistered(0), true); // Task
      expect(Hive.isAdapterRegistered(2), true); // Note
      expect(Hive.isAdapterRegistered(3), true); // TaskHistory
      expect(Hive.isAdapterRegistered(4), true); // UserPreferences
      expect(Hive.isAdapterRegistered(5), true); // SyncMetadata
    });

    test('Task model can be created and has correct properties', () {
      final task = Task(
        title: 'Test Task',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        category: 'Personal',
        priority: 1,
      );

      expect(task.title, 'Test Task');
      expect(task.type, 'daily');
      expect(task.category, 'Personal');
      expect(task.priority, 1);
      expect(task.isCompleted, false);
      expect(task.deleted, false);
    });

    test('Note model can be created and has correct properties', () {
      final note = Note(
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(note.title, 'Test Note');
      expect(note.content, 'This is a test note');
      expect(note.color, '#FFFFFF');
      expect(note.isPinned, false);
      expect(note.deleted, false);
    });

    test('Task model copyWith creates new instance', () {
      final task = Task(
        title: 'Original Title',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        category: 'Personal',
        priority: 1,
      );

      final updatedTask = task.copyWith(title: 'Updated Title', priority: 2);

      expect(updatedTask.title, 'Updated Title');
      expect(updatedTask.priority, 2);
      expect(updatedTask.type, 'daily'); // Unchanged
      expect(task.title, 'Original Title'); // Original unchanged
    });

    test('Task model toFirestore and fromFirestore work correctly', () {
      final task = Task(
        firestoreId: 'fs-123',
        title: 'Test Task',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        category: 'Work',
        priority: 2,
        isCompleted: true,
      );

      final firestore = task.toFirestore();
      final restored = Task.fromFirestore('fs-123', firestore);

      expect(restored.firestoreId, task.firestoreId);
      expect(restored.title, task.title);
      expect(restored.type, task.type);
      expect(restored.category, task.category);
      expect(restored.priority, task.priority);
      expect(restored.isCompleted, task.isCompleted);
    });

    test('UserPreferences model works correctly', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        notificationsEnabled: true,
      );

      expect(prefs.hasAcceptedAll, true);
      expect(prefs.notificationsEnabled, true);
      expect(prefs.cloudSyncEnabled, false); // Default
    });

    test('TaskHistory model can be created', () {
      final history = TaskHistory(
        taskId: 'task-123',
        date: DateTime(2024, 1, 1),
        wasCompleted: true,
      );

      expect(history.taskId, 'task-123');
      expect(history.wasCompleted, true);
      expect(history.date, DateTime(2024, 1, 1));
    });

    test('SyncMetadata model can be created', () {
      final metadata = SyncMetadata(
        recordId: 'task-123',
        recordType: 'task',
        lastLocalUpdate: DateTime(2024, 1, 1),
      );

      expect(metadata.recordId, 'task-123');
      expect(metadata.recordType, 'task');
      expect(metadata.isPendingSync, true);
      expect(metadata.hasConflict, false);
      expect(metadata.syncAttempts, 0);
    });
  });
}

// Note: Integration tests with DatabaseService require mocking platform plugins
// (path_provider, etc.). These tests verify that the models work correctly with Hive.
// Full DatabaseService tests should be run in an integration test environment.
