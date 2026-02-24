import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_finance_link.dart';
import '../providers/forecast_provider.dart';

/// Badge que se muestra en las tarjetas de tarea para indicar impacto financiero.
/// Muestra el monto y el tipo de impacto (costo, beneficio, etc.)
class TaskFinancialImpactBadge extends ConsumerWidget {
  final String taskId;

  const TaskFinancialImpactBadge({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final taskLinks = forecastState.taskLinks
        .where((link) => link.taskId == taskId && !link.deleted)
        .toList();

    if (taskLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Si hay múltiples links, mostrar el más importante
    final link = _getMostImportantLink(taskLinks);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(link.impactType),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(link.impactType),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(link.impactType),
            size: 14,
            color: _getIconColor(link.impactType),
          ),
          const SizedBox(width: 4),
          Text(
            _formatAmount(link.estimatedAmount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(link.impactType),
            ),
          ),
          if (taskLinks.length > 1) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${taskLinks.length - 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(link.impactType),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtiene el link más importante (mayor monto absoluto).
  TaskFinanceLink _getMostImportantLink(List<TaskFinanceLink> links) {
    if (links.length == 1) return links.first;

    links.sort((a, b) => b.estimatedAmount.abs().compareTo(a.estimatedAmount.abs()));
    return links.first;
  }

  String _formatAmount(double amount) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'es_ES');
    final formattedAmount = currencyFormat.format(amount.abs());
    return formattedAmount;
  }

  Color _getBackgroundColor(FinancialImpactType type) {
    switch (type) {
      case FinancialImpactType.cost:
        return Colors.red[50]!;
      case FinancialImpactType.income:
      case FinancialImpactType.saving:
        return Colors.green[50]!;
    }
  }

  Color _getBorderColor(FinancialImpactType type) {
    switch (type) {
      case FinancialImpactType.cost:
        return Colors.red[200]!;
      case FinancialImpactType.income:
      case FinancialImpactType.saving:
        return Colors.green[200]!;
    }
  }

  Color _getIconColor(FinancialImpactType type) {
    switch (type) {
      case FinancialImpactType.cost:
        return Colors.red[700]!;
      case FinancialImpactType.income:
      case FinancialImpactType.saving:
        return Colors.green[700]!;
    }
  }

  Color _getTextColor(FinancialImpactType type) {
    switch (type) {
      case FinancialImpactType.cost:
        return Colors.red[900]!;
      case FinancialImpactType.income:
      case FinancialImpactType.saving:
        return Colors.green[900]!;
    }
  }

  IconData _getIcon(FinancialImpactType type) {
    switch (type) {
      case FinancialImpactType.cost:
        return Icons.money_off;
      case FinancialImpactType.income:
        return Icons.attach_money;
      case FinancialImpactType.saving:
        return Icons.trending_up;
    }
  }
}
