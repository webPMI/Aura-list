import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checklist_app/features/finance/services/recurring_transaction_service.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/features/finance/models/transaction.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/data/recurring_transaction_storage.dart';
import 'package:checklist_app/features/finance/data/transaction_storage.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/models/recurrence_rule.dart';

// Mock classes
class MockRecurringTransactionStorage extends Mock
    implements RecurringTransactionStorage {}

class MockTransactionStorage extends Mock implements TransactionStorage {}

class MockErrorHandler extends Mock implements ErrorHandler {}

void main() {
  late RecurringTransactionService service;
  late MockRecurringTransactionStorage mockRecurringStorage;
  late MockTransactionStorage mockTransactionStorage;
  late MockErrorHandler mockErrorHandler;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(ErrorType.database);
    registerFallbackValue(ErrorSeverity.error);
    registerFallbackValue(StackTrace.empty);

    // Register fallback values for RecurringTransaction
    final now = DateTime.now();
    registerFallbackValue(RecurringTransaction(
      id: 'fallback',
      title: 'Fallback',
      amount: 0,
      categoryId: 'fallback',
      type: FinanceCategoryType.expense,
      recurrence: RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: now,
      ),
      createdAt: now,
    ));

    // Register fallback values for Transaction
    registerFallbackValue(Transaction(
      id: 'fallback',
      title: 'Fallback',
      amount: 0,
      categoryId: 'fallback',
      type: FinanceCategoryType.expense,
      date: now,
      createdAt: now,
    ));
  });

  setUp(() {
    mockRecurringStorage = MockRecurringTransactionStorage();
    mockTransactionStorage = MockTransactionStorage();
    mockErrorHandler = MockErrorHandler();

    // Set up default stub for error handler
    when(
      () => mockErrorHandler.handle(
        any(),
        type: any(named: 'type'),
        severity: any(named: 'severity'),
        message: any(named: 'message'),
        userMessage: any(named: 'userMessage'),
        stackTrace: any(named: 'stackTrace'),
        shouldLog: any(named: 'shouldLog'),
        actionLabel: any(named: 'actionLabel'),
        onAction: any(named: 'onAction'),
      ),
    ).thenReturn(AppError(
      type: ErrorType.database,
      severity: ErrorSeverity.error,
      message: 'Test error',
    ));

    // Set up default stubs for storage methods to prevent null returns
    when(() => mockRecurringStorage.getAll())
        .thenAnswer((_) async => <RecurringTransaction>[]);
    when(() => mockRecurringStorage.getActive())
        .thenAnswer((_) async => <RecurringTransaction>[]);
    when(() => mockRecurringStorage.getByCategory(any()))
        .thenAnswer((_) async => <RecurringTransaction>[]);
    when(() => mockRecurringStorage.save(any()))
        .thenAnswer((_) async {});
    when(() => mockRecurringStorage.delete(any()))
        .thenAnswer((_) async {});

    when(() => mockTransactionStorage.getAll())
        .thenAnswer((_) async => <Transaction>[]);
    when(() => mockTransactionStorage.save(any()))
        .thenAnswer((_) async {});

    service = RecurringTransactionService(
      storage: mockRecurringStorage,
      transactionStorage: mockTransactionStorage,
      errorHandler: mockErrorHandler,
    );
  });

  group('RecurringTransactionService - Pattern Detection', () {
    test('should detect recurring pattern from similar transactions', () async {
      // Create similar transactions with consistent pattern
      final now = DateTime(2024, 1, 1);
      final transactions = [
        Transaction(
          id: '1',
          title: 'Netflix Subscription',
          amount: 15.99,
          date: DateTime(2024, 1, 1),
          categoryId: 'entertainment',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
        Transaction(
          id: '2',
          title: 'Netflix Subscription',
          amount: 15.99,
          date: DateTime(2024, 2, 1),
          categoryId: 'entertainment',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
        Transaction(
          id: '3',
          title: 'Netflix Subscription',
          amount: 15.99,
          date: DateTime(2024, 3, 1),
          categoryId: 'entertainment',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
      ];

      when(
        () => mockTransactionStorage.getAll(),
      ).thenAnswer((_) async => transactions);

      final patterns = await service.detectRecurringPatterns();

      expect(patterns, isNotEmpty);
      expect(patterns.length, greaterThanOrEqualTo(1));

      final pattern = patterns.first;
      expect(pattern.title, 'Netflix Subscription');
      expect(pattern.amount, closeTo(15.99, 0.01));
      expect(pattern.type, FinanceCategoryType.expense);
      expect(pattern.categoryId, 'entertainment');
    });

    test('should not detect pattern with insufficient transactions', () async {
      final now = DateTime(2024, 1, 1);
      final transactions = [
        Transaction(
          id: '1',
          title: 'Test',
          amount: 10.0,
          date: now,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
        Transaction(
          id: '2',
          title: 'Test',
          amount: 10.0,
          date: now.add(const Duration(days: 30)),
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
      ];

      when(
        () => mockTransactionStorage.getAll(),
      ).thenAnswer((_) async => transactions);

      final patterns = await service.detectRecurringPatterns();

      expect(patterns, isEmpty);
    });

    test('should group similar transactions by title and amount', () async {
      final now = DateTime(2024, 1, 1);
      final transactions = [
        // Group 1: Salary
        Transaction(
          id: '1',
          title: 'Salary',
          amount: 3000.0,
          date: DateTime(2024, 1, 1),
          categoryId: 'income',
          type: FinanceCategoryType.income,
          createdAt: now,
        ),
        Transaction(
          id: '2',
          title: 'Salary',
          amount: 3000.0,
          date: DateTime(2024, 2, 1),
          categoryId: 'income',
          type: FinanceCategoryType.income,
          createdAt: now,
        ),
        Transaction(
          id: '3',
          title: 'Salary',
          amount: 3000.0,
          date: DateTime(2024, 3, 1),
          categoryId: 'income',
          type: FinanceCategoryType.income,
          createdAt: now,
        ),
        // Group 2: Rent
        Transaction(
          id: '4',
          title: 'Rent Payment',
          amount: 1200.0,
          date: DateTime(2024, 1, 5),
          categoryId: 'housing',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
        Transaction(
          id: '5',
          title: 'Rent Payment',
          amount: 1200.0,
          date: DateTime(2024, 2, 5),
          categoryId: 'housing',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
        Transaction(
          id: '6',
          title: 'Rent Payment',
          amount: 1200.0,
          date: DateTime(2024, 3, 5),
          categoryId: 'housing',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
      ];

      when(
        () => mockTransactionStorage.getAll(),
      ).thenAnswer((_) async => transactions);

      final patterns = await service.detectRecurringPatterns();

      // Should detect 2 patterns (Salary and Rent)
      expect(patterns.length, greaterThanOrEqualTo(2));

      // Check that both patterns are detected
      final titles = patterns.map((p) => p.title).toSet();
      expect(titles, contains('Salary'));
      expect(titles, contains('Rent Payment'));
    });

    test('should detect daily frequency pattern', () async {
      final now = DateTime(2024, 1, 1);
      final transactions = List.generate(
        5,
        (i) => Transaction(
          id: '$i',
          title: 'Daily Task',
          amount: 5.0,
          date: now.add(Duration(days: i)),
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
      );

      when(
        () => mockTransactionStorage.getAll(),
      ).thenAnswer((_) async => transactions);

      final patterns = await service.detectRecurringPatterns();

      expect(patterns, isNotEmpty);
      final pattern = patterns.first;
      expect(pattern.recurrence.frequency, RecurrenceFrequency.daily);
    });

    test('should detect weekly frequency pattern', () async {
      final now = DateTime(2024, 1, 1);
      final transactions = List.generate(
        4,
        (i) => Transaction(
          id: '$i',
          title: 'Weekly Task',
          amount: 20.0,
          date: now.add(Duration(days: i * 7)),
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          createdAt: now,
        ),
      );

      when(
        () => mockTransactionStorage.getAll(),
      ).thenAnswer((_) async => transactions);

      final patterns = await service.detectRecurringPatterns();

      expect(patterns, isNotEmpty);
      final pattern = patterns.first;
      expect(pattern.recurrence.frequency, RecurrenceFrequency.weekly);
    });

    test('should handle errors gracefully', () async {
      when(
        () => mockTransactionStorage.getAll(),
      ).thenThrow(Exception('Database error'));

      when(
        () => mockErrorHandler.handle(
          any(),
          type: any(named: 'type'),
          stackTrace: any(named: 'stackTrace'),
          userMessage: any(named: 'userMessage'),
        ),
      ).thenReturn(AppError(
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Database error',
      ));

      final patterns = await service.detectRecurringPatterns();

      expect(patterns, isEmpty);
      verify(
        () => mockErrorHandler.handle(
          any(),
          type: ErrorType.database,
          stackTrace: any(named: 'stackTrace'),
          userMessage: 'Error al detectar patrones recurrentes',
        ),
      ).called(1);
    });
  });

  group('RecurringTransactionService - Transaction Generation', () {
    test(
      'should generate upcoming transactions from active recurring',
      () async {
        final now = DateTime.now();
        final recurring = RecurringTransaction(
          id: 'rec-1',
          title: 'Monthly Subscription',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          autoGenerate: true,
          active: true,
          createdAt: now,
        );

        when(
          () => mockRecurringStorage.getActive(),
        ).thenAnswer((_) async => [recurring]);

        when(() => mockTransactionStorage.save(any())).thenAnswer((_) async {});

        when(() => mockRecurringStorage.save(any())).thenAnswer((_) async {});

        final generated = await service.generateUpcomingTransactions(
          until: now.add(const Duration(days: 90)),
          maxTransactions: 3,
        );

        expect(generated, isNotEmpty);
        expect(generated.length, greaterThan(0));

        // Verify transactions were saved
        verify(() => mockTransactionStorage.save(any())).called(greaterThan(0));
        verify(() => mockRecurringStorage.save(any())).called(greaterThan(0));
      },
    );

    test('should not generate transactions for inactive recurring', () async {
      final now = DateTime.now();
      final recurring = RecurringTransaction(
        id: 'rec-inactive',
        title: 'Inactive',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: now,
        ),
        autoGenerate: true,
        active: false, // Inactive
        createdAt: now,
      );

      when(
        () => mockRecurringStorage.getActive(),
      ).thenAnswer((_) async => [recurring]);

      final generated = await service.generateUpcomingTransactions();

      expect(generated, isEmpty);
      verifyNever(() => mockTransactionStorage.save(any()));
    });

    test(
      'should not generate transactions when autoGenerate is false',
      () async {
        final now = DateTime.now();
        final recurring = RecurringTransaction(
          id: 'rec-manual',
          title: 'Manual',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: now,
          ),
          autoGenerate: false, // Manual
          active: true,
          createdAt: now,
        );

        when(
          () => mockRecurringStorage.getActive(),
        ).thenAnswer((_) async => [recurring]);

        final generated = await service.generateUpcomingTransactions();

        expect(generated, isEmpty);
        verifyNever(() => mockTransactionStorage.save(any()));
      },
    );
  });

  group('RecurringTransactionService - CRUD Operations', () {
    test('should save recurring transaction', () async {
      final recurring = RecurringTransaction(
        id: 'test',
        title: 'Test',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      when(() => mockRecurringStorage.save(any())).thenAnswer((_) async {});

      await service.save(recurring);

      verify(() => mockRecurringStorage.save(recurring)).called(1);
    });

    test('should update recurring transaction', () async {
      final recurring = RecurringTransaction(
        id: 'test',
        title: 'Test',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      when(() => mockRecurringStorage.save(any())).thenAnswer((_) async {});

      await service.update(recurring);

      verify(() => mockRecurringStorage.save(any())).called(1);
    });

    test('should pause recurring transaction', () async {
      final recurring = RecurringTransaction(
        id: 'test-pause',
        title: 'Test',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime.now(),
        ),
        active: true,
        createdAt: DateTime.now(),
      );

      when(
        () => mockRecurringStorage.getById('test-pause'),
      ).thenAnswer((_) async => recurring);

      when(() => mockRecurringStorage.save(any())).thenAnswer((_) async {});

      await service.pause('test-pause');

      verify(() => mockRecurringStorage.save(any())).called(1);
    });

    test('should resume recurring transaction', () async {
      final recurring = RecurringTransaction(
        id: 'test-resume',
        title: 'Test',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime.now(),
        ),
        active: false,
        createdAt: DateTime.now(),
      );

      when(
        () => mockRecurringStorage.getById('test-resume'),
      ).thenAnswer((_) async => recurring);

      when(() => mockRecurringStorage.save(any())).thenAnswer((_) async {});

      await service.resume('test-resume');

      verify(() => mockRecurringStorage.save(any())).called(1);
    });

    test('should get all recurring transactions', () async {
      final recurring = [
        RecurringTransaction(
          id: '1',
          title: 'Test 1',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
      ];

      when(
        () => mockRecurringStorage.getAll(),
      ).thenAnswer((_) async => recurring);

      final result = await service.getAll();

      expect(result, recurring);
      verify(() => mockRecurringStorage.getAll()).called(1);
    });

    test('should get active recurring transactions', () async {
      final recurring = [
        RecurringTransaction(
          id: '1',
          title: 'Test 1',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: DateTime.now(),
          ),
          active: true,
          createdAt: DateTime.now(),
        ),
      ];

      when(
        () => mockRecurringStorage.getActive(),
      ).thenAnswer((_) async => recurring);

      final result = await service.getActive();

      expect(result, recurring);
      verify(() => mockRecurringStorage.getActive()).called(1);
    });

    test('should get recurring transactions by category', () async {
      final recurring = [
        RecurringTransaction(
          id: '1',
          title: 'Test 1',
          amount: 10.0,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            interval: 1,
            startDate: DateTime.now(),
          ),
          createdAt: DateTime.now(),
        ),
      ];

      when(
        () => mockRecurringStorage.getByCategory('cat-1'),
      ).thenAnswer((_) async => recurring);

      final result = await service.getByCategory('cat-1');

      expect(result, recurring);
      verify(() => mockRecurringStorage.getByCategory('cat-1')).called(1);
    });
  });
}
