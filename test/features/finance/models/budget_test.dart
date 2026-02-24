import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/budget.dart';
import 'package:checklist_app/features/finance/models/finance_enums.dart';

void main() {
  group('Budget', () {
    test('should create valid budget', () {
      final budget = Budget(
        id: 'test-id',
        name: 'Monthly Groceries',
        categoryId: 'cat-food',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        alertThreshold: 0.8,
        rollover: false,
        rolloverAmount: 0.0,
        active: true,
        createdAt: DateTime.now(),
      );

      expect(budget.id, 'test-id');
      expect(budget.name, 'Monthly Groceries');
      expect(budget.limit, 500.0);
      expect(budget.period, BudgetPeriod.monthly);
      expect(budget.alertThreshold, 0.8);
      expect(budget.active, true);
      expect(budget.deleted, false);
    });

    test('should identify global budget', () {
      final globalBudget = Budget(
        id: 'global',
        name: 'Global Budget',
        categoryId: '',
        limit: 2000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final categoryBudget = Budget(
        id: 'category',
        name: 'Category Budget',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      expect(globalBudget.isGlobal, true);
      expect(categoryBudget.isGlobal, false);
    });

    test('should calculate current period start for weekly budget', () {
      final budget = Budget(
        id: 'weekly',
        name: 'Weekly',
        categoryId: 'cat-1',
        limit: 100.0,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      // Should be the Monday of the current week
      expect(periodStart.weekday, DateTime.monday);
    });

    test('should calculate current period start for monthly budget', () {
      final budget = Budget(
        id: 'monthly',
        name: 'Monthly',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      final now = DateTime.now();

      expect(periodStart.year, now.year);
      expect(periodStart.month, now.month);
      expect(periodStart.day, 1);
    });

    test('should calculate current period start for quarterly budget', () {
      final budget = Budget(
        id: 'quarterly',
        name: 'Quarterly',
        categoryId: 'cat-1',
        limit: 1500.0,
        period: BudgetPeriod.quarterly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      final now = DateTime.now();
      final expectedQuarter = ((now.month - 1) ~/ 3) * 3 + 1;

      expect(periodStart.year, now.year);
      expect(periodStart.month, expectedQuarter);
      expect(periodStart.day, 1);
    });

    test('should calculate current period start for yearly budget', () {
      final budget = Budget(
        id: 'yearly',
        name: 'Yearly',
        categoryId: 'cat-1',
        limit: 6000.0,
        period: BudgetPeriod.yearly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      final now = DateTime.now();

      expect(periodStart.year, now.year);
      expect(periodStart.month, 1);
      expect(periodStart.day, 1);
    });

    test('should calculate current period end for weekly budget', () {
      final budget = Budget(
        id: 'weekly',
        name: 'Weekly',
        categoryId: 'cat-1',
        limit: 100.0,
        period: BudgetPeriod.weekly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      final periodEnd = budget.getCurrentPeriodEnd();

      final daysDiff = periodEnd.difference(periodStart).inDays;
      expect(daysDiff, greaterThanOrEqualTo(6));
      expect(daysDiff, lessThanOrEqualTo(7));
    });

    test('should calculate current period end for monthly budget', () {
      final budget = Budget(
        id: 'monthly',
        name: 'Monthly',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      final periodStart = budget.getCurrentPeriodStart();
      final periodEnd = budget.getCurrentPeriodEnd();

      // Period end should be the last day of the month
      expect(periodEnd.year, periodStart.year);
      expect(periodEnd.month, periodStart.month);
      expect(periodEnd.day, greaterThanOrEqualTo(28));
    });

    test('should serialize to/from Firestore correctly', () {
      final original = Budget(
        id: 'test-firestore',
        name: 'Test Budget',
        categoryId: 'cat-1',
        limit: 750.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        alertThreshold: 0.75,
        rollover: true,
        rolloverAmount: 50.0,
        active: true,
        note: 'Test note',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 2),
        deleted: false,
      );

      // Convert to Firestore
      final firestoreData = original.toFirestore();

      expect(firestoreData['id'], 'test-firestore');
      expect(firestoreData['name'], 'Test Budget');
      expect(firestoreData['categoryId'], 'cat-1');
      expect(firestoreData['limit'], 750.0);
      expect(firestoreData['period'], 'monthly');
      expect(firestoreData['alertThreshold'], 0.75);
      expect(firestoreData['rollover'], true);
      expect(firestoreData['rolloverAmount'], 50.0);
      expect(firestoreData['active'], true);
      expect(firestoreData['note'], 'Test note');

      // Convert from Firestore
      final restored = Budget.fromFirestore('test-firestore', firestoreData);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.categoryId, original.categoryId);
      expect(restored.limit, original.limit);
      expect(restored.period, original.period);
      expect(restored.alertThreshold, original.alertThreshold);
      expect(restored.rollover, original.rollover);
      expect(restored.rolloverAmount, original.rolloverAmount);
      expect(restored.active, original.active);
      expect(restored.note, original.note);
    });

    test('should create copy with modified fields', () {
      final original = Budget(
        id: 'test-copy',
        name: 'Original',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        active: true,
        createdAt: DateTime.now(),
      );

      final copy = original.copyWith(
        name: 'Modified',
        limit: 750.0,
        active: false,
      );

      expect(copy.name, 'Modified');
      expect(copy.limit, 750.0);
      expect(copy.active, false);
      expect(copy.id, original.id); // Unchanged
      expect(copy.categoryId, original.categoryId);
      expect(copy.period, original.period);
    });

    test('should handle default values correctly', () {
      final budget = Budget(
        id: 'defaults',
        name: 'Defaults',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime.now(),
      );

      expect(budget.alertThreshold, 0.8);
      expect(budget.rollover, false);
      expect(budget.rolloverAmount, 0.0);
      expect(budget.active, true);
      expect(budget.deleted, false);
    });

    test('should handle null optional fields in Firestore conversion', () {
      final budget = Budget(
        id: 'test-nulls',
        name: 'Test Nulls',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      );

      final firestoreData = budget.toFirestore();
      final restored = Budget.fromFirestore('test-nulls', firestoreData);

      expect(restored.endDate, isNull);
      expect(restored.lastUpdatedAt, isNull);
      expect(restored.deletedAt, isNull);
      expect(restored.note, isNull);
    });

    test('should handle supported budget periods', () {
      // Test only supported periods (not quarterly yet)
      final supportedPeriods = [
        BudgetPeriod.daily,
        BudgetPeriod.weekly,
        BudgetPeriod.monthly,
        BudgetPeriod.yearly,
      ];

      for (final period in supportedPeriods) {
        final budget = Budget(
          id: 'test-${period.name}',
          name: 'Test ${period.name}',
          categoryId: 'cat-1',
          limit: 500.0,
          period: period,
          startDate: DateTime(2024, 1, 1),
          createdAt: DateTime.now(),
        );

        final periodStart = budget.getCurrentPeriodStart();
        final periodEnd = budget.getCurrentPeriodEnd();

        expect(periodStart, isNotNull);
        expect(periodEnd, isNotNull);
        expect(periodEnd.isAfter(periodStart), true);
      }
    });
  });
}
