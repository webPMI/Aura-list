import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/savings_account.dart';
import '../providers/savings_provider.dart';
import 'add_savings_account_dialog.dart';

Color _parseColor(String hex) {
  try {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse(clean.length >= 8 ? clean : 'FF$clean', radix: 16));
  } catch (_) {
    return Colors.blueGrey;
  }
}

class SavingsAccountCard extends ConsumerWidget {
  final SavingsAccount account;

  const SavingsAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');
    final color = _parseColor(account.color);
    final projection = ref.watch(savingsAccountProjectionProvider(account.id));

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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(
                    account.type == SavingsAccountType.savings
                        ? Icons.savings
                        : Icons.trending_up,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${account.type.label} · ${account.annualInterestRate.toStringAsFixed(2)}% anual',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await AddSavingsAccountDialog.show(
                        context,
                        account: account,
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Saldo actual',
                    value: currencyFormat.format(account.currentBalance),
                    color: color,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: 'Aportación/mes',
                    value: currencyFormat.format(account.monthlyContribution),
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Ganancia',
                    value:
                        '${currencyFormat.format(account.gainedAmount)} (${account.totalReturnPercentage.toStringAsFixed(1)}%)',
                    color: account.gainedAmount >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: 'Proyección 10 años',
                    value: currencyFormat.format(
                      projection.pointAt(120)?.balance ?? 0.0,
                    ),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text(
          '¿Eliminar la cuenta "${account.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(savingsProvider.notifier).deleteAccount(account.id);
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
