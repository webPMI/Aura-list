import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/finance/models/finance_category.dart';
import '../../features/finance/providers/finance_provider.dart';
import '../../features/finance/providers/forecast_provider.dart';
import '../../features/finance/widgets/unified_transaction_dialog.dart';
import '../../providers/navigation_provider.dart';

/// Tarjeta destacada de contabilidad y finanzas para el Dashboard principal
class FinancialSummaryCard extends ConsumerWidget {
  const FinancialSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalIncome = ref.watch(financeProvider.select((s) => s.totalIncome));
    final totalExpenses = ref.watch(financeProvider.select((s) => s.totalExpenses));
    final balance = ref.watch(financeProvider.select((s) => s.balance));
    final activeRecurringCount = ref.watch(forecastProvider.select((s) => s.activeRecurring.length));

    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final theme = Theme.of(context);
    final balanceColor = balance >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Título y enlace a sección completa
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Contabilidad y Finanzas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(navigationHistoryProvider.notifier)
                        .goTo(AppRoute.finance);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver todo'),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Saldo actual destacado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Saldo Neto:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  currencyFormat.format(balance),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comparativa de Ingresos vs Gastos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Ingresos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Ingresos',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(totalIncome),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  // Gastos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Gastos',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(totalExpenses),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recordatorio de recurrentes activos si existen
            if (activeRecurringCount > 0) ...[
              Row(
                children: [
                  const Icon(Icons.repeat, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    '$activeRecurringCount pagos/cobros recurrentes programados',
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Botones de Acción Rápida: + Gasto y + Ingreso
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const UnifiedTransactionDialog(
                          initialType: FinanceCategoryType.expense,
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                    label: const Text('Gasto', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const UnifiedTransactionDialog(
                          initialType: FinanceCategoryType.income,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                    label: const Text('Ingreso', style: TextStyle(color: Colors.green)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
