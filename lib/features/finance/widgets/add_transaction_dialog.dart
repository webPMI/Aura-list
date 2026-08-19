import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'unified_transaction_dialog.dart';

/// Diálogo de compatibilidad que redirige al nuevo UnifiedTransactionDialog
class AddTransactionDialog extends ConsumerWidget {
  const AddTransactionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UnifiedTransactionDialog();
  }
}
