/// Task synchronization service.
///
/// Handles bidirectional sync of tasks between local Hive storage
/// and Firebase Firestore, with retry logic and debouncing.
library;

import 'dart:async';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_task_storage.dart';
import '../storage/cloud/firestore_task_storage.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/task_model.dart';
import 'sync_queue.dart';
import 'sync_utils.dart';

/// Service for synchronizing tasks between local and cloud storage
class TaskSyncService implements ISyncService<Task> {
  final HiveTaskStorage _localStorage;
  final FirestoreTaskStorage _cloudStorage;
  final ErrorHandler _errorHandler;
  final Future<bool> Function() _isCloudSyncEnabled;
  final LoggerService _logger = LoggerService();

  late final GenericSyncQueue<Task> _syncQueue;
  late final DebouncedSyncManager _debouncedSync;

  final SyncConfig config;
  bool _isSyncing = false;
  bool _initialized = false;

  TaskSyncService({
    required HiveTaskStorage localStorage,
    required FirestoreTaskStorage cloudStorage,
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    this.config = const SyncConfig(),
  })  : _localStorage = localStorage,
        _cloudStorage = cloudStorage,
        _errorHandler = errorHandler,
        _isCloudSyncEnabled = isCloudSyncEnabled {
    _syncQueue = GenericSyncQueue<Task>(
      queueBoxName: 'task_sync_queue_v2',
      deadLetterBoxName: 'task_dead_letter_queue',
      errorHandler: errorHandler,
      findLocalItem: (key) => _localStorage.get(key),
      syncItem: _syncSingleTask,
      config: config,
    );

    _debouncedSync = DebouncedSyncManager(
      debounceDelay: config.debounceDelay,
      onFlush: _flushDebouncedItems,
    );
  }

  /// Initialize the sync service
  Future<void> init() async {
    if (_initialized) return;
    await _syncQueue.init();
    _initialized = true;
    _logger.debug('Service', '[TaskSyncService] Initialized');
  }

  @override
  Future<bool> get isSyncEnabled => _isCloudSyncEnabled();

  @override
  bool get isSyncing => _isSyncing;

  @override
  Future<SyncOperationResult> syncToCloud(Task task, String userId) async {
    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    if (!_cloudStorage.isAvailable) {
      return SyncOperationResult.offline();
    }

    if (userId.isEmpty) {
      return SyncOperationResult.skipped('User not authenticated');
    }

    try {
      await _syncSingleTask(task, userId);
      return SyncOperationResult.success();
    } catch (e) {
      await addToQueue(task, userId);
      return SyncOperationResult.failed(e.toString());
    }
  }

  @override
  Future<void> syncToCloudDebounced(Task task, String userId) async {
    if (!await isSyncEnabled) return;
    if (!_cloudStorage.isAvailable) return;
    if (userId.isEmpty) return;

    // Update lastUpdatedAt
    task.lastUpdatedAt = DateTime.now();
    if (task.isInBox) await task.save();

    // Add to debounced sync with captured userId
    if (task.key != null) {
      _debouncedSync.add(task.key, userId);
    }
  }

  /// Sync a single task to cloud
  Future<void> _syncSingleTask(Task task, String userId) async {
    final result = await _cloudStorage.upsert(task, userId);

    if (!result.success) {
      throw Exception(result.error);
    }

    // Update local task with firestoreId if needed
    if (result.documentId != null && task.firestoreId != result.documentId) {
      task.firestoreId = result.documentId!;
      if (task.isInBox) {
        await task.save();
      } else {
        // Find and update the local instance
        final localTask = await _localStorage.findByFirestoreId(result.documentId!) ??
            await _localStorage.findByCreatedAt(task.createdAt);
        if (localTask != null) {
          localTask.firestoreId = result.documentId!;
          await localTask.save();
        }
      }
    }

    _logger.debug(
      'Service',
      '[TaskSyncService] Task synced: ${task.firestoreId}',
    );
  }

