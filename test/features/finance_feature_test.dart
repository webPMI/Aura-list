import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/transaction.dart';

void main() {
  group('Finance Feature Tests', () {
    group('FinanceCategory Model', () {
      test('creation and properties', () {
        final category = FinanceCategory(
          id: 'cat-1',
          name: 'Food',
          icon: '🍔',
          color: '#FF0000',
          type: FinanceCategoryType.expense,
        );

        expect(category.name, 'Food');
        expect(category.type, FinanceCategoryType.expense);
        expect(category.isDefault, false);
      });
    });

    group('Transaction Model', () {
      test('creation and helper methods', () {
        final date = DateTime(2026, 2, 22);
        final transaction = Transaction(
          id: 'tx-1',
          title: 'Lunch',
          amount: 15.5,
          date: date,
          categoryId: 'cat-1',
          type: FinanceCategoryType.expense,
          createdAt: date,
        );

        expect(transaction.title, 'Lunch');
        expect(transaction.amount, 15.5);
        expect(transaction.isExpense, true);
        expect(transaction.isIncome, false);
        expect(transaction.deleted, false);
      });
    });
  });
}
