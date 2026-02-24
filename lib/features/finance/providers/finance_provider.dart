import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_category.dart';
import '../data/category_storage.dart';
import '../models/transaction.dart';
import '../data/transaction_storage.dart';
import '../repositories/finance_repository.dart';
import '../services/category_sync_service.dart';
import '../services/transaction_sync_service.dart';
import '../data/firestore_category_storage.dart';
import '../data/firestore_transaction_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import 'dart:async';

class FinanceState {
  final List<Transaction> transactions;
  final List<FinanceCategory> categories;
  final bool isLoading;

  FinanceState({
    this.transactions = const [],
    this.categories = const [],
    this.isLoading = false,
  });

  FinanceState copyWith({
    List<Transaction>? transactions,
    List<FinanceCategory>? categories,
    bool? isLoading,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get totalIncome => transactions
      .where((t) => t.type == FinanceCategoryType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == FinanceCategoryType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  final Ref _ref;
  StreamSubscription? _transactionSubscription;

  FinanceNotifier({required FinanceRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(FinanceState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _repository.init();

      final categories = await _repository.getCategories();

      // Watch transactions
      _transactionSubscription?.cancel();
      _transactionSubscription = _repository.watchTransactions().listen(
        (transactions) {
          final sortedTransactions = [...transactions]
            ..sort((a, b) => b.date.compareTo(a.date));
          state = state.copyWith(
            transactions: sortedTransactions,
            categories: categories,
            isLoading: false,
          );
        },
        onError: (e, stack) {
          ErrorHandler().handle(
            e,
            type: ErrorType.database,
            message: 'Error al observar transacciones',
            stackTrace: stack,
          );
          state = state.copyWith(isLoading: false);
        },
      );

      // Initial sync if user is logged in
      final authState = _ref.read(authStateProvider);
      final user = authState.valueOrNull;
      if (user != null) {
        _repository.performFullSync(user.uid);
      }
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar FinanceProvider',
        stackTrace: stack,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    required String categoryId,
    required FinanceCategoryType type,
    String? note,
  }) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    final userId = user?.uid ?? '';

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: date,
      categoryId: categoryId,
      type: type,
      note: note,
      createdAt: DateTime.now(),
    );

    await _repository.saveTransaction(transaction, userId);
  }

  Future<void> deleteTransaction(dynamic key) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    final userId = user?.uid ?? '';
    await _repository.deleteTransaction(key, userId);
  }

  Future<void> addCategory(FinanceCategory category) async {
    final authState = _ref.read(authStateProvider);
    final user = authState.valueOrNull;
    final userId = user?.uid ?? '';
    await _repository.saveCategory(category, userId);
    final categories = await _repository.getCategories();
    state = state.copyWith(categories: categories);
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  try {
    final categoryStorage = ref.watch(categoryStorageProvider);
    final transactionStorage = ref.watch(transactionStorageProvider);
    final errorHandler = ref.watch(errorHandlerProvider);

    // Sync services
    final categorySync = CategorySyncService(
      localStorage: categoryStorage,
      cloudStorage: FirestoreCategoryStorage(errorHandler),
      errorHandler: errorHandler,
      isCloudSyncEnabled: () async {
        final db = ref.read(databaseServiceProvider);
        final prefs = await db.getUserPreferences();
        return prefs.cloudSyncEnabled;
      },
    );

    final transactionSync = TransactionSyncService(
      localStorage: transactionStorage,
      cloudStorage: FirestoreTransactionStorage(errorHandler),
      errorHandler: errorHandler,
      isCloudSyncEnabled: () async {
        final db = ref.read(databaseServiceProvider);
        final prefs = await db.getUserPreferences();
        return prefs.cloudSyncEnabled;
      },
    );

    return FinanceRepository(
      categoryStorage: categoryStorage,
      transactionStorage: transactionStorage,
      categorySync: categorySync,
      transactionSync: transactionSync,
      errorHandler: errorHandler,
    );
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear FinanceRepository',
      stackTrace: stack,
    );
    rethrow;
  }
});

final categoryStorageProvider = Provider<CategoryStorage>((ref) {
  try {
    final errorHandler = ref.watch(errorHandlerProvider);
    return CategoryStorage(errorHandler);
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear CategoryStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

final transactionStorageProvider = Provider<TransactionStorage>((ref) {
  try {
    final errorHandler = ref.watch(errorHandlerProvider);
    return TransactionStorage(errorHandler);
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear TransactionStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((
  ref,
) {
  try {
    final repository = ref.watch(financeRepositoryProvider);
    return FinanceNotifier(repository: repository, ref: ref);
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear FinanceNotifier',
      stackTrace: stack,
    );
    rethrow;
  }
});
