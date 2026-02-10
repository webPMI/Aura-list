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

  /// Remove duplicate tasks (same firestoreId or same Hive key)
  List<Task> _deduplicateTasks(List<Task> tasks) {
    final seenFirestoreIds = <String>{};
    final seenHiveKeys = <dynamic>{};
    final unique = <Task>[];

    for (final task in tasks) {
      bool isDuplicate = false;

      // Check by firestoreId first (most reliable for synced tasks)
      if (task.firestoreId.isNotEmpty) {
        if (seenFirestoreIds.contains(task.firestoreId)) {
          isDuplicate = true;
        } else {
          seenFirestoreIds.add(task.firestoreId);
        }
      }

      // Also check by Hive key (for local-only tasks)
      if (!isDuplicate && task.key != null) {
        if (seenHiveKeys.contains(task.key)) {
          isDuplicate = true;
        } else {
          seenHiveKeys.add(task.key);
        }
      }

      if (!isDuplicate) {
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
      // Si la tarea ya está en Hive, usar updateInPlace
      if (task.isInBox) {
        task.lastUpdatedAt = DateTime.now();
        await task.save();

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloudDebounced(task, user.uid);
        }
      } else {
        // Buscar la tarea original en el estado actual por firestoreId o key
        Task? original;
        if (task.firestoreId.isNotEmpty) {
          original = state.firstWhere(
            (t) => t.firestoreId == task.firestoreId,
            orElse: () => task,
          );
        }

        if (original != null && original.isInBox && original != task) {
          // Actualizar la tarea original in-place
          original.updateInPlace(
            title: task.title,
            type: task.type,
            isCompleted: task.isCompleted,
            dueDate: task.dueDate,
            category: task.category,
            priority: task.priority,
            dueTimeMinutes: task.dueTimeMinutes,
            motivation: task.motivation,
            reward: task.reward,
            recurrenceDay: task.recurrenceDay,
            deadline: task.deadline,
            deleted: task.deleted,
            deletedAt: task.deletedAt,
            lastUpdatedAt: DateTime.now(),
          );
          await original.save();

          final user = _auth.currentUser;
          if (user != null) {
            await _db.syncTaskToCloudDebounced(original, user.uid);
          }
        } else {
          // Fallback: guardar usando el servicio (que maneja duplicados)
          await _db.saveTaskLocally(task);

          final user = _auth.currentUser;
          if (user != null) {
            await _db.syncTaskToCloud(task, user.uid);
          }
        }
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
    try {
      // Usar updateInPlace para tareas que ya están en Hive (preserva el key)
      if (task.isInBox) {
        task.updateInPlace(
          isCompleted: !task.isCompleted,
          lastUpdatedAt: DateTime.now(),
        );
        await task.save();

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloudDebounced(task, user.uid);
        }
      } else {
        // Fallback para tareas no guardadas aún
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          lastUpdatedAt: DateTime.now(),
        );
        await updateTask(updatedTask);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al cambiar estado de tarea',
        userMessage: 'No se pudo actualizar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
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
