import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/forecast_provider.dart';

/// Gráfico visual de proyección de flujo de caja
/// Muestra balance proyectado, ingresos y gastos mes a mes
class CashFlowChart extends StatelessWidget {
  final List<MonthlyForecastProjection> projections;
  final double currentBalance;

  const CashFlowChart({
    super.key,
    required this.projections,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    if (projections.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Sin datos de proyección',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Agrega transacciones recurrentes o gastos futuros para ver proyecciones',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evolución del Balance Proyectado',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Balance actual: ${currencyFormat.format(currentBalance)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: currentBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de meses proyectados con barras de progreso y variación
            ...projections.map((projection) {
              final isNegative = projection.endingBalance < 0;
              final changeFromStart = projection.netCashFlow;
              final isIncrease = changeFromStart >= 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MMMM yyyy', 'es_ES').format(projection.month).capitalize(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (projection.items.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${projection.items.length} pagos',
                                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          currencyFormat.format(projection.endingBalance),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isNegative ? Colors.red : (isDark ? Colors.greenAccent : Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Barra de progreso relativa
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _calculateProgressValue(projection.endingBalance, projections),
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isNegative ? Colors.red : Colors.green.shade600,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Compromisos: -${currencyFormat.format(projection.totalProjectedExpenses)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${isIncrease ? '+' : ''}${currencyFormat.format(changeFromStart)} flujo neto',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isIncrease ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // Resumen de Mejor y Peor Mes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Mayor Balance',
                      value: currencyFormat.format(_getBestMonth(projections)),
                      color: Colors.green,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Menor Balance',
                      value: currencyFormat.format(_getWorstMonth(projections)),
                      color: Colors.red,
                      icon: Icons.arrow_downward,
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

  double _calculateProgressValue(double balance, List<MonthlyForecastProjection> allProjections) {
    if (allProjections.isEmpty) return 0.5;

    final balances = allProjections.map((p) => p.endingBalance).toList();
    final max = balances.reduce((a, b) => a > b ? a : b);
    final min = balances.reduce((a, b) => a < b ? a : b);

    if (max == min) return 0.5;
    return ((balance - min) / (max - min)).clamp(0.05, 1.0);
  }

  double _getBestMonth(List<MonthlyForecastProjection> projections) {
    if (projections.isEmpty) return 0;
    return projections.map((p) => p.endingBalance).reduce((a, b) => a > b ? a : b);
  }

  double _getWorstMonth(List<MonthlyForecastProjection> projections) {
    if (projections.isEmpty) return 0;
    return projections.map((p) => p.endingBalance).reduce((a, b) => a < b ? a : b);
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
