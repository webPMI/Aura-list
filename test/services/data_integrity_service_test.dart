import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/data_integrity_service.dart';
import 'package:checklist_app/services/conflict_resolver.dart';
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
  group('DataIntegrityService Tests', () {
    late Directory tempDir;
    late DatabaseService databaseService;
    late DataIntegrityService integrityService;
    late ConflictResolver conflictResolver;
    late ErrorHandler errorHandler;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('integrity_test_');
      Hive.init(tempDir.path);

      // Register all adapters if not already
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
      conflictResolver = ConflictResolver();

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
      final taskRepository = TaskRepository(
        localStorage: taskStorage,
        syncService: taskSyncService,
        errorHandler: errorHandler,
      );
      final noteRepository = NoteRepository(
        localStorage: noteStorage,
        syncService: noteSyncService,
        errorHandler: errorHandler,
      );
      final notebookRepository = NotebookRepository(
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
      integrityService = DataIntegrityService(
        databaseService,
        conflictResolver,
        errorHandler,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      tempDir = await Directory.systemTemp.createTemp('integrity_test_');
    });

    test('isConsistent returns true when no data exists', () async {
      final check = await integrityService.performFullCheck('user123');
      expect(check.isConsistent, true);
    });

    test('detects local items not in cloud', () async {
      final task = Task(
        title: 'Local Only',
        type: 'once',
        createdAt: DateTime.now(),
        firestoreId: 'fs-1',
      );
      await databaseService.saveTaskLocally(task);

      // Since firestore is null in DatabaseService during this test,
      // it should identify the task as missing in cloud because Firestore is not reachable.
      // Wait, performFullCheck handles firestore == null by treating firestoreId tasks as missingInCloud.

      final check = await integrityService.performFullCheck('user123');
      expect(check.missingInCloud, contains('fs-1'));
      expect(check.isConsistent, false);
    });

    test('findDuplicates finds tasks with same title and type', () async {
      final task1 = Task(
        title: 'Duplicate',
        type: 'once',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final task2 = Task(
        title: 'Duplicate',
        type: 'once',
        createdAt: DateTime.now(),
      );

      await databaseService.saveTaskLocally(task1);
      await databaseService.saveTaskLocally(task2);

      final duplicates = await integrityService.findDuplicates();
      expect(duplicates.length, 1);
      expect(duplicates.first.commonIdentifier, 'Duplicate');
      expect(duplicates.first.ids.length, 2);
    });

    test('removeDuplicates keeps the newest one', () async {
      final taskOld = Task(
        title: 'D',
        type: 'once',
        createdAt: DateTime(2024, 1, 1),
      );
      final taskNew = Task(
        title: 'D',
        type: 'once',
        createdAt: DateTime(2024, 1, 2),
      );

      await databaseService.saveTaskLocally(taskOld);
      await databaseService.saveTaskLocally(taskNew);

      final removed = await integrityService.removeDuplicates();
      expect(removed, 1);

      final tasks = await databaseService.getLocalTasks('once');
      expect(tasks.length, 1);
      expect(tasks.first.createdAt, DateTime(2024, 1, 2));
    });
  });
}
