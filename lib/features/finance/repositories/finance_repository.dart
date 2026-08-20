import 'dart:async';
import '../data/category_storage.dart';
import '../data/transaction_storage.dart';
import '../data/recurring_transaction_storage.dart';
import '../services/category_sync_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/recurring_transaction_sync_service.dart';
import '../../../services/error_handler.dart';
import '../models/finance_category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';

class FinanceRepository {
  final CategoryStorage _categoryStorage;
  final TransactionStorage _transactionStorage;
  final RecurringTransactionStorage? _recurringStorage;
  final CategorySyncService _categorySync;
  final TransactionSyncService _transactionSync;
  final RecurringTransactionSyncService? _recurringSync;

  bool _initialized = false;

  FinanceRepository({
    required CategoryStorage categoryStorage,
    required TransactionStorage transactionStorage,
    RecurringTransactionStorage? recurringStorage,
    required CategorySyncService categorySync,
    required TransactionSyncService transactionSync,
    RecurringTransactionSyncService? recurringSync,
    ErrorHandler? errorHandler,
  })  : _categoryStorage = categoryStorage,
        _transactionStorage = transactionStorage,
        _recurringStorage = recurringStorage,
        _categorySync = categorySync,
        _transactionSync = transactionSync,
        _recurringSync = recurringSync;

  Future<void> init() async {
    if (_initialized) return;
    await _categoryStorage.init();
    await _transactionStorage.init();
    if (_recurringStorage != null) await _recurringStorage.init();
    await _categorySync.init();
    await _transactionSync.init();
    if (_recurringSync != null) await _recurringSync.init();
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

  Future<void> deleteCategory(dynamic key, String userId) async {
    await _categoryStorage.delete(key);
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

  // Recurring Transactions / Installments
  Future<void> saveRecurringTransaction(
    RecurringTransaction recurring,
    String userId,
  ) async {
    if (_recurringStorage != null) {
      await _recurringStorage.save(recurring);
    }
    if (_recurringSync != null && userId.isNotEmpty) {
      await _recurringSync
          .syncToCloudDebounced(recurring, userId)
          .handleErrorsOrNull(
            type: ErrorType.network,
            userMessage: 'Error al sincronizar cuota/recurrente',
          );
    }
  }

  Future<void> performFullSync(String userId) async {
    if (userId.isEmpty) return;
    await _categorySync.performFullSync(userId);
    await _transactionSync.performFullSync(userId);
    if (_recurringSync != null) {
      await _recurringSync.performFullSync(userId);
    }
  }
}