  @override
  Future<SyncOperationResult> syncFromCloud(
    String userId, {
    DateTime? since,
  }) async {
    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    if (!_cloudStorage.isAvailable) {
      return SyncOperationResult.offline();
    }

    if (userId.isEmpty) {
      return SyncOperationResult.skipped('User not authenticated');
    }

    try {
      final result = since != null
          ? await _cloudStorage.getModifiedSince(userId, since)
          : await _cloudStorage.getAll(userId);

      if (!result.success) {
        return SyncOperationResult.failed(result.error ?? 'Unknown error');
      }

      final cloudTasks = result.data ?? [];
      int imported = 0;

      for (final cloudTask in cloudTasks) {
        await _mergeCloudTask(cloudTask);
        imported++;
      }

      _logger.debug(
        'Service',
        '[TaskSyncService] Synced $imported tasks from cloud',
      );

      return SyncOperationResult.success(itemsSynced: imported);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error syncing tasks from cloud',
        stackTrace: stack,
      );
      return SyncOperationResult.failed(e.toString());
    }
  }

  /// Merge a cloud task into local storage
  Future<void> _mergeCloudTask(Task cloudTask) async {
    // Find existing local task
    final localTask = await _localStorage.findByFirestoreId(cloudTask.firestoreId);

    if (localTask == null) {
      // New task from cloud - save locally
      await _localStorage.save(cloudTask);
      return;
    }

    // Conflict resolution: last write wins
    final cloudUpdated = cloudTask.lastUpdatedAt ?? cloudTask.createdAt;
    final localUpdated = localTask.lastUpdatedAt ?? localTask.createdAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      // Cloud is newer - update local
      localTask.updateInPlace(
        title: cloudTask.title,
        type: cloudTask.type,
        isCompleted: cloudTask.isCompleted,
        dueDate: cloudTask.dueDate,
        category: cloudTask.category,
        priority: cloudTask.priority,
        dueTimeMinutes: cloudTask.dueTimeMinutes,
        motivation: cloudTask.motivation,
        reward: cloudTask.reward,
        recurrenceDay: cloudTask.recurrenceDay,
        deadline: cloudTask.deadline,
        deleted: cloudTask.deleted,
        deletedAt: cloudTask.deletedAt,
        lastUpdatedAt: cloudTask.lastUpdatedAt,
      );
      await localTask.save();
    }
    // If local is newer, don't overwrite (it will sync to cloud later)
  }

  @override
  Future<SyncOperationResult> performFullSync(String userId) async {
    if (_isSyncing) {
      return SyncOperationResult.skipped('Sync already in progress');
    }

    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    _isSyncing = true;
    int totalSynced = 0;
    final errors = <String>[];

    try {
      // 1. Flush any pending debounced syncs
      await flushPendingSyncs();

      // 2. Process sync queue
      final queueResult = await processQueue();
      if (queueResult.isSuccess) {
        totalSynced += queueResult.itemsSynced;
      } else {
        errors.addAll(queueResult.errors);
      }

      // 3. Sync local-only items
      final localOnlyTasks = await _localStorage.getPendingSync();
      for (final task in localOnlyTasks) {
        try {
          await _syncSingleTask(task, userId);
          totalSynced++;
        } catch (e) {
          await addToQueue(task, userId);
          errors.add(e.toString());
        }
      }

      // 4. Sync from cloud
      final cloudResult = await syncFromCloud(userId);
      if (cloudResult.isSuccess) {
        totalSynced += cloudResult.itemsSynced;
      } else {
        errors.addAll(cloudResult.errors);
      }

      _logger.debug(
        'Service',
        '[TaskSyncService] Full sync complete: $totalSynced items',
      );

      return SyncOperationResult(
        status: errors.isEmpty
            ? SyncOperationStatus.success
            : SyncOperationStatus.failed,
        itemsSynced: totalSynced,
        itemsFailed: errors.length,
        errors: errors,
        timestamp: DateTime.now(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> addToQueue(Task task, String userId) async {
    if (!_initialized) await init();
    await _syncQueue.enqueue(
      localKey: task.key,
      firestoreId: task.firestoreId.isNotEmpty ? task.firestoreId : null,
      userId: userId,
    );
  }

  @override
  Future<SyncOperationResult> processQueue() async {
    if (!_initialized) await init();
    return _syncQueue.processQueue();
  }

  @override
  Future<int> getPendingCount() async {
    if (!_initialized) await init();
    return _syncQueue.getPendingCount();
  }

  @override
  Future<void> flushPendingSyncs() async {
    await _debouncedSync.flush();
  }

  /// Flush debounced items
  Future<void> _flushDebouncedItems(Set<PendingSyncItem> items) async {
    if (items.isEmpty) return;

    _logger.debug(
      'Service',
      '[TaskSyncService] Flushing ${items.length} debounced items',
    );

    // Group by userId
    final byUser = <String, List<dynamic>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.userId, () => []).add(item.key);
    }

    // Sync each user's tasks
    for (final entry in byUser.entries) {
      final userId = entry.key;
      final keys = entry.value;

      final tasks = <Task>[];
      for (final key in keys) {
        final task = await _localStorage.get(key);
        if (task != null && !task.deleted) {
          tasks.add(task);
        }
      }

      if (tasks.isNotEmpty) {
        final result = await _cloudStorage.batchWrite(tasks, userId);
        if (result.success) {
          // Save updated firestoreIds
          for (final task in tasks) {
            if (task.isInBox) await task.save();
          }
        } else {
          // Add failed items to queue
          for (final task in tasks) {
            await addToQueue(task, userId);
          }
        }
      }
    }
  }

  @override
  Future<void> clearQueue() async {
    if (!_initialized) await init();
    await _syncQueue.clear();
  }

  @override
  Future<void> moveToDeadLetter(SyncQueueItem<Task> item) async {
    // Handled internally by GenericSyncQueue
  }

  @override
  Future<List<SyncQueueItem<Task>>> getDeadLetterItems() async {
    // Not implemented - would need to read from dead letter box
    return [];
  }

  @override
  Future<SyncOperationResult> retryDeadLetterItem(SyncQueueItem<Task> item) async {
    // Not implemented
    return SyncOperationResult.skipped('Not implemented');
  }

  /// Get dead letter count
  Future<int> getDeadLetterCount() async {
    if (!_initialized) await init();
    return _syncQueue.getDeadLetterCount();
  }

  /// Retry all dead letter items
  Future<int> retryAllDeadLetterItems() async {
    if (!_initialized) await init();
    return _syncQueue.retryDeadLetterItems();
  }
}
