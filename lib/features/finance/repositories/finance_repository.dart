import 'dart:async';
import '../data/category_storage.dart';
import '../data/transaction_storage.dart';
import '../services/category_sync_service.dart';
import '../services/transaction_sync_service.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';
import '../models/finance_category.dart';
import '../models/transaction.dart';

class FinanceRepository {
  final CategoryStorage _categoryStorage;
  final TransactionStorage _transactionStorage;
  final CategorySyncService _categorySync;
  final TransactionSyncService _transactionSync;
  final ErrorHandler _errorHandler;
  final _logger = LoggerService();

  bool _initialized = false;

  FinanceRepository({
    required CategoryStorage categoryStorage,
    required TransactionStorage transactionStorage,
    required CategorySyncService categorySync,
    required TransactionSyncService transactionSync,
    required ErrorHandler errorHandler,
  }) : _categoryStorage = categoryStorage,
       _transactionStorage = transactionStorage,
       _categorySync = categorySync,
       _transactionSync = transactionSync,
       _errorHandler = errorHandler;

  Future<void> init() async {
    if (_initialized) return;
    await _categoryStorage.init();
    await _transactionStorage.init();
    await _categorySync.init();
    await _transactionSync.init();
    _initialized = true;
  }

  // Categories
  Future<List<FinanceCategory>> getCategories() => _categoryStorage.getAll();

  Future<void> saveCategory(FinanceCategory category, String userId) async {
    await _categoryStorage.save(category);
    if (userId.isNotEmpty) {
      await _categorySync
          .syncToCloudDebounced(category, userId)
          .handleErrorsOrNull(type: ErrorType.network);
    }
  }

  // Transactions
  Future<List<Transaction>> getTransactions() => _transactionStorage.getAll();

  Stream<List<Transaction>> watchTransactions() => _transactionStorage.watch();

  Future<void> saveTransaction(Transaction transaction, String userId) async {
    await _transactionStorage
        .save(transaction)
        .handleErrors(
          type: ErrorType.database,
          userMessage: 'Error al guardar transacción localmente',
        );
    if (userId.isNotEmpty) {
      await _transactionSync
          .syncToCloudDebounced(transaction, userId)
          .handleErrorsOrNull(
            type: ErrorType.network,
            userMessage: 'Error al programar sincronización de transacción',
          );
    }
  }

  Future<void> deleteTransaction(dynamic key, String userId) async {
    final transaction = await _transactionStorage.getByKey(key);
    await _transactionStorage
        .delete(key)
        .handleErrors(
          type: ErrorType.database,
          userMessage: 'Error al eliminar transacción',
        );

    if (transaction != null && userId.isNotEmpty) {
      await _transactionSync
          .syncToCloudDebounced(transaction, userId)
          .handleErrorsOrNull(type: ErrorType.network);
    }
  }

  Future<void> performFullSync(String userId) async {
    if (userId.isEmpty) return;
    await _categorySync.performFullSync(userId);
    await _transactionSync.performFullSync(userId);
  }
}
