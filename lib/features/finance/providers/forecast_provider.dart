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
import 'finance_provider.dart' show transactionStorageProvider;

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
  final Ref _ref;

  StreamSubscription? _recurringSubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _alertSubscription;

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
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar previsiones',
        stackTrace: stack,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        message: 'Error al cambiar estado de transacción recurrente',
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
      return RecurringTransactionStorage(ref.watch(errorHandlerProvider));
    });

/// Provider para BudgetStorage.
final budgetStorageProvider = Provider<BudgetStorage>((ref) {
  return BudgetStorage(ref.watch(errorHandlerProvider));
});

/// Provider para CashFlowProjectionStorage.
final cashFlowProjectionStorageProvider = Provider<CashFlowProjectionStorage>((
  ref,
) {
  return CashFlowProjectionStorage(ref.watch(errorHandlerProvider));
});

/// Provider para FinanceAlertStorage.
final financeAlertStorageProvider = Provider<FinanceAlertStorage>((ref) {
  return FinanceAlertStorage(ref.watch(errorHandlerProvider));
});

/// Provider para TaskFinanceLinkStorage.
final taskFinanceLinkStorageProvider = Provider<TaskFinanceLinkStorage>((ref) {
  return TaskFinanceLinkStorage(ref.watch(errorHandlerProvider));
});

/// Provider para RecurringTransactionService.
final recurringTransactionServiceProvider =
    Provider<RecurringTransactionService>((ref) {
      return RecurringTransactionService(
        storage: ref.watch(recurringTransactionStorageProvider),
        transactionStorage: ref.watch(transactionStorageProvider),
        errorHandler: ref.watch(errorHandlerProvider),
      );
    });

/// Provider principal de previsiones financieras.
final forecastProvider = StateNotifierProvider<ForecastNotifier, ForecastState>(
  (ref) {
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
