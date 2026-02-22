import 'dart:async';
import '../../../services/contracts/i_sync_service.dart';
import '../data/category_storage.dart';
import '../data/firestore_category_storage.dart';
import '../../../services/error_handler.dart';
import '../models/finance_category.dart';
import '../../../services/sync/sync_queue.dart';
import '../../../services/sync/sync_utils.dart';

class CategorySyncService implements ISyncService<FinanceCategory> {
  final CategoryStorage _localStorage;
  final FirestoreCategoryStorage _cloudStorage;
  final ErrorHandler _errorHandler;
  final Future<bool> Function() _isCloudSyncEnabled;

  late final GenericSyncQueue<FinanceCategory> _syncQueue;
  late final DebouncedSyncManager _debouncedSync;

  final SyncConfig config;
  bool _isSyncing = false;
  bool _initialized = false;

  CategorySyncService({
    required CategoryStorage localStorage,
    required FirestoreCategoryStorage cloudStorage,
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    this.config = const SyncConfig(),
  }) : _localStorage = localStorage,
       _cloudStorage = cloudStorage,
       _errorHandler = errorHandler,
       _isCloudSyncEnabled = isCloudSyncEnabled {
    _syncQueue = GenericSyncQueue<FinanceCategory>(
      queueBoxName: 'finance_category_sync_queue',
      deadLetterBoxName: 'finance_category_dead_letter',
      errorHandler: errorHandler,
      findLocalItem: (key) => _localStorage.getByKey(key),
      syncItem: _syncSingleItem,
      config: config,
    );

    _debouncedSync = DebouncedSyncManager(
      debounceDelay: config.debounceDelay,
      onFlush: _flushDebouncedItems,
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    await _syncQueue.init();
    _initialized = true;
  }

  @override
  Future<bool> get isSyncEnabled => _isCloudSyncEnabled();

  @override
  bool get isSyncing => _isSyncing;

  @override
  Future<SyncOperationResult> syncToCloud(
    FinanceCategory item,
    String userId,
  ) async {
    if (!await isSyncEnabled)
      return SyncOperationResult.skipped('Sync disabled');
    if (!_cloudStorage.isAvailable) return SyncOperationResult.offline();
    if (userId.isEmpty) return SyncOperationResult.skipped('No user');

    try {
      await _syncSingleItem(item, userId);
      return SyncOperationResult.success();
    } catch (e) {
      await addToQueue(item, userId);
      return SyncOperationResult.failed(e.toString());
    }
  }

  @override
  Future<void> syncToCloudDebounced(FinanceCategory item, String userId) async {
    if (!await isSyncEnabled || !_cloudStorage.isAvailable || userId.isEmpty)
      return;
    if (item.key != null) {
      _debouncedSync.add(item.key, userId);
    }
  }

  Future<void> _syncSingleItem(FinanceCategory item, String userId) async {
    final result = await _cloudStorage.create(item, userId);
    if (!result.success) throw Exception(result.error);
  }

  @override
  Future<SyncOperationResult> syncFromCloud(
    String userId, {
    DateTime? since,
  }) async {
    if (!await isSyncEnabled || !_cloudStorage.isAvailable || userId.isEmpty) {
      return SyncOperationResult.skipped('Sync unvailable');
    }

    try {
      final result = await _cloudStorage.getAll(userId);
      if (!result.success)
        return SyncOperationResult.failed(result.error ?? 'Error');

      final cloudItems = result.data ?? [];
      for (final cloudItem in cloudItems) {
        // Categories from cloud are considered authoritative for now
        await _localStorage.save(cloudItem);
      }
      return SyncOperationResult.success(itemsSynced: cloudItems.length);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return SyncOperationResult.failed(e.toString());
    }
  }

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
  Future<void> addToQueue(FinanceCategory item, String userId) async {
    if (!_initialized) await init();
    await _syncQueue.enqueue(localKey: item.key, userId: userId);
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

  Future<void> _flushDebouncedItems(Set<PendingSyncItem> items) async {
    if (items.isEmpty) return;
    final byUser = <String, List<dynamic>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.userId, () => []).add(item.key);
    }

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final keys = entry.value;
      final list = <FinanceCategory>[];
      for (final key in keys) {
        final item = await _localStorage.getByKey(key);
        if (item != null) list.add(item);
      }
      if (list.isNotEmpty) {
        await _cloudStorage.batchWrite(list, userId);
      }
    }
  }

  @override
  Future<void> clearQueue() async {
    if (!_initialized) await init();
    await _syncQueue.clear();
  }

  @override
  Future<void> moveToDeadLetter(SyncQueueItem<FinanceCategory> item) async {}
  @override
  Future<List<SyncQueueItem<FinanceCategory>>> getDeadLetterItems() async => [];
  @override
  Future<SyncOperationResult> retryDeadLetterItem(
    SyncQueueItem<FinanceCategory> item,
  ) async => SyncOperationResult.skipped('Not implemented');

  Future<int> getDeadLetterCount() async {
    if (!_initialized) await init();
    return _syncQueue.getDeadLetterCount();
  }
}
