import 'package:hive_flutter/hive_flutter.dart';
import '../models/finance_alert.dart';
import '../models/finance_enums.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class FinanceAlertStorage {
  static const String boxName = 'finance_alerts';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<FinanceAlert>? _box;
  bool _initialized = false;

  FinanceAlertStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<FinanceAlert>(boxName)
          : await Hive.openBox<FinanceAlert>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[FinanceAlertStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<List<FinanceAlert>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((a) => !a.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<FinanceAlert>> getActive() async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((a) => !a.deleted && a.isActive && !a.isDismissed)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<FinanceAlert>> getByType(AlertType alertType) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((a) => !a.deleted && a.type == alertType)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<FinanceAlert>> getBySeverity(AlertSeverity severity) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((a) => !a.deleted && a.severity == severity)
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<FinanceAlert?> getById(String id) async {
    try {
      if (!_initialized) await init();
      return _box?.values.firstWhere(
        (a) => a.id == id && !a.deleted,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<FinanceAlert?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(FinanceAlert alert) async {
    try {
      if (!_initialized) await init();
      if (alert.isInBox) {
        await alert.save();
      } else {
        await _box?.add(alert);
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<void> delete(dynamic key) async {
    try {
      if (!_initialized) await init();
      final alert = _box?.get(key);
      if (alert != null) {
        alert.deleted = true;
        alert.deletedAt = DateTime.now();
        await alert.save();
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Stream<List<FinanceAlert>> watch() async* {
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

  Stream<List<FinanceAlert>> watchActive() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values
        .where((a) => !a.deleted && a.isActive && !a.isDismissed)
        .toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values
          .where((a) => !a.deleted && a.isActive && !a.isDismissed)
          .toList();
    }
  }
}
