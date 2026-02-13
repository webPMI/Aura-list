/// Hive implementation of local note storage.
///
/// Provides persistent local storage for notes using Hive,
/// with support for soft delete, watching changes, and finding notes.
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/note_model.dart';
import '../../contracts/i_local_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Hive-based local storage for notes
class HiveNoteStorage implements ILocalStorage<Note> {
  static const String boxName = 'notes';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<Note>? _box;
  bool _initialized = false;

  HiveNoteStorage(this._errorHandler);

  /// Expose box for direct access when needed
  Box<Note>? get box => _box;

  @override
  bool get isInitialized => _initialized && _box != null && _box!.isOpen;

  Future<Box<Note>> _getBox() async {
    if (!isInitialized) await init();
    return _box!;
  }

  @override
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;

    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<Note>(boxName)
          : await Hive.openBox<Note>(boxName);
      _initialized = true;
      _logger.debug('Service', '[HiveNoteStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing note storage',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Note?> get(dynamic key) async {
    try {
      final box = await _getBox();
      return box.get(key);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting note',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Note>> getAll() async {
    try {
      final box = await _getBox();
      return box.values.where((note) => !note.deleted).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting all notes',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<Note>> getAllIncludingDeleted() async {
    try {
      final box = await _getBox();
      return box.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting all notes including deleted',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> save(Note note) async {
    try {
      final box = await _getBox();

      if (note.isInBox) {
        await note.save();
      } else {
        final existing = await _findExisting(note);
        if (existing != null) {
          existing.updateInPlace(
            firestoreId: note.firestoreId.isNotEmpty ? note.firestoreId : null,
            title: note.title,
            content: note.content,
            updatedAt: note.updatedAt,
            taskId: note.taskId,
            color: note.color,
            isPinned: note.isPinned,
            tags: note.tags,
            deleted: note.deleted,
            deletedAt: note.deletedAt,
            checklist: note.checklist,
            notebookId: note.notebookId,
            status: note.status,
            richContent: note.richContent,
            contentType: note.contentType,
          );
          await existing.save();
          _logger.debug('Service', '[HiveNoteStorage] Updated existing note');
        } else {
          await box.add(note);
          _logger.debug('Service', '[HiveNoteStorage] Added new note');
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error saving note',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> saveAll(List<Note> notes) async {
    for (final note in notes) {
      await save(note);
    }
  }

  @override
  Future<void> delete(dynamic key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
      _logger.debug('Service', '[HiveNoteStorage] Hard deleted note: $key');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting note',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAll(List<dynamic> keys) async {
    try {
      final box = await _getBox();
      await box.deleteAll(keys);
      _logger.debug(
        'Service',
        '[HiveNoteStorage] Hard deleted ${keys.length} notes',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting notes',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> softDelete(dynamic key) async {
    try {
      final note = await get(key);
      if (note != null) {
        note.deleted = true;
        note.deletedAt = DateTime.now();
        note.updatedAt = DateTime.now();
        note.status = 'deleted';
        await note.save();
        _logger.debug('Service', '[HiveNoteStorage] Soft deleted note: $key');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error soft deleting note',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Note>> watch() async* {
    try {
      final box = await _getBox();

      yield box.values.where((note) => !note.deleted).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      await for (final _ in box.watch()) {
        yield box.values.where((note) => !note.deleted).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error watching notes',
        stackTrace: stack,
      );
      yield [];
    }
  }

  @override
  Stream<List<Note>> watchWhere(bool Function(Note) predicate) async* {
    try {
      final box = await _getBox();

      List<Note> getFiltered() {
        return box.values.where((n) => !n.deleted && predicate(n)).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      yield getFiltered();

      await for (final _ in box.watch()) {
        yield getFiltered();
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error watching notes with filter',
        stackTrace: stack,
      );
      yield [];
    }
  }

  @override
  Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
      _logger.debug('Service', '[HiveNoteStorage] Cleared all notes');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error clearing notes',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<int> count() async {
    try {
      final box = await _getBox();
      return box.values.where((note) => !note.deleted).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> exists(dynamic key) async {
    try {
      final box = await _getBox();
      return box.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Note?> findFirst(bool Function(Note) predicate) async {
    try {
      final box = await _getBox();
      return box.values.cast<Note?>().firstWhere(
            (n) => n != null && !n.deleted && predicate(n),
            orElse: () => null,
          );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding note',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Note>> findAll(bool Function(Note) predicate) async {
    try {
      final box = await _getBox();
      return box.values.where((n) => !n.deleted && predicate(n)).toList();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding notes',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> close() async {
    try {
      await _box?.close();
      _initialized = false;
      _logger.debug('Service', '[HiveNoteStorage] Closed');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error closing note storage',
        stackTrace: stack,
      );
    }
  }

  // ==================== NOTE-SPECIFIC METHODS ====================

  /// Get notes by notebook ID
  Future<List<Note>> getByNotebook(String? notebookId) async {
    return findAll((note) => note.notebookId == notebookId);
  }

  /// Watch notes by notebook ID
  Stream<List<Note>> watchByNotebook(String? notebookId) {
    return watchWhere((note) => note.notebookId == notebookId);
  }

  /// Get notes without a notebook (root notes)
  Future<List<Note>> getRootNotes() async {
    return findAll((note) => note.notebookId == null || note.notebookId!.isEmpty);
  }

  /// Watch root notes
  Stream<List<Note>> watchRootNotes() {
    return watchWhere((note) => note.notebookId == null || note.notebookId!.isEmpty);
  }

  /// Get pinned notes
  Future<List<Note>> getPinned() async {
    return findAll((note) => note.isPinned);
  }

  /// Get active notes (not archived or deleted)
  Future<List<Note>> getActive() async {
    return findAll((note) => note.isActive);
  }

  /// Get archived notes
  Future<List<Note>> getArchived() async {
    return findAll((note) => note.isArchived);
  }

  /// Get notes by tag
  Future<List<Note>> getByTag(String tag) async {
    return findAll((note) => note.tags.contains(tag));
  }

  /// Get notes linked to a task
  Future<List<Note>> getByTask(String taskId) async {
    return findAll((note) => note.taskId == taskId);
  }

  /// Search notes by title or content
  Future<List<Note>> search(String query) async {
    final lowerQuery = query.toLowerCase();
    return findAll((note) =>
        note.title.toLowerCase().contains(lowerQuery) ||
        note.displayContent.toLowerCase().contains(lowerQuery));
  }

  /// Find note by firestoreId
  Future<Note?> findByFirestoreId(String firestoreId) async {
    if (firestoreId.isEmpty) return null;
    return findFirst((note) => note.firestoreId == firestoreId);
  }

  /// Find note by createdAt timestamp
  Future<Note?> findByCreatedAt(DateTime createdAt) async {
    return findFirst((note) =>
        note.createdAt.millisecondsSinceEpoch ==
        createdAt.millisecondsSinceEpoch);
  }

  /// Find existing note by any identity
  Future<Note?> _findExisting(Note note) async {
    if (note.key != null) {
      final n = await get(note.key);
      if (n != null) return n;
    }
    if (note.firestoreId.isNotEmpty) {
      final n = await findByFirestoreId(note.firestoreId);
      if (n != null) return n;
    }
    return findByCreatedAt(note.createdAt);
  }

  /// Get notes pending cloud sync (no firestoreId)
  Future<List<Note>> getPendingSync() async {
    return findAll((note) => note.firestoreId.isEmpty);
  }

  /// Toggle pin status
  Future<void> togglePin(dynamic key) async {
    final note = await get(key);
    if (note != null) {
      note.isPinned = !note.isPinned;
      note.updatedAt = DateTime.now();
      await note.save();
    }
  }

  /// Archive a note
  Future<void> archive(dynamic key) async {
    final note = await get(key);
    if (note != null) {
      note.status = 'archived';
      note.updatedAt = DateTime.now();
      await note.save();
    }
  }

  /// Unarchive a note
  Future<void> unarchive(dynamic key) async {
    final note = await get(key);
    if (note != null) {
      note.status = 'active';
      note.updatedAt = DateTime.now();
      await note.save();
    }
  }

  /// Move note to notebook
  Future<void> moveToNotebook(dynamic key, String? notebookId) async {
    final note = await get(key);
    if (note != null) {
      note.notebookId = notebookId;
      note.updatedAt = DateTime.now();
      await note.save();
    }
  }

  /// Purge soft-deleted notes older than specified days
  Future<int> purgeSoftDeleted({int olderThanDays = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
      final box = await _getBox();

      final keysToDelete = <dynamic>[];
      for (final entry in box.toMap().entries) {
        final note = entry.value;
        if (note.deleted &&
            note.deletedAt != null &&
            note.deletedAt!.isBefore(cutoff)) {
          keysToDelete.add(entry.key);
        }
      }

      await box.deleteAll(keysToDelete);
      _logger.debug(
        'Service',
        '[HiveNoteStorage] Purged ${keysToDelete.length} soft-deleted notes',
      );

      return keysToDelete.length;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error purging soft-deleted notes',
        stackTrace: stack,
      );
      return 0;
    }
  }
}
