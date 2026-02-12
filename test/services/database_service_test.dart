import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/models/task_history.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/models/sync_metadata.dart';
import 'package:checklist_app/models/notebook_model.dart';

void main() {
  group('DatabaseService Local Operations', () {
    late Directory tempDir;
    late DatabaseService databaseService;
    late ErrorHandler errorHandler;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('db_service_test_');

      // Register all adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());
      if (!Hive.isAdapterRegistered(3))
        Hive.registerAdapter(TaskHistoryAdapter());
      if (!Hive.isAdapterRegistered(4))
        Hive.registerAdapter(UserPreferencesAdapter());
      if (!Hive.isAdapterRegistered(5))
        Hive.registerAdapter(SyncMetadataAdapter());
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(NotebookAdapter());
      if (!Hive.isAdapterRegistered(7))
        Hive.registerAdapter(ChecklistItemAdapter());
    });

    setUp(() async {
      errorHandler = ErrorHandler();
      databaseService = DatabaseService(errorHandler);
      await databaseService.init(path: tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      // Re-init for next test if needed, but tearDown runs after each test.
      // Better to use a fresh temp dir for each test if we want isolation.
      tempDir = await Directory.systemTemp.createTemp('db_service_test_');
      Hive.init(tempDir.path);
    });

    test('saveTaskLocally and getLocalTasks', () async {
      final task = Task(
        title: 'Work Task',
        type: 'once',
        createdAt: DateTime.now(),
        priority: 1,
      );

      await databaseService.saveTaskLocally(task);

      final tasks = await databaseService.getLocalTasks('once');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Work Task');
    });

    test('deleteTaskLocally works', () async {
      final task = Task(
        title: 'To Delete',
        type: 'once',
        createdAt: DateTime.now(),
      );

      await databaseService.saveTaskLocally(task);
      final key = task.key;
      expect(key, isNotNull);

      await databaseService.deleteTaskLocally(key);

      final tasks = await databaseService.getLocalTasks('once');
      expect(tasks, isEmpty);
    });

    test('User preferences CRUD', () async {
      final prefs = await databaseService.getUserPreferences();
      expect(prefs.cloudSyncEnabled, false); // Default

      prefs.cloudSyncEnabled = true;
      await databaseService.saveUserPreferences(prefs);

      final updatedPrefs = await databaseService.getUserPreferences();
      expect(updatedPrefs.cloudSyncEnabled, true);
    });

    test('Note CRUD', () async {
      final note = Note(
        title: 'Local Note',
        content: 'Content',
        createdAt: DateTime.now(),
      );

      await databaseService.saveNoteLocally(note);

      final notes = await databaseService.getAllNotes();
      expect(notes.any((n) => n.title == 'Local Note'), true);
    });
  });
}
