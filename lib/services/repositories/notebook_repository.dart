/// Notebook repository implementation.
///
/// Provides a high-level API for notebook operations, coordinating
/// between local storage, cloud storage, and synchronization.
library;

import '../contracts/i_repository.dart';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_notebook_storage.dart';
import '../sync/notebook_sync_service.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/notebook_model.dart';

/// Repository for managing notebooks with local and cloud sync
class NotebookRepository implements INotebookRepository {
  final HiveNotebookStorage _localStorage;
  final NotebookSyncService _syncService;
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  bool _initialized = false;

  /// Expose localStorage for direct access when needed
  HiveNotebookStorage get localStorage => _localStorage;

  /// Expose syncService for direct access when needed
  NotebookSyncService get syncService => _syncService;

  NotebookRepository({
    required HiveNotebookStorage localStorage,
    required NotebookSyncService syncService,
    required ErrorHandler errorHandler,
  })  : _localStorage = localStorage,
        _syncService = syncService,
        _errorHandler = errorHandler;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _localStorage.init();
      await _syncService.init();
      _initialized = true;
      _logger.debug('Service', '[NotebookRepository] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing NotebookRepository',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Notebook?> getById(dynamic key) async {
    return _localStorage.get(key);
  }

  @override
  Future<List<dynamic>> getAll() async {
    return _localStorage.getAll();
  }

  @override
  Future<void> save(dynamic item, String userId) async {
    final notebook = item as Notebook;
    notebook.updatedAt = DateTime.now();
    await _localStorage.save(notebook);
    await _syncService.syncToCloudDebounced(notebook, userId);
  }

  @override
  Future<void> saveAll(List<dynamic> items, String userId) async {
    for (final item in items) {
      await save(item, userId);
    }
  }

  @override
  Future<void> delete(dynamic key, String userId) async {
    // Notebooks use hard delete: eliminar local y en cloud si estaba sincronizado
    final notebook = await _localStorage.get(key);
    if (notebook != null && notebook.firestoreId.isNotEmpty) {
      await _syncService.deleteFromCloud(notebook.firestoreId, userId);
    }
    await _localStorage.delete(key);
  }

  @override
  Future<void> deleteAll(List<dynamic> keys, String userId) async {
    for (final key in keys) {
      await delete(key, userId);
    }
  }

  @override
  Stream<List<dynamic>> watchAll() {
    return _localStorage.watch();
  }

  @override
  Future<SyncOperationResult> sync(String userId) async {
    return _syncService.performFullSync(userId);
  }

  @override
  Future<int> getPendingSyncCount() async {
    return _syncService.getPendingCount();
  }

  @override
  Future<void> processSyncQueue() async {
    await _syncService.processQueue();
  }

  // ==================== NOTEBOOK-SPECIFIC METHODS ====================

  @override
  Future<List<Map<String, dynamic>>> getWithNoteCounts() async {
    // This would need to be implemented with a note storage reference
    // For now, return notebooks without counts
    final notebooks = await _localStorage.getAll();
    return notebooks.map((n) => {
      'notebook': n,
      'noteCount': 0,
    }).toList();
  }

  @override
  Future<dynamic> getDefault() async {
    return _localStorage.findByName('General');
  }

  @override
  Future<void> ensureDefaultExists(String userId) async {
    final defaultNotebook = await _localStorage.ensureDefaultExists();
    await _syncService.syncToCloudDebounced(defaultNotebook, userId);
  }

  // ==================== ADDITIONAL METHODS ====================

  /// Get favorited notebooks
  Future<List<Notebook>> getFavorited() async {
    return _localStorage.getFavorited();
  }

  /// Watch favorited notebooks
  Stream<List<Notebook>> watchFavorited() {
    return _localStorage.watchFavorited();
  }

  /// Get root notebooks (no parent)
  Future<List<Notebook>> getRootNotebooks() async {
    return _localStorage.getRootNotebooks();
  }

  /// Get child notebooks
  Future<List<Notebook>> getChildren(String parentId) async {
    return _localStorage.getChildren(parentId);
  }

  /// Find notebook by Firestore ID
  Future<Notebook?> findByFirestoreId(String firestoreId) async {
    return _localStorage.findByFirestoreId(firestoreId);
  }

  /// Find notebook by name
  Future<Notebook?> findByName(String name) async {
    return _localStorage.findByName(name);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(dynamic key, String userId) async {
    await _localStorage.toggleFavorite(key);
    final notebook = await _localStorage.get(key);
    if (notebook != null) {
      await _syncService.syncToCloudDebounced(notebook, userId);
    }
  }

  /// Force sync a specific notebook
  Future<SyncOperationResult> forceSyncNotebook(Notebook notebook, String userId) async {
    return _syncService.syncToCloud(notebook, userId);
  }

  /// Flush pending debounced syncs
  Future<void> flushPendingSyncs() async {
    await _syncService.flushPendingSyncs();
  }

  /// Get dead letter queue count
  Future<int> getDeadLetterCount() async {
    return _syncService.getDeadLetterCount();
  }

  /// Retry all dead letter items
  Future<int> retryDeadLetterItems() async {
    return _syncService.retryAllDeadLetterItems();
  }

  /// Get notebook by string ID (for note.notebookId)
  Future<Notebook?> getByStringId(String id) async {
    return _localStorage.getByStringId(id);
  }

  /// Close the repository
  Future<void> close() async {
    await _localStorage.close();
  }
}
