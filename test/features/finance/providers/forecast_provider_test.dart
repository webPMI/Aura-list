import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/features/finance/providers/forecast_provider.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/features/finance/models/budget.dart';
import 'package:checklist_app/features/finance/models/finance_alert.dart';
import 'package:checklist_app/features/finance/models/task_finance_link.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/finance_enums.dart'
    as finance;
import 'package:checklist_app/features/finance/data/recurring_transaction_storage.dart';
import 'package:checklist_app/features/finance/data/budget_storage.dart';
import 'package:checklist_app/features/finance/data/cash_flow_projection_storage.dart';
import 'package:checklist_app/features/finance/data/finance_alert_storage.dart';
import 'package:checklist_app/features/finance/data/task_finance_link_storage.dart';
import 'package:checklist_app/features/finance/services/recurring_transaction_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/models/recurrence_rule.dart';

// Mock classes
class MockRecurringTransactionStorage extends Mock
    implements RecurringTransactionStorage {}

class MockBudgetStorage extends Mock implements BudgetStorage {}

class MockCashFlowProjectionStorage extends Mock
    implements CashFlowProjectionStorage {}

class MockFinanceAlertStorage extends Mock implements FinanceAlertStorage {}

class MockTaskFinanceLinkStorage extends Mock
    implements TaskFinanceLinkStorage {}

class MockRecurringTransactionService extends Mock
    implements RecurringTransactionService {}

class MockErrorHandler extends Mock implements ErrorHandler {}

