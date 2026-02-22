import 'package:hive_flutter/hive_flutter.dart';
import '../models/finance_category.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class CategoryStorage {
  static const String boxName = 'finance_categories';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  Box<FinanceCategory>? _box;
  bool _initialized = false;

  CategoryStorage(this._errorHandler);

  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    try {
      _box = Hive.isBoxOpen(boxName)
          ? Hive.box<FinanceCategory>(boxName)
          : await Hive.openBox<FinanceCategory>(boxName);
      _initialized = true;

      if (_box!.isEmpty) {
        await _box!.addAll(FinanceCategory.defaultCategories);
        _logger.debug('Finance', 'Seeded default finance categories');
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<List<FinanceCategory>> getAll() async {
    try {
      if (!_initialized) await init();
      return _box?.values.toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return [];
    }
  }

  Future<FinanceCategory?> getByKey(dynamic key) async {
    try {
      if (!_initialized) await init();
      return _box?.get(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
      return null;
    }
  }

  Future<void> save(FinanceCategory category) async {
    try {
      if (!_initialized) await init();
      if (category.isInBox) {
        await category.save();
      } else {
        await _box?.add(category);
      }
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }

  Future<void> delete(dynamic key) async {
    try {
      if (!_initialized) await init();
      await _box?.delete(key);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
    }
  }
}
