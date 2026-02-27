import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'navigation_provider.dart';
import '../services/logger_service.dart';

final tasksProvider = StateNotifierProvider.family
    .autoDispose<TaskNotifier, List<Task>, String>((ref, type) {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final errorHandler = ref.read(errorHandlerProvider);
      return TaskNotifier(dbService, authService, errorHandler, type, ref);
    });

class TaskNotifier extends StateNotifier<List<Task>> {
  final DatabaseService _db;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  final String _type;
  final Ref _ref;
  StreamSubscription? _subscription;

  TaskNotifier(
    this._db,
    this._auth,
    this._errorHandler,
    this._type,
    this._ref,
  ) : super([]) {
    _init();
  }

  void _init() {
    _subscription = _db
        .watchLocalTasks(_type)
        .listen(
          (tasks) => state = _deduplicateTasks(tasks),
          onError: (e) => LoggerService().error('Provider', 'Error watching tasks: $e', error: e),
        );
  }

  /// IMPORTANT: Identification must check firestoreId, Hive key, OR createdAt.
  /// AI agents often create new Task instances which lose their Hive reference.
  List<Task> _deduplicateTasks(List<Task> tasks) {
    final seenFirestoreIds = <String>{};
    final seenHiveKeys = <dynamic>{};
    final seenTimestamps = <int>{};
    final unique = <Task>[];

    for (final task in tasks) {
      bool isDuplicate = false;

      // 1. Check by firestoreId
      if (task.firestoreId.isNotEmpty) {
        if (seenFirestoreIds.contains(task.firestoreId)) {
          isDuplicate = true;
        } else {
          seenFirestoreIds.add(task.firestoreId);
        }
      }

      // 2. Check by Hive key
      if (!isDuplicate && task.key != null) {
        if (seenHiveKeys.contains(task.key)) {
          isDuplicate = true;
        } else {
          seenHiveKeys.add(task.key);
        }
      }

      // 3. Check by createdAt (crucial for local tasks with lost keys)
      if (!isDuplicate) {
        final ts = task.createdAt.millisecondsSinceEpoch;
        if (seenTimestamps.contains(ts)) {
          isDuplicate = true;
        } else {
          seenTimestamps.add(ts);
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
    double? financialCost,
    double? financialBenefit,
    String? financialCategoryId,
    String? financialNote,
    bool autoGenerateTransaction = false,
    String? financialImpactType,
    String? linkedRecurringTransactionId,
  }) async {
    try {
      final now = DateTime.now();
      final newTask = Task(
        title: title,
        type: _type,
        createdAt: now,
        category: category,
        priority: priority,
        dueDate: dueDate,
        dueTimeMinutes: dueTimeMinutes,
        motivation: motivation,
        reward: reward,
        deadline: deadline,
        recurrenceDay: recurrenceDay,
        financialCost: financialCost,
        financialBenefit: financialBenefit,
        financialCategoryId: financialCategoryId,
        financialNote: financialNote,
        autoGenerateTransaction: autoGenerateTransaction,
        financialImpactType: financialImpactType,
        linkedRecurringTransactionId: linkedRecurringTransactionId,
        lastUpdatedAt: now, // FIX 6 - Establecer lastUpdatedAt desde creación
      );

      await _db.saveTaskLocally(newTask);

      final user = _auth.currentUser;
      if (user != null) {
        await _db.syncTaskToCloud(newTask, user.uid);
      } else {
        // FIX 5 - Si no hay userId, igual agregar a cola para sincronizar después
        LoggerService().debug('Provider', '⚠️ [TaskProvider] Usuario no autenticado, tarea se sincronizará cuando haya auth');
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
      // Si la tarea ya está en Hive, guardar directamente
      if (task.isInBox) {
        task.lastUpdatedAt = DateTime.now();
        await task.save();

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloudDebounced(task, user.uid);
        }
        return;
      }

      // Buscar la tarea original en el estado actual
      Task? original;

      // Primero buscar por Hive key (más confiable para tareas locales)
      if (task.key != null) {
        original = state.cast<Task?>().firstWhere(
          (t) => t?.key == task.key,
          orElse: () => null,
        );
      }

      // Si no se encuentra por key, buscar por firestoreId
      if (original == null && task.firestoreId.isNotEmpty) {
        original = state.cast<Task?>().firstWhere(
          (t) => t?.firestoreId == task.firestoreId,
          orElse: () => null,
        );
      }

      // Si aún no se encuentra, buscar por createdAt (identidad local persistente)
      original ??= state.cast<Task?>().firstWhere(
        (t) =>
            t != null &&
            t.createdAt.millisecondsSinceEpoch ==
                task.createdAt.millisecondsSinceEpoch,
        orElse: () => null,
      );

      if (original != null && original.isInBox) {
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
          financialCost: task.financialCost,
          financialBenefit: task.financialBenefit,
          financialCategoryId: task.financialCategoryId,
          financialNote: task.financialNote,
          autoGenerateTransaction: task.autoGenerateTransaction,
          financialImpactType: task.financialImpactType,
          linkedRecurringTransactionId: task.linkedRecurringTransactionId,
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
        // La tarea no existe en el estado - esto no debería pasar en edición normal
        // Solo agregar si realmente es una tarea nueva
        LoggerService().debug('Provider', '⚠️ [TaskProvider] updateTask llamado con tarea no encontrada en state');
        task.lastUpdatedAt = DateTime.now();
        await _db.saveTaskLocally(task);

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloud(task, user.uid);
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
        // Fallback: buscar el original en el estado y actualizarlo
        Task? original;

        if (task.key != null) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.key == task.key,
            orElse: () => null,
          );
        }
        if (original == null && task.firestoreId.isNotEmpty) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.firestoreId == task.firestoreId,
            orElse: () => null,
          );
        }

        // Fallback: buscar por createdAt
        original ??= state.cast<Task?>().firstWhere(
          (t) =>
              t != null &&
              t.createdAt.millisecondsSinceEpoch ==
                  task.createdAt.millisecondsSinceEpoch,
          orElse: () => null,
        );

        if (original != null && original.isInBox) {
          original.updateInPlace(
            isCompleted: !original.isCompleted,
            lastUpdatedAt: DateTime.now(),
          );
          await original.save();

          final user = _auth.currentUser;
          if (user != null) {
            await _db.syncTaskToCloudDebounced(original, user.uid);
          }
        } else {
          // Caso muy raro: actualizar la tarea pasada
          LoggerService().debug('Provider', '⚠️ [TaskProvider] toggleTask fallback: tarea no encontrada');
          await updateTask(
            task.copyWith(
              isCompleted: !task.isCompleted,
              lastUpdatedAt: DateTime.now(),
            ),
          );
        }
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

  /// Restaura una tarea eliminada (para deshacer eliminacion).
  /// Guarda de nuevo localmente y sincroniza con la nube si hay usuario autenticado.
  Future<void> restoreTask(Task task) async {
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
        message: 'Error al restaurar tarea',
        userMessage: 'No se pudo restaurar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Pospone una tarea hasta una fecha/hora específica.
  /// La tarea se ocultará de las vistas normales hasta ese momento.
  Future<void> snoozeTask(Task task, DateTime deferredUntil) async {
    try {
      if (task.isInBox) {
        task.updateInPlace(
          deferredUntil: deferredUntil,
          lastUpdatedAt: DateTime.now(),
        );
        await task.save();

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloudDebounced(task, user.uid);
        }
      } else {
        // Fallback: buscar la tarea original y actualizarla
        Task? original;

        if (task.key != null) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.key == task.key,
            orElse: () => null,
          );
        }
        if (original == null && task.firestoreId.isNotEmpty) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.firestoreId == task.firestoreId,
            orElse: () => null,
          );
        }
        original ??= state.cast<Task?>().firstWhere(
          (t) =>
              t != null &&
              t.createdAt.millisecondsSinceEpoch ==
                  task.createdAt.millisecondsSinceEpoch,
          orElse: () => null,
        );

