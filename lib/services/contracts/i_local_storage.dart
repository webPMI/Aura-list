/// Interface for local storage operations.
///
/// Provides a consistent API for storing and retrieving data locally
/// using Hive or any other local storage solution.
library;

/// Generic interface for local storage operations
abstract class ILocalStorage<T> {
  /// Initialize the storage (open box, etc.)
  Future<void> init();

  /// Check if storage is initialized and ready
  bool get isInitialized;

  /// Get an item by its key
  Future<T?> get(dynamic key);

  /// Get all items (excluding soft-deleted)
  Future<List<T>> getAll();

  /// Get all items including soft-deleted
  Future<List<T>> getAllIncludingDeleted();

  /// Save an item (insert or update)
  Future<void> save(T item);

  /// Save multiple items in batch
  Future<void> saveAll(List<T> items);

  /// Delete an item by key (hard delete)
  Future<void> delete(dynamic key);

  /// Delete multiple items by keys
  Future<void> deleteAll(List<dynamic> keys);

  /// Soft delete an item (mark as deleted)
  Future<void> softDelete(dynamic key);

  /// Watch for changes and emit updated list
  Stream<List<T>> watch();

  /// Watch for changes filtered by a predicate
  Stream<List<T>> watchWhere(bool Function(T) predicate);

  /// Clear all items
  Future<void> clear();

  /// Get count of items
  Future<int> count();

  /// Check if an item exists by key
  Future<bool> exists(dynamic key);

  /// Find item by a predicate
  Future<T?> findFirst(bool Function(T) predicate);

  /// Find all items matching a predicate
  Future<List<T>> findAll(bool Function(T) predicate);

  /// Close the storage connection
  Future<void> close();
}

/// Interface for items that support soft delete
abstract class ISoftDeletable {
  bool get deleted;
  DateTime? get deletedAt;
  void markDeleted();
}

/// Interface for items that have a cloud ID
abstract class ICloudSyncable {
  String get firestoreId;
  set firestoreId(String value);
  DateTime? get lastUpdatedAt;
  set lastUpdatedAt(DateTime? value);
}

/// Interface for items with creation timestamp
abstract class ITimestamped {
  DateTime get createdAt;
}
