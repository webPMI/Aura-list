import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class BudgetStorage {
  static const String boxName = 'finance_budgets';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<Budget>? _box;
  bool _initialized = false;

  BudgetStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<Budget>(boxName)
          : await Hive.openBox<Budget>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[BudgetStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<List<Budget>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((b) => !b.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<Budget>> getActive() async {
    try {
      if (!_initialized) await init();
      final now = DateTime.now();
      return _box?.values
              .where((b) =>
                  !b.deleted &&
                  b.active &&
                  b.startDate.isBefore(now) &&
                  (b.endDate == null || b.endDate!.isAfter(now)))
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<Budget>> getByCategory(String categoryId) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((b) => !b.deleted && b.categoryId == categoryId)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<Budget>> getByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((b) =>
                  !b.deleted &&
                  b.startDate.isBefore(endDate) &&
                  (b.endDate == null || b.endDate!.isAfter(startDate)))
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<Budget?> getById(String id) async {
    try {
      if (!_initialized) await init();
      return _box?.values.firstWhere(
        (b) => b.id == id && !b.deleted,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<Budget?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(Budget budget) async {
    try {
      if (!_initialized) await init();
      if (budget.isInBox) {
        await budget.save();
      } else {
        await _box?.add(budget);
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<void> delete(dynamic key) async {
    try {
      if (!_initialized) await init();
      final budget = _box?.get(key);
      if (budget != null) {
        budget.deleted = true;
        budget.deletedAt = DateTime.now();
        await budget.save();
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Stream<List<Budget>> watch() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((b) => !b.deleted).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((b) => !b.deleted).toList();
    }
  }

  Stream<List<Budget>> watchActive() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    final now = DateTime.now();
    yield _box!.values
        .where(
            (b) => !b.deleted && b.active && b.startDate.isBefore(now) && (b.endDate == null || b.endDate!.isAfter(now)))
        .toList();

    await for (final _ in _box!.watch()) {
      final now = DateTime.now();
      yield _box!.values
          .where((b) =>
              !b.deleted && b.active && b.startDate.isBefore(now) && (b.endDate == null || b.endDate!.isAfter(now)))
          .toList();
    }
  }
}
