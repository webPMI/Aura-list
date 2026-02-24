import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_transaction.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class RecurringTransactionStorage {
  static const String boxName = 'finance_recurring_transactions';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<RecurringTransaction>? _box;
  bool _initialized = false;

  RecurringTransactionStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      // Check if RecurringTransaction adapter is registered (typeId: 17)
      if (!Hive.isAdapterRegistered(17)) {
        _logger.warning(
          'Finance',
          '[RecurringTransactionStorage] Hive adapter not registered yet',
        );
        _errorHandler.handle(
          Exception('Hive adapter not registered for RecurringTransaction'),
          type: ErrorType.database,
          message: 'RecurringTransaction adapter not registered',
        );
        return;
      }

      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<RecurringTransaction>(boxName)
          : await Hive.openBox<RecurringTransaction>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[RecurringTransactionStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar RecurringTransactionStorage',
        stackTrace: stack,
      );
      _initialized = false;
      _box = null;
    }
  }

  Future<List<RecurringTransaction>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((t) => !t.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<RecurringTransaction>> getActive() async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((t) => !t.deleted && t.isActive)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<RecurringTransaction>> getByCategory(String categoryId) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((t) => !t.deleted && t.categoryId == categoryId)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<RecurringTransaction>> getByFrequency(String frequency) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((t) => !t.deleted && t.frequency == frequency)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<RecurringTransaction?> getById(String id) async {
    try {
      if (!_initialized) await init();
      return _box?.values.firstWhere(
        (t) => t.id == id && !t.deleted,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<RecurringTransaction?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(RecurringTransaction transaction) async {
    try {
      if (!_initialized) await init();
      if (_box == null) {
        _logger.warning(
          'Finance',
          '[RecurringTransactionStorage] Box not initialized, cannot save',
        );
        return;
      }
      if (transaction.isInBox) {
        await transaction.save();
      } else {
        await _box!.add(transaction);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  Future<void> delete(dynamic key) async {
    try {
      if (!_initialized) await init();
      if (_box == null) {
        _logger.warning(
          'Finance',
          '[RecurringTransactionStorage] Box not initialized, cannot delete',
        );
        return;
      }
      final transaction = _box!.get(key);
      if (transaction != null) {
        transaction.deleted = true;
        transaction.deletedAt = DateTime.now();
        await transaction.save();
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  Stream<List<RecurringTransaction>> watch() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((t) => !t.deleted).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((t) => !t.deleted).toList();
    }
  }

  Stream<List<RecurringTransaction>> watchActive() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((t) => !t.deleted && t.isActive).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((t) => !t.deleted && t.isActive).toList();
    }
  }
}
