import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../services/logger_service.dart';

/// Provider for independent notes (not linked to tasks)
final independentNotesProvider =
    StateNotifierProvider.autoDispose<IndependentNotesNotifier, List<Note>>((
      ref,
    ) {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final errorHandler = ref.read(errorHandlerProvider);
      return IndependentNotesNotifier(dbService, authService, errorHandler);
    });

/// Provider for archived notes
final archivedNotesProvider =
    StateNotifierProvider.autoDispose<ArchivedNotesNotifier, List<Note>>((
      ref,
    ) {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final errorHandler = ref.read(errorHandlerProvider);
      return ArchivedNotesNotifier(dbService, authService, errorHandler);
    });

/// Provider for notes linked to a specific task (family provider)
final taskNotesProvider = StateNotifierProvider.autoDispose
    .family<TaskNotesNotifier, List<Note>, String>((ref, taskId) {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final errorHandler = ref.read(errorHandlerProvider);
      return TaskNotesNotifier(dbService, authService, errorHandler, taskId);
    });

/// Provider for task notes count (for showing badge on task)
final taskNotesCountProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  taskId,
) async {
  final dbService = ref.read(databaseServiceProvider);
  return dbService.getTaskNotesCount(taskId);
});

/// Provider for note search results
final noteSearchProvider = FutureProvider.autoDispose
    .family<List<Note>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final dbService = ref.read(databaseServiceProvider);
      return dbService.searchNotes(query);
    });

/// Provider for all notes count (for dashboard)
final totalNotesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  final notes = await dbService.getAllNotes();
  return notes.length;
});

