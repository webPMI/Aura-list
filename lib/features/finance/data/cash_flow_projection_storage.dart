import 'package:hive_flutter/hive_flutter.dart';
import '../models/cash_flow_projection.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class CashFlowProjectionStorage {
  static const String boxName = 'finance_cash_flow_projections';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<CashFlowProjection>? _box;
  bool _initialized = false;

  CashFlowProjectionStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<CashFlowProjection>(boxName)
          : await Hive.openBox<CashFlowProjection>(boxName);
      _initialized = true;
      _logger.debug('Finance', '[CashFlowProjectionStorage] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<List<CashFlowProjection>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.where((p) => !p.deleted).toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<List<CashFlowProjection>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!_initialized) await init();
      return _box?.values
              .where((p) =>
                  !p.deleted &&
                  p.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  p.date.isBefore(endDate.add(const Duration(days: 1))))
              .toList() ??
          [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<CashFlowProjection?> getByDate(DateTime date) async {
    try {
      if (!_initialized) await init();
      final normalized = DateTime(date.year, date.month, date.day);
      return _box?.values.firstWhere(
        (p) {
          final pNormalized = DateTime(p.date.year, p.date.month, p.date.day);
          return pNormalized == normalized && !p.deleted;
        },
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<CashFlowProjection?> getById(String id) async {
    try {
      if (!_initialized) await init();
      return _box?.values.firstWhere(
        (p) => p.id == id && !p.deleted,
        orElse: () => throw Exception('Not found'),
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<CashFlowProjection?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(CashFlowProjection projection) async {
    try {
      if (!_initialized) await init();
      if (projection.isInBox) {
        await projection.save();
      } else {
        await _box?.add(projection);
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<void> delete(dynamic key) async {
    try {
      if (!_initialized) await init();
      final projection = _box?.get(key);
      if (projection != null) {
        projection.deleted = true;
        projection.deletedAt = DateTime.now();
        await projection.save();
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Stream<List<CashFlowProjection>> watch() async* {
    if (!_initialized) await init();
    if (_box == null) {
      yield [];
      return;
    }

    yield _box!.values.where((p) => !p.deleted).toList();

    await for (final _ in _box!.watch()) {
      yield _box!.values.where((p) => !p.deleted).toList();
    }
  }
}
