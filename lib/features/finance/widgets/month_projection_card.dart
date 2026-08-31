import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/forecast_provider.dart';

extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

/// Acordeón / Tarjeta expandible reutilizable por mes con desglose de pagos específicos
class MonthProjectionCard extends StatelessWidget {
  final MonthlyForecastProjection projection;
  final bool initiallyExpanded;

  const MonthProjectionCard({
    super.key,
    required this.projection,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = NumberFormat.simpleCurrency(locale: 'es_ES');
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(projection.month).capitalize();

    final isDeficit = projection.endingBalance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeficit
              ? Colors.red.shade400
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isDeficit ? 1.5 : 1,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDeficit
                  ? Colors.red.withValues(alpha: 0.15)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeficit ? Icons.error_outline_rounded : Icons.calendar_month_rounded,
              color: isDeficit ? Colors.red : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            monthName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            'Compromisos: -${currency.format(projection.totalProjectedExpenses)} | Final: ${currency.format(projection.endingBalance)}',
            style: TextStyle(
              fontSize: 12,
              color: isDeficit ? Colors.red : Colors.grey.shade600,
              fontWeight: isDeficit ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          children: [
            if (projection.items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Sin pagos fijos programados para este mes.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    for (final item in projection.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _parseColor(item.categoryColor).withValues(alpha: 0.2),
                              child: Icon(
                                item.isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                size: 14,
                                color: _parseColor(item.categoryColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Text(
                                        DateFormat('d MMM', 'es_ES').format(item.dueDate),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                      if (item.installmentSummary != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.installmentSummary!,
                                            style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else if (item.source == 'future_transaction')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Gasto Futuro',
                                            style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.isExpense ? '-' : '+'}${currency.format(item.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: item.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || !colorStr.startsWith('#')) return Colors.blueGrey;
    final hex = colorStr.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}
