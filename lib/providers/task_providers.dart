/// Riverpod providers for the new task architecture.
///
/// Provides dependency injection for task storage, sync, and repository layers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/storage/local/hive_task_storage.dart';
import '../services/storage/cloud/firestore_task_storage.dart';
import '../services/sync/task_sync_service.dart';
import '../services/repositories/task_repository.dart';
import '../services/error_handler.dart';
import '../services/database_service.dart';

// ==================== STORAGE PROVIDERS ====================

/// Provider for Hive task storage
final hiveTaskStorageProvider = Provider<HiveTaskStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final storage = HiveTaskStorage(errorHandler);

  ref.onDispose(() {
    storage.close();
  });

  return storage;
});

/// Provider for Firestore task storage
final firestoreTaskStorageProvider = Provider<FirestoreTaskStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return FirestoreTaskStorage(errorHandler);
});

// ==================== SYNC PROVIDERS ====================

/// Provider for task sync service
final taskSyncServiceProvider = Provider<TaskSyncService>((ref) {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  final cloudStorage = ref.watch(firestoreTaskStorageProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final dbService = ref.watch(databaseServiceProvider);

  return TaskSyncService(
    localStorage: localStorage,
    cloudStorage: cloudStorage,
    errorHandler: errorHandler,
    isCloudSyncEnabled: () => dbService.isCloudSyncEnabled(),
  );
});

// ==================== REPOSITORY PROVIDERS ====================

/// Provider for task repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  final syncService = ref.watch(taskSyncServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);

  final repository = TaskRepository(
    localStorage: localStorage,
    syncService: syncService,
    errorHandler: errorHandler,
  );

  ref.onDispose(() {
    repository.close();
  });

  return repository;
});

// ==================== TASK LIST PROVIDERS ====================

/// Provider for tasks by type using new architecture
/// This can be used as an alternative to the existing tasksProvider
final tasksByTypeProvider = StreamProvider.family<List<Task>, String>((ref, type) async* {
  final localStorage = ref.watch(hiveTaskStorageProvider);

  // Ensure initialized
  await localStorage.init();

  // Watch tasks by type
  yield* localStorage.watchByType(type);
});

/// Provider for all tasks
final allTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  await localStorage.init();
  yield* localStorage.watch();
});

/// Provider for overdue tasks
final overdueTasksProvider = FutureProvider<List<Task>>((ref) async {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  await localStorage.init();
  return localStorage.getOverdue();
});

/// Provider for tasks due today
final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  await localStorage.init();
  return localStorage.getDueToday();
});

/// Provider for completed tasks
final completedTasksProvider = FutureProvider<List<Task>>((ref) async {
  final localStorage = ref.watch(hiveTaskStorageProvider);
  await localStorage.init();
  return localStorage.getCompleted();
});

// ==================== SYNC STATUS PROVIDERS ====================

/// Provider for pending task sync count
final pendingTaskSyncCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(taskSyncServiceProvider);
  await syncService.init();
  return syncService.getPendingCount();
});

/// Provider for dead letter count
final taskDeadLetterCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(taskSyncServiceProvider);
  await syncService.init();
  return syncService.getDeadLetterCount();
});

/// Provider to check if task sync is in progress
final isTaskSyncingProvider = Provider<bool>((ref) {
  final syncService = ref.watch(taskSyncServiceProvider);
  return syncService.isSyncing;
});
