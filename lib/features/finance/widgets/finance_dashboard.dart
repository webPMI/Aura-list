import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';

/// Dashboard contable moderno con filtrado por períodos y desglose de categorías.
class FinanceDashboard extends ConsumerWidget {
  const FinanceDashboard({super.key});

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
    final stats = ref.watch(periodFinanceStatsProvider);
    final currentPeriod = ref.watch(selectedFinancePeriodProvider);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selector de Período Contable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FinanceTimePeriod.values.map((period) {
                final isSelected = period == currentPeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(period.label),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedFinancePeriodProvider.notifier).state = period;
                    },
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimaryContainer : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Tarjeta Principal de Balance Contable
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.tertiary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ahorro Neto (${currentPeriod.label})',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tasa: ${stats.savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currencyFormat.format(stats.netSavings),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ingresos
                      _StatColumn(
                        label: 'Ingresos',
                        amount: stats.totalIncome,
                        icon: Icons.arrow_upward,
                        color: Colors.greenAccent,
                        currencyFormat: currencyFormat,
                      ),
                      // Gastos
                      _StatColumn(
                        label: 'Gastos',
                        amount: stats.totalExpenses,
                        icon: Icons.arrow_downward,
                        color: Colors.orangeAccent,
                        currencyFormat: currencyFormat,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Desglose de Gastos por Categoría
          Text(
            'Distribución de Gastos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (stats.expenseCategories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Sin gastos registrados en ${currentPeriod.label.toLowerCase()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: stats.expenseCategories.map((item) {
                    final catColor = _parseCategoryColor(item.category.color);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: catColor.withValues(alpha: 0.2),
                                    child: Icon(Icons.circle, color: catColor, size: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.category.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Text(
                                '${currencyFormat.format(item.amount)} (${item.percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: item.percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: catColor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // 4. Desglose de Ingresos si existen
          if (stats.incomeCategories.isNotEmpty) ...[
            Text(
              'Fuentes de Ingresos',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: stats.incomeCategories.map((item) {
                    final catColor = _parseCategoryColor(item.category.color);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: catColor.withValues(alpha: 0.2),
                                    child: Icon(Icons.circle, color: catColor, size: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.category.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Text(
                                '${currencyFormat.format(item.amount)} (${item.percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: item.percentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: catColor,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final NumberFormat currencyFormat;

  const _StatColumn({
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
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
