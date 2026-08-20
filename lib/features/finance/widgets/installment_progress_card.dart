import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';

/// Tarjeta premium que muestra el progreso de pago de un gasto por cuotas.
class InstallmentProgressCard extends StatelessWidget {
  final RecurringTransaction transaction;
  final VoidCallback? onPayInstallment;
  final VoidCallback? onDefer;
  final VoidCallback? onTap;

  const InstallmentProgressCard({
    super.key,
    required this.transaction,
    this.onPayInstallment,
    this.onDefer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(locale: 'es_ES');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final isExpense = transaction.isExpense;
    final baseColor = isExpense
        ? const Color(0xFFE53935) // rojo premium
        : const Color(0xFF43A047); // verde premium
    final bgColor = isExpense
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);

    final progress = transaction.installmentProgress;
    final isCompleted = transaction.isCompleted;
    final hasFixed = transaction.hasFixedInstallments;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withAlpha(80)
                : baseColor.withAlpha(40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Icono
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpense ? Icons.credit_card : Icons.savings,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título y badge de estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusBadge(transaction: transaction),
                            const SizedBox(width: 8),
                            Text(
                              transaction.recurrenceDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Monto mensual
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isExpense ? '-' : '+'}${currency.format(transaction.amount)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: baseColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'por cuota',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Cuerpo ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de progreso (solo si tiene cuotas fijas)
                  if (hasFixed) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.installmentSummary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.green[700] : null,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? Colors.green : baseColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Stats row ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.payments_outlined,
                          label: 'Pagado',
                          value: currency.format(transaction.paidAmount),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (transaction.remainingAmount != null)
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.pending_outlined,
                            label: 'Restante',
                            value: currency.format(transaction.remainingAmount!),
                            color: baseColor,
                          ),
                        ),
                      if (transaction.totalAmount != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.calculate_outlined,
                            label: 'Total',
                            value: currency.format(transaction.totalAmount!),
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Fechas ──────────────────────────────────────
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Inicio: ${dateFormat.format(transaction.recurrence.startDate)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      if (transaction.expectedEndDate != null) ...[
                        const Spacer(),
                        Icon(Icons.flag_outlined,
                            size: 13,
                            color: isCompleted ? Colors.green : Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Fin: ${dateFormat.format(transaction.expectedEndDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Acciones (modo manual) ───────────────────────
                  if (!isCompleted &&
                      transaction.paymentMode == InstallmentPaymentMode.manual &&
                      transaction.hasPendingManualPayment) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDefer,
                            icon: const Icon(Icons.schedule, size: 16),
                            label: const Text('Aplazar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onPayInstallment,
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Pagar cuota'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Aplazadas ──────────────────────────────────
                  if (transaction.deferredInstallments > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${transaction.deferredInstallments} cuota(s) aplazada(s)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final RecurringTransaction transaction;

  const _StatusBadge({required this.transaction});

  @override
  Widget build(BuildContext context) {
    if (transaction.isCompleted) {
      return _badge('COMPLETADO', Colors.green);
    }
    if (!transaction.hasFixedInstallments) {
      return _badge('INDEFINIDO', Colors.blueGrey);
    }
    if (transaction.paymentMode == InstallmentPaymentMode.manual) {
      return _badge('MANUAL', Colors.orange);
    }
    return _badge('AUTO', Colors.blue);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
