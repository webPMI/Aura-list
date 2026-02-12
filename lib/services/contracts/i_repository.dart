/// Interface for repository pattern.
///
/// Repositories provide a high-level API for data operations,
/// abstracting away the details of local and cloud storage.
library;

import 'i_sync_service.dart';

/// Generic interface for repositories
abstract class IRepository<T> {
  /// Initialize the repository
  Future<void> init();

  /// Check if repository is initialized
  bool get isInitialized;

  /// Get an item by key
  Future<T?> getById(dynamic key);

  /// Get all items
  Future<List<T>> getAll();

  /// Save an item (local + cloud sync)
  Future<void> save(T item, String userId);

  /// Save multiple items
  Future<void> saveAll(List<T> items, String userId);

  /// Delete an item (soft delete + cloud sync)
  Future<void> delete(dynamic key, String userId);

  /// Delete multiple items
  Future<void> deleteAll(List<dynamic> keys, String userId);

  /// Watch for changes
  Stream<List<T>> watchAll();

  /// Perform full sync with cloud
  Future<SyncOperationResult> sync(String userId);

  /// Get count of pending sync items
  Future<int> getPendingSyncCount();

  /// Force process sync queue
  Future<void> processSyncQueue();
}

/// Interface for repositories with filtering support
abstract class IFilterableRepository<T> extends IRepository<T> {
  /// Get items matching a predicate
  Future<List<T>> getWhere(bool Function(T) predicate);

  /// Watch items matching a predicate
  Stream<List<T>> watchWhere(bool Function(T) predicate);

  /// Get items by a specific field value
  Future<List<T>> getByField(String field, dynamic value);
}

/// Interface for repositories with search support
abstract class ISearchableRepository<T> extends IRepository<T> {
  /// Search items by text
  Future<List<T>> search(String query);

  /// Search with pagination
  Future<List<T>> searchPaginated(String query, {int page = 0, int pageSize = 20});
}

/// Interface for task-specific repository
abstract class ITaskRepository extends IFilterableRepository<dynamic> {
  /// Get tasks by type (daily, weekly, etc.)
  Future<List<dynamic>> getByType(String type);

  /// Watch tasks by type
  Stream<List<dynamic>> watchByType(String type);

  /// Get completed tasks
  Future<List<dynamic>> getCompleted();

  /// Get overdue tasks
  Future<List<dynamic>> getOverdue();

  /// Get tasks by category
  Future<List<dynamic>> getByCategory(String category);

  /// Get tasks by priority
  Future<List<dynamic>> getByPriority(int priority);

  /// Mark task as completed
  Future<void> markCompleted(dynamic key, String userId);

  /// Mark task as uncompleted
  Future<void> markUncompleted(dynamic key, String userId);
}

/// Interface for note-specific repository
abstract class INoteRepository extends IFilterableRepository<dynamic> {
  /// Get notes by notebook
  Future<List<dynamic>> getByNotebook(String notebookId);

  /// Watch notes by notebook
  Stream<List<dynamic>> watchByNotebook(String notebookId);

  /// Get pinned notes
  Future<List<dynamic>> getPinned();

  /// Search notes by content
  Future<List<dynamic>> searchContent(String query);
}

/// Interface for notebook-specific repository
abstract class INotebookRepository extends IRepository<dynamic> {
  /// Get notebooks with note counts
  Future<List<Map<String, dynamic>>> getWithNoteCounts();

  /// Get default notebook
  Future<dynamic> getDefault();

  /// Create default notebook if not exists
  Future<void> ensureDefaultExists(String userId);
}
