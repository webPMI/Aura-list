import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_category.dart';
import '../data/category_storage.dart';
import '../models/transaction.dart';
import '../data/transaction_storage.dart';
import '../repositories/finance_repository.dart';
import '../services/category_sync_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/recurring_transaction_sync_service.dart';
import '../data/firestore_category_storage.dart';
import '../data/firestore_transaction_storage.dart';
import '../data/firestore_recurring_transaction_storage.dart';
import '../data/recurring_transaction_storage.dart';
import '../data/savings_account_storage.dart';
import '../data/firestore_savings_account_storage.dart';
import '../services/savings_account_sync_service.dart';
import '../../../services/error_handler.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import 'dart:async';

class FinanceState {
  final List<Transaction> transactions;
  final List<FinanceCategory> categories;
  final bool isLoading;

  double? _cachedTotalIncome;
  double? _cachedTotalExpenses;

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

  double get totalIncome {
    _cachedTotalIncome ??= transactions
        .where((t) => t.type == FinanceCategoryType.income)
        .fold<double>(0.0, (double sum, t) => sum + t.amount);
    return _cachedTotalIncome!;
  }

  double get totalExpenses {
    _cachedTotalExpenses ??= transactions
        .where((t) => t.type == FinanceCategoryType.expense)
        .fold<double>(0.0, (double sum, t) => sum + t.amount);
    return _cachedTotalExpenses!;
  }

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
      // Ensure DatabaseService has been initialized so all Hive adapters are
      // registered before CategoryStorage / TransactionStorage attempt to open
      // their typed boxes.
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.init();

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
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        unawaited(_repository.performFullSync(userId));
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

  String _getUserId() {
    try {
      final authService = _ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        return authService.currentUser!.uid;
      }
    } catch (_) {}
    return '';
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    String? categoryId,
    required FinanceCategoryType type,
    String? note,
  }) async {
    final userId = _getUserId();

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
    final userId = _getUserId();
    await _repository.deleteTransaction(key, userId);
  }

  Future<void> addCategory(FinanceCategory category) async {
    final userId = _getUserId();
    await _repository.saveCategory(category, userId);
    final categories = await _repository.getCategories();
    state = state.copyWith(categories: categories);
  }

  Future<void> updateCategory(FinanceCategory category) async {
    final userId = _getUserId();
    await _repository.saveCategory(category, userId);
    final categories = await _repository.getCategories();
    state = state.copyWith(categories: categories);
  }

  Future<void> deleteCategory(dynamic key) async {
    final userId = _getUserId();
    await _repository.deleteCategory(key, userId);
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

    final recurringStorage = RecurringTransactionStorage(errorHandler);

    final recurringSync = RecurringTransactionSyncService(
      localStorage: recurringStorage,
      cloudStorage: FirestoreRecurringTransactionStorage(errorHandler),
      errorHandler: errorHandler,
      isCloudSyncEnabled: () async {
        final db = ref.read(databaseServiceProvider);
        final prefs = await db.getUserPreferences();
        return prefs.cloudSyncEnabled;
      },
    );

    final savingsStorage = SavingsAccountStorage(errorHandler);

    final savingsSync = SavingsAccountSyncService(
      localStorage: savingsStorage,
      cloudStorage: FirestoreSavingsAccountStorage(errorHandler),
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
      recurringStorage: recurringStorage,
      savingsStorage: savingsStorage,
      categorySync: categorySync,
      transactionSync: transactionSync,
      recurringSync: recurringSync,
      savingsSync: savingsSync,
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

final savingsAccountStorageProvider = Provider<SavingsAccountStorage>((ref) {
  try {
    final errorHandler = ref.watch(errorHandlerProvider);
    return SavingsAccountStorage(errorHandler);
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear SavingsAccountStorage',
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

/// Períodos contables disponibles para filtrado
enum FinanceTimePeriod { thisMonth, lastMonth, thisYear, allTime }

extension FinanceTimePeriodExtension on FinanceTimePeriod {
  String get label {
    switch (this) {
      case FinanceTimePeriod.thisMonth:
        return 'Este Mes';
      case FinanceTimePeriod.lastMonth:
        return 'Mes Anterior';
      case FinanceTimePeriod.thisYear:
        return 'Este Año';
      case FinanceTimePeriod.allTime:
        return 'Todo el Historial';
    }
  }
}

/// Provider para el período contable seleccionado
final selectedFinancePeriodProvider = StateProvider<FinanceTimePeriod>(
  (ref) => FinanceTimePeriod.thisMonth,
);

/// Provider de transacciones filtradas según el período contable seleccionado
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(financeProvider.select((s) => s.transactions));
  final period = ref.watch(selectedFinancePeriodProvider);
  final now = DateTime.now();

  return transactions.where((t) {
    switch (period) {
      case FinanceTimePeriod.thisMonth:
        return t.date.year == now.year && t.date.month == now.month;
      case FinanceTimePeriod.lastMonth:
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return t.date.year == year && t.date.month == lastMonth;
      case FinanceTimePeriod.thisYear:
        return t.date.year == now.year;
      case FinanceTimePeriod.allTime:
        return true;
    }
  }).toList();
});

/// Elemento de desglose de categoría con monto y porcentaje
class CategoryBreakdownItem {
  final FinanceCategory category;
  final double amount;
  final double percentage;

  const CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

/// Estadísticas contables del período seleccionado
class PeriodFinanceStats {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;
  final List<CategoryBreakdownItem> expenseCategories;
  final List<CategoryBreakdownItem> incomeCategories;

  const PeriodFinanceStats({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
    required this.expenseCategories,
    required this.incomeCategories,
  });
}

/// Provider que calcula las estadísticas contables del período activo
final periodFinanceStatsProvider = Provider<PeriodFinanceStats>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final categories = ref.watch(financeProvider.select((s) => s.categories));

  final totalIncome = transactions
      .where((t) => t.type == FinanceCategoryType.income)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  final totalExpenses = transactions
      .where((t) => t.type == FinanceCategoryType.expense)
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  final netSavings = totalIncome - totalExpenses;
  final savingsRate =
      totalIncome > 0 ? ((netSavings / totalIncome) * 100).clamp(-100.0, 100.0) : 0.0;

  final Map<String, double> expenseMap = {};
  final Map<String, double> incomeMap = {};

  for (final t in transactions) {
    final catId = t.categoryId ?? 'uncategorized';
    if (t.type == FinanceCategoryType.expense) {
      expenseMap[catId] = (expenseMap[catId] ?? 0.0) + t.amount;
    } else {
      incomeMap[catId] = (incomeMap[catId] ?? 0.0) + t.amount;
    }
  }

  List<CategoryBreakdownItem> buildBreakdown(Map<String, double> map, double total) {
    if (total <= 0) return [];
    final items = <CategoryBreakdownItem>[];
    for (final entry in map.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => FinanceCategory(
          id: entry.key,
          name: 'General',
          icon: 'help',
          color: '#9E9E9E',
          type: FinanceCategoryType.expense,
        ),
      );
      final percentage = (entry.value / total) * 100;
      items.add(CategoryBreakdownItem(
        category: category,
        amount: entry.value,
        percentage: percentage,
      ));
    }
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  return PeriodFinanceStats(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netSavings: netSavings,
    savingsRate: savingsRate,
    expenseCategories: buildBreakdown(expenseMap, totalExpenses),
    incomeCategories: buildBreakdown(incomeMap, totalIncome),
  );
});



