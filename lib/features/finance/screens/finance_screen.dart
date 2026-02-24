import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/finance_dashboard.dart';
import '../widgets/transaction_list.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/finance_alert_banner.dart';
import '../widgets/recurring_transaction_list.dart';
import '../widgets/budget_progress_card.dart';
import '../providers/forecast_provider.dart';
import '../providers/finance_provider.dart';
import 'budget_management_screen.dart';
import 'forecast_screen.dart';

/// Pantalla principal de finanzas con sistema de tabs.
/// Incluye: Transacciones | Recurrentes | Presupuestos | Previsión
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAlertsCount = ref.watch(activeAlertsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (activeAlertsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        activeAlertsCount > 9 ? '9+' : '$activeAlertsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showAlerts(context),
            tooltip: 'Alertas',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Transacciones', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Recurrentes', icon: Icon(Icons.repeat)),
            Tab(text: 'Presupuestos', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Previsión', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner de alertas en la parte superior
          const FinanceAlertBanner(),
          // Contenido de los tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(),
                _buildRecurrentTab(),
                _buildBudgetsTab(),
                _buildForecastTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildTransactionsTab() {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceDashboard(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Transacciones Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TransactionList(),
        ],
      ),
    );
  }

  Widget _buildRecurrentTab() {
    return const RecurringTransactionList();
  }

  Widget _buildBudgetsTab() {
    final forecastState = ref.watch(forecastProvider);
    final financeState = ref.watch(financeProvider);
    final activeBudgets = forecastState.activeBudgets;

    if (activeBudgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Sin Presupuestos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea presupuestos para controlar tus gastos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BudgetManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Presupuesto'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeBudgets.length,
      itemBuilder: (context, index) {
        final budget = activeBudgets[index];

        // Calcular gasto actual
        final now = DateTime.now();
        final periodStart = _getPeriodStart(budget.period, now);
        final periodEnd = _getPeriodEnd(budget.period, periodStart);

        final transactions = financeState.transactions.where((tx) {
          return tx.categoryId == budget.categoryId &&
              tx.date.isAfter(periodStart) &&
              tx.date.isBefore(periodEnd) &&
              tx.amount < 0;
        }).toList();

        final spent = transactions.fold<double>(
          0,
          (sum, tx) => sum + tx.amount.abs(),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BudgetProgressCard(
            categoryName: budget.name,
            budgetAmount: budget.limit,
            spentAmount: spent,
            startDate: periodStart,
            endDate: periodEnd,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BudgetManagementScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildForecastTab() {
    return const ForecastScreen();
  }

  Widget? _buildFAB() {
    // Mostrar FAB solo en la pestaña de transacciones
    if (_tabController.index != 0) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () => _showAddTransaction(context),
      child: const Icon(Icons.add),
    );
  }

  void _showAddTransaction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
  }

  void _showAlerts(BuildContext context) {
    final alerts = ref.read(activeAlertsProvider);

    if (alerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay alertas activas')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Card(
            child: ListTile(
              leading: Icon(_getAlertIcon(alert.type)),
              title: Text(alert.title),
              subtitle: Text(alert.message),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(forecastProvider.notifier).dismissAlert(alert);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getAlertIcon(dynamic type) {
    // Esta es una implementación simple, debería usar el tipo correcto
    return Icons.warning;
  }

  DateTime _getPeriodStart(dynamic period, DateTime now) {
    final periodString = period.toString().split('.').last;
    switch (periodString) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final weekday = now.weekday;
        return now.subtract(Duration(days: weekday - 1));
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return now;
    }
  }

  DateTime _getPeriodEnd(dynamic period, DateTime start) {
    final periodString = period.toString().split('.').last;
    switch (periodString) {
      case 'daily':
        return start.add(const Duration(days: 1));
      case 'weekly':
        return start.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(start.year, start.month + 1, 1);
      case 'yearly':
        return DateTime(start.year + 1, 1, 1);
      default:
        return start;
    }
  }
}
