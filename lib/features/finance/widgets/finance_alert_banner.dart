import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_alert.dart';
import '../models/finance_enums.dart';
import '../providers/forecast_provider.dart';

/// Banner que muestra alertas financieras activas en la parte superior de la pantalla.
/// Las alertas se pueden desestimar o marcar como leídas.
class FinanceAlertBanner extends ConsumerWidget {
  const FinanceAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(activeAlertsProvider);

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Mostrar solo la alerta más reciente o más crítica
    final alert = _getMostImportantAlert(alerts);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getAlertColor(alert.severity),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAlertDetails(context, alert),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _getAlertIcon(alert.type),
                  color: _getIconColor(alert.severity),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _getTextColor(alert.severity),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTextColor(alert.severity).withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (alerts.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${alerts.length - 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(alert.severity),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _getTextColor(alert.severity),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dismissAlert(ref, alert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Obtiene la alerta más importante según severidad y tipo.
  FinanceAlert _getMostImportantAlert(List<FinanceAlert> alerts) {
    if (alerts.length == 1) return alerts.first;

    // Ordenar por severidad (critical > warning > info)
    alerts.sort((a, b) {
      final severityOrder = {
        AlertSeverity.critical: 3,
        AlertSeverity.warning: 2,
        AlertSeverity.info: 1,
      };
      return (severityOrder[b.severity] ?? 0)
          .compareTo(severityOrder[a.severity] ?? 0);
    });

    return alerts.first;
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[50]!;
      case AlertSeverity.warning:
        return Colors.orange[50]!;
      case AlertSeverity.info:
        return Colors.blue[50]!;
    }
  }

  Color _getIconColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[700]!;
      case AlertSeverity.warning:
        return Colors.orange[700]!;
      case AlertSeverity.info:
        return Colors.blue[700]!;
    }
  }

  Color _getTextColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red[900]!;
      case AlertSeverity.warning:
        return Colors.orange[900]!;
      case AlertSeverity.info:
        return Colors.blue[900]!;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.budgetExceeded:
        return Icons.warning_amber_rounded;
      case AlertType.budgetWarning:
        return Icons.info_outline;
      case AlertType.negativeCashFlow:
        return Icons.trending_down;
      case AlertType.unusualExpense:
        return Icons.attach_money;
      case AlertType.unusualIncome:
        return Icons.monetization_on;
      case AlertType.recurringTransactionDue:
        return Icons.schedule;
      case AlertType.lowBalance:
        return Icons.account_balance_wallet;
    }
  }

  void _showAlertDetails(BuildContext context, FinanceAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: _getIconColor(alert.severity),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(alert.title),
            ),
          ],
        ),
        content: Text(alert.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _dismissAlert(WidgetRef ref, FinanceAlert alert) {
    ref.read(forecastProvider.notifier).dismissAlert(alert);
  }
}
