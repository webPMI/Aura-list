import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class TransactionStorage {
  static const String boxName = 'finance_transactions';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<Transaction>? _box;
  bool _initialized = false;

  TransactionStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      // Check if Transaction adapter is registered (typeId: 16)
      if (!Hive.isAdapterRegistered(16)) {
        _logger.warning(
          'Finance',
          '[TransactionStorage] Hive adapter not registered yet',
        );
        _errorHandler.handle(
          Exception('Hive adapter not registered for Transaction'),
          type: ErrorType.database,
          message: 'Transaction adapter not registered',
        );
        return;
      }

      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<Transaction>(boxName)
          : await Hive.openBox<Transaction>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[TransactionStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar TransactionStorage',
        stackTrace: stack,
      );
      _initialized = false;
      _box = null;
    }
  }

  Future<List<Transaction>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((t) => !t.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<Transaction?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(Transaction transaction) async {
    try {
      if (!_initialized) await init();
      if (_box == null) {
        _logger.warning(
          'Finance',
          '[TransactionStorage] Box not initialized, cannot save',
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
        message: 'Error al guardar transacción',
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
          '[TransactionStorage] Box not initialized, cannot delete',
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
        message: 'Error al eliminar transacción',
        stackTrace: stack,
      );
    }
  }

  Stream<List<Transaction>> watch() async* {
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
}
