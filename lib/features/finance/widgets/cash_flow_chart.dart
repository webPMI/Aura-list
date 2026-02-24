import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cash_flow_projection.dart' as models;

/// Gráfico simple de proyección de flujo de caja
/// Muestra balance proyectado para los próximos 3-6 meses
/// Por ahora es una lista, se puede convertir a gráfico después
class CashFlowChart extends StatelessWidget {
  final List<models.CashFlowProjection> projections;
  final double currentBalance;

  const CashFlowChart({
    super.key,
    required this.projections,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    if (projections.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              Text(
                'Sin datos de proyección',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega transacciones recurrentes para ver proyecciones',
                style: TextStyle(
                  fontSize: 14,
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
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Proyección de Flujo de Caja',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Balance actual: ${currencyFormat.format(currentBalance)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: currentBalance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de proyecciones
            ...projections.map((projection) {
              final isNegative = projection.projectedBalance < 0;
              final changeFromCurrent = projection.projectedBalance - currentBalance;
              final isIncrease = changeFromCurrent > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Mes
                    SizedBox(
                      width: 80,
                      child: Text(
                        DateFormat('MMM yyyy', 'es_ES').format(projection.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Barra de visualización
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _calculateProgressValue(
                                      projection.projectedBalance,
                                      projections,
                                    ),
                                    backgroundColor: Colors.grey.withOpacity(0.2),
                                    color: isNegative ? Colors.red : Colors.green,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Indicador de cambio
                              Icon(
                                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 16,
                                color: isIncrease ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currencyFormat.format(projection.projectedBalance),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNegative ? Colors.red : Colors.green,
                                ),
                              ),
                              Text(
                                '${isIncrease ? '+' : ''}${currencyFormat.format(changeFromCurrent)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Resumen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Mejor mes',
                      value: currencyFormat.format(_getBestMonth(projections)),
                      color: Colors.green,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Peor mes',
                      value: currencyFormat.format(_getWorstMonth(projections)),
                      color: Colors.red,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ),

            // Advertencias
            ..._buildWarnings(projections, theme, currencyFormat),
          ],
        ),
      ),
    );
  }

  double _calculateProgressValue(double balance, List<models.CashFlowProjection> allProjections) {
    if (allProjections.isEmpty) return 0.5;

    final max = allProjections.map((p) => p.projectedBalance).reduce((a, b) => a > b ? a : b);
    final min = allProjections.map((p) => p.projectedBalance).reduce((a, b) => a < b ? a : b);

    if (max == min) return 0.5;

    // Normalizar entre 0 y 1
    return ((balance - min) / (max - min)).clamp(0.0, 1.0);
  }

  double _getBestMonth(List<models.CashFlowProjection> projections) {
    if (projections.isEmpty) return 0;
    return projections.map((p) => p.projectedBalance).reduce((a, b) => a > b ? a : b);
  }

  double _getWorstMonth(List<models.CashFlowProjection> projections) {
    if (projections.isEmpty) return 0;
    return projections.map((p) => p.projectedBalance).reduce((a, b) => a < b ? a : b);
  }

  List<Widget> _buildWarnings(
    List<models.CashFlowProjection> projections,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    final warnings = <Widget>[];

    // Advertencia si algún mes es negativo
    final negativeMonths = projections.where((p) => p.projectedBalance < 0).toList();
    if (negativeMonths.isNotEmpty) {
      warnings.add(const SizedBox(height: 12));
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Atención: ${negativeMonths.length} ${negativeMonths.length == 1 ? 'mes con' : 'meses con'} balance negativo proyectado',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return warnings;
  }
}

/// Widget auxiliar para mostrar resumen
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
