import 'dart:async';
import 'package:hive/hive.dart';
import '../../../services/contracts/i_sync_service.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';
import '../../../services/sync/sync_queue.dart';
import '../../../services/sync/sync_utils.dart';

/// Base storage interface for generic sync operations
abstract class BaseSyncStorage<T extends HiveObject> {
  T? getByKey(dynamic key);
  Future<void> save(T item);
  bool get isAvailable;
}

/// Base cloud storage interface for generic sync operations
abstract class BaseCloudStorage<T> {
  Future<StorageOperationResult<void>> create(T item, String userId);
  Future<StorageOperationResult<List<T>>> getAll(String userId);
  Future<void> batchWrite(List<T> items, String userId);
  bool get isAvailable;
}

/// Generic storage operation result
class StorageOperationResult<T> {
  final bool success;
  final T? data;
  final String? error;

  StorageOperationResult({required this.success, this.data, this.error});

  factory StorageOperationResult.success({T? data}) =>
      StorageOperationResult(success: true, data: data);

  factory StorageOperationResult.failure(String error) =>
      StorageOperationResult(success: false, error: error);
}

/// Base generic sync service that eliminates code duplication
/// Consolidates common sync logic for any Hive-based entity type
abstract class BaseSyncService<T extends HiveObject>
    implements ISyncService<T> {
  final BaseSyncStorage<T> localStorage;
  final BaseCloudStorage<T> cloudStorage;
  final ErrorHandler errorHandler;
  final Future<bool> Function() isCloudSyncEnabled;
  final LoggerService logger = LoggerService();

  late final GenericSyncQueue<T> syncQueue;
  late final DebouncedSyncManager debouncedSync;

  final SyncConfig config;
  bool _isSyncing = false;
  bool _initialized = false;

  BaseSyncService({
    required this.localStorage,
    required this.cloudStorage,
    required this.errorHandler,
    required this.isCloudSyncEnabled,
    required String queueBoxName,
    required String deadLetterBoxName,
    this.config = const SyncConfig(),
  }) {
    syncQueue = GenericSyncQueue<T>(
      queueBoxName: queueBoxName,
      deadLetterBoxName: deadLetterBoxName,
      errorHandler: errorHandler,
      findLocalItem: (key) async => localStorage.getByKey(key),
      syncItem: syncSingleItem,
      config: config,
    );

    debouncedSync = DebouncedSyncManager(
      debounceDelay: config.debounceDelay,
      onFlush: flushDebouncedItems,
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    await syncQueue.init();
    _initialized = true;
  }

  @override
  Future<bool> get isSyncEnabled => isCloudSyncEnabled();

  @override
  bool get isSyncing => _isSyncing;

  @override
  Future<SyncOperationResult> syncToCloud(T item, String userId) async {
    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Sync disabled');
    }
    if (!cloudStorage.isAvailable) return SyncOperationResult.offline();
    if (userId.isEmpty) return SyncOperationResult.skipped('No user');

    try {
      await syncSingleItem(item, userId);
      return SyncOperationResult.success();
    } catch (e) {
      await addToQueue(item, userId);
      return SyncOperationResult.failed(e.toString());
    }
  }

  @override
  Future<void> syncToCloudDebounced(T item, String userId) async {
    if (!await isSyncEnabled || !cloudStorage.isAvailable || userId.isEmpty) {
      return;
    }

    // Allow subclasses to update item before debouncing
    await onBeforeDebounceSync(item);

    if (item.key != null) {
      debouncedSync.add(item.key, userId);
    }
  }

  /// Hook for subclasses to update item before debounced sync
  /// (e.g., set lastUpdatedAt timestamp)
  Future<void> onBeforeDebounceSync(T item) async {
    // Default: do nothing. Subclasses can override.
  }

  /// Sync a single item to cloud storage
  Future<void> syncSingleItem(T item, String userId) async {
    final result = await cloudStorage.create(item, userId);
    if (!result.success) throw Exception(result.error);
  }

  @override
  Future<SyncOperationResult> syncFromCloud(
    String userId, {
    DateTime? since,
  }) async {
    if (!await isSyncEnabled || !cloudStorage.isAvailable || userId.isEmpty) {
      return SyncOperationResult.skipped('Sync unavailable');
    }

    try {
      final result = await cloudStorage.getAll(userId);
      if (!result.success) {
        return SyncOperationResult.failed(result.error ?? 'Error');
      }

      final cloudItems = result.data ?? [];
      for (final cloudItem in cloudItems) {
        await mergeCloudItem(cloudItem);
      }
      return SyncOperationResult.success(itemsSynced: cloudItems.length);
    } catch (e, stack) {
      errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return SyncOperationResult.failed(e.toString());
    }
  }

  /// Merge a cloud item with local storage
  /// Subclasses must implement their merge strategy
  Future<void> mergeCloudItem(T cloudItem);

  @override
  Future<SyncOperationResult> performFullSync(String userId) async {
    if (_isSyncing) return SyncOperationResult.skipped('Syncing');
    _isSyncing = true;
    try {
      await flushPendingSyncs();
      await processQueue();
      return await syncFromCloud(userId);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> addToQueue(T item, String userId) async {
    if (!_initialized) await init();
    await syncQueue.enqueue(localKey: item.key, userId: userId);
  }

  @override
  Future<SyncOperationResult> processQueue() async {
    if (!_initialized) await init();
    return syncQueue.processQueue();
  }

  @override
  Future<int> getPendingCount() async {
    if (!_initialized) await init();
    return syncQueue.getPendingCount();
  }

  @override
  Future<void> flushPendingSyncs() async {
    await debouncedSync.flush();
  }

  Future<void> flushDebouncedItems(Set<PendingSyncItem> items) async {
    if (items.isEmpty) return;
    final byUser = <String, List<dynamic>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.userId, () => []).add(item.key);
    }

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final keys = entry.value;
      final list = <T>[];
      for (final key in keys) {
        final item = localStorage.getByKey(key);
        if (item != null) list.add(item);
      }
      if (list.isNotEmpty) {
        await cloudStorage.batchWrite(list, userId);
      }
    }
  }

  @override
  Future<void> clearQueue() async {
    if (!_initialized) await init();
    await syncQueue.clear();
  }

  @override
  Future<void> moveToDeadLetter(SyncQueueItem<T> item) async {}

  @override
  Future<List<SyncQueueItem<T>>> getDeadLetterItems() async => [];

  @override
  Future<SyncOperationResult> retryDeadLetterItem(
    SyncQueueItem<T> item,
  ) async => SyncOperationResult.skipped('Not implemented');

  Future<int> getDeadLetterCount() async {
    if (!_initialized) await init();
    return syncQueue.getDeadLetterCount();
  }
}
