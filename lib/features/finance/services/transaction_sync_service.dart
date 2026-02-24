import '../data/transaction_storage.dart';
import '../data/firestore_transaction_storage.dart';
import '../../../services/error_handler.dart';
import '../models/transaction.dart';
import '../../../services/contracts/i_sync_service.dart';
import 'base_sync_service.dart';

/// Adapter to make TransactionStorage compatible with BaseSyncStorage
class _TransactionStorageAdapter implements BaseSyncStorage<Transaction> {
  final TransactionStorage _storage;
  final Map<dynamic, Transaction?> _cache = {};

  _TransactionStorageAdapter(this._storage);

  @override
  Transaction? getByKey(dynamic key) {
    // Hive's get is synchronous, but getByKey is async for consistency
    // Use a cache to avoid async/sync mismatch
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    // Schedule async load and return cached value
    _storage.getByKey(key).then((value) {
      _cache[key] = value;
    });
    return _cache[key];
  }

  @override
  Future<void> save(Transaction item) async {
    await _storage.save(item);
    if (item.key != null) {
      _cache[item.key] = item;
    }
  }

  @override
  bool get isAvailable => true;
}

/// Adapter to make FirestoreTransactionStorage compatible with BaseCloudStorage
class _FirestoreTransactionStorageAdapter
    implements BaseCloudStorage<Transaction> {
  final FirestoreTransactionStorage _storage;

  _FirestoreTransactionStorageAdapter(this._storage);

  @override
  Future<StorageOperationResult<void>> create(
    Transaction item,
    String userId,
  ) async {
    final result = await _storage.create(item, userId);
    return StorageOperationResult(success: result.success, error: result.error);
  }

  @override
  Future<StorageOperationResult<List<Transaction>>> getAll(
    String userId,
  ) async {
    final result = await _storage.getAll(userId);
    return StorageOperationResult(
      success: result.success,
      data: result.data,
      error: result.error,
    );
  }

  @override
  Future<void> batchWrite(List<Transaction> items, String userId) async {
    await _storage.batchWrite(items, userId);
  }

  @override
  bool get isAvailable => _storage.isAvailable;
}

/// Transaction-specific sync service extending BaseSyncService
/// Eliminates ~200 lines of duplicated code
class TransactionSyncService extends BaseSyncService<Transaction> {
  final TransactionStorage _localStorage;

  TransactionSyncService({
    required TransactionStorage localStorage,
    required FirestoreTransactionStorage cloudStorage,
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    SyncConfig config = const SyncConfig(),
  }) : _localStorage = localStorage,
       super(
         localStorage: _TransactionStorageAdapter(localStorage),
         cloudStorage: _FirestoreTransactionStorageAdapter(cloudStorage),
         errorHandler: errorHandler,
         isCloudSyncEnabled: isCloudSyncEnabled,
         queueBoxName: 'finance_transaction_sync_queue',
         deadLetterBoxName: 'finance_transaction_dead_letter',
         config: config,
       );

  @override
  Future<void> onBeforeDebounceSync(Transaction item) async {
    // Update timestamp before debounced sync
    item.lastUpdatedAt = DateTime.now();
    if (item.isInBox) await item.save();
  }

  @override
  Future<void> mergeCloudItem(Transaction cloudItem) async {
    final localItem = await _localStorage.getByKey(cloudItem.id);
    if (localItem == null) {
      await _localStorage.save(cloudItem);
      return;
    }

    final cloudUpdated = cloudItem.lastUpdatedAt ?? cloudItem.createdAt;
    final localUpdated = localItem.lastUpdatedAt ?? localItem.createdAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      localItem.title = cloudItem.title;
      localItem.amount = cloudItem.amount;
      localItem.date = cloudItem.date;
      localItem.categoryId = cloudItem.categoryId;
      localItem.type = cloudItem.type;
      localItem.note = cloudItem.note;
      localItem.lastUpdatedAt = cloudItem.lastUpdatedAt;
      localItem.deleted = cloudItem.deleted;
      localItem.deletedAt = cloudItem.deletedAt;
      await localItem.save();
    }
  }
}
