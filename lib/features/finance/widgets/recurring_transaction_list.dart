import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/finance_category.dart';

/// Lista de transacciones recurrentes con acciones de swipe
class RecurringTransactionList extends ConsumerWidget {
  const RecurringTransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Conectar con provider de transacciones recurrentes cuando esté disponible
    // final recurringTransactions = ref.watch(recurringTransactionsProvider);

    // Datos de ejemplo mientras se implementa el provider
    final exampleRecurringTransactions = <Map<String, dynamic>>[];

    if (exampleRecurringTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.repeat,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Sin transacciones recurrentes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Toca + para agregar una transacción recurrente',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exampleRecurringTransactions.length,
      itemBuilder: (context, index) {
        final transaction = exampleRecurringTransactions[index];
        return _RecurringTransactionTile(
          transaction: transaction,
          onEdit: () => _showEditDialog(context, transaction),
          onPause: () => _pauseTransaction(transaction),
          onDelete: () => _deleteTransaction(context, transaction),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> transaction) {
    // TODO: Abrir dialog de edición
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar transacción recurrente')),
    );
  }

  void _pauseTransaction(Map<String, dynamic> transaction) {
    // TODO: Pausar transacción recurrente
  }

  void _deleteTransaction(BuildContext context, Map<String, dynamic> transaction) {
    // TODO: Eliminar transacción recurrente
  }
}

/// Tile individual para transacción recurrente con swipe actions
class _RecurringTransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  const _RecurringTransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onPause,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    final title = transaction['title'] as String? ?? 'Sin título';
    final amount = transaction['amount'] as double? ?? 0.0;
    final type = transaction['type'] as FinanceCategoryType? ?? FinanceCategoryType.expense;
    final frequency = transaction['frequency'] as String? ?? 'monthly';
    final nextOccurrence = transaction['nextOccurrence'] as DateTime? ?? DateTime.now();
    final isPaused = transaction['isPaused'] as bool? ?? false;

    return Dismissible(
      key: Key(transaction['id']?.toString() ?? 'recurring_${DateTime.now().millisecondsSinceEpoch}'),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        } else {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eliminar transacción recurrente'),
              content: const Text('¿Estás seguro de que deseas eliminar esta transacción recurrente?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: type == FinanceCategoryType.income
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            child: Icon(
              type == FinanceCategoryType.income
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: type == FinanceCategoryType.income
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isPaused ? TextDecoration.lineThrough : null,
                    color: isPaused ? Colors.grey : null,
                  ),
                ),
              ),
              if (isPaused)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pausada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getFrequencyText(frequency),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Próxima: ${DateFormat('dd/MM/yyyy').format(nextOccurrence)}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: type == FinanceCategoryType.income
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              IconButton(
                icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                ),
                onPressed: onPause,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      default:
        return frequency;
    }
  }
}
