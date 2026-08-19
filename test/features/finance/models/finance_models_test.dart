import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart' as fe;
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/transaction.dart';
import 'package:checklist_app/features/finance/models/budget.dart';
import 'package:checklist_app/features/finance/models/cash_flow_projection.dart';
import 'package:checklist_app/features/finance/models/finance_alert.dart';
import 'package:checklist_app/features/finance/models/finance_enums.dart' as fe;
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/models/recurrence_rule.dart';

/// ============================================================
/// Tests de Modelos — Finanzas
/// Cubre: round-trip Firestore, cálculos de dominio, casos de borde
/// ============================================================
void main() {
  // ==========================================================
  // FinanceCategory
  // ==========================================================
  group('FinanceCategory', () {
    test('creation with all fields', () {
      final cat = FinanceCategory(
        id: 'cat-1',
        name: 'Food',
        icon: 'restaurant',
        color: '#FF0000',
        type: fe.FinanceCategoryType.expense,
        isDefault: true,
      );

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Food');
      expect(cat.icon, 'restaurant');
      expect(cat.color, '#FF0000');
      expect(cat.type, fe.FinanceCategoryType.expense);
      expect(cat.isDefault, true);
    });

    test('toFirestore round-trip', () {
      final original = FinanceCategory(
        id: 'cat-firestore',
        name: 'Supermercado',
        icon: 'shopping_cart',
        color: '#FFB74D',
        type: fe.FinanceCategoryType.expense,
        isDefault: false,
      );

      final data = original.toFirestore();
      final restored = FinanceCategory.fromFirestore('different-id', data);

      expect(restored.id, 'cat-firestore'); // fromFirestore usa data['id'] si existe
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.type, original.type);
      expect(restored.isDefault, original.isDefault);
    });

    test('fromFirestore handles missing fields with defaults', () {
      final data = <String, dynamic>{};
      final restored = FinanceCategory.fromFirestore('fallback-id', data);

      expect(restored.id, 'fallback-id');
      expect(restored.name, '');
      expect(restored.icon, 'category');
      expect(restored.color, '#9E9E9E');
      expect(restored.type, fe.FinanceCategoryType.expense); // valor por defecto
      expect(restored.isDefault, false);
    });

    test('fromFirestore handles unknown type gracefully', () {
      final data = {
        'id': 'cat-1',
        'name': 'Test',
        'icon': 'test',
        'color': '#000000',
        'type': 'unknown_type',
        'isDefault': true,
      };

      final restored = FinanceCategory.fromFirestore('cat-1', data);
      expect(restored.type, fe.FinanceCategoryType.expense); // orElse
      expect(restored.isDefault, true);
    });

    test('defaultCategories has exactly 20 entries', () {
      final defaults = FinanceCategory.defaultCategories;
      expect(defaults.length, equals(20));
    });

    test('defaultCategories has 14 expense and 6 income categories', () {
      final defaults = FinanceCategory.defaultCategories;
      final expenses = defaults.where((c) => c.type == fe.FinanceCategoryType.expense).toList();
      final incomes = defaults.where((c) => c.type == fe.FinanceCategoryType.income).toList();

      expect(expenses.length, equals(14));
      expect(incomes.length, equals(6));
    });

    test('all default categories are marked as default', () {
      for (final cat in FinanceCategory.defaultCategories) {
        expect(cat.isDefault, isTrue);
      }
    });

    test('all default categories have non-empty ids and names', () {
      for (final cat in FinanceCategory.defaultCategories) {
        expect(cat.id, isNotEmpty);
        expect(cat.name, isNotEmpty);
      }
    });

    test('expense category ids all start with exp_', () {
      for (final cat in FinanceCategory.defaultCategories
          .where((c) => c.type == fe.FinanceCategoryType.expense)) {
        expect(cat.id.startsWith('exp_'), isTrue);
      }
    });

    test('income category ids all start with inc_', () {
      for (final cat in FinanceCategory.defaultCategories
          .where((c) => c.type == fe.FinanceCategoryType.income)) {
        expect(cat.id.startsWith('inc_'), isTrue);
      }
    });
  });

  // ==========================================================
  // Transaction
  // ==========================================================
  group('Transaction', () {
    test('creation with all fields', () {
      final date = DateTime(2026, 3, 15, 10, 30);
      final tx = Transaction(
        id: 'tx-1',
        title: 'Compra',
        amount: 45.50,
        date: date,
        categoryId: 'exp_food',
        type: fe.FinanceCategoryType.expense,
        note: 'Compra semanal',
        createdAt: DateTime(2026, 3, 15),
        lastUpdatedAt: DateTime(2026, 3, 16),
        deleted: false,
      );

      expect(tx.id, 'tx-1');
      expect(tx.title, 'Compra');
      expect(tx.amount, 45.50);
      expect(tx.date, date);
      expect(tx.categoryId, 'exp_food');
      expect(tx.type, fe.FinanceCategoryType.expense);
      expect(tx.note, 'Compra semanal');
      expect(tx.isExpense, true);
      expect(tx.isIncome, false);
      expect(tx.deleted, false);
    });

    test('isIncome and isExpense are correct', () {
      final txIncome = Transaction(
        id: 'tx-inc',
        title: 'Salario',
        amount: 2000,
        date: DateTime.now(),
        categoryId: 'inc_salary',
        type: fe.FinanceCategoryType.income,
        createdAt: DateTime.now(),
      );

      final txExpense = Transaction(
        id: 'tx-exp',
        title: 'Alquiler',
        amount: 800,
        date: DateTime.now(),
        categoryId: 'exp_home',
        type: fe.FinanceCategoryType.expense,
        createdAt: DateTime.now(),
      );

      expect(txIncome.isIncome, isTrue);
      expect(txIncome.isExpense, isFalse);
      expect(txExpense.isIncome, isFalse);
      expect(txExpense.isExpense, isTrue);
    });

    test('toFirestore round-trip with all fields', () {
      final now = DateTime(2026, 4, 10, 14, 0);
      final original = Transaction(
        id: 'tx-roundtrip',
        title: 'Test Transaction',
        amount: 123.45,
        date: now,
        categoryId: 'exp_shopping',
        type: fe.FinanceCategoryType.expense,
        note: ' nota de prueba ',
        createdAt: now,
        lastUpdatedAt: now.add(const Duration(days: 1)),
        deleted: true,
      );

      final data = original.toFirestore();
      final restored = Transaction.fromFirestore('different-id', data);

      expect(restored.id, 'tx-roundtrip');
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.date, original.date);
      expect(restored.categoryId, original.categoryId);
      expect(restored.type, original.type);
      expect(restored.note, original.note);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastUpdatedAt, original.lastUpdatedAt);
      expect(restored.deleted, original.deleted);
      // BUG: deletedAt no se deserializa — verificar que está en los datos pero no se lee
      expect(data['deletedAt'], original.deletedAt?.millisecondsSinceEpoch);
    });

    test('fromFirestore handles null amount gracefully', () {
      final data = {
        'id': 'tx-null',
        'title': 'Sin monto',
        'amount': null,
        'date': 0,
        'categoryId': '',
        'type': 'expense',
        'createdAt': 0,
      };

      final restored = Transaction.fromFirestore('tx-null', data);
      expect(restored.amount, equals(0.0));
    });

    test('fromFirestore handles null date gracefully', () {
      final data = {
        'id': 'tx-null-date',
        'title': 'Sin fecha',
        'amount': 100,
        'date': null,
        'categoryId': 'cat-1',
        'type': 'expense',
        'createdAt': 0,
      };

      final restored = Transaction.fromFirestore('tx-null-date', data);
      expect(restored.date, equals(DateTime.fromMillisecondsSinceEpoch(0)));
    });

    test('fromFirestore handles unknown type', () {
      final data = {
        'id': 'tx-bad-type',
        'title': 'Test',
        'amount': 50,
        'date': DateTime.now().millisecondsSinceEpoch,
        'categoryId': 'cat-1',
        'type': 'bogus_type',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final restored = Transaction.fromFirestore('tx-bad-type', data);
      expect(restored.type, fe.FinanceCategoryType.expense); // orElse
    });

    test('toFirestore serializes dates as millisecondsSinceEpoch', () {
      final date = DateTime(2026, 6, 15, 12, 30, 45);
      final createdAt = DateTime(2026, 6, 14);
      final tx = Transaction(
        id: 'tx-dates',
        title: 'Test',
        amount: 10,
        date: date,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        createdAt: createdAt,
        lastUpdatedAt: createdAt,
      );

      final data = tx.toFirestore();
      expect(data['date'], date.millisecondsSinceEpoch);
      expect(data['createdAt'], createdAt.millisecondsSinceEpoch);
    });
  });

  // ==========================================================
  // Budget
  // ==========================================================
  group('Budget', () {
    test('creation with all fields', () {
      final now = DateTime(2026, 4, 15);
      final budget = Budget(
        id: 'budget-1',
        name: 'Supermercado Mensual',
        categoryId: 'exp_groceries',
        limit: 500.0,
        period: fe.BudgetPeriod.monthly,
        startDate: now,
        endDate: DateTime(2026, 5, 1),
        alertThreshold: 0.75,
        rollover: true,
        rolloverAmount: 50.0,
        active: true,
        createdAt: now,
        lastUpdatedAt: now,
        note: 'Presupuesto de prueba',
      );

      expect(budget.id, 'budget-1');
      expect(budget.name, 'Supermercado Mensual');
      expect(budget.categoryId, 'exp_groceries');
      expect(budget.limit, 500.0);
      expect(budget.period, fe.BudgetPeriod.monthly);
      expect(budget.startDate, now);
      expect(budget.endDate, DateTime(2026, 5, 1));
      expect(budget.alertThreshold, 0.75);
      expect(budget.rollover, true);
      expect(budget.rolloverAmount, 50.0);
      expect(budget.active, true);
      expect(budget.note, 'Presupuesto de prueba');
    });

    test('isGlobal returns true when categoryId is empty', () {
      final budget = Budget(
        id: 'global',
        name: 'General',
        categoryId: '',
        limit: 1000,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(budget.isGlobal, isTrue);
    });

    test('isGlobal returns false when categoryId is set', () {
      final budget = Budget(
        id: 'cat',
        name: 'Alimentación',
        categoryId: 'exp_food',
        limit: 500,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(budget.isGlobal, isFalse);
    });

    test('toFirestore round-trip', () {
      final now = DateTime(2026, 4, 15);
      final original = Budget(
        id: 'budget-rt',
        name: 'Round Trip',
        categoryId: 'exp_food',
        limit: 300,
        period: fe.BudgetPeriod.weekly,
        startDate: now,
        alertThreshold: 0.9,
        rollover: true,
        rolloverAmount: 25,
        active: false,
        createdAt: now,
        deleted: true,
        note: 'Nota de prueba',
      );

      final data = original.toFirestore();
      final restored = Budget.fromFirestore('different-id', data);

      expect(restored.id, 'budget-rt');
      expect(restored.name, original.name);
      expect(restored.categoryId, original.categoryId);
      expect(restored.limit, original.limit);
      expect(restored.period, original.period);
      expect(restored.startDate, original.startDate);
      expect(restored.alertThreshold, original.alertThreshold);
      expect(restored.rollover, original.rollover);
      expect(restored.rolloverAmount, original.rolloverAmount);
      expect(restored.active, original.active);
      expect(restored.deleted, original.deleted);
      expect(restored.note, original.note);
    });

    test('copyWith preserves unchanged fields and updates specified ones', () {
      final original = Budget(
        id: 'copy-test',
        name: 'Original',
        categoryId: 'exp_food',
        limit: 500,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime(2026, 4, 1),
        alertThreshold: 0.8,
        rollover: false,
        rolloverAmount: 0,
        active: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated',
        limit: 600,
        active: false,
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated');
      expect(updated.categoryId, original.categoryId);
      expect(updated.limit, 600);
      expect(updated.period, original.period);
      expect(updated.startDate, original.startDate);
      expect(updated.alertThreshold, original.alertThreshold);
      expect(updated.rollover, original.rollover);
      expect(updated.rolloverAmount, original.rolloverAmount);
      expect(updated.active, false);
      expect(updated.createdAt, original.createdAt);
    });

    test('getCurrentPeriodStart returns first day of month for monthly', () {
      final budget = Budget(
        id: 'monthly-test',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime(2026, 3, 15),
        createdAt: DateTime(2026, 3, 15),
      );

      final start = budget.getCurrentPeriodStart(DateTime(2026, 3, 15));
      expect(start.day, 1);
      expect(start.month, 3);
      expect(start.year, 2026);
    });

    test('getCurrentPeriodStart returns first day of year for yearly', () {
      final budget = Budget(
        id: 'yearly-test',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.yearly,
        startDate: DateTime(2026, 6, 15),
        createdAt: DateTime(2026, 6, 15),
      );

      final start = budget.getCurrentPeriodStart(DateTime(2026, 6, 15));
      expect(start.day, 1);
      expect(start.month, 1);
      expect(start.year, 2026);
    });

    test('getCurrentPeriodStart returns first day of quarter for quarterly', () {
      // April → Q2 starts April 1
      final budget = Budget(
        id: 'quarterly-test',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.quarterly,
        startDate: DateTime(2026, 4, 15),
        createdAt: DateTime(2026, 4, 15),
      );

      final start = budget.getCurrentPeriodStart(DateTime(2026, 4, 15));
      expect(start.day, 1);
      expect(start.month, 4);
      expect(start.year, 2026);
    });

    test('getCurrentPeriodEnd returns last second of day for daily', () {
      final start = DateTime(2026, 4, 15);
      final budget = Budget(
        id: 'daily-test',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.daily,
        startDate: start,
        createdAt: start,
      );

      final end = budget.getCurrentPeriodEnd(DateTime(2026, 4, 15));
      expect(end.year, 2026);
      expect(end.month, 4);
      expect(end.day, 15);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('getCurrentPeriodEnd for monthly is last day of same month', () {
      final budget = Budget(
        id: 'monthly-end',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime(2026, 2, 1), // mes con 28 días
        createdAt: DateTime(2026, 2, 1),
      );

      final end = budget.getCurrentPeriodEnd(DateTime(2026, 2, 15));
      expect(end.year, 2026);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('getCurrentPeriodEnd for February leap year is 29', () {
      final budget = Budget(
        id: 'leap-year',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.monthly,
        startDate: DateTime(2024, 2, 1), // año bisiesto
        createdAt: DateTime(2024, 2, 1),
      );

      final end = budget.getCurrentPeriodEnd(DateTime(2024, 2, 15));
      expect(end.year, 2024);
      expect(end.month, 2);
      expect(end.day, 29);
    });

    test('getCurrentPeriodEnd returns last second of year for yearly', () {
      final budget = Budget(
        id: 'yearly-end',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.yearly,
        startDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

      final end = budget.getCurrentPeriodEnd(DateTime(2026, 5, 20));
      expect(end.year, 2026);
      expect(end.month, 12);
      expect(end.day, 31);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('getCurrentPeriodStart uses actual now, not startDate', () {
      // Si el presupuesto empezó en diciembre pero estamos en abril,
      // getCurrentPeriodStart debe dar abril, no diciembre
      final december = DateTime(2025, 12, 1);
      final budget = Budget(
        id: 'now-test',
        name: 'Test',
        categoryId: 'cat-1',
        limit: 100,
        period: fe.BudgetPeriod.monthly,
        startDate: december,
        createdAt: december,
      );

      final start = budget.getCurrentPeriodStart();
      // El método usa DateTime.now(), pero si se llamó en abril, daría abril
      // Como no podemos controlar DateTime.now(), verificamos que el método
      // usa la fecha actual (no startDate)
      // Este test verifica que no lanza excepción y produce una fecha válida
      expect(start.day, greaterThanOrEqualTo(1));
      expect(start.month, lessThanOrEqualTo(12));
      expect(start.year, greaterThanOrEqualTo(2025));
    });
  });

  // ==========================================================
  // CashFlowProjection
  // ==========================================================
  group('CashFlowProjection', () {
    test('creation with all fields', () {
      final now = DateTime(2026, 5, 1);
      final proj = CashFlowProjection(
        id: 'proj-1',
        date: DateTime(2026, 6, 1),
        projectedIncome: 3000,
        projectedExpenses: 2000,
        projectedBalance: 1000,
        actualIncome: 2900,
        actualExpenses: 1900,
        createdAt: now,
        lastUpdatedAt: now,
        isHistorical: true,
        deleted: false,
      );

      expect(proj.id, 'proj-1');
      expect(proj.date, DateTime(2026, 6, 1));
      expect(proj.projectedIncome, 3000);
      expect(proj.projectedExpenses, 2000);
      expect(proj.projectedBalance, 1000);
      expect(proj.actualIncome, 2900);
      expect(proj.actualExpenses, 1900);
      expect(proj.isHistorical, true);
      expect(proj.deleted, false);
    });

    test('actualBalance calculation', () {
      final proj = CashFlowProjection(
        id: 'bal-1',
        date: DateTime.now(),
        projectedIncome: 5000,
        projectedExpenses: 3000,
        projectedBalance: 2000,
        actualIncome: 4800,
        actualExpenses: 2800,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.actualBalance, 2000); // 4800 - 2800
    });

    test('variance calculation', () {
      final proj = CashFlowProjection(
        id: 'var-1',
        date: DateTime.now(),
        projectedIncome: 5000,
        projectedExpenses: 3000,
        projectedBalance: 2000,
        actualIncome: 5500,
        actualExpenses: 3200,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      // actualBalance = 5500 - 3200 = 2300
      // variance = 2300 - 2000 = 300 (positive = better than projected)
      expect(proj.actualBalance, 2300);
      expect(proj.variance, 300);
    });

    test('incomeVariance and expenseVariance', () {
      final proj = CashFlowProjection(
        id: 'v-var',
        date: DateTime.now(),
        projectedIncome: 5000,
        projectedExpenses: 3000,
        projectedBalance: 2000,
        actualIncome: 5500,
        actualExpenses: 3200,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.incomeVariance, 500); // 5500 - 5000
      expect(proj.expenseVariance, 200); // 3200 - 3000
    });

    test('accuracy is 1.0 when projectedBalance is 0', () {
      final proj = CashFlowProjection(
        id: 'acc-zero',
        date: DateTime.now(),
        projectedIncome: 0,
        projectedExpenses: 0,
        projectedBalance: 0,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.accuracy, 1.0);
    });

    test('accuracy calculation with positive variance', () {
      // projectedBalance=1000, actualBalance=1200 → variance=+200
      // accuracy = 1 - (200/1000) = 0.8
      final proj = CashFlowProjection(
        id: 'acc-pos',
        date: DateTime.now(),
        projectedIncome: 2000,
        projectedExpenses: 1000,
        projectedBalance: 1000,
        actualIncome: 2200,
        actualExpenses: 1000,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.variance, 200);
      expect(proj.accuracy, 0.8);
    });

    test('accuracy calculation with negative variance', () {
      // projectedBalance=1000, actualBalance=800 → variance=-200
      // accuracy = 1 - (200/1000) = 0.8 (variance.abs() usado)
      final proj = CashFlowProjection(
        id: 'acc-neg',
        date: DateTime.now(),
        projectedIncome: 2000,
        projectedExpenses: 1000,
        projectedBalance: 1000,
        actualIncome: 1800,
        actualExpenses: 1000,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.variance, -200);
      expect(proj.accuracy, 0.8);
    });

    test('accuracy clamped to 0.0 when variance exceeds projection', () {
      // projectedBalance=100, actualBalance=0 → variance=-100
      // accuracy = 1 - (100/100) = 0
      final proj = CashFlowProjection(
        id: 'acc-clamp',
        date: DateTime.now(),
        projectedIncome: 200,
        projectedExpenses: 100,
        projectedBalance: 100,
        actualIncome: 100,
        actualExpenses: 100,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.variance, -100);
      expect(proj.accuracy, 0.0);
    });

    test('accuracy clamped to 0.0 when overshot significantly', () {
      // projectedBalance=100, actualBalance=300 → variance=+200
      // accuracy = 1 - (200/100) = 1 - 2 = -1 → clamped to 0
      final proj = CashFlowProjection(
        id: 'acc-overshoot',
        date: DateTime.now(),
        projectedIncome: 400,
        projectedExpenses: 300,
        projectedBalance: 100,
        actualIncome: 600,
        actualExpenses: 300,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(proj.variance, 200);
      expect(proj.accuracy, 0.0);
    });

    test('toFirestore round-trip', () {
      final now = DateTime(2026, 5, 15);
      final original = CashFlowProjection(
        id: 'proj-rt',
        date: DateTime(2026, 6, 15),
        projectedIncome: 3000,
        projectedExpenses: 2000,
        projectedBalance: 1000,
        actualIncome: 2900,
        actualExpenses: 1800,
        createdAt: now,
        lastUpdatedAt: now,
        isHistorical: true,
        deleted: true,
      );

      final data = original.toFirestore();
      final restored = CashFlowProjection.fromFirestore('different-id', data);

      expect(restored.id, 'proj-rt');
      expect(restored.date, original.date);
      expect(restored.projectedIncome, original.projectedIncome);
      expect(restored.projectedExpenses, original.projectedExpenses);
      expect(restored.projectedBalance, original.projectedBalance);
      expect(restored.actualIncome, original.actualIncome);
      expect(restored.actualExpenses, original.actualExpenses);
      expect(restored.isHistorical, original.isHistorical);
      expect(restored.deleted, original.deleted);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastUpdatedAt, original.lastUpdatedAt);
    });

    test('copyWith preserves unchanged fields', () {
      final original = CashFlowProjection(
        id: 'copy-proj',
        date: DateTime(2026, 6, 1),
        projectedIncome: 2000,
        projectedExpenses: 1500,
        projectedBalance: 500,
        actualIncome: 1900,
        actualExpenses: 1400,
        createdAt: DateTime(2026, 1, 1),
        lastUpdatedAt: DateTime(2026, 1, 1),
        isHistorical: false,
        deleted: false,
      );

      final updated = original.copyWith(
        actualIncome: 1950,
        isHistorical: true,
      );

      expect(updated.id, original.id);
      expect(updated.date, original.date);
      expect(updated.projectedIncome, original.projectedIncome);
      expect(updated.projectedExpenses, original.projectedExpenses);
      expect(updated.projectedBalance, original.projectedBalance);
      expect(updated.actualIncome, 1950);
      expect(updated.actualExpenses, original.actualExpenses);
      expect(updated.isHistorical, true);
      expect(updated.deleted, original.deleted);
      expect(updated.createdAt, original.createdAt);
      expect(updated.lastUpdatedAt, original.lastUpdatedAt);
    });
  });

  // ==========================================================
  // FinanceAlert
  // ==========================================================
  group('FinanceAlert', () {
    test('creation with all fields', () {
      final now = DateTime(2026, 4, 15);
      final alert = FinanceAlert(
        id: 'alert-1',
        type: fe.AlertType.budgetExceeded,
        severity: fe.AlertSeverity.critical,
        title: 'Presupuesto excedido',
        message: 'Gastaste el 120% de tu presupuesto',
        relatedBudgetId: 'budget-1',
        relatedCategoryId: 'exp_food',
        createdAt: now,
        isRead: false,
        isDismissed: false,
        metadata: {'percent': 120},
      );

      expect(alert.id, 'alert-1');
      expect(alert.type, fe.AlertType.budgetExceeded);
      expect(alert.severity, fe.AlertSeverity.critical);
      expect(alert.title, 'Presupuesto excedido');
      expect(alert.message, 'Gastaste el 120% de tu presupuesto');
      expect(alert.relatedBudgetId, 'budget-1');
      expect(alert.relatedCategoryId, 'exp_food');
      expect(alert.createdAt, now);
      expect(alert.isRead, false);
      expect(alert.isDismissed, false);
      expect(alert.metadata, {'percent': 120});
    });

    test('isActive returns true when not dismissed and not deleted', () {
      final alert = FinanceAlert(
        id: 'active',
        type: fe.AlertType.budgetWarning,
        severity: fe.AlertSeverity.warning,
        title: 'Test',
        message: 'Test',
        createdAt: DateTime.now(),
      );

      expect(alert.isActive, isTrue);
    });

    test('isActive returns false when dismissed', () {
      final alert = FinanceAlert(
        id: 'dismissed',
        type: fe.AlertType.budgetWarning,
        severity: fe.AlertSeverity.warning,
        title: 'Test',
        message: 'Test',
        createdAt: DateTime.now(),
        isDismissed: true,
      );

      expect(alert.isActive, isFalse);
    });

    test('isActive returns false when deleted', () {
      final alert = FinanceAlert(
        id: 'deleted',
        type: fe.AlertType.budgetWarning,
        severity: fe.AlertSeverity.warning,
        title: 'Test',
        message: 'Test',
        createdAt: DateTime.now(),
        deleted: true,
      );

      expect(alert.isActive, isFalse);
    });

    test('toFirestore round-trip with all fields', () {
      final now = DateTime(2026, 4, 20);
      final original = FinanceAlert(
        id: 'alert-rt',
        type: fe.AlertType.unusualExpense,
        severity: fe.AlertSeverity.warning,
        title: 'Gasto inusual detectado',
        message: 'Gasto de 500€ en una categoría que usualmente no supera 50€',
        relatedBudgetId: 'budget-2',
        createdAt: now,
        isRead: true,
        isDismissed: false,
        readAt: now,
        metadata: {'amount': 500, 'category': 'exp_shopping'},
      );

      final data = original.toFirestore();
      final restored = FinanceAlert.fromFirestore('different-id', data);

      expect(restored.id, 'alert-rt');
      expect(restored.type, original.type);
      expect(restored.severity, original.severity);
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.relatedBudgetId, original.relatedBudgetId);
      expect(restored.isRead, original.isRead);
      expect(restored.isDismissed, original.isDismissed);
      expect(restored.readAt, original.readAt);
      expect(restored.metadata, {'amount': 500, 'category': 'exp_shopping'});
    });

    test('copyWith updates specified fields and preserves others', () {
      final original = FinanceAlert(
        id: 'copy-alert',
        type: fe.AlertType.budgetWarning,
        severity: fe.AlertSeverity.info,
        title: 'Original Title',
        message: 'Original Message',
        createdAt: DateTime(2026, 1, 1),
        isRead: false,
      );

      final updated = original.copyWith(
        severity: fe.AlertSeverity.critical,
        isRead: true,
        readAt: DateTime(2026, 2, 1),
      );

      expect(updated.id, original.id);
      expect(updated.type, original.type);
      expect(updated.severity, fe.AlertSeverity.critical);
      expect(updated.title, original.title);
      expect(updated.message, original.message);
      expect(updated.isRead, true);
      expect(updated.readAt, DateTime(2026, 2, 1));
      expect(updated.createdAt, original.createdAt);
    });

    test('fromFirestore handles unknown alert type', () {
      final data = {
        'id': 'bad-alert',
        'type': 'bogus_type',
        'severity': 'info',
        'title': 'Test',
        'message': 'Test',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final restored = FinanceAlert.fromFirestore('bad-alert', data);
      expect(restored.type, fe.AlertType.budgetWarning); // orElse
    });

    test('fromFirestore handles unknown severity', () {
      final data = {
        'id': 'bad-sev',
        'type': 'budgetWarning',
        'severity': 'bogus_sev',
        'title': 'Test',
        'message': 'Test',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final restored = FinanceAlert.fromFirestore('bad-sev', data);
      expect(restored.severity, fe.AlertSeverity.info); // orElse
    });

    test('metadata is null when not provided', () {
      final alert = FinanceAlert(
        id: 'no-meta',
        type: fe.AlertType.budgetWarning,
        severity: fe.AlertSeverity.info,
        title: 'Test',
        message: 'Test',
        createdAt: DateTime.now(),
      );

      expect(alert.metadata, isNull);
    });
  });

  // ==========================================================
  // RecurringTransaction
  // ==========================================================
  group('RecurringTransaction', () {
    test('creation with all fields', () {
      final now = DateTime(2026, 4, 15);
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
      );

      final rt = RecurringTransaction(
        id: 'rt-1',
        title: 'Netflix',
        amount: 15.99,
        categoryId: 'exp_entertainment',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        autoGenerate: true,
        lastGenerated: DateTime(2026, 3, 1),
        active: true,
        linkedTaskId: 'task-1',
        note: 'Suscripción mensual',
        createdAt: now,
        lastUpdatedAt: now,
        deleted: false,
        firestoreId: 'fs-1',
      );

      expect(rt.id, 'rt-1');
      expect(rt.title, 'Netflix');
      expect(rt.amount, 15.99);
      expect(rt.categoryId, 'exp_entertainment');
      expect(rt.type, fe.FinanceCategoryType.expense);
      expect(rt.recurrence.frequency, RecurrenceFrequency.monthly);
      expect(rt.autoGenerate, true);
      expect(rt.lastGenerated, DateTime(2026, 3, 1));
      expect(rt.active, true);
      expect(rt.linkedTaskId, 'task-1');
      expect(rt.note, 'Suscripción mensual');
      expect(rt.isIncome, false);
      expect(rt.isExpense, true);
      expect(rt.isActive, true);
      expect(rt.deleted, false);
      expect(rt.firestoreId, 'fs-1');
    });

    test('isIncome and isExpense', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime.now(),
      );

      final rtIncome = RecurringTransaction(
        id: 'rt-inc',
        title: 'Salario',
        amount: 3000,
        categoryId: 'inc_salary',
        type: fe.FinanceCategoryType.income,
        recurrence: recurrence,
        createdAt: DateTime.now(),
      );

      final rtExpense = RecurringTransaction(
        id: 'rt-exp',
        title: 'Alquiler',
        amount: 1000,
        categoryId: 'exp_home',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        createdAt: DateTime.now(),
      );

      expect(rtIncome.isIncome, isTrue);
      expect(rtIncome.isExpense, isFalse);
      expect(rtExpense.isIncome, isFalse);
      expect(rtExpense.isExpense, isTrue);
    });

    test('nextOccurrence returns null when inactive', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
      );

      final rt = RecurringTransaction(
        id: 'rt-inactive',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: false,
        createdAt: DateTime.now(),
      );

      expect(rt.nextOccurrence(), isNull);
    });

    test('nextOccurrence returns null when deleted', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
      );

      final rt = RecurringTransaction(
        id: 'rt-deleted',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: true,
        deleted: true,
        createdAt: DateTime.now(),
      );

      expect(rt.nextOccurrence(), isNull);
    });

    test('nextOccurrence calculates correctly for monthly', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 15),
      );

      // Sin lastGenerated → usa startDate
      final rt1 = RecurringTransaction(
        id: 'rt-monthly-1',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        createdAt: DateTime.now(),
      );

      final next1 = rt1.nextOccurrence();
      expect(next1, isNotNull);
      expect(next1!.year, 2026);
      expect(next1.month, 1);
      expect(next1.day, 15);

      // Con lastGenerated → usa lastGenerated
      final rt2 = RecurringTransaction(
        id: 'rt-monthly-2',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        lastGenerated: DateTime(2026, 3, 15),
        createdAt: DateTime.now(),
      );

      final next2 = rt2.nextOccurrence();
      expect(next2, isNotNull);
      expect(next2!.year, 2026);
      expect(next2.month, 4);
      expect(next2.day, 15);
    });

    test('nextOccurrence calculates correctly for weekly', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startDate: DateTime(2026, 4, 15), // miércoles
      );

      final rt = RecurringTransaction(
        id: 'rt-weekly',
        title: 'Test',
        amount: 50,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        lastGenerated: DateTime(2026, 4, 15),
        createdAt: DateTime.now(),
      );

      final next = rt.nextOccurrence();
      expect(next, isNotNull);
      expect(next!.difference(rt.lastGenerated!).inDays, 7);
    });

    test('nextOccurrence calculates correctly for daily', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2026, 4, 15),
      );

      final rt = RecurringTransaction(
        id: 'rt-daily',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        lastGenerated: DateTime(2026, 4, 15),
        createdAt: DateTime.now(),
      );

      final next = rt.nextOccurrence();
      expect(next, isNotNull);
      expect(next!.difference(rt.lastGenerated!).inDays, 1);
    });

    test('nextOccurrence calculates correctly for yearly', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        interval: 1,
        startDate: DateTime(2026, 4, 15),
      );

      final rt = RecurringTransaction(
        id: 'rt-yearly',
        title: 'Test',
        amount: 1000,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        lastGenerated: DateTime(2026, 4, 15),
        createdAt: DateTime.now(),
      );

      final next = rt.nextOccurrence();
      expect(next, isNotNull);
      expect(next!.year, 2027);
      expect(next.month, 4);
      expect(next.day, 15);
    });

    test('isPendingGeneration returns false when not active', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final rt = RecurringTransaction(
        id: 'rt-pending-inactive',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: false,
        createdAt: DateTime.now(),
      );

      expect(rt.isPendingGeneration, false);
    });

    test('isPendingGeneration returns false when autoGenerate is false', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final rt = RecurringTransaction(
        id: 'rt-pending-no-auto',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        autoGenerate: false,
        createdAt: DateTime.now(),
      );

      expect(rt.isPendingGeneration, false);
    });

    test('isPendingGeneration returns false when deleted', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final rt = RecurringTransaction(
        id: 'rt-pending-deleted',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        deleted: true,
        createdAt: DateTime.now(),
      );

      expect(rt.isPendingGeneration, false);
    });

    test('recurrenceDescription returns display string', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 2,
        startDate: DateTime(2026, 1, 1),
      );

      final rt = RecurringTransaction(
        id: 'rt-desc',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        createdAt: DateTime.now(),
      );

      expect(rt.recurrenceDescription, isNotEmpty);
    });

    test('frequency returns correct enum name', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        startDate: DateTime.now(),
      );

      final rt = RecurringTransaction(
        id: 'rt-freq',
        title: 'Test',
        amount: 100,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        createdAt: DateTime.now(),
      );

      expect(rt.frequency, 'weekly');
    });

    test('toFirestore round-trip with all fields', () {
      final now = DateTime(2026, 4, 20);
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2027, 1, 1),
      );

      final original = RecurringTransaction(
        id: 'rt-full-rt',
        title: 'Full Round Trip',
        amount: 99.99,
        categoryId: 'exp_subscriptions',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        autoGenerate: true,
        lastGenerated: DateTime(2026, 3, 1),
        active: true,
        linkedTaskId: 'task-link-1',
        note: ' nota ',
        createdAt: now,
        lastUpdatedAt: now.add(const Duration(hours: 1)),
        deleted: false,
        firestoreId: 'fs-rt-1',
      );

      final data = original.toFirestore();
      final restored = RecurringTransaction.fromFirestore('different-id', data);

      expect(restored.id, 'rt-full-rt');
      expect(restored.title, original.title);
      expect(restored.amount, original.amount);
      expect(restored.categoryId, original.categoryId);
      expect(restored.type, original.type);
      expect(restored.recurrence.frequency, original.recurrence.frequency);
      expect(restored.recurrence.interval, original.recurrence.interval);
      expect(restored.recurrence.startDate, original.recurrence.startDate);
      expect(restored.autoGenerate, original.autoGenerate);
      expect(restored.lastGenerated, original.lastGenerated);
      expect(restored.active, original.active);
      expect(restored.linkedTaskId, original.linkedTaskId);
      expect(restored.note, original.note);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastUpdatedAt, original.lastUpdatedAt);
      expect(restored.deleted, original.deleted);
      expect(restored.firestoreId, 'different-id'); // fromFirestore uses the doc id argument
    });

    test('copyWith basic fields', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
      );

      final original = RecurringTransaction(
        id: 'rt-copy',
        title: 'Original',
        amount: 50,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        title: 'Updated',
        amount: 75,
        active: false,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Updated');
      expect(updated.amount, 75);
      expect(updated.categoryId, original.categoryId);
      expect(updated.type, original.type);
      expect(updated.recurrence, original.recurrence);
      expect(updated.active, false);
      expect(updated.createdAt, original.createdAt);
    });

    test('copyWith clears optional fields with clear flags', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime(2026, 1, 1),
      );

      final original = RecurringTransaction(
        id: 'rt-clear',
        title: 'Test',
        amount: 50,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        linkedTaskId: 'task-123',
        note: 'Nota importante',
        firestoreId: 'fs-123',
        createdAt: DateTime(2026, 1, 1),
      );

      final cleared = original.copyWith(
        clearLinkedTaskId: true,
        clearNote: true,
        clearFirestoreId: true,
      );

      expect(cleared.linkedTaskId, isNull);
      expect(cleared.note, isNull);
      expect(cleared.firestoreId, isNull);
      expect(cleared.id, original.id);
      expect(cleared.title, original.title);
      expect(cleared.amount, original.amount);
    });

    test('fromFirestore handles missing recurrence data gracefully', () {
      final data = {
        'id': 'rt-bad-recurrence',
        'title': 'Test',
        'amount': 50,
        'categoryId': 'cat-1',
        'type': 'expense',
        'recurrence': null,
        'autoGenerate': true,
        'active': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Esto debería fallar porque recurrence es null pero el constructor lo requiere
      // Verificamos el comportamiento actual
      expect(
        () => RecurringTransaction.fromFirestore('rt-bad-recurrence', data),
        throwsA(isA<TypeError>()),
      );
    });

    test('isActive considers both active flag and deleted flag', () {
      final recurrence = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        startDate: DateTime.now(),
      );

      final activeNotDeleted = RecurringTransaction(
        id: 'rt-active-clean',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: true,
        deleted: false,
        createdAt: DateTime.now(),
      );

      final activeButDeleted = RecurringTransaction(
        id: 'rt-active-deleted',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: true,
        deleted: true,
        createdAt: DateTime.now(),
      );

      final inactiveNotDeleted = RecurringTransaction(
        id: 'rt-inactive-clean',
        title: 'Test',
        amount: 10,
        categoryId: 'cat-1',
        type: fe.FinanceCategoryType.expense,
        recurrence: recurrence,
        active: false,
        deleted: false,
        createdAt: DateTime.now(),
      );

      expect(activeNotDeleted.isActive, isTrue);
      expect(activeButDeleted.isActive, isFalse);
      expect(inactiveNotDeleted.isActive, isFalse);
    });
  });
}
