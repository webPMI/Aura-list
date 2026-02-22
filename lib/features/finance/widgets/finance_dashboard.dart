import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import 'package:intl/intl.dart';

class FinanceDashboard extends ConsumerWidget {
  const FinanceDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    if (financeState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceCard(
            balance: financeState.balance,
            income: financeState.totalIncome,
            expenses: financeState.totalExpenses,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 24),
          Text(
            'Resumen Mensual',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Placeholder for charts or more detailed summary
          _MonthlySummary(
            income: financeState.totalIncome,
            expenses: financeState.totalExpenses,
            currencyFormat: currencyFormat,
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final NumberFormat currencyFormat;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Balance Total',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(balance),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  label: 'Ingresos',
                  amount: income,
                  icon: Icons.arrow_upward,
                  color: Colors.greenAccent,
                  currencyFormat: currencyFormat,
                ),
                _SummaryItem(
                  label: 'Gastos',
                  amount: expenses,
                  icon: Icons.arrow_downward,
                  color: Colors.orangeAccent,
                  currencyFormat: currencyFormat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final NumberFormat currencyFormat;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final double income;
  final double expenses;
  final NumberFormat currencyFormat;

  const _MonthlySummary({
    required this.income,
    required this.expenses,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (income == 0 && expenses == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 8),
              const Text('Sin transacciones este mes'),
            ],
          ),
        ),
      );
    }

    final expensePercent = income > 0
        ? (expenses / income).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Proporción Gastos/Ingresos'),
                Text('${(expensePercent * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: expensePercent,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: expensePercent > 0.8 ? Colors.red : Colors.blue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
