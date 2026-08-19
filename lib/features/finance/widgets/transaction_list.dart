import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/finance_category.dart';

/// Provider local para el filtro de tipo de transacción en la lista
final _transactionTypeFilterProvider =
    StateProvider.autoDispose<FinanceCategoryType?>((ref) => null);

/// Provider local para la búsqueda de transacciones
final _transactionSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  Color _parseCategoryColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(financeProvider.select((s) => s.categories));
    final typeFilter = ref.watch(_transactionTypeFilterProvider);
    final searchQuery = ref.watch(_transactionSearchQueryProvider).trim().toLowerCase();
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final theme = Theme.of(context);

    // Filtrar por búsqueda y tipo
    final filtered = transactions.where((tx) {
      if (typeFilter != null && tx.type != typeFilter) return false;
      if (searchQuery.isNotEmpty && !tx.title.toLowerCase().contains(searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de búsqueda y filtros rápidos
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar transacción...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                  onChanged: (val) =>
                      ref.read(_transactionSearchQueryProvider.notifier).state = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filtros tipo: Todos / Gastos / Ingresos
          Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: typeFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(_transactionTypeFilterProvider.notifier).state = null;
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Gastos'),
                selected: typeFilter == FinanceCategoryType.expense,
                selectedColor: Colors.red.shade100,
                onSelected: (selected) {
                  ref.read(_transactionTypeFilterProvider.notifier).state =
                      selected ? FinanceCategoryType.expense : null;
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ingresos'),
                selected: typeFilter == FinanceCategoryType.income,
                selectedColor: Colors.green.shade100,
                onSelected: (selected) {
                  ref.read(_transactionTypeFilterProvider.notifier).state =
                      selected ? FinanceCategoryType.income : null;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Lista de transacciones
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron transacciones',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final transaction = filtered[index];
                final category = categories.firstWhere(
                  (c) => c.id == transaction.categoryId,
                  orElse: () => FinanceCategory(
                    id: 'unknown',
                    name: 'General',
                    icon: 'help',
                    color: '#9E9E9E',
                    type: transaction.type,
                  ),
                );
                final catColor = _parseCategoryColor(category.color);
                final isIncome = transaction.isIncome;
                final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

                return Dismissible(
                  key: Key(transaction.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(financeProvider.notifier).deleteTransaction(transaction.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        child: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transaction.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: catColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy', 'es').format(transaction.date),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
