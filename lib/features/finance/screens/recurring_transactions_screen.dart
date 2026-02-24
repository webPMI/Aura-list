import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/forecast_provider.dart';
import '../widgets/recurring_transaction_list.dart';
import '../widgets/add_recurring_transaction_dialog.dart';

/// Pantalla de gestión de transacciones recurrentes.
/// Permite ver, crear, editar y eliminar transacciones recurrentes.
class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final activeRecurring = forecastState.activeRecurring;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones Recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
            tooltip: 'Información',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas rápidas
          if (activeRecurring.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    label: 'Total',
                    value: activeRecurring.length.toString(),
                    icon: Icons.repeat,
                  ),
                  _StatCard(
                    label: 'Ingresos',
                    value: activeRecurring
                        .where((rt) => rt.amount > 0)
                        .length
                        .toString(),
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                  ),
                  _StatCard(
                    label: 'Gastos',
                    value: activeRecurring
                        .where((rt) => rt.amount < 0)
                        .length
                        .toString(),
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          // Lista de transacciones recurrentes
          const Expanded(
            child: RecurringTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Recurrente'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddRecurringTransactionDialog(),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Text('Transacciones Recurrentes'),
          ],
        ),
        content: const Text(
          'Las transacciones recurrentes son ingresos o gastos que se repiten '
          'automáticamente según la frecuencia que configures.\n\n'
          'Útiles para:\n'
          '• Salarios y nóminas\n'
          '• Alquileres y hipotecas\n'
          '• Suscripciones y servicios\n'
          '• Facturas periódicas\n\n'
          'El sistema las usará para generar proyecciones de flujo de efectivo.',
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: displayColor,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}
