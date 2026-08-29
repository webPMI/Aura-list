import 'package:hive_flutter/hive_flutter.dart';
import '../models/savings_account.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class SavingsAccountStorage {
  static const String boxName = 'finance_savings_accounts';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<SavingsAccount>? _box;
  bool _initialized = false;

  SavingsAccountStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      // Check if SavingsAccount adapter is registered (typeId: 32)
      if (!Hive.isAdapterRegistered(32)) {
        _logger.warning(
          'Finance',
          '[SavingsAccountStorage] Hive adapter not registered yet',
        );
        _errorHandler.handle(
          Exception('Hive adapter not registered for SavingsAccount'),
          type: ErrorType.database,
          message: 'SavingsAccount adapter not registered',
        );
        return;
      }

      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<SavingsAccount>(boxName)
          : await Hive.openBox<SavingsAccount>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[SavingsAccountStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar SavingsAccountStorage',
        stackTrace: stack,
      );
      _initialized = false;
      _box = null;
    }
  }

  Future<List<SavingsAccount>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((a) => !a.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<SavingsAccount?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(SavingsAccount account) async {
    try {
      if (!_initialized) await init();
      if (_box == null) {
        _logger.warning(
          'Finance',
          '[SavingsAccountStorage] Box not initialized, cannot save',
        );
        return;
      }
      // Use account.id as Hive key for consistent lookups and deletions.
      await _box!.put(account.id, account);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar cuenta de ahorro',
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
          '[SavingsAccountStorage] Box not initialized, cannot delete',
        );
        return;
      }
      final account = _box!.get(key);
      if (account != null) {
        account.deleted = true;
        account.deletedAt = DateTime.now();
        await _box!.put(key, account);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar cuenta de ahorro',
        stackTrace: stack,
      );
    }
  }

  Stream<List<SavingsAccount>> watch() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((a) => !a.deleted).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((a) => !a.deleted).toList();
    }
  }
}
