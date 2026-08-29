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
        heroTag: 'budget_fab',
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
    _AddBudgetDialog.show(context);
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
    _AddBudgetDialog.show(context, existingBudget: budget);
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
  final bool? isBottomSheet;

  const _AddBudgetDialog({
    this.existingBudget,
    this.isBottomSheet,
  });

  static Future<void> show(
    BuildContext context, {
    Budget? existingBudget,
  }) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => _AddBudgetDialog(
          existingBudget: existingBudget,
          isBottomSheet: true,
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => _AddBudgetDialog(
          existingBudget: existingBudget,
          isBottomSheet: false,
        ),
      );
    }
  }

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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final limit = double.tryParse(_limitController.text.replaceAll(',', '.')) ?? 0.0;
    if (limit <= 0) return;

    final budget = Budget(
      id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      limit: limit,
      period: _selectedPeriod,
      startDate: DateTime.now(),
      alertThreshold: _alertThreshold,
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (widget.existingBudget == null) {
      ref.read(forecastProvider.notifier).addBudget(budget);
    } else {
      ref.read(forecastProvider.notifier).updateBudget(budget);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(financeProvider).categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = widget.isBottomSheet ?? (mediaQuery.size.width < 600);
    final isEditing = widget.existingBudget != null;

    final contentWidget = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre del presupuesto
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del presupuesto',
              hintText: 'Ej: Supermercado, Ocio, Restaurantes',
              prefixIcon: const Icon(Icons.label_outline_rounded),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
          ),
          const SizedBox(height: 12),

          // Selector de Categoría
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: const Icon(Icons.category_outlined),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Text(cat.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            validator: (value) => value == null ? 'Selecciona una categoría' : null,
          ),
          const SizedBox(height: 12),

          // Límite monetario y Período
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Límite',
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Requerido';
                    final v = double.tryParse(value.replaceAll(',', '.'));
                    if (v == null || v <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<BudgetPeriod>(
                  initialValue: _selectedPeriod,
                  decoration: InputDecoration(
                    labelText: 'Período',
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: BudgetPeriod.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period.spanishName),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedPeriod = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Umbral de alerta
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alerta de umbral de gasto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_alertThreshold * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _alertThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_alertThreshold * 100).toInt()}%',
                  onChanged: (val) => setState(() => _alertThreshold = val),
                ),
                Text(
                  'Te avisaremos cuando tus gastos alcancen el ${(_alertThreshold * 100).toInt()}% del límite.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Nota opcional
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Nota (opcional)',
              prefixIcon: const Icon(Icons.notes_rounded),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 18),

          // Botón Principal
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text(
              isEditing ? 'Guardar Cambios' : 'Crear Presupuesto',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );

    final headerBar = Row(
      children: [
        Icon(
          Icons.account_balance_wallet_rounded,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          isEditing ? 'Editar Presupuesto' : 'Nuevo Presupuesto',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.90,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: mediaQuery.viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                headerBar,
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: contentWidget,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.90,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            headerBar,
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: contentWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



