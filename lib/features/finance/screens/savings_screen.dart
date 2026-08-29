import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/savings_projection.dart';
import '../providers/savings_provider.dart';
import '../widgets/add_savings_account_dialog.dart';
import '../widgets/savings_account_card.dart';
import '../widgets/savings_projection_chart.dart';

/// Pantalla de cuentas de ahorro e inversión.
///
/// Muestra estadísticas generales y promedios del saldo, proyecciones por
/// hitos temporales (1, 5, 10, 20 y 30 años) con interés compuesto, el
/// gráfico de simulación consolidado y la lista de cuentas del usuario.
class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);
    final stats = ref.watch(savingsOverallStatsProvider);
    final projection = ref.watch(combinedSavingsProjectionProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: state.accounts.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OverallStatsCard(stats: stats),
                  const SizedBox(height: 16),
                  _MilestonesCard(stats: stats),
                  const SizedBox(height: 16),
                  SavingsProjectionChart(projection: projection),
                  const SizedBox(height: 24),
                  Text(
                    'Mis cuentas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.accounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SavingsAccountCard(account: account),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context),
        icon: const Icon(Icons.savings_outlined),
        label: const Text('Añadir cuenta'),
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    AddSavingsAccountDialog.show(context);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Controla tus ahorros e inversiones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Registra tus cuentas de ahorro o inversión y proyecta su '
              'crecimiento a 1, 5, 10, 20 y 30 años con interés compuesto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => AddSavingsAccountDialog.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear mi primera cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallStatsCard extends StatelessWidget {
  final SavingsOverallStats stats;
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(
    locale: 'es_ES',
  );

  _OverallStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final gainColor = stats.totalGained >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Resumen de ahorro e inversión',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.accountCount} cuenta${stats.accountCount == 1 ? '' : 's'} activa${stats.accountCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatDisplay(
                  label: 'Saldo total',
                  value: _currencyFormat.format(stats.totalCurrentBalance),
                  color: primaryColor,
                  icon: Icons.payments,
                ),
                const SizedBox(width: 8),
                _StatDisplay(
                  label: 'Aportación/mes',
                  value: _currencyFormat.format(stats.totalMonthlyContribution),
                  color: theme.colorScheme.secondary,
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatDisplay(
                  label: 'Ganancia total',
                  value: _currencyFormat.format(stats.totalGained),
                  color: gainColor,
                  icon: Icons.trending_up,
                ),
                const SizedBox(width: 8),
                _StatDisplay(
                  label: 'Rendimiento promedio',
                  value: '${stats.weightedAverageRate.toStringAsFixed(2)}%',
                  color: Colors.blue,
                  icon: Icons.percent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestonesCard extends StatelessWidget {
  final SavingsOverallStats stats;
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(
    locale: 'es_ES',
  );

  _MilestonesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = <int, SavingsMilestoneStats?>{
      1: stats.oneYear,
      5: stats.fiveYears,
      10: stats.tenYears,
      20: stats.twentyYears,
      30: stats.thirtyYears,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Proyección de tu futuro',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Saldo proyectado si mantienes tus aportaciones actuales',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: milestones.entries.map((entry) {
                final milestone = entry.value;
                if (milestone == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'A ${entry.key} años',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Sin datos',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _MilestoneRow(
                  years: entry.key,
                  balance: milestone.projectedBalance,
                  interest: milestone.interest,
                  currencyFormat: _currencyFormat,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final int years;
  final double balance;
  final double interest;
  final NumberFormat currencyFormat;

  const _MilestoneRow({
    required this.years,
    required this.balance,
    required this.interest,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final interestShare = balance <= 0
        ? 0.0
        : (interest / balance).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'A $years año${years == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                currencyFormat.format(balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: interestShare,
            backgroundColor: Colors.grey.shade200,
            color: Colors.orange,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          Text(
            'Interés generado: ${currencyFormat.format(interest)}',
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
          ),
        ],
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatDisplay({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
