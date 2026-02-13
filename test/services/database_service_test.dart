import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/services/repositories/task_repository.dart';
import 'package:checklist_app/services/repositories/note_repository.dart';
import 'package:checklist_app/services/repositories/notebook_repository.dart';
import 'package:checklist_app/services/storage/local/hive_task_storage.dart';
import 'package:checklist_app/services/storage/local/hive_note_storage.dart';
import 'package:checklist_app/services/storage/local/hive_notebook_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_task_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_note_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_notebook_storage.dart';
import 'package:checklist_app/services/sync/task_sync_service.dart';
import 'package:checklist_app/services/sync/note_sync_service.dart';
import 'package:checklist_app/services/sync/notebook_sync_service.dart';
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
    late TaskRepository taskRepository;
    late NoteRepository noteRepository;
    late NotebookRepository notebookRepository;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('db_service_test_');

      // Register all adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TaskHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(SyncMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(NotebookAdapter());
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ChecklistItemAdapter());
      }
    });

    setUp(() async {
      errorHandler = ErrorHandler();

      // Create storage layers
      final taskStorage = HiveTaskStorage(errorHandler);
      final noteStorage = HiveNoteStorage(errorHandler);
      final notebookStorage = HiveNotebookStorage(errorHandler);

      // Create cloud storage layers
      final taskCloudStorage = FirestoreTaskStorage(errorHandler);
      final noteCloudStorage = FirestoreNoteStorage(errorHandler);
      final notebookCloudStorage = FirestoreNotebookStorage(errorHandler);

      // Create sync services (disabled for tests)
      final taskSyncService = TaskSyncService(
        localStorage: taskStorage,
        cloudStorage: taskCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => false,
      );
      final noteSyncService = NoteSyncService(
        localStorage: noteStorage,
        cloudStorage: noteCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => false,
      );
      final notebookSyncService = NotebookSyncService(
        localStorage: notebookStorage,
        cloudStorage: notebookCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => false,
      );

      // Create repositories
      taskRepository = TaskRepository(
        localStorage: taskStorage,
        syncService: taskSyncService,
        errorHandler: errorHandler,
      );
      noteRepository = NoteRepository(
        localStorage: noteStorage,
        syncService: noteSyncService,
        errorHandler: errorHandler,
      );
      notebookRepository = NotebookRepository(
        localStorage: notebookStorage,
        syncService: notebookSyncService,
        errorHandler: errorHandler,
      );

      databaseService = DatabaseService(
        errorHandler,
        taskRepository: taskRepository,
        noteRepository: noteRepository,
        notebookRepository: notebookRepository,
      );
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
