import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

final tasksProvider =
    StateNotifierProvider.family<TaskNotifier, List<Task>, String>((ref, type) {
      final dbService = ref.watch(databaseServiceProvider);
      final authService = ref.watch(authServiceProvider);
      final errorHandler = ref.watch(errorHandlerProvider);
      return TaskNotifier(dbService, authService, errorHandler, type);
    });

class TaskNotifier extends StateNotifier<List<Task>> {
  final DatabaseService _db;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  final String _type;
  StreamSubscription? _subscription;

  TaskNotifier(this._db, this._auth, this._errorHandler, this._type) : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db.watchLocalTasks(_type).listen(
      (tasks) => state = _deduplicateTasks(tasks),
      onError: (e) => debugPrint('Error watching tasks: $e'),
    );
  }

  /// Remove duplicate tasks (same firestoreId)
  List<Task> _deduplicateTasks(List<Task> tasks) {
    final seen = <String>{};
    final unique = <Task>[];

    for (final task in tasks) {
      // For tasks with firestoreId, deduplicate by firestoreId
      if (task.firestoreId.isNotEmpty) {
        if (!seen.contains(task.firestoreId)) {
          seen.add(task.firestoreId);
          unique.add(task);
        }
      } else {
        // For local-only tasks, keep all (they have unique Hive keys)
        unique.add(task);
      }
    }

    return unique;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addTask(
    String title, {
    String category = 'Personal',
    int priority = 1,
    DateTime? dueDate,
    int? dueTimeMinutes,
    String? motivation,
    String? reward,
    DateTime? deadline,
    int? recurrenceDay,
  }) async {
    try {
      final newTask = Task(
        title: title,
        type: _type,
        createdAt: DateTime.now(),
        category: category,
        priority: priority,
        dueDate: dueDate,
        dueTimeMinutes: dueTimeMinutes,
        motivation: motivation,
        reward: reward,
        deadline: deadline,
        recurrenceDay: recurrenceDay,
      );

      await _db.saveTaskLocally(newTask);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncTaskToCloud(newTask, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar tarea',
        userMessage: 'No se pudo agregar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _db.saveTaskLocally(task);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncTaskToCloud(task, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al actualizar tarea',
        userMessage: 'No se pudo actualizar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> toggleTask(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(Task task) async {
    try {
      final firestoreId = task.firestoreId;
      await _db.deleteTaskLocally(task.key);

      // Also delete from Firestore if synced
      final user = _auth.currentUser;
      if (user != null && firestoreId.isNotEmpty) {
        await _db.deleteTaskFromCloud(firestoreId, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar tarea',
        userMessage: 'No se pudo eliminar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