        if (original != null && original.isInBox) {
          original.updateInPlace(
            deferredUntil: deferredUntil,
            lastUpdatedAt: DateTime.now(),
          );
          await original.save();

          final user = _auth.currentUser;
          if (user != null) {
            await _db.syncTaskToCloudDebounced(original, user.uid);
          }
        } else {
          LoggerService().debug('Provider', '⚠️ [TaskProvider] snoozeTask llamado con tarea no encontrada');
          await updateTask(
            task.copyWith(
              deferredUntil: deferredUntil,
              lastUpdatedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al posponer tarea',
        userMessage: 'No se pudo posponer la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Quita la posposición de una tarea, haciéndola visible de nuevo.
  Future<void> unsnoozeTask(Task task) async {
    try {
      if (task.isInBox) {
        task.updateInPlace(
          clearDeferredUntil: true,
          lastUpdatedAt: DateTime.now(),
        );
        await task.save();

        final user = _auth.currentUser;
        if (user != null) {
          await _db.syncTaskToCloudDebounced(task, user.uid);
        }
      } else {
        // Fallback: buscar la tarea original y actualizarla
        Task? original;

        if (task.key != null) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.key == task.key,
            orElse: () => null,
          );
        }
        if (original == null && task.firestoreId.isNotEmpty) {
          original = state.cast<Task?>().firstWhere(
            (t) => t?.firestoreId == task.firestoreId,
            orElse: () => null,
          );
        }
        original ??= state.cast<Task?>().firstWhere(
          (t) =>
              t != null &&
              t.createdAt.millisecondsSinceEpoch ==
                  task.createdAt.millisecondsSinceEpoch,
          orElse: () => null,
        );

        if (original != null && original.isInBox) {
          original.updateInPlace(
            clearDeferredUntil: true,
            lastUpdatedAt: DateTime.now(),
          );
          await original.save();

          final user = _auth.currentUser;
          if (user != null) {
            await _db.syncTaskToCloudDebounced(original, user.uid);
          }
        } else {
          LoggerService().debug('Provider', '⚠️ [TaskProvider] unsnoozeTask llamado con tarea no encontrada');
          await updateTask(
            task.copyWith(
              clearDeferredUntil: true,
              lastUpdatedAt: DateTime.now(),
            ),
          );
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al quitar posposición de tarea',
        userMessage: 'No se pudo quitar la posposición',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

/// Provider for active (non-deferred) tasks of a specific type
/// Filters out tasks that are currently deferred
final activeTasksProvider = Provider.autoDispose.family<List<Task>, String>((
  ref,
  type,
) {
  final tasks = ref.watch(tasksProvider(type));
  return tasks.where((task) => !task.isDeferred).toList();
});

/// Provider for all deferred tasks across all types
/// Returns tasks sorted by deferredUntil date
final deferredTasksProvider = Provider.autoDispose<List<Task>>((ref) {
  final types = ['daily', 'weekly', 'monthly', 'yearly', 'once'];
  final allDeferred = <Task>[];

  for (final type in types) {
    final tasks = ref.watch(tasksProvider(type));
    allDeferred.addAll(tasks.where((task) => task.isDeferred));
  }

  // Sort by deferredUntil date (earliest first)
  allDeferred.sort((a, b) {
    if (a.deferredUntil == null) return 1;
    if (b.deferredUntil == null) return -1;
    return a.deferredUntil!.compareTo(b.deferredUntil!);
  });

  return allDeferred;
});

/// Provider for filtered tasks based on search query
/// Combines task type filtering with text search
/// Now uses activeTasksProvider to exclude deferred tasks
final filteredTasksProvider = Provider.autoDispose.family<List<Task>, String>((
  ref,
  type,
) {
  final tasks = ref.watch(activeTasksProvider(type));
  final searchQuery = ref.watch(taskSearchQueryProvider).toLowerCase().trim();

  if (searchQuery.isEmpty) {
    return tasks;
  }

  return tasks.where((task) {
    final titleMatch = task.title.toLowerCase().contains(searchQuery);
    final categoryMatch = task.category.toLowerCase().contains(searchQuery);
    final motivationMatch =
        task.motivation?.toLowerCase().contains(searchQuery) ?? false;
    final rewardMatch =
        task.reward?.toLowerCase().contains(searchQuery) ?? false;

    return titleMatch || categoryMatch || motivationMatch || rewardMatch;
  }).toList();
});
