import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/features/finance/models/budget.dart';
import 'package:checklist_app/features/finance/models/task_finance_link.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/finance_enums.dart';
import 'package:checklist_app/models/recurrence_rule.dart' as recurrence;

/// Integration tests for the finance system flow.
/// These tests verify that the models work together correctly.
void main() {
  group('Finance System Integration', () {
    test('should create complete finance workflow', () {
      final now = DateTime.now();

      // Step 1: Create a recurring transaction (monthly salary)
      final salary = RecurringTransaction(
        id: 'salary-1',
        title: 'Monthly Salary',
        amount: 3000.0,
        categoryId: 'income-salary',
        type: FinanceCategoryType.income,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime(now.year, now.month, 1),
        ),
        autoGenerate: true,
        active: true,
        createdAt: now,
      );

      expect(salary.isIncome, true);
      expect(salary.nextOccurrence(), isNotNull);

      // Step 2: Create a budget for expenses
      final monthlyBudget = Budget(
        id: 'budget-1',
        name: 'Monthly Expenses',
        categoryId: 'expense-general',
        limit: 2000.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        alertThreshold: 0.8,
        active: true,
        createdAt: now,
      );

      expect(monthlyBudget.active, true);
      expect(monthlyBudget.getCurrentPeriodStart().month, now.month);

      // Step 3: Create task finance links
      final taskLink = TaskFinanceLink(
        id: 'link-1',
        taskId: 'task-gym',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'expense-health',
        autoCreateTransaction: true,
        createdAt: now,
      );

      expect(taskLink.isLinked, false);
      expect(taskLink.autoCreateTransaction, true);

      // Step 4: Verify complete workflow
      expect(salary.amount, greaterThan(monthlyBudget.limit));
      expect(taskLink.estimatedAmount, lessThan(monthlyBudget.limit));
    });

    test('should handle budget period calculations correctly', () {
      final now = DateTime.now();

      // Weekly budget
      final weeklyBudget = Budget(
        id: 'weekly',
        name: 'Weekly Groceries',
        categoryId: 'food',
        limit: 150.0,
        period: BudgetPeriod.weekly,
        startDate: now,
        createdAt: now,
      );

      final weekStart = weeklyBudget.getCurrentPeriodStart();
      final weekEnd = weeklyBudget.getCurrentPeriodEnd();

      expect(weekEnd.isAfter(weekStart), true);
      expect(weekEnd.difference(weekStart).inDays, greaterThanOrEqualTo(6));

      // Monthly budget
      final monthlyBudget = Budget(
        id: 'monthly',
        name: 'Monthly Bills',
        categoryId: 'bills',
        limit: 800.0,
        period: BudgetPeriod.monthly,
        startDate: now,
        createdAt: now,
      );

      final monthStart = monthlyBudget.getCurrentPeriodStart();
      final monthEnd = monthlyBudget.getCurrentPeriodEnd();

      expect(monthEnd.isAfter(monthStart), true);
      expect(monthStart.day, 1);
      expect(monthEnd.day, greaterThanOrEqualTo(28));
      expect(monthEnd.month, monthStart.month);

      // Yearly budget
      final yearlyBudget = Budget(
        id: 'yearly',
        name: 'Annual Savings',
        categoryId: 'savings',
        limit: 10000.0,
        period: BudgetPeriod.yearly,
        startDate: now,
        createdAt: now,
      );

      final yearStart = yearlyBudget.getCurrentPeriodStart();
      final yearEnd = yearlyBudget.getCurrentPeriodEnd();

      expect(yearEnd.isAfter(yearStart), true);
      expect(yearStart.month, 1);
      expect(yearStart.day, 1);
    });

    test('should handle recurring transaction lifecycle', () {
      final now = DateTime.now();
      // Set start date in the future to ensure not pending
      final futureDate = now.add(const Duration(days: 30));

      // Create recurring transaction
      var recurring = RecurringTransaction(
        id: 'rec-1',
        title: 'Netflix Subscription',
        amount: 15.99,
        categoryId: 'entertainment',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.monthly,
          interval: 1,
          startDate: futureDate,
        ),
        autoGenerate: true,
        active: true,
        createdAt: now,
      );

      // Verify initial state
      expect(recurring.active, true);
      expect(recurring.isPendingGeneration, false);
      expect(recurring.nextOccurrence(), isNotNull);

      // Pause the transaction
      recurring = recurring.copyWith(active: false);
      expect(recurring.active, false);
      expect(recurring.nextOccurrence(), isNull);

      // Resume the transaction
      recurring = recurring.copyWith(active: true);
      expect(recurring.active, true);
      expect(recurring.nextOccurrence(), isNotNull);

      // Mark as generated
      final nextDate = recurring.nextOccurrence();
      recurring = recurring.copyWith(lastGenerated: nextDate);
      expect(recurring.lastGenerated, nextDate);
    });

    test('should handle task finance link lifecycle', () {
      final now = DateTime.now();

      // Create unlinked task finance link
      var taskLink = TaskFinanceLink(
        id: 'link-1',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        autoCreateTransaction: true,
        createdAt: now,
      );

      // Verify initial state
      expect(taskLink.isLinked, false);
      expect(taskLink.actualTransactionId, isNull);

      // Link to a transaction
      taskLink = taskLink.copyWith(
        actualTransactionId: 'txn-123',
        linkedAt: now,
      );

      expect(taskLink.isLinked, true);
      expect(taskLink.actualTransactionId, 'txn-123');
      expect(taskLink.linkedAt, isNotNull);
    });

    test('should handle budget with rollover', () {
      final now = DateTime.now();

      // Create budget with rollover
      var budget = Budget(
        id: 'budget-rollover',
        name: 'Budget with Rollover',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: now,
        rollover: true,
        rolloverAmount: 0.0,
        createdAt: now,
      );

      expect(budget.rollover, true);
      expect(budget.rolloverAmount, 0.0);

      // Add rollover amount
      budget = budget.copyWith(rolloverAmount: 50.0);
      expect(budget.rolloverAmount, 50.0);

      // Effective limit should be original limit + rollover
      final effectiveLimit = budget.limit + budget.rolloverAmount;
      expect(effectiveLimit, 550.0);
    });

    test('should handle multiple recurring frequencies', () {
      final now = DateTime.now();

      // Daily recurring
      final daily = RecurringTransaction(
        id: 'daily',
        title: 'Daily Task',
        amount: 5.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.daily,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      // Weekly recurring
      final weekly = RecurringTransaction(
        id: 'weekly',
        title: 'Weekly Task',
        amount: 20.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.weekly,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      // Monthly recurring
      final monthly = RecurringTransaction(
        id: 'monthly',
        title: 'Monthly Task',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.monthly,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      // Yearly recurring
      final yearly = RecurringTransaction(
        id: 'yearly',
        title: 'Yearly Task',
        amount: 1000.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.yearly,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      expect(daily.recurrence.frequency, recurrence.RecurrenceFrequency.daily);
      expect(weekly.recurrence.frequency, recurrence.RecurrenceFrequency.weekly);
      expect(monthly.recurrence.frequency, recurrence.RecurrenceFrequency.monthly);
      expect(yearly.recurrence.frequency, recurrence.RecurrenceFrequency.yearly);

      // All should be able to generate next occurrence
      expect(daily.nextOccurrence(), isNotNull);
      expect(weekly.nextOccurrence(), isNotNull);
      expect(monthly.nextOccurrence(), isNotNull);
      expect(yearly.nextOccurrence(), isNotNull);
    });

    test('should handle financial impact types', () {
      final now = DateTime.now();

      // Cost impact
      final costLink = TaskFinanceLink(
        id: 'cost',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: now,
      );

      // Saving impact
      final savingLink = TaskFinanceLink(
        id: 'saving',
        taskId: 'task-2',
        impactType: FinancialImpactType.saving,
        estimatedAmount: 30.0,
        categoryId: 'cat-1',
        createdAt: now,
      );

      // Income impact
      final incomeLink = TaskFinanceLink(
        id: 'income',
        taskId: 'task-3',
        impactType: FinancialImpactType.income,
        estimatedAmount: 100.0,
        categoryId: 'cat-1',
        createdAt: now,
      );

      expect(costLink.impactType, FinancialImpactType.cost);
      expect(savingLink.impactType, FinancialImpactType.saving);
      expect(incomeLink.impactType, FinancialImpactType.income);

      // Net impact calculation
      final netImpact = incomeLink.estimatedAmount +
          savingLink.estimatedAmount -
          costLink.estimatedAmount;
      expect(netImpact, 80.0);
    });

    test('should serialize and deserialize complete workflow', () {
      final now = DateTime.now();

      // Create objects
      final recurring = RecurringTransaction(
        id: 'rec-1',
        title: 'Test',
        amount: 100.0,
        categoryId: 'cat-1',
        type: FinanceCategoryType.expense,
        recurrence: recurrence.RecurrenceRule(
          frequency: recurrence.RecurrenceFrequency.monthly,
          interval: 1,
          startDate: now,
        ),
        createdAt: now,
      );

      final budget = Budget(
        id: 'budget-1',
        name: 'Test Budget',
        categoryId: 'cat-1',
        limit: 500.0,
        period: BudgetPeriod.monthly,
        startDate: now,
        createdAt: now,
      );

      final taskLink = TaskFinanceLink(
        id: 'link-1',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: now,
      );

      // Serialize to Firestore
      final recurringData = recurring.toFirestore();
      final budgetData = budget.toFirestore();
      final linkData = taskLink.toFirestore();

      // Deserialize from Firestore
      final restoredRecurring =
          RecurringTransaction.fromFirestore('rec-1', recurringData);
      final restoredBudget = Budget.fromFirestore('budget-1', budgetData);
      final restoredLink = TaskFinanceLink.fromFirestore('link-1', linkData);

      // Verify restoration
      expect(restoredRecurring.id, recurring.id);
      expect(restoredRecurring.title, recurring.title);
      expect(restoredRecurring.amount, recurring.amount);

      expect(restoredBudget.id, budget.id);
      expect(restoredBudget.name, budget.name);
      expect(restoredBudget.limit, budget.limit);

      expect(restoredLink.id, taskLink.id);
      expect(restoredLink.taskId, taskLink.taskId);
      expect(restoredLink.estimatedAmount, taskLink.estimatedAmount);
    });
  });
}
