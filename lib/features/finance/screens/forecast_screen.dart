import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/cash_flow_projection.dart' as models;
import '../providers/forecast_provider.dart';
import '../widgets/cash_flow_chart.dart';

/// Pantalla de dashboard de previsiones financieras.
/// Muestra proyecciones de flujo de efectivo, alertas y tendencias.
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final projections = forecastState.projections
        .where((p) => !p.deleted && !p.isHistorical)
        .toList();

    // Ordenar proyecciones por fecha
    projections.sort((a, b) => a.date.compareTo(b.date));

    // Calcular balance actual (suma de todas las transacciones)
    final currentBalance = _calculateCurrentBalance(projections);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsiones Financieras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(forecastProvider.notifier).refreshAll(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
            tooltip: 'Información',
          ),
        ],
      ),
      body: forecastState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance actual
                  _BalanceCard(balance: currentBalance),

                  // Resumen de alertas activas
                  if (forecastState.activeAlerts.isNotEmpty)
                    _AlertsSummaryCard(
                      alertCount: forecastState.activeAlerts.length,
                    ),

                  // Gráfico de proyecciones
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Proyección de Flujo de Efectivo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CashFlowChart(
                    projections: projections,
                    currentBalance: currentBalance,
                  ),

                  // Resumen de transacciones recurrentes
                  _RecurringSummary(),

                  // Resumen de presupuestos
                  _BudgetsSummary(),

                  const SizedBox(height: 80), // Espacio para FAB
                ],
              ),
            ),
    );
  }

  double _calculateCurrentBalance(List<models.CashFlowProjection> projections) {
    if (projections.isEmpty) return 0.0;

    // Por ahora retornamos 0, en una implementación real
    // esto debería calcularse sumando todas las transacciones
    return 0.0;
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Text('Previsiones'),
          ],
        ),
        content: const Text(
          'El sistema de previsiones analiza tus transacciones recurrentes '
          'y presupuestos para proyectar tu flujo de efectivo futuro.\n\n'
          'Te ayuda a:\n'
          '• Anticipar períodos de balance negativo\n'
          '• Planificar gastos grandes\n'
          '• Identificar patrones de gasto\n'
          '• Recibir alertas tempranas de problemas financieros',
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

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance Actual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPositive ? 'Balance positivo' : 'Balance negativo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsSummaryCard extends StatelessWidget {
  final int alertCount;

  const _AlertsSummaryCard({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$alertCount ${alertCount == 1 ? 'Alerta Activa' : 'Alertas Activas'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revisa las alertas en la pestaña principal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.orange[700],
            size: 20,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
