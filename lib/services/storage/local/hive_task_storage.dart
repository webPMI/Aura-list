/// Hive implementation of local task storage.
///
/// Provides persistent local storage for tasks using Hive,
/// with support for soft delete, watching changes, and finding tasks.
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/task_model.dart';
import '../../contracts/i_local_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Hive-based local storage for tasks
class HiveTaskStorage implements ILocalStorage<Task> {
  static const String boxName = 'tasks';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<Task>? _box;
  bool _initialized = false;

  HiveTaskStorage(this._errorHandler);

  @override
  bool get isInitialized => _initialized && _box != null && _box!.isOpen;

  /// Get the box, initializing if necessary
  Future<Box<Task>> _getBox() async {
    if (!isInitialized) await init();
    return _box!;
  }

  @override
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;

    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<Task>(boxName)
          : await Hive.openBox<Task>(boxName);
      _initialized = true;
      _logger.debug('Service', '[HiveTaskStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error initializing task storage',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<Task?> get(dynamic key) async {
    try {
      final box = await _getBox();
      return box.get(key);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting task',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Task>> getAll() async {
    try {
      final box = await _getBox();
      return box.values.where((task) => !task.deleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting all tasks',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<Task>> getAllIncludingDeleted() async {
    try {
      final box = await _getBox();
      return box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error getting all tasks including deleted',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> save(Task task) async {
    try {
      final box = await _getBox();

      if (task.isInBox) {
        await task.save();
      } else {
        // Check for existing task to avoid duplicates
        final existing = await _findExisting(task);
        if (existing != null) {
          // Update existing task
          existing.updateInPlace(
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
            lastUpdatedAt: task.lastUpdatedAt,
          );
          await existing.save();
          _logger.debug('Service', '[HiveTaskStorage] Updated existing task');
        } else {
          await box.add(task);
          _logger.debug('Service', '[HiveTaskStorage] Added new task');
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error saving task',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    try {
      for (final task in tasks) {
        await save(task);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error saving tasks',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(dynamic key) async {
    try {
      final box = await _getBox();
      await box.delete(key);
      _logger.debug('Service', '[HiveTaskStorage] Hard deleted task: $key');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting task',
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
        '[HiveTaskStorage] Hard deleted ${keys.length} tasks',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error deleting tasks',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> softDelete(dynamic key) async {
    try {
      final task = await get(key);
      if (task != null) {
        task.deleted = true;
        task.deletedAt = DateTime.now();
        task.lastUpdatedAt = DateTime.now();
        await task.save();
        _logger.debug('Service', '[HiveTaskStorage] Soft deleted task: $key');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error soft deleting task',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> watch() async* {
    try {
      final box = await _getBox();

      // Emit initial data
      yield box.values.where((task) => !task.deleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Watch for changes
      await for (final _ in box.watch()) {
        yield box.values.where((task) => !task.deleted).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error watching tasks',
        stackTrace: stack,
      );
      yield [];
    }
  }

  @override
  Stream<List<Task>> watchWhere(bool Function(Task) predicate) async* {
    try {
      final box = await _getBox();

      List<Task> getFiltered() {
        return box.values.where((t) => !t.deleted && predicate(t)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        message: 'Error watching tasks with filter',
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
      _logger.debug('Service', '[HiveTaskStorage] Cleared all tasks');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error clearing tasks',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<int> count() async {
    try {
      final box = await _getBox();
      return box.values.where((task) => !task.deleted).length;
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
  Future<Task?> findFirst(bool Function(Task) predicate) async {
    try {
      final box = await _getBox();
      return box.values.cast<Task?>().firstWhere(
            (t) => t != null && !t.deleted && predicate(t),
            orElse: () => null,
          );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding task',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Task>> findAll(bool Function(Task) predicate) async {
    try {
      final box = await _getBox();
      return box.values.where((t) => !t.deleted && predicate(t)).toList();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error finding tasks',
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
      _logger.debug('Service', '[HiveTaskStorage] Closed');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error closing task storage',
        stackTrace: stack,
      );
    }
  }

  // ==================== TASK-SPECIFIC METHODS ====================

  /// Get tasks by type (daily, weekly, monthly, yearly, once)
  Future<List<Task>> getByType(String type) async {
    return findAll((task) => task.type == type);
  }

  /// Watch tasks by type
  Stream<List<Task>> watchByType(String type) {
    return watchWhere((task) => task.type == type);
  }

  /// Get completed tasks
  Future<List<Task>> getCompleted() async {
    return findAll((task) => task.isCompleted);
  }

  /// Get uncompleted tasks
  Future<List<Task>> getUncompleted() async {
    return findAll((task) => !task.isCompleted);
  }

  /// Get tasks by category
  Future<List<Task>> getByCategory(String category) async {
    return findAll((task) => task.category == category);
  }

  /// Get tasks by priority
  Future<List<Task>> getByPriority(int priority) async {
    return findAll((task) => task.priority == priority);
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdue() async {
    final now = DateTime.now();
    return findAll((task) =>
        !task.isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(now));
  }

  /// Get tasks due today
  Future<List<Task>> getDueToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return findAll((task) =>
        !task.isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isAfter(today) &&
        task.dueDate!.isBefore(tomorrow));
  }

  /// Find task by firestoreId
  Future<Task?> findByFirestoreId(String firestoreId) async {
    if (firestoreId.isEmpty) return null;
    return findFirst((task) => task.firestoreId == firestoreId);
  }

  /// Find task by createdAt timestamp
  Future<Task?> findByCreatedAt(DateTime createdAt) async {
    return findFirst((task) =>
        task.createdAt.millisecondsSinceEpoch ==
        createdAt.millisecondsSinceEpoch);
  }

  /// Find existing task by any identity
  Future<Task?> _findExisting(Task task) async {
    // 1. By Hive key
    if (task.key != null) {
      final t = await get(task.key);
      if (t != null) return t;
    }
    // 2. By firestoreId
    if (task.firestoreId.isNotEmpty) {
      final t = await findByFirestoreId(task.firestoreId);
      if (t != null) return t;
    }
    // 3. By createdAt
    return findByCreatedAt(task.createdAt);
  }

  /// Mark task as completed
  Future<void> markCompleted(dynamic key) async {
    final task = await get(key);
    if (task != null) {
      task.isCompleted = true;
      task.lastUpdatedAt = DateTime.now();
      await task.save();
    }
  }

  /// Mark task as uncompleted
  Future<void> markUncompleted(dynamic key) async {
    final task = await get(key);
    if (task != null) {
      task.isCompleted = false;
      task.lastUpdatedAt = DateTime.now();
      await task.save();
    }
  }

  /// Get tasks pending cloud sync (no firestoreId)
  Future<List<Task>> getPendingSync() async {
    return findAll((task) => task.firestoreId.isEmpty);
  }

  /// Purge soft-deleted tasks older than specified days
  Future<int> purgeSoftDeleted({int olderThanDays = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
      final box = await _getBox();

      final keysToDelete = <dynamic>[];
      for (final entry in box.toMap().entries) {
        final task = entry.value;
        if (task.deleted &&
            task.deletedAt != null &&
            task.deletedAt!.isBefore(cutoff)) {
          keysToDelete.add(entry.key);
        }
      }

      await box.deleteAll(keysToDelete);
      _logger.debug(
        'Service',
        '[HiveTaskStorage] Purged ${keysToDelete.length} soft-deleted tasks',
      );

      return keysToDelete.length;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error purging soft-deleted tasks',
        stackTrace: stack,
      );
      return 0;
    }
  }
}
