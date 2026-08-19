import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'unified_transaction_dialog.dart';
import '../models/recurring_transaction.dart';

/// Diálogo de compatibilidad que redirige al nuevo UnifiedTransactionDialog
class AddRecurringTransactionDialog extends ConsumerWidget {
  final RecurringTransaction? existingTransaction;

  const AddRecurringTransactionDialog({super.key, this.existingTransaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UnifiedTransactionDialog();
  }
}
