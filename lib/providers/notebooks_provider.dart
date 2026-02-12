import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook_model.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'notes_provider.dart';
import '../services/logger_service.dart';

/// Provider for all notebooks
final notebooksProvider = StateNotifierProvider.autoDispose<NotebooksNotifier, List<Notebook>>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  final authService = ref.read(authServiceProvider);
  final errorHandler = ref.read(errorHandlerProvider);
  return NotebooksNotifier(dbService, authService, errorHandler);
});

/// Provider para notas de un notebook específico (family provider)
final notesByNotebookProvider = Provider.autoDispose.family<List<Note>, String?>((ref, notebookId) {
  final notes = ref.watch(independentNotesProvider);
  if (notebookId == null) {
    // Notas sin carpeta
    return notes.where((n) => n.notebookId == null || n.notebookId!.isEmpty).toList();
  }
  // Notas del notebook especificado
  return notes.where((n) => n.notebookId == notebookId).toList();
});

/// Provider para contar notas en un notebook
final notesCountByNotebookProvider = Provider.autoDispose.family<int, String?>((ref, notebookId) {
  final notes = ref.watch(notesByNotebookProvider(notebookId));
  return notes.length;
});

/// Provider para notebooks favoritos
final favoriteNotebooksProvider = Provider.autoDispose<List<Notebook>>((ref) {
  final notebooks = ref.watch(notebooksProvider);
  return notebooks.where((n) => n.isFavorited).toList();
});

class NotebooksNotifier extends StateNotifier<List<Notebook>> {
  final DatabaseService _db;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  StreamSubscription? _subscription;

  NotebooksNotifier(this._db, this._auth, this._errorHandler) : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchNotebooks().listen(
      (notebooks) => state = notebooks,
      onError: (e) => LoggerService().error('Provider', 'Error watching notebooks: $e', error: e),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Crear un nuevo notebook
  Future<Notebook?> createNotebook({
    required String name,
    String icon = '📁',
    String color = '#6750A4',
    String? parentId,
  }) async {
    try {
      final newNotebook = Notebook(
        name: name,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      await _db.saveNotebookLocally(newNotebook);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNotebookToCloud(newNotebook, user.uid);
      }

      return newNotebook;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al crear notebook',
        userMessage: 'No se pudo crear el notebook',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Actualizar un notebook existente
  Future<void> updateNotebook(Notebook notebook) async {
    try {
      await _db.saveNotebookLocally(notebook);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncNotebookToCloud(notebook, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al actualizar notebook',
        userMessage: 'No se pudo actualizar el notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Cambiar el nombre de un notebook
  Future<void> renameNotebook(Notebook notebook, String newName) async {
    final updatedNotebook = notebook.copyWith(name: newName);
    await updateNotebook(updatedNotebook);
  }

  /// Cambiar el icono de un notebook
  Future<void> changeIcon(Notebook notebook, String newIcon) async {
    final updatedNotebook = notebook.copyWith(icon: newIcon);
    await updateNotebook(updatedNotebook);
  }

  /// Cambiar el color de un notebook
  Future<void> changeColor(Notebook notebook, String newColor) async {
    final updatedNotebook = notebook.copyWith(color: newColor);
    await updateNotebook(updatedNotebook);
  }

  /// Toggle favorito
  Future<void> toggleFavorite(Notebook notebook) async {
    final updatedNotebook = notebook.copyWith(isFavorited: !notebook.isFavorited);
    await updateNotebook(updatedNotebook);
  }

  /// Eliminar un notebook (mover notas a "sin carpeta")
  Future<void> deleteNotebook(Notebook notebook) async {
    try {
      // Primero, desasociar todas las notas de este notebook
      await _db.moveNotesOutOfNotebook(notebook.key.toString());

      // Luego, eliminar el notebook
      final firestoreId = notebook.firestoreId;
      await _db.deleteNotebookLocally(notebook.key);

      // También eliminar de Firestore si está sincronizado
      final user = _auth.currentUser;
      if (user != null && firestoreId.isNotEmpty) {
        await _db.deleteNotebookFromCloud(firestoreId, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar notebook',
        userMessage: 'No se pudo eliminar el notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Mover una nota a un notebook
  Future<void> moveNoteToNotebook(Note note, String? notebookId) async {
    try {
      final updatedNote = note.copyWith(
        notebookId: notebookId,
        clearNotebookId: notebookId == null,
      );

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
        message: 'Error al mover nota',
        userMessage: 'No se pudo mover la nota al notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Obtener un notebook por su ID
  Notebook? getNotebookById(String notebookId) {
    try {
      return state.firstWhere((n) => n.key.toString() == notebookId);
    } catch (e) {
      return null;
    }
  }
}
