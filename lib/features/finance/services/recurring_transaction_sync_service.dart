import '../data/recurring_transaction_storage.dart';
import '../data/firestore_recurring_transaction_storage.dart';
import '../models/recurring_transaction.dart';
import 'base_sync_service.dart';

/// Adapter to make RecurringTransactionStorage compatible with BaseSyncStorage
class _RecurringTransactionStorageAdapter
    implements BaseSyncStorage<RecurringTransaction> {
  final RecurringTransactionStorage _storage;
  final Map<dynamic, RecurringTransaction?> _cache = {};

  _RecurringTransactionStorageAdapter(this._storage);

  @override
  RecurringTransaction? getByKey(dynamic key) {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    _storage.getById(key.toString()).then((value) {
      _cache[key] = value;
    });
    return _cache[key];
  }

  @override
  Future<void> save(RecurringTransaction item) async {
    await _storage.save(item);
    if (item.key != null) {
      _cache[item.key] = item;
    }
  }

  @override
  bool get isAvailable => true;
}

/// Adapter to make FirestoreRecurringTransactionStorage compatible with BaseCloudStorage
class _FirestoreRecurringTransactionStorageAdapter
    implements BaseCloudStorage<RecurringTransaction> {
  final FirestoreRecurringTransactionStorage _storage;

  _FirestoreRecurringTransactionStorageAdapter(this._storage);

  @override
  Future<StorageOperationResult<void>> create(
    RecurringTransaction item,
    String userId,
  ) async {
    final result = await _storage.create(item, userId);
    return StorageOperationResult(success: result.success, error: result.error);
  }

  @override
  Future<StorageOperationResult<List<RecurringTransaction>>> getAll(
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
  Future<void> batchWrite(List<RecurringTransaction> items, String userId) async {
    await _storage.batchWrite(items, userId);
  }

  @override
  bool get isAvailable => _storage.isAvailable;
}

/// RecurringTransaction sync service extending BaseSyncService
class RecurringTransactionSyncService
    extends BaseSyncService<RecurringTransaction> {
  final RecurringTransactionStorage _localStorage;

  RecurringTransactionSyncService({
    required RecurringTransactionStorage localStorage,
    required FirestoreRecurringTransactionStorage cloudStorage,
    required super.errorHandler,
    required super.isCloudSyncEnabled,
    super.config,
  })  : _localStorage = localStorage,
        super(
          localStorage: _RecurringTransactionStorageAdapter(localStorage),
          cloudStorage:
              _FirestoreRecurringTransactionStorageAdapter(cloudStorage),
          queueBoxName: 'finance_recurring_sync_queue',
          deadLetterBoxName: 'finance_recurring_dead_letter',
        );

  @override
  Future<void> onBeforeDebounceSync(RecurringTransaction item) async {
    item.lastUpdatedAt = DateTime.now();
    if (item.isInBox) await item.save();
  }

  @override
  Future<void> mergeCloudItem(RecurringTransaction cloudItem) async {
    final localItem = await _localStorage.getById(cloudItem.id);
    if (localItem == null) {
      await _localStorage.save(cloudItem);
      return;
    }

    final cloudUpdated = cloudItem.lastUpdatedAt ?? cloudItem.createdAt;
    final localUpdated = localItem.lastUpdatedAt ?? localItem.createdAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      localItem.title = cloudItem.title;
      localItem.amount = cloudItem.amount;
      localItem.categoryId = cloudItem.categoryId;
      localItem.type = cloudItem.type;
      localItem.recurrence = cloudItem.recurrence;
      localItem.autoGenerate = cloudItem.autoGenerate;
      localItem.lastGenerated = cloudItem.lastGenerated;
      localItem.active = cloudItem.active;
      localItem.linkedTaskId = cloudItem.linkedTaskId;
      localItem.note = cloudItem.note;
      localItem.lastUpdatedAt = cloudItem.lastUpdatedAt;
      localItem.deleted = cloudItem.deleted;
      localItem.deletedAt = cloudItem.deletedAt;
      localItem.firestoreId = cloudItem.firestoreId;
      localItem.totalInstallments = cloudItem.totalInstallments;
      localItem.paidInstallments = cloudItem.paidInstallments;
      localItem.deferredInstallments = cloudItem.deferredInstallments;
      localItem.installmentPaymentModeStr = cloudItem.installmentPaymentModeStr;
      localItem.paymentDateHistory = cloudItem.paymentDateHistory;
      await localItem.save();
    }
  }
}
