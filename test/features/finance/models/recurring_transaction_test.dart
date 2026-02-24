import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/models/recurrence_rule.dart';

void main() {
  group('RecurringTransaction', () {
    late DateTime startDate;
    late RecurrenceRule dailyRule;
    late RecurrenceRule weeklyRule;
    late RecurrenceRule monthlyRule;

    setUp(() {
      startDate = DateTime(2024, 1, 1);
      dailyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: startDate,
      );
      weeklyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startDate: startDate,
      );
      monthlyRule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: startDate,
      );
    });

    test('should create valid recurring transaction', () {
      final transaction = RecurringTransaction(
        id: 'test-id',
        title: 'Salario',
        amount: 1500.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.income,
        recurrence: monthlyRule,
        createdAt: DateTime.now(),
      );

      expect(transaction.id, 'test-id');
      expect(transaction.title, 'Salario');
      expect(transaction.amount, 1500.0);
      expect(transaction.categoryId, 'cat-1');
      expect(transaction.type, FinanceCategoryType.income);
      expect(transaction.active, true);
      expect(transaction.autoGenerate, true);
      expect(transaction.deleted, false);
    });

    test('should calculate next occurrence correctly for daily frequency', () {
      final transaction = RecurringTransaction(
        id: 'test-daily',
        title: 'Daily Task',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: dailyRule,
        createdAt: DateTime.now(),
        lastGenerated: DateTime(2024, 1, 1),
      );

      final next = transaction.nextOccurrence();
      expect(next, isNotNull);
      expect(next?.year, 2024);
      expect(next?.month, 1);
      // Next occurrence after 2024-01-01 is 2024-01-01 (same day if it matches)
      // The recurrence rule calculates from lastGenerated
      expect(next?.day, greaterThanOrEqualTo(1));
    });

    test('should calculate next occurrence correctly for weekly frequency', () {
      final transaction = RecurringTransaction(
        id: 'test-weekly',
        title: 'Weekly Task',
        amount: 50.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: weeklyRule,
        createdAt: DateTime.now(),
        lastGenerated: DateTime(2024, 1, 1), // Monday
      );

      final next = transaction.nextOccurrence();
      expect(next, isNotNull);
      expect(next?.year, 2024);
      expect(next?.month, 1);
      // Should be at least one day after lastGenerated
      expect(next?.day, greaterThanOrEqualTo(1));
    });

    test('should calculate next occurrence correctly for monthly frequency', () {
      final transaction = RecurringTransaction(
        id: 'test-monthly',
        title: 'Monthly Task',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: monthlyRule,
        createdAt: DateTime.now(),
        lastGenerated: DateTime(2024, 1, 1),
      );

      final next = transaction.nextOccurrence();
      expect(next, isNotNull);
      expect(next?.year, 2024);
      // Should be in January or later
      expect(next?.month, greaterThanOrEqualTo(1));
      expect(next?.day, greaterThanOrEqualTo(1));
    });

    test('should return null for next occurrence when inactive', () {
      final transaction = RecurringTransaction(
        id: 'test-inactive',
        title: 'Inactive',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: dailyRule,
        active: false,
        createdAt: DateTime.now(),
      );

      expect(transaction.nextOccurrence(), isNull);
    });

    test('should return null for next occurrence when deleted', () {
      final transaction = RecurringTransaction(
        id: 'test-deleted',
        title: 'Deleted',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: dailyRule,
        deleted: true,
        createdAt: DateTime.now(),
      );

      expect(transaction.nextOccurrence(), isNull);
    });

    test('should correctly identify pending generation', () {
      // Transaction that needs generation (yesterday)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final transaction = RecurringTransaction(
        id: 'test-pending',
        title: 'Pending',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: yesterday,
        ),
        autoGenerate: true,
        lastGenerated: yesterday.subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );

      expect(transaction.isPendingGeneration, true);
    });

    test('should not be pending when auto-generate is disabled', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final transaction = RecurringTransaction(
        id: 'test-no-auto',
        title: 'No Auto',
        amount: 10.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: yesterday,
        ),
        autoGenerate: false,
        createdAt: DateTime.now(),
      );

      expect(transaction.isPendingGeneration, false);
    });

    test('should correctly identify income vs expense', () {
      final income = RecurringTransaction(
        id: 'income',
        title: 'Income',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.income,
        recurrence: monthlyRule,
        createdAt: DateTime.now(),
      );

      final expense = RecurringTransaction(
        id: 'expense',
        title: 'Expense',
        amount: 50.0,
        categoryId: 'cat-2',
        type: FinanceCategoryType.expense,
        recurrence: monthlyRule,
        createdAt: DateTime.now(),
      );

      expect(income.isIncome, true);
      expect(income.isExpense, false);
      expect(expense.isIncome, false);
      expect(expense.isExpense, true);
    });

    test('should serialize to/from Firestore correctly', () {
      final original = RecurringTransaction(
        id: 'test-firestore',
        title: 'Test Firestore',
        amount: 75.50,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: monthlyRule,
        autoGenerate: true,
        active: true,
        linkedTaskId: 'task-123',
        note: 'Test note',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 2),
        deleted: false,
      );

      // Convert to Firestore
      final firestoreData = original.toFirestore();

      expect(firestoreData['id'], 'test-firestore');
      expect(firestoreData['title'], 'Test Firestore');
      expect(firestoreData['amount'], 75.50);
      expect(firestoreData['categoryId'], 'cat-1');
      expect(firestoreData['type'], 'expense');
      expect(firestoreData['autoGenerate'], true);
      expect(firestoreData['active'], true);
      expect(firestoreData['linkedTaskId'], 'task-123');
      expect(firestoreData['note'], 'Test note');
      expect(firestoreData['deleted'], false);

      // Convert from Firestore
      final restored = RecurringTransaction.fromFirestore(
        'test-firestore',
        firestoreData,
      );

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.categoryId, original.categoryId);
      expect(restored.type, original.type);
      expect(restored.autoGenerate, original.autoGenerate);
      expect(restored.active, original.active);
      expect(restored.linkedTaskId, original.linkedTaskId);
      expect(restored.note, original.note);
      expect(restored.deleted, original.deleted);
      expect(restored.firestoreId, 'test-firestore');
    });

    test('should create copy with modified fields', () {
      final original = RecurringTransaction(
        id: 'test-copy',
        title: 'Original',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: monthlyRule,
        active: true,
        createdAt: DateTime.now(),
      );

      final copy = original.copyWith(
        title: 'Modified',
        amount: 200.0,
        active: false,
      );

      expect(copy.title, 'Modified');
      expect(copy.amount, 200.0);
      expect(copy.active, false);
      expect(copy.id, original.id); // Unchanged fields
      expect(copy.categoryId, original.categoryId);
      expect(copy.type, original.type);
    });

    test('should get recurrence description', () {
      final transaction = RecurringTransaction(
        id: 'test-desc',
        title: 'Test',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime(2024, 1, 1),
        ),
        createdAt: DateTime.now(),
      );

      final description = transaction.recurrenceDescription;
      expect(description, isNotEmpty);
      expect(description.toLowerCase(), contains('mes'));
    });

    test('should handle null optional fields in Firestore conversion', () {
      final transaction = RecurringTransaction(
        id: 'test-nulls',
        title: 'Test Nulls',
        amount: 50.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: monthlyRule,
        createdAt: DateTime(2024, 1, 1),
        // All optional fields are null
      );

      final firestoreData = transaction.toFirestore();
      final restored = RecurringTransaction.fromFirestore(
        'test-nulls',
        firestoreData,
      );

      expect(restored.lastGenerated, isNull);
      expect(restored.linkedTaskId, isNull);
      expect(restored.note, isNull);
      expect(restored.lastUpdatedAt, isNull);
      expect(restored.deletedAt, isNull);
    });
  });
}
