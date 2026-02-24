import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card mostrando progreso de presupuesto con barra de progreso y alertas
class BudgetProgressCard extends StatelessWidget {
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    final percentage = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0.0;
    final percentageDisplay = (percentage * 100).clamp(0, 100);
    final remaining = budgetAmount - spentAmount;
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    final totalDays = endDate.difference(startDate).inDays;
    final daysElapsed = totalDays - daysRemaining;

    // Determinar color según porcentaje usado
    Color progressColor;
    Color backgroundColor;
    IconData alertIcon;
    String? alertMessage;

    if (percentage < 0.75) {
      // Verde: menos del 75%
      progressColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
      alertIcon = Icons.check_circle;
      alertMessage = null;
    } else if (percentage < 0.90) {
      // Amarillo: 75-90%
      progressColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
      alertIcon = Icons.warning;
      alertMessage = 'Te acercas al límite del presupuesto';
    } else {
      // Rojo: más del 90%
      progressColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
      alertIcon = Icons.error;
      alertMessage = percentage >= 1.0
          ? 'Presupuesto excedido'
          : 'Presupuesto casi agotado';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    alertIcon,
                    color: progressColor,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: progressColor,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),

              // Información de cantidades
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastado',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(spentAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Presupuesto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(budgetAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información adicional
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.account_balance_wallet,
                      label: 'Restante',
                      value: currencyFormat.format(remaining.clamp(0, double.infinity)),
                      color: remaining > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.calendar_today,
                      label: 'Días restantes',
                      value: daysRemaining > 0 ? '$daysRemaining días' : 'Finalizado',
                      color: daysRemaining > 0 ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),

              // Porcentaje
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${percentageDisplay.toStringAsFixed(1)}% usado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ),

              // Mensaje de alerta si existe
              if (alertMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: progressColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alertIcon,
                        size: 16,
                        color: progressColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alertMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: progressColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Indicador de tiempo
              if (daysRemaining > 0 && totalDays > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: daysElapsed / totalDays,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          color: Colors.blue.withOpacity(0.5),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((daysElapsed / totalDays) * 100).toStringAsFixed(0)}% del período',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget auxiliar para mostrar información en chips
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
