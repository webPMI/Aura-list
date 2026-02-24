import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/finance_enums.dart';
import '../providers/forecast_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/budget_progress_card.dart';

/// Pantalla de gestión de presupuestos.
/// Permite crear, editar y monitorear presupuestos por categoría.
class BudgetManagementScreen extends ConsumerWidget {
  const BudgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final activeBudgets = forecastState.activeBudgets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
            tooltip: 'Información',
          ),
        ],
      ),
      body: activeBudgets.isEmpty
          ? _buildEmptyState(context)
          : _buildBudgetList(context, ref, activeBudgets),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Presupuesto'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              'Crea presupuestos para controlar tus gastos\npor categoría y recibir alertas cuando te acerques al límite',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    WidgetRef ref,
    List<Budget> budgets,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BudgetCard(budget: budget),
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(),
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
            Text('Presupuestos'),
          ],
        ),
        content: const Text(
          'Los presupuestos te ayudan a controlar tus gastos estableciendo '
          'límites por categoría.\n\n'
          'Características:\n'
          '• Define límites diarios, semanales, mensuales o anuales\n'
          '• Recibe alertas cuando alcances el umbral (por defecto 80%)\n'
          '• Opción de arrastre del saldo no usado al próximo período\n'
          '• Visualiza el progreso en tiempo real',
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

class _BudgetCard extends ConsumerWidget {
  final Budget budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);

    // Calcular gasto actual en el período
    final now = DateTime.now();
    final periodStart = _getPeriodStart(budget.period, now);
    final periodEnd = _getPeriodEnd(budget.period, periodStart);

    final transactions = financeState.transactions.where((tx) {
      return tx.categoryId == budget.categoryId &&
          tx.date.isAfter(periodStart) &&
          tx.date.isBefore(periodEnd) &&
          tx.amount < 0; // Solo gastos
    }).toList();

    final spent = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount.abs(),
    );

    return BudgetProgressCard(
      categoryName: budget.name,
      budgetAmount: budget.limit,
      spentAmount: spent,
      startDate: periodStart,
      endDate: periodEnd,
      onTap: () => _showBudgetDetails(context, ref, budget, spent),
    );
  }

  DateTime _getPeriodStart(BudgetPeriod period, DateTime now) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case BudgetPeriod.weekly:
        final weekday = now.weekday;
        return now.subtract(Duration(days: weekday - 1));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.quarterly:
        final quarter = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarter, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _getPeriodEnd(BudgetPeriod period, DateTime start) {
    switch (period) {
      case BudgetPeriod.daily:
        return start.add(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(start.year, start.month + 1, 1);
      case BudgetPeriod.quarterly:
        return DateTime(start.year, start.month + 3, 1);
      case BudgetPeriod.yearly:
        return DateTime(start.year + 1, 1, 1);
    }
  }

  void _showBudgetDetails(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
    double spent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Límite: ${NumberFormat.simpleCurrency(locale: 'es_ES').format(budget.limit)}'),
            Text('Gastado: ${NumberFormat.simpleCurrency(locale: 'es_ES').format(spent)}'),
            Text('Período: ${budget.period.spanishName}'),
            if (budget.note?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text('Nota: ${budget.note}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditBudgetDialog(context, ref, budget);
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(context, ref, budget);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(existingBudget: budget),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text('¿Estás seguro de eliminar el presupuesto "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(forecastProvider.notifier).deleteBudget(budget.id);
              Navigator.of(context).pop();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetDialog extends ConsumerStatefulWidget {
  final Budget? existingBudget;

  const _AddBudgetDialog({this.existingBudget});

  @override
  ConsumerState<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  double _alertThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      final budget = widget.existingBudget!;
      _nameController.text = budget.name;
      _limitController.text = budget.limit.toString();
      _noteController.text = budget.note ?? '';
      _selectedCategoryId = budget.categoryId;
      _selectedPeriod = budget.period;
      _alertThreshold = budget.alertThreshold;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(financeProvider).categories;

    return AlertDialog(
      title: Text(widget.existingBudget == null
          ? 'Nuevo Presupuesto'
          : 'Editar Presupuesto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'ej: Supermercado',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: 'Límite',
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(value!) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                value: _selectedPeriod,
                decoration: const InputDecoration(labelText: 'Período'),
                items: BudgetPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.spanishName),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedPeriod = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final budget = Budget(
      id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      categoryId: _selectedCategoryId!,
      limit: double.parse(_limitController.text),
      period: _selectedPeriod,
      startDate: DateTime.now(),
      alertThreshold: _alertThreshold,
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (widget.existingBudget == null) {
      ref.read(forecastProvider.notifier).addBudget(budget);
    } else {
      ref.read(forecastProvider.notifier).updateBudget(budget);
    }

    Navigator.of(context).pop();
  }
}