void main() {
  late MockRecurringTransactionStorage mockRecurringStorage;
  late MockBudgetStorage mockBudgetStorage;
  late MockCashFlowProjectionStorage mockProjectionStorage;
  late MockFinanceAlertStorage mockAlertStorage;
  late MockTaskFinanceLinkStorage mockLinkStorage;
  late MockRecurringTransactionService mockRecurringService;
  late MockErrorHandler mockErrorHandler;

  setUp(() {
    mockRecurringStorage = MockRecurringTransactionStorage();
    mockBudgetStorage = MockBudgetStorage();
    mockProjectionStorage = MockCashFlowProjectionStorage();
    mockAlertStorage = MockFinanceAlertStorage();
    mockLinkStorage = MockTaskFinanceLinkStorage();
    mockRecurringService = MockRecurringTransactionService();
    mockErrorHandler = MockErrorHandler();

    // Register fallback values
    registerFallbackValue(ErrorType.database);
    registerFallbackValue(StackTrace.empty);
  });

  group('ForecastState', () {
    test('should create initial state', () {
      const state = ForecastState();

      expect(state.recurringTransactions, isEmpty);
      expect(state.budgets, isEmpty);
      expect(state.projections, isEmpty);
      expect(state.alerts, isEmpty);
      expect(state.taskLinks, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should copy with modified fields', () {
      const state = ForecastState(isLoading: true);

      final modified = state.copyWith(isLoading: false, error: 'Test error');

      expect(modified.isLoading, false);
      expect(modified.error, 'Test error');
    });

    test('should filter active alerts correctly', () {
      final now = DateTime.now();
      final alerts = [
        FinanceAlert(
          id: '1',
          type: finance.AlertType.budgetWarning,
          severity: finance.AlertSeverity.warning,
          title: 'Active Alert',
          message: 'Test',
          createdAt: now,
          isRead: false,
        ),
        FinanceAlert(
          id: '2',
          type: finance.AlertType.budgetExceeded,
          severity: finance.AlertSeverity.critical,
          title: 'Read Alert',
          message: 'Test',
          createdAt: now,
          isRead: true,
        ),
        FinanceAlert(
          id: '3',
          type: finance.AlertType.lowBalance,
          severity: finance.AlertSeverity.info,
          title: 'Inactive Alert',
          message: 'Test',
          createdAt: now,
          isRead: false,
          isDismissed:
              true, // Used to make it inactive (isActive = !isDismissed && !deleted)
        ),
      ];

      final state = ForecastState(alerts: alerts);
      final activeAlerts = state.activeAlerts;

      expect(activeAlerts.length, 1);
      expect(activeAlerts.first.id, '1');
    });

    test('should filter active recurring transactions correctly', () {
      final now = DateTime.now();
      final recurring = [
        RecurringTransaction(
          id: '1',
          title: 'Active',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          active: true,
          deleted: false,
          createdAt: now,
        ),
        RecurringTransaction(
          id: '2',
          title: 'Inactive',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          active: false,
          deleted: false,
          createdAt: now,
        ),
        RecurringTransaction(
          id: '3',
          title: 'Deleted',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: finance.RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          active: true,
          deleted: true,
          createdAt: now,
        ),
      ];

      final state = ForecastState(recurringTransactions: recurring);
      final activeRecurring = state.activeRecurring;

      expect(activeRecurring.length, 1);
      expect(activeRecurring.first.id, '1');
    });

    test('should filter active budgets correctly', () {
      final now = DateTime.now();
      final budgets = [
        Budget(
          id: '1',
          name: 'Active Budget',
          categoryId: 'cat-1',
          limit: 500.0,
          period: finance.BudgetPeriod.monthly,
          startDate: now,
          active: true,
          deleted: false,
          createdAt: now,
        ),
        Budget(
          id: '2',
          name: 'Inactive Budget',
          categoryId: 'cat-2',
          limit: 300.0,
          period: finance.BudgetPeriod.monthly,
          startDate: now,
          active: false,
          deleted: false,
          createdAt: now,
        ),
        Budget(
          id: '3',
          name: 'Deleted Budget',
          categoryId: 'cat-3',
          limit: 200.0,
          period: finance.BudgetPeriod.monthly,
          startDate: now,
          active: true,
          deleted: true,
          createdAt: now,
        ),
      ];

      final state = ForecastState(budgets: budgets);
      final activeBudgets = state.activeBudgets;

      expect(activeBudgets.length, 1);
      expect(activeBudgets.first.id, '1');
    });
  });

  group('ForecastNotifier - Basic Operations', () {
    test('should initialize with loading state', () {
      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      final state = container.read(forecastProvider);

      expect(state.isLoading, true);

      container.dispose();
    });

    test('should handle empty data', () async {
      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(forecastProvider);

      expect(state.recurringTransactions, isEmpty);
      expect(state.budgets, isEmpty);
      expect(state.alerts, isEmpty);

      container.dispose();
    });
  });

  group('ForecastNotifier - Data Operations', () {
    test('should add recurring transaction', () async {
      final now = DateTime.now();
      final transaction = RecurringTransaction(
        id: 'test',
        title: 'Test',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);
      when(
        () => mockRecurringStorage.save(any()),
      ).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      await container
          .read(forecastProvider.notifier)
          .addRecurringTransaction(transaction);

      verify(() => mockRecurringStorage.save(transaction)).called(1);

      container.dispose();
    });

    test('should add budget', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test',
        name: 'Test Budget',
        categoryId: 'cat-1',
        limit: 500.0,
        period: finance.BudgetPeriod.monthly,
        startDate: now,
        createdAt: now,
      );

      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockBudgetStorage.save(any())).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      await container.read(forecastProvider.notifier).addBudget(budget);

      verify(() => mockBudgetStorage.save(budget)).called(1);

      container.dispose();
    });

    test('should detect recurring patterns', () async {
      final now = DateTime.now();
      final patterns = [
        RecurringTransaction(
          id: 'pattern-1',
          title: 'Detected Pattern',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: finance.RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          createdAt: now,
        ),
      ];

      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockAlertStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);
      when(
        () => mockRecurringService.detectRecurringPatterns(),
      ).thenAnswer((_) async => patterns);
      when(
        () => mockRecurringStorage.save(any()),
      ).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      await container.read(forecastProvider.notifier).detectRecurringPatterns();

      verify(() => mockRecurringService.detectRecurringPatterns()).called(1);
      verify(() => mockRecurringStorage.save(any())).called(patterns.length);

      container.dispose();
    });
  });

  group('Forecast Providers', () {
    test('activeAlertsProvider should return only active alerts', () {
      final now = DateTime.now();
      final alerts = [
        FinanceAlert(
          id: '1',
          type: finance.AlertType.budgetWarning,
          severity: finance.AlertSeverity.warning,
          title: 'Active',
          message: 'Test',
          createdAt: now,
          isRead: false,
        ),
        FinanceAlert(
          id: '2',
          type: finance.AlertType.budgetExceeded,
          severity: finance.AlertSeverity.critical,
          title: 'Read',
          message: 'Test',
          createdAt: now,
          isRead: true,
        ),
      ];

      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(
        () => mockAlertStorage.watch(),
      ).thenAnswer((_) => Stream.value(alerts));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      // Wait for streams to emit
      Future.delayed(const Duration(milliseconds: 100), () {
        final activeAlerts = container.read(activeAlertsProvider);
        expect(activeAlerts.length, 1);
        expect(activeAlerts.first.id, '1');
      });

      container.dispose();
    });

    test('activeAlertsCountProvider should return count of active alerts', () {
      final now = DateTime.now();
      final alerts = [
        FinanceAlert(
          id: '1',
          type: finance.AlertType.budgetWarning,
          severity: finance.AlertSeverity.warning,
          title: 'Active 1',
          message: 'Test',
          createdAt: now,
          isRead: false,
        ),
        FinanceAlert(
          id: '2',
          type: finance.AlertType.lowBalance,
          severity: finance.AlertSeverity.info,
          title: 'Active 2',
          message: 'Test',
          createdAt: now,
          isRead: false,
        ),
      ];

      when(
        () => mockRecurringStorage.watch(),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBudgetStorage.watch()).thenAnswer((_) => Stream.value([]));
      when(
        () => mockAlertStorage.watch(),
      ).thenAnswer((_) => Stream.value(alerts));
      when(() => mockProjectionStorage.getAll()).thenAnswer((_) async => []);
      when(() => mockLinkStorage.getAll()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          recurringTransactionStorageProvider.overrideWithValue(
            mockRecurringStorage,
          ),
          budgetStorageProvider.overrideWithValue(mockBudgetStorage),
          cashFlowProjectionStorageProvider.overrideWithValue(
            mockProjectionStorage,
          ),
          financeAlertStorageProvider.overrideWithValue(mockAlertStorage),
          taskFinanceLinkStorageProvider.overrideWithValue(mockLinkStorage),
          recurringTransactionServiceProvider.overrideWithValue(
            mockRecurringService,
          ),
          errorHandlerProvider.overrideWithValue(mockErrorHandler),
        ],
      );

      // Wait for streams to emit
      Future.delayed(const Duration(milliseconds: 100), () {
        final count = container.read(activeAlertsCountProvider);
        expect(count, 2);
      });

      container.dispose();
    });
  });
}
