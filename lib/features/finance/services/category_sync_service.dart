import '../data/category_storage.dart';
import '../data/firestore_category_storage.dart';
import '../models/finance_category.dart';
import 'base_sync_service.dart';

/// Adapter to make CategoryStorage compatible with BaseSyncStorage
class _CategoryStorageAdapter implements BaseSyncStorage<FinanceCategory> {
  final CategoryStorage _storage;

  _CategoryStorageAdapter(this._storage);

  @override
  Future<FinanceCategory?> getByKey(dynamic key) => _storage.getByKey(key);

  @override
  Future<List<FinanceCategory>> getAll() => _storage.getAll();

  @override
  Future<void> save(FinanceCategory item) => _storage.save(item);

  @override
  bool get isAvailable => true;
}

/// Adapter to make FirestoreCategoryStorage compatible with BaseCloudStorage
class _FirestoreCategoryStorageAdapter
    implements BaseCloudStorage<FinanceCategory> {
  final FirestoreCategoryStorage _storage;

  _FirestoreCategoryStorageAdapter(this._storage);

  @override
  Future<StorageOperationResult<void>> create(
    FinanceCategory item,
    String userId,
  ) async {
    final result = await _storage.create(item, userId);
    return StorageOperationResult(success: result.success, error: result.error);
  }

  @override
  Future<StorageOperationResult<List<FinanceCategory>>> getAll(
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
  Future<void> batchWrite(List<FinanceCategory> items, String userId) async {
    await _storage.batchWrite(items, userId);
  }

  @override
  bool get isAvailable => _storage.isAvailable;
}

/// Category-specific sync service extending BaseSyncService
/// Eliminates ~200 lines of duplicated code
class CategorySyncService extends BaseSyncService<FinanceCategory> {
  final CategoryStorage _localStorage;

  CategorySyncService({
    required CategoryStorage localStorage,
    required FirestoreCategoryStorage cloudStorage,
    required super.errorHandler,
    required super.isCloudSyncEnabled,
    super.config,
  }) : _localStorage = localStorage,
       super(
         localStorage: _CategoryStorageAdapter(localStorage),
         cloudStorage: _FirestoreCategoryStorageAdapter(cloudStorage),
         queueBoxName: 'finance_category_sync_queue',
         deadLetterBoxName: 'finance_category_dead_letter',
       );

  @override
  Future<void> mergeCloudItem(FinanceCategory cloudItem) async {
    // Categories from cloud are considered authoritative for now
    // Simple merge strategy: always save cloud version
    await _localStorage.save(cloudItem);
  }
}



