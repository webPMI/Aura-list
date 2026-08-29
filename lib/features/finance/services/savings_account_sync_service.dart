import '../data/savings_account_storage.dart';
import '../data/firestore_savings_account_storage.dart';
import '../models/savings_account.dart';
import 'base_sync_service.dart';

/// Adapter to make SavingsAccountStorage compatible with BaseSyncStorage
class _SavingsAccountStorageAdapter implements BaseSyncStorage<SavingsAccount> {
  final SavingsAccountStorage _storage;

  _SavingsAccountStorageAdapter(this._storage);

  @override
  Future<SavingsAccount?> getByKey(dynamic key) => _storage.getByKey(key);

  @override
  Future<List<SavingsAccount>> getAll() => _storage.getAll();

  @override
  Future<void> save(SavingsAccount item) => _storage.save(item);

  @override
  bool get isAvailable => true;
}

/// Adapter to make FirestoreSavingsAccountStorage compatible with BaseCloudStorage
class _FirestoreSavingsAccountStorageAdapter
    implements BaseCloudStorage<SavingsAccount> {
  final FirestoreSavingsAccountStorage _storage;

  _FirestoreSavingsAccountStorageAdapter(this._storage);

  @override
  Future<StorageOperationResult<void>> create(
    SavingsAccount item,
    String userId,
  ) async {
    final result = await _storage.create(item, userId);
    return StorageOperationResult(success: result.success, error: result.error);
  }

  @override
  Future<StorageOperationResult<List<SavingsAccount>>> getAll(
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
  Future<void> batchWrite(List<SavingsAccount> items, String userId) async {
    await _storage.batchWrite(items, userId);
  }

  @override
  bool get isAvailable => _storage.isAvailable;
}

/// Sync service para cuentas de ahorro e inversión.
class SavingsAccountSyncService extends BaseSyncService<SavingsAccount> {
  final SavingsAccountStorage _localStorage;

  SavingsAccountSyncService({
    required SavingsAccountStorage localStorage,
    required FirestoreSavingsAccountStorage cloudStorage,
    required super.errorHandler,
    required super.isCloudSyncEnabled,
    super.config,
  }) : _localStorage = localStorage,
       super(
         localStorage: _SavingsAccountStorageAdapter(localStorage),
         cloudStorage: _FirestoreSavingsAccountStorageAdapter(cloudStorage),
         queueBoxName: 'finance_savings_accounts_sync_queue',
         deadLetterBoxName: 'finance_savings_accounts_dead_letter',
       );

  @override
  Future<void> onBeforeDebounceSync(SavingsAccount item) async {
    // Update timestamp before debounced sync
    item.lastUpdatedAt = DateTime.now();
    if (item.isInBox) await item.save();
  }

  @override
  Future<void> mergeCloudItem(SavingsAccount cloudItem) async {
    final localItem = await _localStorage.getByKey(cloudItem.id);
    if (localItem == null) {
      await _localStorage.save(cloudItem);
      return;
    }

    final cloudUpdated = cloudItem.lastUpdatedAt ?? cloudItem.createdAt;
    final localUpdated = localItem.lastUpdatedAt ?? localItem.createdAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      localItem.name = cloudItem.name;
      localItem.type = cloudItem.type;
      localItem.initialBalance = cloudItem.initialBalance;
      localItem.currentBalance = cloudItem.currentBalance;
      localItem.monthlyContribution = cloudItem.monthlyContribution;
      localItem.annualInterestRate = cloudItem.annualInterestRate;
      localItem.icon = cloudItem.icon;
      localItem.color = cloudItem.color;
      localItem.startDate = cloudItem.startDate;
      localItem.lastUpdatedAt = cloudItem.lastUpdatedAt;
      localItem.deleted = cloudItem.deleted;
      localItem.deletedAt = cloudItem.deletedAt;
      localItem.firestoreId = cloudItem.firestoreId;
      await localItem.save();
    }
  }
}
