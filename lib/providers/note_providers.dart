/// Riverpod providers for the new note architecture.
///
/// Provides dependency injection for note storage, sync, and repository layers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../services/storage/local/hive_note_storage.dart';
import '../services/storage/cloud/firestore_note_storage.dart';
import '../services/sync/note_sync_service.dart';
import '../services/repositories/note_repository.dart';
import '../services/error_handler.dart';
import 'task_providers.dart' show cloudSyncEnabledFunctionProvider;

// ==================== STORAGE PROVIDERS ====================

/// Provider for Hive note storage
final hiveNoteStorageProvider = Provider<HiveNoteStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final storage = HiveNoteStorage(errorHandler);

  ref.onDispose(() {
    storage.close();
  });

  return storage;
});

/// Provider for Firestore note storage
final firestoreNoteStorageProvider = Provider<FirestoreNoteStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return FirestoreNoteStorage(errorHandler);
});

// ==================== SYNC PROVIDERS ====================

/// Provider for note sync service
final noteSyncServiceProvider = Provider<NoteSyncService>((ref) {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  final cloudStorage = ref.watch(firestoreNoteStorageProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final isCloudSyncEnabled = ref.watch(cloudSyncEnabledFunctionProvider);

  return NoteSyncService(
    localStorage: localStorage,
    cloudStorage: cloudStorage,
    errorHandler: errorHandler,
    isCloudSyncEnabled: isCloudSyncEnabled,
  );
});

// ==================== REPOSITORY PROVIDERS ====================

/// Provider for note repository
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  final syncService = ref.watch(noteSyncServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);

  final repository = NoteRepository(
    localStorage: localStorage,
    syncService: syncService,
    errorHandler: errorHandler,
  );

  ref.onDispose(() {
    repository.close();
  });

  return repository;
});

// ==================== NOTE LIST PROVIDERS ====================

/// Provider for all notes
final allNotesProvider = StreamProvider<List<Note>>((ref) async* {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  yield* localStorage.watch();
});

/// Provider for notes by notebook
final notesByNotebookProvider = StreamProvider.family<List<Note>, String?>((ref, notebookId) async* {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  yield* localStorage.watchByNotebook(notebookId);
});

/// Provider for root notes (no notebook)
final rootNotesProvider = StreamProvider<List<Note>>((ref) async* {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  yield* localStorage.watchRootNotes();
});

/// Provider for pinned notes
final pinnedNotesProvider = FutureProvider<List<Note>>((ref) async {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  return localStorage.getPinned();
});

/// Provider for active notes
final activeNotesProvider = FutureProvider<List<Note>>((ref) async {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  return localStorage.getActive();
});

/// Provider for archived notes
final archivedNotesProvider = FutureProvider<List<Note>>((ref) async {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  return localStorage.getArchived();
});

// ==================== SYNC STATUS PROVIDERS ====================

/// Provider for pending note sync count
final pendingNoteSyncCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(noteSyncServiceProvider);
  await syncService.init();
  return syncService.getPendingCount();
});

/// Provider for note dead letter count
final noteDeadLetterCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(noteSyncServiceProvider);
  await syncService.init();
  return syncService.getDeadLetterCount();
});

/// Provider to check if note sync is in progress
final isNoteSyncingProvider = Provider<bool>((ref) {
  final syncService = ref.watch(noteSyncServiceProvider);
  return syncService.isSyncing;
});

// ==================== SEARCH PROVIDER ====================

/// Provider for note search results
final noteSearchProvider = FutureProvider.family<List<Note>, String>((ref, query) async {
  final localStorage = ref.watch(hiveNoteStorageProvider);
  await localStorage.init();
  return localStorage.search(query);
});
