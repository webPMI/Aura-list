import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../providers/forecast_provider.dart';
import '../widgets/installment_progress_card.dart';
import '../widgets/unified_transaction_dialog.dart';

/// Pantalla de resumen de cuotas y compromisos financieros.
class InstallmentsOverviewScreen extends ConsumerWidget {
  const InstallmentsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final all = forecastState.activeRecurring;

    // Separar en grupos
    final withInstallments = all.where((t) => t.hasFixedInstallments).toList()
      ..sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        final aEnd = a.expectedEndDate;
        final bEnd = b.expectedEndDate;
        if (aEnd == null) return 1;
        if (bEnd == null) return -1;
        return aEnd.compareTo(bEnd);
      });

    final indefinite = all.where((t) => !t.hasFixedInstallments).toList();

    final inProgress = withInstallments.where((t) => !t.isCompleted).toList();
    final completed = withInstallments.where((t) => t.isCompleted).toList();

    // Estadísticas globales
    final totalMonthlyCommitment = inProgress
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalRemainingDebt = inProgress
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + (t.remainingAmount ?? 0));

    final currency = NumberFormat.simpleCurrency(locale: 'es_ES');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuotas y Compromisos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nuevo compromiso',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const UnifiedTransactionDialog(),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Panel de resumen global ───────────────────────────
          SliverToBoxAdapter(
            child: _GlobalSummaryPanel(
              totalMonthly: totalMonthlyCommitment,
              totalRemaining: totalRemainingDebt,
              activeCount: inProgress.length,
              completedCount: completed.length,
              indefiniteCount: indefinite.length,
              currency: currency,
            ),
          ),

          // ── En progreso ───────────────────────────────────────
          if (inProgress.isNotEmpty) ...[
            _sectionHeader(context, '📋 En Progreso (${inProgress.length})'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => InstallmentProgressCard(
                    transaction: inProgress[i],
                    onPayInstallment: () => _handlePayInstallment(
                        context, ref, inProgress[i]),
                    onDefer: () =>
                        _handleDefer(context, ref, inProgress[i]),
                  ),
                  childCount: inProgress.length,
                ),
              ),
            ),
          ],

          // ── Indefinidas ───────────────────────────────────────
          if (indefinite.isNotEmpty) ...[
            _sectionHeader(
                context, '🔁 Recurrentes Indefinidas (${indefinite.length})'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => InstallmentProgressCard(
                    transaction: indefinite[i],
                  ),
                  childCount: indefinite.length,
                ),
              ),
            ),
          ],

          // ── Completadas ───────────────────────────────────────
          if (completed.isNotEmpty) ...[
            _sectionHeader(
                context, '✅ Completadas (${completed.length})'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Opacity(
                    opacity: 0.65,
                    child: InstallmentProgressCard(
                      transaction: completed[i],
                    ),
                  ),
                  childCount: completed.length,
                ),
              ),
            ),
          ],

          // ── Estado vacío ──────────────────────────────────────
          if (all.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                onAdd: () => showDialog(
                  context: context,
                  builder: (_) => const UnifiedTransactionDialog(),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }

  Future<void> _handlePayInstallment(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Registrar pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Confirmas el pago de la cuota ${transaction.paidInstallments + 1} de ${transaction.totalInstallments} para:'),
            const SizedBox(height: 8),
            Text(
              transaction.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Monto: ${NumberFormat.simpleCurrency(locale: 'es_ES').format(transaction.amount)}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(forecastProvider.notifier).payInstallment(transaction);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transaction.isCompleted
                  ? '🎉 ¡${transaction.title} completado!'
                  : 'Cuota registrada: ${transaction.installmentSummary}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleDefer(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction transaction,
  ) async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            SizedBox(width: 8),
            Text('Aplazar cuota'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Cuota ${transaction.paidInstallments + 1} de ${transaction.totalInstallments}'),
            const SizedBox(height: 4),
            Text(transaction.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('¿Qué deseas hacer con esta cuota?',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'skip'),
            icon: const Icon(Icons.block, color: Colors.red, size: 16),
            label: const Text('Omitir cuota',
                style: TextStyle(color: Colors.red)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'defer'),
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Aplazar al siguiente'),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );

    if (option == null || !context.mounted) return;

    if (option == 'defer') {
      await ref.read(forecastProvider.notifier).deferInstallment(transaction);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuota aplazada al siguiente período'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (option == 'skip') {
      await ref.read(forecastProvider.notifier).skipInstallment(transaction);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuota omitida'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GlobalSummaryPanel extends StatelessWidget {
  final double totalMonthly;
  final double totalRemaining;
  final int activeCount;
  final int completedCount;
  final int indefiniteCount;
  final NumberFormat currency;

  const _GlobalSummaryPanel({
    required this.totalMonthly,
    required this.totalRemaining,
    required this.activeCount,
    required this.completedCount,
    required this.indefiniteCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'RESUMEN DE COMPROMISOS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStatCard(
                  label: 'Pago mensual',
                  value: currency.format(totalMonthly),
                  icon: Icons.calendar_month,
                  isMain: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStatCard(
                  label: 'Deuda total restante',
                  value: currency.format(totalRemaining),
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PillStat(label: '$activeCount activas', color: Colors.blue),
              const SizedBox(width: 8),
              _PillStat(label: '$completedCount completadas', color: Colors.green),
              const SizedBox(width: 8),
              _PillStat(label: '$indefiniteCount indefinidas', color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isMain;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isMain ? 30 : 15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMain ? 22 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final Color color;

  const _PillStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withAlpha(230),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 50,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin compromisos financieros',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Registra tus gastos fijos por cuotas:\nhipoteca, préstamos, suscripciones anuales...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Añadir compromiso'),
            ),
          ],
        ),
      ),
    );
  }
}
