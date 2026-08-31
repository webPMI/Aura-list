import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarjeta reutilizable de Distribución de Gastos por Categoría con barras de progreso y porcentajes
class CategoryDistributionCard extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final double totalExpenses;
  final String title;

  const CategoryDistributionCard({
    super.key,
    required this.categoryExpenses,
    required this.totalExpenses,
    this.title = 'Gastos Previstos por Categoría',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.simpleCurrency(locale: 'es_ES');

    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in sortedEntries) ...[
              Builder(builder: (ctx) {
                final percentage = totalExpenses > 0 ? (entry.value / totalExpenses) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '${currency.format(entry.value)} (${(percentage * 100).toStringAsFixed(0)}%)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
