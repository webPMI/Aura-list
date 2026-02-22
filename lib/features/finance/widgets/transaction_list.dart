import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/finance_category.dart';
import 'package:intl/intl.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);
    final transactions = financeState.transactions;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay transacciones aún',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final category = financeState.categories.firstWhere(
          (c) => c.id == transaction.categoryId,
          orElse: () => FinanceCategory(
            id: 'unknown',
            name: 'Desconocido',
            icon: 'help',
            color: '#9E9E9E',
            type: transaction.type,
          ),
        );

        return Dismissible(
          key: Key(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref
                .read(financeProvider.notifier)
                .deleteTransaction(transaction.key);
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColor(category.color).withOpacity(0.1),
              child: Icon(
                _getIconData(category.icon),
                color: _getColor(category.color),
              ),
            ),
            title: Text(transaction.title),
            subtitle: Text(DateFormat('dd MMM yyyy').format(transaction.date)),
            trailing: Text(
              '${transaction.isIncome ? "+" : "-"}${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                color: transaction.isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'trending_up':
        return Icons.trending_up;
      case 'redeem':
        return Icons.redeem;
      case 'add_circle':
        return Icons.add_circle;
      default:
        return Icons.category;
    }
  }
}
