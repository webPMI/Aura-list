/// Riverpod providers for the new notebook architecture.
///
/// Provides dependency injection for notebook storage, sync, and repository layers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook_model.dart';
import '../services/storage/local/hive_notebook_storage.dart';
import '../services/storage/cloud/firestore_notebook_storage.dart';
import '../services/sync/notebook_sync_service.dart';
import '../services/repositories/notebook_repository.dart';
import '../services/error_handler.dart';
import 'task_providers.dart' show cloudSyncEnabledFunctionProvider;

// ==================== STORAGE PROVIDERS ====================

/// Provider for Hive notebook storage
final hiveNotebookStorageProvider = Provider<HiveNotebookStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final storage = HiveNotebookStorage(errorHandler);

  ref.onDispose(() {
    storage.close();
  });

  return storage;
});

/// Provider for Firestore notebook storage
final firestoreNotebookStorageProvider = Provider<FirestoreNotebookStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return FirestoreNotebookStorage(errorHandler);
});

// ==================== SYNC PROVIDERS ====================

/// Provider for notebook sync service
final notebookSyncServiceProvider = Provider<NotebookSyncService>((ref) {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  final cloudStorage = ref.watch(firestoreNotebookStorageProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final isCloudSyncEnabled = ref.watch(cloudSyncEnabledFunctionProvider);

  return NotebookSyncService(
    localStorage: localStorage,
    cloudStorage: cloudStorage,
    errorHandler: errorHandler,
    isCloudSyncEnabled: isCloudSyncEnabled,
  );
});

// ==================== REPOSITORY PROVIDERS ====================

/// Provider for notebook repository
final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  final syncService = ref.watch(notebookSyncServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);

  final repository = NotebookRepository(
    localStorage: localStorage,
    syncService: syncService,
    errorHandler: errorHandler,
  );

  ref.onDispose(() {
    repository.close();
  });

  return repository;
});

// ==================== NOTEBOOK LIST PROVIDERS ====================

/// Provider for all notebooks
final allNotebooksProvider = StreamProvider<List<Notebook>>((ref) async* {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  yield* localStorage.watch();
});

/// Provider for favorited notebooks
final favoritedNotebooksProvider = StreamProvider<List<Notebook>>((ref) async* {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  yield* localStorage.watchFavorited();
});

/// Provider for root notebooks (no parent)
final rootNotebooksProvider = FutureProvider<List<Notebook>>((ref) async {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  return localStorage.getRootNotebooks();
});

/// Provider for child notebooks
final childNotebooksProvider = FutureProvider.family<List<Notebook>, String>((ref, parentId) async {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  return localStorage.getChildren(parentId);
});

/// Provider for default notebook
final defaultNotebookProvider = FutureProvider<Notebook?>((ref) async {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  return localStorage.findByName('General');
});

// ==================== SYNC STATUS PROVIDERS ====================

/// Provider for pending notebook sync count
final pendingNotebookSyncCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(notebookSyncServiceProvider);
  await syncService.init();
  return syncService.getPendingCount();
});

/// Provider for notebook dead letter count
final notebookDeadLetterCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(notebookSyncServiceProvider);
  await syncService.init();
  return syncService.getDeadLetterCount();
});

/// Provider to check if notebook sync is in progress
final isNotebookSyncingProvider = Provider<bool>((ref) {
  final syncService = ref.watch(notebookSyncServiceProvider);
  return syncService.isSyncing;
});

// ==================== NOTEBOOK BY ID PROVIDER ====================

/// Provider for a single notebook by key
final notebookByIdProvider = FutureProvider.family<Notebook?, dynamic>((ref, key) async {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  return localStorage.get(key);
});

/// Provider for a notebook by string ID (for note.notebookId)
final notebookByStringIdProvider = FutureProvider.family<Notebook?, String>((ref, id) async {
  final localStorage = ref.watch(hiveNotebookStorageProvider);
  await localStorage.init();
  return localStorage.getByStringId(id);
});
