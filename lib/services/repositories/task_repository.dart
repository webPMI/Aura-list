/// Task repository implementation.
///
/// Provides a high-level API for task operations, coordinating
/// between local storage, cloud storage, and synchronization.
library;

import '../contracts/i_repository.dart';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_task_storage.dart';
import '../sync/task_sync_service.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/task_model.dart';

/// Repository for managing tasks with local and cloud sync
class TaskRepository implements ITaskRepository {
  final HiveTaskStorage _localStorage;
  final TaskSyncService _syncService;
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  bool _initialized = false;

  TaskRepository({
    required HiveTaskStorage localStorage,
    required TaskSyncService syncService,
    required ErrorHandler errorHandler,
  })  : _localStorage = localStorage,
        _syncService = syncService,
        _errorHandler = errorHandler;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _localStorage.init();
      await _syncService.init();
      _initialized = true;
      _logger.debug('Service', '[TaskRepository] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing TaskRepository',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Task?> getById(dynamic key) async {
    return _localStorage.get(key);
  }

  @override
  Future<List<dynamic>> getAll() async {
    return _localStorage.getAll();
  }

  @override
  Future<void> save(dynamic item, String userId) async {
    final task = item as Task;
    task.lastUpdatedAt = DateTime.now();
    await _localStorage.save(task);
    await _syncService.syncToCloudDebounced(task, userId);
  }

  @override
  Future<void> saveAll(List<dynamic> items, String userId) async {
    for (final item in items) {
      await save(item, userId);
    }
  }

  @override
  Future<void> delete(dynamic key, String userId) async {
    final task = await _localStorage.get(key);
    if (task != null) {
      task.deleted = true;
      task.deletedAt = DateTime.now();
      task.lastUpdatedAt = DateTime.now();
      await task.save();
      await _syncService.syncToCloudDebounced(task, userId);
    }
  }

  @override
  Future<void> deleteAll(List<dynamic> keys, String userId) async {
    for (final key in keys) {
      await delete(key, userId);
    }
  }

  @override
  Stream<List<dynamic>> watchAll() {
    return _localStorage.watch();
  }

  @override
  Future<SyncOperationResult> sync(String userId) async {
    return _syncService.performFullSync(userId);
  }

  @override
  Future<int> getPendingSyncCount() async {
    return _syncService.getPendingCount();
  }

  @override
  Future<void> processSyncQueue() async {
    await _syncService.processQueue();
  }

  // ==================== FILTERABLE REPOSITORY ====================

  @override
  Future<List<dynamic>> getWhere(bool Function(dynamic) predicate) async {
    final tasks = await _localStorage.getAll();
    return tasks.where(predicate).toList();
  }

  @override
  Stream<List<dynamic>> watchWhere(bool Function(dynamic) predicate) {
    return _localStorage.watchWhere((task) => predicate(task));
  }

  @override
  Future<List<dynamic>> getByField(String field, dynamic value) async {
    final tasks = await _localStorage.getAll();
    return tasks.where((task) {
      switch (field) {
        case 'type':
          return task.type == value;
        case 'category':
          return task.category == value;
        case 'priority':
          return task.priority == value;
        case 'isCompleted':
          return task.isCompleted == value;
        default:
          return false;
      }
    }).toList();
  }

  // ==================== TASK-SPECIFIC METHODS ====================

  @override
  Future<List<dynamic>> getByType(String type) async {
    return _localStorage.getByType(type);
  }

  @override
  Stream<List<dynamic>> watchByType(String type) {
    return _localStorage.watchByType(type);
  }

  @override
  Future<List<dynamic>> getCompleted() async {
    return _localStorage.getCompleted();
  }

  @override
  Future<List<dynamic>> getOverdue() async {
    return _localStorage.getOverdue();
  }

  @override
  Future<List<dynamic>> getByCategory(String category) async {
    return _localStorage.getByCategory(category);
  }

  @override
  Future<List<dynamic>> getByPriority(int priority) async {
    return _localStorage.getByPriority(priority);
  }

  @override
  Future<void> markCompleted(dynamic key, String userId) async {
    final task = await _localStorage.get(key);
    if (task != null) {
      task.isCompleted = true;
      task.lastUpdatedAt = DateTime.now();
      await task.save();
      await _syncService.syncToCloudDebounced(task, userId);
    }
  }

  @override
  Future<void> markUncompleted(dynamic key, String userId) async {
    final task = await _localStorage.get(key);
    if (task != null) {
      task.isCompleted = false;
      task.lastUpdatedAt = DateTime.now();
      await task.save();
      await _syncService.syncToCloudDebounced(task, userId);
    }
  }

  // ==================== ADDITIONAL METHODS ====================

  /// Get tasks due today
  Future<List<Task>> getDueToday() async {
    return _localStorage.getDueToday();
  }

  /// Get uncompleted tasks
  Future<List<Task>> getUncompleted() async {
    return _localStorage.getUncompleted();
  }

  /// Find task by Firestore ID
  Future<Task?> findByFirestoreId(String firestoreId) async {
    return _localStorage.findByFirestoreId(firestoreId);
  }

  /// Force sync a specific task
  Future<SyncOperationResult> forceSyncTask(Task task, String userId) async {
    return _syncService.syncToCloud(task, userId);
  }

  /// Flush pending debounced syncs
  Future<void> flushPendingSyncs() async {
    await _syncService.flushPendingSyncs();
  }

  /// Purge soft-deleted tasks older than specified days
  Future<int> purgeSoftDeleted({int olderThanDays = 30}) async {
    return _localStorage.purgeSoftDeleted(olderThanDays: olderThanDays);
  }

  /// Get dead letter queue count
  Future<int> getDeadLetterCount() async {
    return _syncService.getDeadLetterCount();
  }

  /// Retry all dead letter items
  Future<int> retryDeadLetterItems() async {
    return _syncService.retryAllDeadLetterItems();
  }

  /// Close the repository
  Future<void> close() async {
    await _localStorage.close();
  }
}
