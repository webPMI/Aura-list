import '../data/category_storage.dart';
import '../data/firestore_category_storage.dart';
import '../../../services/error_handler.dart';
import '../models/finance_category.dart';
import '../../../services/contracts/i_sync_service.dart';
import 'base_sync_service.dart';

/// Adapter to make CategoryStorage compatible with BaseSyncStorage
class _CategoryStorageAdapter implements BaseSyncStorage<FinanceCategory> {
  final CategoryStorage _storage;
  final Map<dynamic, FinanceCategory?> _cache = {};

  _CategoryStorageAdapter(this._storage);

  @override
  FinanceCategory? getByKey(dynamic key) {
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
  Future<void> save(FinanceCategory item) async {
    await _storage.save(item);
    if (item.key != null) {
      _cache[item.key] = item;
    }
  }

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
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    SyncConfig config = const SyncConfig(),
  }) : _localStorage = localStorage,
       super(
         localStorage: _CategoryStorageAdapter(localStorage),
         cloudStorage: _FirestoreCategoryStorageAdapter(cloudStorage),
         errorHandler: errorHandler,
         isCloudSyncEnabled: isCloudSyncEnabled,
         queueBoxName: 'finance_category_sync_queue',
         deadLetterBoxName: 'finance_category_dead_letter',
         config: config,
       );

  @override
  Future<void> mergeCloudItem(FinanceCategory cloudItem) async {
    // Categories from cloud are considered authoritative for now
    // Simple merge strategy: always save cloud version
    await _localStorage.save(cloudItem);
  }
}
