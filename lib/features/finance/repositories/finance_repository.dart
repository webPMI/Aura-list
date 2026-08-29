import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/category_storage.dart';
import '../data/transaction_storage.dart';
import '../data/recurring_transaction_storage.dart';
import '../data/savings_account_storage.dart';
import '../services/category_sync_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/recurring_transaction_sync_service.dart';
import '../services/savings_account_sync_service.dart';
import '../../../services/error_handler.dart';
import '../models/finance_category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';
import '../models/savings_account.dart';

class FinanceRepository {
  final CategoryStorage _categoryStorage;
  final TransactionStorage _transactionStorage;
  final RecurringTransactionStorage? _recurringStorage;
  final SavingsAccountStorage? _savingsStorage;
  final CategorySyncService _categorySync;
  final TransactionSyncService _transactionSync;
  final RecurringTransactionSyncService? _recurringSync;
  final SavingsAccountSyncService? _savingsSync;

  bool _initialized = false;

  FinanceRepository({
    required CategoryStorage categoryStorage,
    required TransactionStorage transactionStorage,
    RecurringTransactionStorage? recurringStorage,
    SavingsAccountStorage? savingsStorage,
    required CategorySyncService categorySync,
    required TransactionSyncService transactionSync,
    RecurringTransactionSyncService? recurringSync,
    SavingsAccountSyncService? savingsSync,
    ErrorHandler? errorHandler,
  })  : _categoryStorage = categoryStorage,
        _transactionStorage = transactionStorage,
        _recurringStorage = recurringStorage,
        _savingsStorage = savingsStorage,
        _categorySync = categorySync,
        _transactionSync = transactionSync,
        _recurringSync = recurringSync,
        _savingsSync = savingsSync;

  String _resolveUserId(String userId) {
    if (userId.isNotEmpty) return userId;
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    await _categoryStorage.init();
    await _transactionStorage.init();
    if (_recurringStorage != null) await _recurringStorage.init();
    if (_savingsStorage != null) await _savingsStorage.init();
    await _categorySync.init();
    await _transactionSync.init();
    if (_recurringSync != null) await _recurringSync.init();
    if (_savingsSync != null) await _savingsSync.init();
    _initialized = true;
  }

  // Categories
  Future<List<FinanceCategory>> getCategories() => _categoryStorage.getAll();

  Future<void> saveCategory(FinanceCategory category, String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    await _categoryStorage.save(category);
    if (effectiveUserId.isNotEmpty) {
      await _categorySync
          .syncToCloudDebounced(category, effectiveUserId)
          .handleErrorsOrNull(type: ErrorType.network);
      unawaited(_categorySync.flushPendingSyncs());
    }
  }

  Future<void> deleteCategory(dynamic key, String userId) async {
    await _categoryStorage.delete(key);
  }

  // Transactions
  Future<List<Transaction>> getTransactions() => _transactionStorage.getAll();

  Stream<List<Transaction>> watchTransactions() => _transactionStorage.watch();

  Future<void> saveTransaction(Transaction transaction, String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    await _transactionStorage
        .save(transaction)
        .handleErrors(
          type: ErrorType.database,
          userMessage: 'Error al guardar transacción localmente',
        );
    if (effectiveUserId.isNotEmpty) {
      await _transactionSync
          .syncToCloudDebounced(transaction, effectiveUserId)
          .handleErrorsOrNull(
            type: ErrorType.network,
            userMessage: 'Error al programar sincronización de transacción',
          );
      unawaited(_transactionSync.flushPendingSyncs());
    }
  }

  Future<void> deleteTransaction(dynamic key, String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    final transaction = await _transactionStorage.getByKey(key);
    await _transactionStorage
        .delete(key)
        .handleErrors(
          type: ErrorType.database,
          userMessage: 'Error al eliminar transacción',
        );

    if (transaction != null && effectiveUserId.isNotEmpty) {
      await _transactionSync
          .syncToCloudDebounced(transaction, effectiveUserId)
          .handleErrorsOrNull(type: ErrorType.network);
      unawaited(_transactionSync.flushPendingSyncs());
    }
  }

  // Recurring Transactions / Installments
  Future<void> saveRecurringTransaction(
    RecurringTransaction recurring,
    String userId,
  ) async {
    final effectiveUserId = _resolveUserId(userId);
    if (_recurringStorage != null) {
      await _recurringStorage.save(recurring);
    }
    if (_recurringSync != null && effectiveUserId.isNotEmpty) {
      await _recurringSync
          .syncToCloudDebounced(recurring, effectiveUserId)
          .handleErrorsOrNull(
            type: ErrorType.network,
            userMessage: 'Error al sincronizar cuota/recurrente',
          );
      unawaited(_recurringSync.flushPendingSyncs());
    }
  }

  Future<void> performFullSync(String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    if (effectiveUserId.isEmpty) return;
    await _categorySync.performFullSync(effectiveUserId);
    await _transactionSync.performFullSync(effectiveUserId);
    if (_recurringSync != null) {
      await _recurringSync.performFullSync(effectiveUserId);
    }
    if (_savingsSync != null) {
      await _savingsSync.performFullSync(effectiveUserId);
    }
  }

  // Savings Accounts
  Future<List<SavingsAccount>> getSavingsAccounts() async {
    if (_savingsStorage == null) return [];
    return _savingsStorage.getAll();
  }

  Stream<List<SavingsAccount>> watchSavingsAccounts() {
    final storage = _savingsStorage;
    if (storage == null) {
      return Stream.value(const []);
    }
    return storage.watch();
  }

  Future<void> saveSavingsAccount(SavingsAccount account, String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    if (_savingsStorage == null) return;
    await _savingsStorage
        .save(account)
        .handleErrors(
          type: ErrorType.database,
          userMessage: 'Error al guardar cuenta de ahorro localmente',
        );
    if (_savingsSync != null && effectiveUserId.isNotEmpty) {
      await _savingsSync
          .syncToCloudDebounced(account, effectiveUserId)
          .handleErrorsOrNull(
            type: ErrorType.network,
            userMessage: 'Error al programar sincronización de cuenta de ahorro',
          );
      unawaited(_savingsSync.flushPendingSyncs());
    }
  }

  Future<void> deleteSavingsAccount(dynamic key, String userId) async {
    final effectiveUserId = _resolveUserId(userId);
    final account = await _savingsStorage?.getByKey(key);
    if (_savingsStorage != null) {
      await _savingsStorage
          .delete(key)
          .handleErrors(
            type: ErrorType.database,
            userMessage: 'Error al eliminar cuenta de ahorro',
          );
    }

    if (account != null && _savingsSync != null && effectiveUserId.isNotEmpty) {
      await _savingsSync
          .syncToCloudDebounced(account, effectiveUserId)
          .handleErrorsOrNull(type: ErrorType.network);
      unawaited(_savingsSync.flushPendingSyncs());
    }
  }
}
