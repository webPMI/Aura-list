import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/recurring_transaction.dart';
import '../models/budget.dart';
import '../models/cash_flow_projection.dart';
import '../models/finance_alert.dart';
import '../models/task_finance_link.dart';
import '../data/recurring_transaction_storage.dart';
import '../data/budget_storage.dart';
import '../data/cash_flow_projection_storage.dart';
import '../data/finance_alert_storage.dart';
import '../data/task_finance_link_storage.dart';
import '../services/recurring_transaction_service.dart';
import '../../../services/error_handler.dart';
import '../../../services/auth_service.dart';
import '../models/finance_category.dart';
import 'finance_provider.dart';

/// Estado del provider de previsiones financieras.
class ForecastState {
  final List<RecurringTransaction> recurringTransactions;
  final List<Budget> budgets;
  final List<CashFlowProjection> projections;
  final List<FinanceAlert> alerts;
  final List<TaskFinanceLink> taskLinks;
  final bool isLoading;
  final String? error;

  const ForecastState({
    this.recurringTransactions = const [],
    this.budgets = const [],
    this.projections = const [],
    this.alerts = const [],
    this.taskLinks = const [],
    this.isLoading = false,
    this.error,
  });

  ForecastState copyWith({
    List<RecurringTransaction>? recurringTransactions,
    List<Budget>? budgets,
    List<CashFlowProjection>? projections,
    List<FinanceAlert>? alerts,
    List<TaskFinanceLink>? taskLinks,
    bool? isLoading,
    String? error,
  }) {
    return ForecastState(
      recurringTransactions:
          recurringTransactions ?? this.recurringTransactions,
      budgets: budgets ?? this.budgets,
      projections: projections ?? this.projections,
      alerts: alerts ?? this.alerts,
      taskLinks: taskLinks ?? this.taskLinks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Obtiene alertas activas (no leídas ni desestimadas).
  List<FinanceAlert> get activeAlerts =>
      alerts.where((alert) => alert.isActive && !alert.isRead).toList();

  /// Obtiene transacciones recurrentes activas.
  List<RecurringTransaction> get activeRecurring =>
      recurringTransactions.where((rt) => rt.active && !rt.deleted).toList();

  /// Obtiene presupuestos activos.
  List<Budget> get activeBudgets =>
      budgets.where((b) => b.active && !b.deleted).toList();
}

/// Notificador del estado de previsiones financieras.
class ForecastNotifier extends StateNotifier<ForecastState> {
  final RecurringTransactionStorage _recurringStorage;
  final BudgetStorage _budgetStorage;
  final CashFlowProjectionStorage _projectionStorage;
  final FinanceAlertStorage _alertStorage;
  final TaskFinanceLinkStorage _linkStorage;
  final RecurringTransactionService _recurringService;
  final ErrorHandler _errorHandler;

  StreamSubscription? _recurringSubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _alertSubscription;

  final Ref _ref;

  ForecastNotifier({
    required RecurringTransactionStorage recurringStorage,
    required BudgetStorage budgetStorage,
    required CashFlowProjectionStorage projectionStorage,
    required FinanceAlertStorage alertStorage,
    required TaskFinanceLinkStorage linkStorage,
    required RecurringTransactionService recurringService,
    required ErrorHandler errorHandler,
    required Ref ref,
  }) : _recurringStorage = recurringStorage,
       _budgetStorage = budgetStorage,
       _projectionStorage = projectionStorage,
       _alertStorage = alertStorage,
       _linkStorage = linkStorage,
       _recurringService = recurringService,
       _errorHandler = errorHandler,
       _ref = ref,
       super(ForecastState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Initialize storages first to ensure boxes are ready
      await _recurringStorage.init();
      await _budgetStorage.init();
      await _projectionStorage.init();
      await _alertStorage.init();
      await _linkStorage.init();

      // Watch recurring transactions
      _recurringSubscription?.cancel();
      _recurringSubscription = _recurringStorage.watch().listen(
        (recurring) {
          state = state.copyWith(
            recurringTransactions: recurring,
            isLoading: false,
          );
        },
        onError: (e, stack) {
          _errorHandler.handle(
            e,
            type: ErrorType.database,
            message: 'Error al observar transacciones recurrentes',
            stackTrace: stack,
          );
        },
      );

      // Watch budgets
      _budgetSubscription?.cancel();
      _budgetSubscription = _budgetStorage.watch().listen(
        (budgets) {
          state = state.copyWith(budgets: budgets);
        },
        onError: (e, stack) {
          _errorHandler.handle(
            e,
            type: ErrorType.database,
            message: 'Error al observar presupuestos',
            stackTrace: stack,
          );
        },
      );

      // Watch alerts
      _alertSubscription?.cancel();
      _alertSubscription = _alertStorage.watch().listen(
        (alerts) {
          state = state.copyWith(alerts: alerts);
        },
        onError: (e, stack) {
          _errorHandler.handle(
            e,
            type: ErrorType.database,
            message: 'Error al observar alertas',
            stackTrace: stack,
          );
        },
      );

      // Load initial data
      await refreshAll();

      // Initial sync if user is authenticated
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        unawaited(_ref.read(financeRepositoryProvider).performFullSync(userId));
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al inicializar previsiones',
        stackTrace: stack,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
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

  /// Refresca todos los datos.
  Future<void> refreshAll() async {
    try {
      state = state.copyWith(isLoading: true);

      final projections = await _projectionStorage.getAll();
      final taskLinks = await _linkStorage.getAll();

      state = state.copyWith(
        projections: projections,
        taskLinks: taskLinks,
        isLoading: false,
        error: null,
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al refrescar datos',
        stackTrace: stack,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Detecta patrones recurrentes en el historial.
  Future<void> detectRecurringPatterns() async {
    try {
      final detected = await _recurringService.detectRecurringPatterns();

      if (detected.isNotEmpty) {
        // Guardar los patrones detectados
        for (final pattern in detected) {
          await _recurringStorage.save(pattern);
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al detectar patrones',
        stackTrace: stack,
      );
    }
  }

  /// Agrega una transacción recurrente.
  Future<void> addRecurringTransaction(RecurringTransaction transaction) async {
    try {
      await _recurringStorage.save(transaction);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(transaction, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  /// Actualiza una transacción recurrente.
  Future<void> updateRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      await _recurringStorage.save(transaction);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(transaction, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al actualizar transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  /// Elimina una transacción recurrente.
  Future<void> deleteRecurringTransaction(String id) async {
    try {
      await _recurringStorage.delete(id);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  /// Pausa/reanuda una transacción recurrente.
  Future<void> toggleRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    try {
      final updated = transaction.copyWith(active: !transaction.active);
      await _recurringStorage.save(updated);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(updated, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al cambiar estado de transacción recurrente',
        stackTrace: stack,
      );
    }
  }

  /// Registra el pago de una cuota (modo manual o confirmación manual).
  /// Incrementa el contador de cuotas y, si se completaron todas, desactiva la recurrencia.
  Future<void> payInstallment(RecurringTransaction transaction) async {
    try {
      final newPaid = transaction.paidInstallments + 1;
      final history = List<int>.from(transaction.paymentDateHistory)
        ..add(DateTime.now().millisecondsSinceEpoch);

      final bool nowComplete = transaction.totalInstallments != null &&
          newPaid >= transaction.totalInstallments!;

      final updated = transaction.copyWith(
        paidInstallments: newPaid,
        paymentDateHistory: history,
        lastGenerated: DateTime.now(),
        active: !nowComplete,
        lastUpdatedAt: DateTime.now(),
      );
      await _recurringStorage.save(updated);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(updated, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al registrar pago de cuota',
        stackTrace: stack,
      );
    }
  }

  /// Aplaza una cuota al siguiente período (no la paga, incrementa deferredInstallments).
  Future<void> deferInstallment(RecurringTransaction transaction) async {
    try {
      final updated = transaction.copyWith(
        deferredInstallments: transaction.deferredInstallments + 1,
        lastUpdatedAt: DateTime.now(),
      );
      await _recurringStorage.save(updated);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(updated, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al aplazar cuota',
        stackTrace: stack,
      );
    }
  }

  /// Omite una cuota (la marca como saltada sin pagar ni aplazar).
  /// Avanza el contador como si se hubiera pagado para no bloquear el flujo.
  Future<void> skipInstallment(RecurringTransaction transaction) async {
    try {
      final newPaid = transaction.paidInstallments + 1;
      final bool nowComplete = transaction.totalInstallments != null &&
          newPaid >= transaction.totalInstallments!;
      final updated = transaction.copyWith(
        paidInstallments: newPaid,
        active: !nowComplete,
        lastUpdatedAt: DateTime.now(),
      );
      await _recurringStorage.save(updated);
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        await _ref
            .read(financeRepositoryProvider)
            .saveRecurringTransaction(updated, userId);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al omitir cuota',
        stackTrace: stack,
      );
    }
  }

  /// Agrega un presupuesto.
  Future<void> addBudget(Budget budget) async {
    try {
      await _budgetStorage.save(budget);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar presupuesto',
        stackTrace: stack,
      );
    }
  }

  /// Actualiza un presupuesto.
  Future<void> updateBudget(Budget budget) async {
    try {
      await _budgetStorage.save(budget);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al actualizar presupuesto',
        stackTrace: stack,
      );
    }
  }

  /// Elimina un presupuesto.
  Future<void> deleteBudget(String id) async {
    try {
      await _budgetStorage.delete(id);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar presupuesto',
        stackTrace: stack,
      );
    }
  }

  /// Marca una alerta como leída.
  Future<void> markAlertAsRead(FinanceAlert alert) async {
    try {
      final updated = alert.copyWith(isRead: true, readAt: DateTime.now());
      await _alertStorage.save(updated);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al marcar alerta como leída',
        stackTrace: stack,
      );
    }
  }

  /// Desestima una alerta.
  Future<void> dismissAlert(FinanceAlert alert) async {
    try {
      final updated = alert.copyWith(
        isDismissed: true,
        dismissedAt: DateTime.now(),
      );
      await _alertStorage.save(updated);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al desestimar alerta',
        stackTrace: stack,
      );
    }
  }

  /// Agrega un enlace tarea-finanzas.
  Future<void> addTaskFinanceLink(TaskFinanceLink link) async {
    try {
      await _linkStorage.save(link);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al guardar enlace tarea-finanzas',
        stackTrace: stack,
      );
    }
  }

  /// Elimina un enlace tarea-finanzas.
  Future<void> deleteTaskFinanceLink(String id) async {
    try {
      await _linkStorage.delete(id);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al eliminar enlace tarea-finanzas',
        stackTrace: stack,
      );
    }
  }

  @override
  void dispose() {
    _recurringSubscription?.cancel();
    _budgetSubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider para RecurringTransactionStorage.
final recurringTransactionStorageProvider =
    Provider<RecurringTransactionStorage>((ref) {
      try {
        return RecurringTransactionStorage(ref.watch(errorHandlerProvider));
      } catch (e, stack) {
        final errorHandler = ref.watch(errorHandlerProvider);
        errorHandler.handle(
          e,
          type: ErrorType.database,
          message: 'Error al crear RecurringTransactionStorage',
          stackTrace: stack,
        );
        rethrow;
      }
    });

/// Provider para BudgetStorage.
final budgetStorageProvider = Provider<BudgetStorage>((ref) {
  try {
    return BudgetStorage(ref.watch(errorHandlerProvider));
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear BudgetStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider para CashFlowProjectionStorage.
final cashFlowProjectionStorageProvider = Provider<CashFlowProjectionStorage>((
  ref,
) {
  try {
    return CashFlowProjectionStorage(ref.watch(errorHandlerProvider));
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear CashFlowProjectionStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider para FinanceAlertStorage.
final financeAlertStorageProvider = Provider<FinanceAlertStorage>((ref) {
  try {
    return FinanceAlertStorage(ref.watch(errorHandlerProvider));
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear FinanceAlertStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider para TaskFinanceLinkStorage.
final taskFinanceLinkStorageProvider = Provider<TaskFinanceLinkStorage>((ref) {
  try {
    return TaskFinanceLinkStorage(ref.watch(errorHandlerProvider));
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear TaskFinanceLinkStorage',
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Provider para RecurringTransactionService.
final recurringTransactionServiceProvider =
    Provider<RecurringTransactionService>((ref) {
      try {
        return RecurringTransactionService(
          storage: ref.watch(recurringTransactionStorageProvider),
          transactionStorage: ref.watch(transactionStorageProvider),
          errorHandler: ref.watch(errorHandlerProvider),
        );
      } catch (e, stack) {
        final errorHandler = ref.watch(errorHandlerProvider);
        errorHandler.handle(
          e,
          type: ErrorType.database,
          message: 'Error al crear RecurringTransactionService',
          stackTrace: stack,
        );
        rethrow;
      }
    });

/// Provider principal de previsiones financieras.
final forecastProvider = StateNotifierProvider<ForecastNotifier, ForecastState>(
  (ref) {
    try {
      return ForecastNotifier(
        recurringStorage: ref.watch(recurringTransactionStorageProvider),
        budgetStorage: ref.watch(budgetStorageProvider),
        projectionStorage: ref.watch(cashFlowProjectionStorageProvider),
        alertStorage: ref.watch(financeAlertStorageProvider),
        linkStorage: ref.watch(taskFinanceLinkStorageProvider),
        recurringService: ref.watch(recurringTransactionServiceProvider),
        errorHandler: ref.watch(errorHandlerProvider),
        ref: ref,
      );
    } catch (e, stack) {
      final errorHandler = ref.watch(errorHandlerProvider);
      errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al crear ForecastNotifier',
        stackTrace: stack,
      );
      rethrow;
    }
  },
);

/// Provider de alertas activas.
final activeAlertsProvider = Provider<List<FinanceAlert>>((ref) {
  return ref.watch(forecastProvider).activeAlerts;
});

/// Provider de conteo de alertas activas.
final activeAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(forecastProvider).activeAlerts.length;
});

/// Provider de transacciones recurrentes activas.
final activeRecurringProvider = Provider<List<RecurringTransaction>>((ref) {
  return ref.watch(forecastProvider).activeRecurring;
});

/// Provider de presupuestos activos.
final activeBudgetsProvider = Provider<List<Budget>>((ref) {
  return ref.watch(forecastProvider).activeBudgets;
});

// ============================================================
// ESTRUCTURAS Y PROVIDERS DE ANÁLISIS Y PROYECCIÓN DE GASTOS
// ============================================================

/// Detalle de un gasto o ingreso proyectado en un mes específico
class ProjectedItemDetail {
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isExpense;
  final String? categoryId;
  final String categoryName;
  final String categoryColor;
  final String source; // 'recurring', 'installment', 'future_transaction'
  final String? installmentSummary;

  const ProjectedItemDetail({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.isExpense,
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.source,
    this.installmentSummary,
  });
}

/// Proyección financiera de un mes específico
class MonthlyForecastProjection {
  final DateTime month;
  final double startingBalance;
  final double projectedIncome;
  final double projectedFixedExpenses;
  final double projectedScheduledExpenses;
  final double estimatedDiscretionaryExpenses;
  final double totalProjectedExpenses;
  final double endingBalance;
  final double netCashFlow;
  final List<ProjectedItemDetail> items;
  final Map<String, double> expensesByCategory;

  const MonthlyForecastProjection({
    required this.month,
    required this.startingBalance,
    required this.projectedIncome,
    required this.projectedFixedExpenses,
    required this.projectedScheduledExpenses,
    required this.estimatedDiscretionaryExpenses,
    required this.totalProjectedExpenses,
    required this.endingBalance,
    required this.netCashFlow,
    required this.items,
    required this.expensesByCategory,
  });

  bool get hasDeficit => endingBalance < 0 || netCashFlow < 0;
}

/// Estadísticas completas de previsión financiera y proyección de gastos
class ExpenseForecastStats {
  final double currentBalance;
  final double totalSavingsBalance;
  final double averageDailyExpenseHistorical;
  final double averageMonthlyExpenseHistorical;
  final double monthlyFixedCommitments;
  final double upcoming30DaysExpenses;
  final double upcoming30DaysIncome;
  final int activeInstallmentsCount;
  final int activeRecurringCount;
  final List<MonthlyForecastProjection> monthlyProjections;

  const ExpenseForecastStats({
    required this.currentBalance,
    required this.totalSavingsBalance,
    required this.averageDailyExpenseHistorical,
    required this.averageMonthlyExpenseHistorical,
    required this.monthlyFixedCommitments,
    required this.upcoming30DaysExpenses,
    required this.upcoming30DaysIncome,
    required this.activeInstallmentsCount,
    required this.activeRecurringCount,
    required this.monthlyProjections,
  });
}

/// Provider principal que calcula el análisis de proyecciones y estadísticas de gastos futuros
final expenseForecastStatsProvider = Provider<ExpenseForecastStats>((ref) {
  final financeState = ref.watch(financeProvider);
  final activeRecurring = ref.watch(activeRecurringProvider);
  final allTransactions = financeState.transactions;
  final categories = financeState.categories;

  final now = DateTime.now();

  // 1. Balance actual (histórico)
  final pastTransactions = allTransactions.where((t) => !t.date.isAfter(now)).toList();
  final pastIncome = pastTransactions
      .where((t) => t.type == FinanceCategoryType.income)
      .fold<double>(0.0, (sum, t) => sum + t.amount);
  final pastExpenses = pastTransactions
      .where((t) => t.type == FinanceCategoryType.expense)
      .fold<double>(0.0, (sum, t) => sum + t.amount);
  final currentBalance = pastIncome - pastExpenses;

  // 2. Gasto promedio histórico diario y mensual
  double avgDaily = 0.0;
  if (pastTransactions.where((t) => t.isExpense).isNotEmpty) {
    final expenseTxs = pastTransactions.where((t) => t.isExpense).toList();
    DateTime minDate = expenseTxs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final daysSpan = (now.difference(minDate).inDays + 1).clamp(30, 365);
    avgDaily = pastExpenses / daysSpan;
  }
  final avgMonthly = avgDaily * 30.416;

  // 3. Compromisos fijos mensuales (cuotas + servicios recurrentes)
  final activeInstallments = activeRecurring.where((t) => t.hasFixedInstallments && !t.isCompleted).toList();
  final activeIndefinite = activeRecurring.where((t) => !t.hasFixedInstallments).toList();
  final monthlyFixedCommitments = activeRecurring
      .where((t) => t.isExpense && !t.isCompleted)
      .fold<double>(0.0, (sum, t) => sum + t.monthlyEquivalent);

  // 4. Transacciones futuras puntuales ya programadas (gastos o ingresos a futuro)
  final futureTransactions = allTransactions.where((t) => t.date.isAfter(now)).toList();

  // 5. Próximos 30 días
  final next30DaysEnd = now.add(const Duration(days: 30));
  double upcoming30DaysExp = 0.0;
  double upcoming30DaysInc = 0.0;

  for (final rt in activeRecurring) {
    final occs = rt.getOccurrencesBetween(now, next30DaysEnd);
    for (final _ in occs) {
      if (rt.isExpense) {
        upcoming30DaysExp += rt.amount;
      } else {
        upcoming30DaysInc += rt.amount;
      }
    }
  }
  for (final ft in futureTransactions) {
    if (!ft.date.isAfter(next30DaysEnd)) {
      if (ft.isExpense) {
        upcoming30DaysExp += ft.amount;
      } else {
        upcoming30DaysInc += ft.amount;
      }
    }
  }

  // 6. Proyección mes a mes para los próximos 12 meses
  final monthlyProjections = <MonthlyForecastProjection>[];
  double runningBalance = currentBalance;

  for (int i = 0; i < 12; i++) {
    final monthDate = DateTime(now.year, now.month + i, 1);
    final monthStart = i == 0 ? now : DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
    final daysInMonth = monthEnd.difference(monthStart).inDays + 1;

    final items = <ProjectedItemDetail>[];
    final Map<String, double> catMap = {};

    double projIncome = 0.0;
    double projFixedExpenses = 0.0;
    double projScheduledExpenses = 0.0;

    // Recurrentes y Cuotas
    for (final rt in activeRecurring) {
      final occs = rt.getOccurrencesBetween(monthStart, monthEnd);
      for (final occ in occs) {
        final cat = categories.firstWhere(
          (c) => c.id == rt.categoryId,
          orElse: () => FinanceCategory(
            id: rt.categoryId ?? 'other',
            name: 'General',
            icon: 'help',
            color: '#607D8B',
            type: rt.type,
          ),
        );

        if (rt.isIncome) {
          projIncome += rt.amount;
        } else {
          projFixedExpenses += rt.amount;
          catMap[cat.name] = (catMap[cat.name] ?? 0.0) + rt.amount;
        }

        items.add(ProjectedItemDetail(
          title: rt.title,
          amount: rt.amount,
          dueDate: occ,
          isExpense: rt.isExpense,
          categoryId: rt.categoryId,
          categoryName: cat.name,
          categoryColor: cat.color,
          source: rt.hasFixedInstallments ? 'installment' : 'recurring',
          installmentSummary: rt.hasFixedInstallments ? rt.installmentSummary : null,
        ));
      }
    }

    // Transacciones futuras puntuales en este mes
    for (final ft in futureTransactions) {
      if (!ft.date.isBefore(monthStart) && !ft.date.isAfter(monthEnd)) {
        final cat = categories.firstWhere(
          (c) => c.id == ft.categoryId,
          orElse: () => FinanceCategory(
            id: ft.categoryId ?? 'other',
            name: 'General',
            icon: 'help',
            color: '#607D8B',
            type: ft.type,
          ),
        );

        if (ft.isIncome) {
          projIncome += ft.amount;
        } else {
          projScheduledExpenses += ft.amount;
          catMap[cat.name] = (catMap[cat.name] ?? 0.0) + ft.amount;
        }

        items.add(ProjectedItemDetail(
          title: ft.title,
          amount: ft.amount,
          dueDate: ft.date,
          isExpense: ft.isExpense,
          categoryId: ft.categoryId,
          categoryName: cat.name,
          categoryColor: cat.color,
          source: 'future_transaction',
        ));
      }
    }

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final estimatedDiscretionary = avgDaily * daysInMonth;
    final totalProjExp = projFixedExpenses + projScheduledExpenses;
    final netFlow = projIncome - totalProjExp;
    final endBal = runningBalance + netFlow;

    monthlyProjections.add(MonthlyForecastProjection(
      month: monthDate,
      startingBalance: runningBalance,
      projectedIncome: projIncome,
      projectedFixedExpenses: projFixedExpenses,
      projectedScheduledExpenses: projScheduledExpenses,
      estimatedDiscretionaryExpenses: estimatedDiscretionary,
      totalProjectedExpenses: totalProjExp,
      endingBalance: endBal,
      netCashFlow: netFlow,
      items: items,
      expensesByCategory: catMap,
    ));

    runningBalance = endBal;
  }

  return ExpenseForecastStats(
    currentBalance: currentBalance,
    totalSavingsBalance: 0.0,
    averageDailyExpenseHistorical: avgDaily,
    averageMonthlyExpenseHistorical: avgMonthly,
    monthlyFixedCommitments: monthlyFixedCommitments,
    upcoming30DaysExpenses: upcoming30DaysExp,
    upcoming30DaysIncome: upcoming30DaysInc,
    activeInstallmentsCount: activeInstallments.length,
    activeRecurringCount: activeIndefinite.length,
    monthlyProjections: monthlyProjections,
  );
});



