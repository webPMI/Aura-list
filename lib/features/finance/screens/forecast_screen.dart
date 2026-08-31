import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/finance_category.dart';
import '../providers/forecast_provider.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/unified_transaction_dialog.dart';
import '../widgets/metric_mini_card.dart';
import '../widgets/hero_forecast_card.dart';
import '../widgets/month_projection_card.dart';
import '../widgets/category_distribution_card.dart';

extension StringCasingExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

/// Pantalla integral de análisis de proyecciones y previsión de gastos futuros.
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  int _selectedHorizonMonths = 3; // 1, 3, 6, 12 meses

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    final forecastStats = ref.watch(expenseForecastStatsProvider);
    final forecastState = ref.watch(forecastProvider);

    // Filtrar proyecciones según el horizonte seleccionado
    final horizonProjections = forecastStats.monthlyProjections
        .take(_selectedHorizonMonths)
        .toList();

    // Total de gastos e ingresos acumulados en el horizonte
    double totalHorizonExpenses = 0.0;
    double totalHorizonIncome = 0.0;
    final Map<String, double> horizonCategoryExpenses = {};

    for (final p in horizonProjections) {
      totalHorizonExpenses += p.totalProjectedExpenses;
      totalHorizonIncome += p.projectedIncome;
      p.expensesByCategory.forEach((cat, amt) {
        horizonCategoryExpenses[cat] = (horizonCategoryExpenses[cat] ?? 0.0) + amt;
      });
    }

    final hasAnyDeficit = horizonProjections.any((p) => p.endingBalance < 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Previsión de Gastos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfo(context),
            tooltip: 'Acerca del análisis',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UnifiedTransactionDialog.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Programar Gasto'),
      ),
      body: forecastState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => ref.read(forecastProvider.notifier).refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Selector de Horizonte Temporal
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            for (final entry in {
                              1: '1 Mes',
                              3: '3 Meses',
                              6: '6 Meses',
                              12: '1 Año',
                            }.entries)
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedHorizonMonths = entry.key),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedHorizonMonths == entry.key
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedHorizonMonths == entry.key
                                              ? Colors.white
                                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Alerta temprana si hay déficit proyectado
                    if (hasAnyDeficit)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Alerta de Saldo Proyectado',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Se proyecta un balance negativo en uno o más meses de este horizonte con los gastos programados actuales.',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. Tarjeta Hero de Balance y Compromisos
                    HeroForecastCard(
                      currentBalance: forecastStats.currentBalance,
                      monthlyFixedCommitments: forecastStats.monthlyFixedCommitments,
                      horizonExpenses: totalHorizonExpenses,
                      horizonMonths: _selectedHorizonMonths,
                    ),

                    // 4. Grid de Métricas Clave
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.55,
                        children: [
                          MetricMiniCard(
                            icon: Icons.calendar_today_rounded,
                            title: 'Gasto Promedio Diario',
                            value: currencyFormat.format(forecastStats.averageDailyExpenseHistorical),
                            subtitle: 'Ritmo de consumo base',
                            color: Colors.orange,
                          ),
                          MetricMiniCard(
                            icon: Icons.date_range_rounded,
                            title: 'Gasto Promedio Mensual',
                            value: currencyFormat.format(forecastStats.averageMonthlyExpenseHistorical),
                            subtitle: 'Gasto total habitual',
                            color: Colors.blue,
                          ),
                          MetricMiniCard(
                            icon: Icons.timelapse_rounded,
                            title: 'Próximos 30 Días',
                            value: currencyFormat.format(forecastStats.upcoming30DaysExpenses),
                            subtitle: '${forecastStats.activeInstallmentsCount} cuotas activas',
                            color: Colors.purple,
                          ),
                          MetricMiniCard(
                            icon: Icons.repeat_rounded,
                            title: 'Compromisos Fijos',
                            value: currencyFormat.format(forecastStats.monthlyFixedCommitments),
                            subtitle: '${forecastStats.activeRecurringCount} suscripciones',
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 5. Gráfico Evolutivo de Flujo de Caja
                    CashFlowChart(
                      projections: horizonProjections,
                      currentBalance: forecastStats.currentBalance,
                    ),

                    const SizedBox(height: 14),

                    // 6. Desglose Detallado de Gastos Programados por Mes
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.event_note_rounded, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Próximos Gastos por Mes ($_selectedHorizonMonths ${_selectedHorizonMonths == 1 ? 'mes' : 'meses'})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    for (final projection in horizonProjections)
                      MonthProjectionCard(projection: projection),

                    const SizedBox(height: 16),

                    // 7. Distribución por Categorías en el Horizonte
                    if (horizonCategoryExpenses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.pie_chart_rounded, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Gastos Previstos por Categoría',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CategoryDistributionCard(
                        categoryExpenses: horizonCategoryExpenses,
                        totalExpenses: totalHorizonExpenses,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: Colors.blue),
            SizedBox(width: 10),
            Text('Motor de Previsión'),
          ],
        ),
        content: const Text(
          'El análisis de previsión financiera calcula tu flujo de efectivo combinando:\n\n'
          '• Tus saldos y transacciones actuales.\n'
          '• Todas tus cuotas activas (número exacto de pagos restantes y pagos adelantados).\n'
          '• Gastos e ingresos recurrentes (diarios, semanales, quincenales, mensuales, trimestrales, semestrales y anuales).\n'
          '• Gastos puntuales programados a futuro (como inscripciones de cursos del próximo año).\n'
          '• Tu ritmo de gasto diario histórico para darte visibilidad y tranquilidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _RecurringSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRecurring = ref.watch(activeRecurringProvider);

    if (activeRecurring.isEmpty) {
      return const SizedBox.shrink();
    }

    final incomeCount = activeRecurring.where((rt) => rt.amount > 0).length;
    final expenseCount = activeRecurring.where((rt) => rt.amount < 0).length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transacciones Recurrentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Ingresos',
                  value: incomeCount.toString(),
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Gastos',
                  value: expenseCount.toString(),
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetsSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBudgets = ref.watch(activeBudgetsProvider);

    if (activeBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presupuestos Activos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            label: 'Presupuestos',
            value: activeBudgets.length.toString(),
            icon: Icons.pie_chart,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