/// Consolidates the repeated saveNoteLocally → syncNoteToCloud pattern shared
/// across all note notifiers. Fix sync logic once here instead of in 3 places.
mixin _NoteSyncMixin on StateNotifier<List<Note>> {
  DatabaseService get _db;
  AuthService get _auth;
  ErrorHandler get _errorHandler;

  Future<void> _saveAndSync(
    Note note, {
    required String errorMessage,
    String? userMessage,
  }) async {
    try {
      await _db.saveNoteLocally(note);
      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(note, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: errorMessage,
        userMessage: userMessage,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

class IndependentNotesNotifier extends StateNotifier<List<Note>> with _NoteSyncMixin {
  @override final DatabaseService _db;
  @override final AuthService _auth;
  @override final ErrorHandler _errorHandler;
  StreamSubscription? _subscription;

  IndependentNotesNotifier(this._db, this._auth, this._errorHandler)
    : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchIndependentNotes().listen(
      (notes) => state = notes,
      onError: (e) => LoggerService().error('Provider', 'Error watching notes: $e', error: e),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addNote({
    required String title,
    String content = '',
    String color = '#FFFFFF',
    List<String> tags = const [],
    List<ChecklistItem> checklist = const [],
    String? richContent,
    String contentType = 'plain',
  }) async {
    final newNote = Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      color: color,
      tags: tags,
      checklist: checklist,
      richContent: richContent,
      contentType: contentType,
    );
    await _saveAndSync(
      newNote,
      errorMessage: 'Error al agregar nota',
      userMessage: 'No se pudo agregar la nota',
    );
  }

  Future<void> addQuickNote(String content) async {
    final newNote = Note.quick(content);
    await _saveAndSync(
      newNote,
      errorMessage: 'Error al agregar nota rapida',
      userMessage: 'No se pudo agregar la nota',
    );
  }

  Future<void> updateNote(Note note) async {
    await _saveAndSync(
      note,
      errorMessage: 'Error al actualizar nota',
      userMessage: 'No se pudo actualizar la nota',
    );
  }

  Future<void> togglePin(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updatedNote);
  }

  Future<void> changeColor(Note note, String color) async {
    final updatedNote = note.copyWith(color: color);
    await updateNote(updatedNote);
  }

  Future<void> archiveNote(Note note) async {
    final updatedNote = note.copyWith(status: 'archived');
    await updateNote(updatedNote);
  }

  Future<void> restoreNote(Note note) async {
    final updatedNote = note.copyWith(status: 'active');
    await updateNote(updatedNote);
  }

  Future<void> deleteNote(Note note) async {
    try {
      final firestoreId = note.firestoreId;
      await _db.deleteNoteLocally(note.key);

      // Also delete from Firestore if synced
      final user = _auth.currentUser;
      if (user != null && firestoreId.isNotEmpty) {
        await _db.deleteNoteFromCloud(firestoreId, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar nota',
        userMessage: 'No se pudo eliminar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

class ArchivedNotesNotifier extends StateNotifier<List<Note>> with _NoteSyncMixin {
  @override final DatabaseService _db;
  @override final AuthService _auth;
  @override final ErrorHandler _errorHandler;
  StreamSubscription? _subscription;

  ArchivedNotesNotifier(this._db, this._auth, this._errorHandler)
    : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchArchivedNotes().listen(
      (notes) => state = notes,
      onError: (e) => LoggerService().error('Provider', 'Error watching archived notes: $e', error: e),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> restoreNote(Note note) async {
    final updatedNote = note.copyWith(status: 'active');
    await _updateNote(updatedNote);
  }

  Future<void> permanentlyDeleteNote(Note note) async {
    try {
      final firestoreId = note.firestoreId;
      await _db.deleteNoteLocally(note.key);

      // Also delete from Firestore if synced
      final user = _auth.currentUser;
      if (user != null && firestoreId.isNotEmpty) {
        await _db.deleteNoteFromCloud(firestoreId, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar nota permanentemente',
        userMessage: 'No se pudo eliminar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _updateNote(Note note) async {
    await _saveAndSync(
      note,
      errorMessage: 'Error al actualizar nota',
      userMessage: 'No se pudo actualizar la nota',
    );
  }
}

class TaskNotesNotifier extends StateNotifier<List<Note>> with _NoteSyncMixin {
  @override final DatabaseService _db;
  @override final AuthService _auth;
  @override final ErrorHandler _errorHandler;
  final String _taskId;
  StreamSubscription? _subscription;

  TaskNotesNotifier(this._db, this._auth, this._errorHandler, this._taskId)
    : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db
        .watchNotesForTask(_taskId)
        .listen(
          (notes) => state = notes,
          onError: (e) => LoggerService().error('Provider', 'Error watching task notes: $e', error: e),
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addNote({
    required String title,
    String content = '',
    String color = '#FFFDE7', // Default yellow for task notes
    List<ChecklistItem> checklist = const [],
  }) async {
    final newNote = Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      taskId: _taskId,
      color: color,
      checklist: checklist,
    );
    await _saveAndSync(
      newNote,
      errorMessage: 'Error al agregar nota a tarea',
      userMessage: 'No se pudo agregar la nota',
    );
  }

  Future<void> addQuickNote(String content) async {
    final newNote = Note.quick(content, taskId: _taskId);
    await _saveAndSync(
      newNote,
      errorMessage: 'Error al agregar nota rapida',
      userMessage: 'No se pudo agregar la nota',
    );
  }

  Future<void> updateNote(Note note) async {
    await _saveAndSync(note, errorMessage: 'Error al actualizar nota');
  }

  Future<void> deleteNote(Note note) async {
    try {
      final firestoreId = note.firestoreId;
      await _db.deleteNoteLocally(note.key);

      // Also delete from Firestore if synced
      final user = _auth.currentUser;
      if (user != null && firestoreId.isNotEmpty) {
        await _db.deleteNoteFromCloud(firestoreId, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar nota',
        userMessage: 'No se pudo eliminar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Unlink note from task (converts to independent note)
  Future<void> unlinkNote(Note note) async {
    final updatedNote = note.copyWith(clearTaskId: true);
    await _saveAndSync(updatedNote, errorMessage: 'Error al desvincular nota');
  }
}

/// Quick note provider - for adding notes with minimal UI
final quickNoteProvider = Provider.autoDispose((ref) {
  return (String content, {String? taskId}) async {
    final dbService = ref.read(databaseServiceProvider);
    final authService = ref.read(authServiceProvider);

    final note = Note.quick(content, taskId: taskId);

    await dbService.saveNoteLocally(note);

    final user = authService.currentUser;
    if (user != null) {
      await dbService.syncNoteToCloud(note, user.uid);
    }
  };
});

/// Provider to refresh notes count for a task
final refreshTaskNotesCountProvider = Provider.autoDispose((ref) {
  return (String taskId) {
    ref.invalidate(taskNotesCountProvider(taskId));
  };
});
