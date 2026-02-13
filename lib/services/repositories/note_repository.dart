/// Note repository implementation.
///
/// Provides a high-level API for note operations, coordinating
/// between local storage, cloud storage, and synchronization.
library;

import '../contracts/i_repository.dart';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_note_storage.dart';
import '../sync/note_sync_service.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/note_model.dart';

/// Repository for managing notes with local and cloud sync
class NoteRepository implements INoteRepository {
  final HiveNoteStorage _localStorage;
  final NoteSyncService _syncService;
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  bool _initialized = false;

  /// Expose localStorage for direct access when needed
  HiveNoteStorage get localStorage => _localStorage;

  /// Expose syncService for direct access when needed
  NoteSyncService get syncService => _syncService;

  NoteRepository({
    required HiveNoteStorage localStorage,
    required NoteSyncService syncService,
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
      _logger.debug('Service', '[NoteRepository] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing NoteRepository',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Note?> getById(dynamic key) async {
    return _localStorage.get(key);
  }

  @override
  Future<List<dynamic>> getAll() async {
    return _localStorage.getAll();
  }

  @override
  Future<void> save(dynamic item, String userId) async {
    final note = item as Note;
    note.updatedAt = DateTime.now();
    await _localStorage.save(note);
    await _syncService.syncToCloudDebounced(note, userId);
  }

  @override
  Future<void> saveAll(List<dynamic> items, String userId) async {
    for (final item in items) {
      await save(item, userId);
    }
  }

  @override
  Future<void> delete(dynamic key, String userId) async {
    final note = await _localStorage.get(key);
    if (note != null) {
      note.deleted = true;
      note.deletedAt = DateTime.now();
      note.updatedAt = DateTime.now();
      note.status = 'deleted';
      await note.save();
      await _syncService.syncToCloudDebounced(note, userId);
    }
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

  // ==================== FILTERABLE REPOSITORY ====================

  @override
  Future<List<dynamic>> getWhere(bool Function(dynamic) predicate) async {
    final notes = await _localStorage.getAll();
    return notes.where(predicate).toList();
  }

  @override
  Stream<List<dynamic>> watchWhere(bool Function(dynamic) predicate) {
    return _localStorage.watchWhere((note) => predicate(note));
  }

  @override
  Future<List<dynamic>> getByField(String field, dynamic value) async {
    final notes = await _localStorage.getAll();
    return notes.where((note) {
      switch (field) {
        case 'notebookId':
          return note.notebookId == value;
        case 'isPinned':
          return note.isPinned == value;
        case 'status':
          return note.status == value;
        case 'contentType':
          return note.contentType == value;
        default:
          return false;
      }
    }).toList();
  }

  // ==================== NOTE-SPECIFIC METHODS ====================

  @override
  Future<List<dynamic>> getByNotebook(String notebookId) async {
    return _localStorage.getByNotebook(notebookId);
  }

  @override
  Stream<List<dynamic>> watchByNotebook(String notebookId) {
    return _localStorage.watchByNotebook(notebookId);
  }

  @override
  Future<List<dynamic>> getPinned() async {
    return _localStorage.getPinned();
  }

  @override
  Future<List<dynamic>> searchContent(String query) async {
    return _localStorage.search(query);
  }

  // ==================== ADDITIONAL METHODS ====================

  /// Get root notes (no notebook)
  Future<List<Note>> getRootNotes() async {
    return _localStorage.getRootNotes();
  }

  /// Watch root notes
  Stream<List<Note>> watchRootNotes() {
    return _localStorage.watchRootNotes();
  }

  /// Get active notes
  Future<List<Note>> getActive() async {
    return _localStorage.getActive();
  }

  /// Get archived notes
  Future<List<Note>> getArchived() async {
    return _localStorage.getArchived();
  }

  /// Get notes by tag
  Future<List<Note>> getByTag(String tag) async {
    return _localStorage.getByTag(tag);
  }

  /// Get notes linked to a task
  Future<List<Note>> getByTask(String taskId) async {
    return _localStorage.getByTask(taskId);
  }

  /// Find note by Firestore ID
  Future<Note?> findByFirestoreId(String firestoreId) async {
    return _localStorage.findByFirestoreId(firestoreId);
  }

  /// Toggle pin status
  Future<void> togglePin(dynamic key, String userId) async {
    await _localStorage.togglePin(key);
    final note = await _localStorage.get(key);
    if (note != null) {
      await _syncService.syncToCloudDebounced(note, userId);
    }
  }

  /// Archive a note
  Future<void> archive(dynamic key, String userId) async {
    await _localStorage.archive(key);
    final note = await _localStorage.get(key);
    if (note != null) {
      await _syncService.syncToCloudDebounced(note, userId);
    }
  }

  /// Unarchive a note
  Future<void> unarchive(dynamic key, String userId) async {
    await _localStorage.unarchive(key);
    final note = await _localStorage.get(key);
    if (note != null) {
      await _syncService.syncToCloudDebounced(note, userId);
    }
  }

  /// Move note to notebook
  Future<void> moveToNotebook(dynamic key, String? notebookId, String userId) async {
    await _localStorage.moveToNotebook(key, notebookId);
    final note = await _localStorage.get(key);
    if (note != null) {
      await _syncService.syncToCloudDebounced(note, userId);
    }
  }

  /// Force sync a specific note
  Future<SyncOperationResult> forceSyncNote(Note note, String userId) async {
    return _syncService.syncToCloud(note, userId);
  }

  /// Flush pending debounced syncs
  Future<void> flushPendingSyncs() async {
    await _syncService.flushPendingSyncs();
  }

  /// Purge soft-deleted notes older than specified days
  Future<int> purgeSoftDeleted({int olderThanDays = 30}) async {
    return _localStorage.purgeSoftDeleted(olderThanDays: olderThanDays);
  }

  /// Get dead letter queue count
  Future<int> getDeadLetterCount() async {
    return _syncService.getDeadLetterCount();
  }

  /// Retry all dead letter items
  Future<int> retryDeadLetterItems() async {
    return _syncService.retryAllDeadLetterItems();
  }

  /// Close the repository
  Future<void> close() async {
    await _localStorage.close();
  }
}
