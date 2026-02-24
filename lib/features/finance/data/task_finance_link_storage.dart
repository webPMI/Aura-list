import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_finance_link.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class TaskFinanceLinkStorage {
  static const String boxName = 'finance_task_links';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<TaskFinanceLink>? _box;
  bool _initialized = false;

  TaskFinanceLinkStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      // Check if TaskFinanceLink adapter is registered (typeId: 28)
      if (!Hive.isAdapterRegistered(28)) {
        _logger.warning(
          'Finance',
          '[TaskFinanceLinkStorage] Hive adapter not registered yet',
        );
        _errorHandler.handle(
          Exception('Hive adapter not registered for TaskFinanceLink'),
          type: ErrorType.database,
          message: 'TaskFinanceLink adapter not registered',
        );
        return;
      }

      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<TaskFinanceLink>(boxName)
          : await Hive.openBox<TaskFinanceLink>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[TaskFinanceLinkStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar TaskFinanceLinkStorage',
        stackTrace: stack,
      );
      _initialized = false;
      _box = null;
    }
  }

  Future<List<TaskFinanceLink>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((l) => !l.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<TaskFinanceLink>> getByTaskId(String taskId) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((l) => !l.deleted && l.taskId == taskId)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<TaskFinanceLink>> getByTransactionId(String transactionId) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((l) => !l.deleted && l.actualTransactionId == transactionId)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<TaskFinanceLink>> getByImpactType(FinancialImpactType impactType) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((l) => !l.deleted && l.impactType == impactType)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<TaskFinanceLink?> getById(String id) async {
    try {
      if (!_initialized) await init();
      return _box?.values.firstWhere(
        (l) => l.id == id && !l.deleted,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<TaskFinanceLink?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(TaskFinanceLink link) async {
    try {
      if (!_initialized) await init();
      if (_box == null) {
        _logger.warning(
          'Finance',
          '[TaskFinanceLinkStorage] Box not initialized, cannot save',
        );
        return;
      }
      if (link.isInBox) {
        await link.save();
      } else {
        await _box!.add(link);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar enlace tarea-finanzas',
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
          '[TaskFinanceLinkStorage] Box not initialized, cannot delete',
        );
        return;
      }
      final link = _box!.get(key);
      if (link != null) {
        link.deleted = true;
        link.deletedAt = DateTime.now();
        await link.save();
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar enlace tarea-finanzas',
        stackTrace: stack,
      );
    }
  }

  Stream<List<TaskFinanceLink>> watch() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((l) => !l.deleted).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((l) => !l.deleted).toList();
    }
  }

  Stream<List<TaskFinanceLink>> watchByTaskId(String taskId) async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((l) => !l.deleted && l.taskId == taskId).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((l) => !l.deleted && l.taskId == taskId).toList();
    }
  }
}
