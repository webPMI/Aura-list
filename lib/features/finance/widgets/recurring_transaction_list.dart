import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/finance_category.dart';
import '../models/recurring_transaction.dart';
import '../providers/forecast_provider.dart';
import 'unified_transaction_dialog.dart';

/// Lista reactiva de transacciones recurrentes conectada al estado real.
class RecurringTransactionList extends ConsumerWidget {
  const RecurringTransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final recurringList = forecastState.activeRecurring;

    if (recurringList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.repeat,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin transacciones recurrentes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Programa gastos o ingresos recurrentes diarios, semanales o mensuales.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const UnifiedTransactionDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Programar Recurrente'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recurringList.length,
      itemBuilder: (context, index) {
        final item = recurringList[index];
        return _RecurringTransactionTile(
          item: item,
          onDelete: () => ref.read(forecastProvider.notifier).deleteRecurringTransaction(item.id),
        );
      },
    );
  }
}

/// Tile para mostrar cada transacción recurrente activa
class _RecurringTransactionTile extends StatelessWidget {
  final RecurringTransaction item;
  final VoidCallback onDelete;

  const _RecurringTransactionTile({
    required this.item,
    required this.onDelete,
  });

  String _formatFrequency(RecurringTransaction rt) {
    final freq = rt.recurrence.frequency.name;
    switch (freq) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      default:
        return 'Recurrente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final isIncome = item.type == FinanceCategoryType.income;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatFrequency(item),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
              ),
            ),
            if (item.note != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${currencyFormat.format(item.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar recurrencia'),
                    content: Text('¿Deseas eliminar la regla recurrente "${item.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
