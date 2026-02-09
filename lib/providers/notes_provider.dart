import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

/// Provider for independent notes (not linked to tasks)
final independentNotesProvider =
    StateNotifierProvider<IndependentNotesNotifier, List<Note>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return IndependentNotesNotifier(dbService, authService, errorHandler);
});

/// Provider for notes linked to a specific task (family provider)
final taskNotesProvider =
    StateNotifierProvider.family<TaskNotesNotifier, List<Note>, String>(
        (ref, taskId) {
  final dbService = ref.watch(databaseServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return TaskNotesNotifier(dbService, authService, errorHandler, taskId);
});

/// Provider for task notes count (for showing badge on task)
final taskNotesCountProvider =
    FutureProvider.family<int, String>((ref, taskId) async {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getTaskNotesCount(taskId);
});

/// Provider for note search results
final noteSearchProvider =
    FutureProvider.family<List<Note>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.searchNotes(query);
});

/// Provider for all notes count (for dashboard)
final totalNotesCountProvider = FutureProvider<int>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final notes = await dbService.getAllNotes();
  return notes.length;
});

class IndependentNotesNotifier extends StateNotifier<List<Note>> {
  final DatabaseService _db;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  StreamSubscription? _subscription;

  IndependentNotesNotifier(this._db, this._auth, this._errorHandler)
      : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchIndependentNotes().listen(
          (notes) => state = notes,
          onError: (e) => debugPrint('Error watching notes: $e'),
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
  }) async {
    try {
      final newNote = Note(
        title: title,
        content: content,
        createdAt: DateTime.now(),
        color: color,
        tags: tags,
      );

      await _db.saveNoteLocally(newNote);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(newNote, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar nota',
        userMessage: 'No se pudo agregar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> addQuickNote(String content) async {
    try {
      final newNote = Note.quick(content);
      await _db.saveNoteLocally(newNote);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(newNote, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar nota rapida',
        userMessage: 'No se pudo agregar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
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
        message: 'Error al actualizar nota',
        userMessage: 'No se pudo actualizar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> togglePin(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updatedNote);
  }

  Future<void> changeColor(Note note, String color) async {
    final updatedNote = note.copyWith(color: color);
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

class TaskNotesNotifier extends StateNotifier<List<Note>> {
  final DatabaseService _db;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  final String _taskId;
  StreamSubscription? _subscription;

  TaskNotesNotifier(this._db, this._auth, this._errorHandler, this._taskId)
      : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchNotesForTask(_taskId).listen(
          (notes) => state = notes,
          onError: (e) => debugPrint('Error watching task notes: $e'),
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
  }) async {
    try {
      final newNote = Note(
        title: title,
        content: content,
        createdAt: DateTime.now(),
        taskId: _taskId,
        color: color,
      );

      await _db.saveNoteLocally(newNote);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(newNote, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar nota a tarea',
        userMessage: 'No se pudo agregar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> addQuickNote(String content) async {
    try {
      final newNote = Note.quick(content, taskId: _taskId);
      await _db.saveNoteLocally(newNote);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(newNote, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar nota rapida',
        userMessage: 'No se pudo agregar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
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
        message: 'Error al actualizar nota',
        stackTrace: stack,
      );
      rethrow;
    }
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
    try {
      await _db.saveNoteLocally(updatedNote);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNoteToCloud(updatedNote, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al desvincular nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

/// Quick note provider - for adding notes with minimal UI
final quickNoteProvider = Provider((ref) {
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
final refreshTaskNotesCountProvider = Provider((ref) {
  return (String taskId) {
    ref.invalidate(taskNotesCountProvider(taskId));
  };
});
