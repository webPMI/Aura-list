// Verification script to check finance box initialization
// Run with: dart run verify_finance_boxes.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/transaction.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/features/finance/models/budget.dart';
import 'package:checklist_app/features/finance/models/cash_flow_projection.dart';
import 'package:checklist_app/features/finance/models/finance_alert.dart';
import 'package:checklist_app/features/finance/models/task_finance_link.dart';
import 'package:checklist_app/features/finance/models/finance_enums.dart';

void main() async {
  print('=== Finance Box Verification ===\n');

  try {
    // Initialize Hive
    await Hive.initFlutter();
    print('✓ Hive initialized');

    // Register all finance-related adapters
    print('\nRegistering TypeAdapters...');

    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(FinanceCategoryTypeAdapter());
      print('✓ FinanceCategoryTypeAdapter (14)');
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(FinanceCategoryAdapter());
      print('✓ FinanceCategoryAdapter (15)');
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(TransactionAdapter());
      print('✓ TransactionAdapter (16)');
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(RecurringTransactionAdapter());
      print('✓ RecurringTransactionAdapter (17)');
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(BudgetAdapter());
      print('✓ BudgetAdapter (18)');
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(CashFlowProjectionAdapter());
      print('✓ CashFlowProjectionAdapter (19)');
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(FinanceAlertAdapter());
      print('✓ FinanceAlertAdapter (20)');
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(RecurrenceRuleAdapter());
      print('✓ RecurrenceRuleAdapter (9)');
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(RecurrenceFrequencyAdapter());
      print('✓ RecurrenceFrequencyAdapter (10)');
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(WeekDayAdapter());
      print('✓ WeekDayAdapter (11)');
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(WeekParityAdapter());
      print('✓ WeekParityAdapter (12)');
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(BudgetPeriodAdapter());
      print('✓ BudgetPeriodAdapter (23)');
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(TaskFinanceLinkTypeAdapter());
      print('✓ TaskFinanceLinkTypeAdapter (24)');
    }
    if (!Hive.isAdapterRegistered(25)) {
      Hive.registerAdapter(AlertTypeAdapter());
      print('✓ AlertTypeAdapter (25)');
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(AlertSeverityAdapter());
      print('✓ AlertSeverityAdapter (26)');
    }
    if (!Hive.isAdapterRegistered(27)) {
      Hive.registerAdapter(RiskLevelAdapter());
      print('✓ RiskLevelAdapter (27)');
    }
    if (!Hive.isAdapterRegistered(28)) {
      Hive.registerAdapter(FinancialImpactTypeAdapter());
      print('✓ FinancialImpactTypeAdapter (28)');
    }
    if (!Hive.isAdapterRegistered(29)) {
      Hive.registerAdapter(TaskFinanceLinkAdapter());
      print('✓ TaskFinanceLinkAdapter (29)');
    }

    print('\nAll TypeAdapters registered successfully!');

    // Test opening each finance box
    print('\nOpening finance boxes...');

    final financeBoxes = [
      'finance_categories',
      'finance_transactions',
      'finance_recurring_transactions',
      'finance_budgets',
      'finance_cash_flow_projections',
      'finance_alerts',
      'finance_task_links',
    ];

    for (final boxName in financeBoxes) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
        final box = Hive.box(boxName);
        print('✓ $boxName (${box.length} items)');
      } catch (e) {
        print('✗ $boxName - ERROR: $e');
      }
    }

    print('\n=== Verification Complete ===');
    print('All finance boxes initialized successfully!');

    // Close all boxes
    print('\nClosing boxes...');
    await Hive.close();
    print('✓ All boxes closed');
  } catch (e, stack) {
    print('\n✗ ERROR: $e');
    print('Stack trace: $stack');
  }
}
