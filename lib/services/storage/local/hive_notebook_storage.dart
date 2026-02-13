/// Hive implementation of local notebook storage.
///
/// Provides persistent local storage for notebooks using Hive,
/// with support for watching changes and finding notebooks.
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/notebook_model.dart';
import '../../contracts/i_local_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Hive-based local storage for notebooks
class HiveNotebookStorage implements ILocalStorage<Notebook> {
  static const String boxName = 'notebooks';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<Notebook>? _box;
  bool _initialized = false;

  HiveNotebookStorage(this._errorHandler);

  /// Expose box for direct access when needed
  Box<Notebook>? get box => _box;

  @override
  bool get isInitialized => _initialized && _box != null && _box!.isOpen;

  Future<Box<Notebook>> _getBox() async {
    if (!isInitialized) await init();
    return _box!;
  }

  @override
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;

    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<Notebook>(boxName)
          : await Hive.openBox<Notebook>(boxName);
      _initialized = true;
      _logger.debug('Service', '[HiveNotebookStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing notebook storage',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Notebook?> get(dynamic key) async {
    try {
      final box = await _getBox();
      return box.get(key);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting notebook',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Notebook>> getAll() async {
    try {
      final box = await _getBox();
      return box.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting all notebooks',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<Notebook>> getAllIncludingDeleted() async {
    // Notebooks don't have soft delete, so this is the same as getAll
    return getAll();
  }

  @override
  Future<void> save(Notebook notebook) async {
    try {
      final box = await _getBox();

      if (notebook.isInBox) {
        await notebook.save();
      } else {
        final existing = await _findExisting(notebook);
        if (existing != null) {
          existing.updateInPlace(
            firestoreId: notebook.firestoreId.isNotEmpty ? notebook.firestoreId : null,
            name: notebook.name,
            icon: notebook.icon,
            color: notebook.color,
            updatedAt: notebook.updatedAt,
            isFavorited: notebook.isFavorited,
            parentId: notebook.parentId,
          );
          await existing.save();
          _logger.debug('Service', '[HiveNotebookStorage] Updated existing notebook');
        } else {
          await box.add(notebook);
          _logger.debug('Service', '[HiveNotebookStorage] Added new notebook');
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error saving notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> saveAll(List<Notebook> notebooks) async {
    for (final notebook in notebooks) {
      await save(notebook);
    }
  }

  @override
  Future<void> delete(dynamic key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
      _logger.debug('Service', '[HiveNotebookStorage] Deleted notebook: $key');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting notebook',
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
        '[HiveNotebookStorage] Deleted ${keys.length} notebooks',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting notebooks',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> softDelete(dynamic key) async {
    // Notebooks don't support soft delete, just hard delete
    await delete(key);
  }

  @override
  Stream<List<Notebook>> watch() async* {
    try {
      final box = await _getBox();

      yield box.values.toList()..sort((a, b) => a.name.compareTo(b.name));

      await for (final _ in box.watch()) {
        yield box.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error watching notebooks',
        stackTrace: stack,
      );
      yield [];
    }
  }

  @override
  Stream<List<Notebook>> watchWhere(bool Function(Notebook) predicate) async* {
    try {
      final box = await _getBox();

      List<Notebook> getFiltered() {
        return box.values.where(predicate).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
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
        message: 'Error watching notebooks with filter',
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
      _logger.debug('Service', '[HiveNotebookStorage] Cleared all notebooks');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error clearing notebooks',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<int> count() async {
    try {
      final box = await _getBox();
      return box.length;
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
  Future<Notebook?> findFirst(bool Function(Notebook) predicate) async {
    try {
      final box = await _getBox();
      return box.values.cast<Notebook?>().firstWhere(
            (n) => n != null && predicate(n),
            orElse: () => null,
          );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding notebook',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Notebook>> findAll(bool Function(Notebook) predicate) async {
    try {
      final box = await _getBox();
      return box.values.where(predicate).toList();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding notebooks',
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
      _logger.debug('Service', '[HiveNotebookStorage] Closed');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error closing notebook storage',
        stackTrace: stack,
      );
    }
  }

  // ==================== NOTEBOOK-SPECIFIC METHODS ====================

  /// Get favorited notebooks
  Future<List<Notebook>> getFavorited() async {
    return findAll((notebook) => notebook.isFavorited);
  }

  /// Watch favorited notebooks
  Stream<List<Notebook>> watchFavorited() {
    return watchWhere((notebook) => notebook.isFavorited);
  }

  /// Get root notebooks (no parent)
  Future<List<Notebook>> getRootNotebooks() async {
    return findAll((notebook) => notebook.parentId == null || notebook.parentId!.isEmpty);
  }

  /// Get child notebooks
  Future<List<Notebook>> getChildren(String parentId) async {
    return findAll((notebook) => notebook.parentId == parentId);
  }

  /// Find notebook by firestoreId
  Future<Notebook?> findByFirestoreId(String firestoreId) async {
    if (firestoreId.isEmpty) return null;
    return findFirst((notebook) => notebook.firestoreId == firestoreId);
  }

  /// Find notebook by name
  Future<Notebook?> findByName(String name) async {
    return findFirst((notebook) => notebook.name.toLowerCase() == name.toLowerCase());
  }

  /// Find notebook by createdAt timestamp
  Future<Notebook?> findByCreatedAt(DateTime createdAt) async {
    return findFirst((notebook) =>
        notebook.createdAt.millisecondsSinceEpoch ==
        createdAt.millisecondsSinceEpoch);
  }

  /// Find existing notebook by any identity
  Future<Notebook?> _findExisting(Notebook notebook) async {
    if (notebook.key != null) {
      final n = await get(notebook.key);
      if (n != null) return n;
    }
    if (notebook.firestoreId.isNotEmpty) {
      final n = await findByFirestoreId(notebook.firestoreId);
      if (n != null) return n;
    }
    return findByCreatedAt(notebook.createdAt);
  }

  /// Get notebooks pending cloud sync (no firestoreId)
  Future<List<Notebook>> getPendingSync() async {
    return findAll((notebook) => notebook.firestoreId.isEmpty);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(dynamic key) async {
    final notebook = await get(key);
    if (notebook != null) {
      notebook.isFavorited = !notebook.isFavorited;
      notebook.updatedAt = DateTime.now();
      await notebook.save();
    }
  }

  /// Create default notebook if not exists
  Future<Notebook> ensureDefaultExists() async {
    final existing = await findByName('General');
    if (existing != null) return existing;

    final defaultNotebook = Notebook(
      name: 'General',
      icon: '📁',
      color: '#6750A4',
      createdAt: DateTime.now(),
    );
    await save(defaultNotebook);
    return defaultNotebook;
  }

  /// Get notebook by key as string (for note.notebookId)
  Future<Notebook?> getByStringId(String id) async {
    // First try to parse as int (Hive key)
    final intKey = int.tryParse(id);
    if (intKey != null) {
      return get(intKey);
    }
    // Otherwise try as firestoreId
    return findByFirestoreId(id);
  }
}
