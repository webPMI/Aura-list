import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/recurrence_rule.dart';
import '../models/finance_category.dart';
import '../models/recurring_transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/forecast_provider.dart';

import '../models/transaction.dart';

/// Modal unificado y responsivo para registrar o editar gastos e ingresos (puntuales o recurrentes).
class UnifiedTransactionDialog extends ConsumerStatefulWidget {
  final FinanceCategoryType initialType;
  final bool? isBottomSheet;
  final RecurringTransaction? existingRecurringTransaction;
  final Transaction? existingTransaction;

  const UnifiedTransactionDialog({
    super.key,
    this.initialType = FinanceCategoryType.expense,
    this.isBottomSheet,
    this.existingRecurringTransaction,
    this.existingTransaction,
  });

  /// Muestra el modal de manera adaptativa:
  /// - En pantallas móviles (< 600px): Modal Bottom Sheet con esquinas redondeadas y padding optimizado.
  /// - En pantallas de escritorio / tablet (>= 600px): Diálogo flotante centrado.
  static Future<bool?> show(
    BuildContext context, {
    FinanceCategoryType initialType = FinanceCategoryType.expense,
    RecurringTransaction? existingRecurringTransaction,
    Transaction? existingTransaction,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final effectiveType = existingTransaction?.type ??
        existingRecurringTransaction?.type ??
        initialType;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => UnifiedTransactionDialog(
          initialType: effectiveType,
          isBottomSheet: true,
          existingRecurringTransaction: existingRecurringTransaction,
          existingTransaction: existingTransaction,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => UnifiedTransactionDialog(
          initialType: effectiveType,
          isBottomSheet: false,
          existingRecurringTransaction: existingRecurringTransaction,
          existingTransaction: existingTransaction,
        ),
      );
    }
  }

  @override
  ConsumerState<UnifiedTransactionDialog> createState() =>
      _UnifiedTransactionDialogState();
}

/// Frecuencias de registro disponibles
enum TransactionFrequencyMode {
  oneTime,    // Puntual (por defecto)
  daily,      // Diario
  weekly,     // Semanal
  biweekly,   // Quincenal (cada 2 semanas)
  monthly,    // Mensual
  quarterly,  // Trimestral (cada 3 meses)
  semiannual, // Semestral (cada 6 meses / 2 veces al año)
  yearly,     // Anual
}

extension TransactionFrequencyModeExtension on TransactionFrequencyMode {
  String get label {
    switch (this) {
      case TransactionFrequencyMode.oneTime:
        return 'Puntual';
      case TransactionFrequencyMode.daily:
        return 'Diario';
      case TransactionFrequencyMode.weekly:
        return 'Semanal';
      case TransactionFrequencyMode.biweekly:
        return 'Quincenal';
      case TransactionFrequencyMode.monthly:
        return 'Mensual';
      case TransactionFrequencyMode.quarterly:
        return 'Trimestral';
      case TransactionFrequencyMode.semiannual:
        return 'Semestral';
      case TransactionFrequencyMode.yearly:
        return 'Anual';
    }
  }

  String get description {
    switch (this) {
      case TransactionFrequencyMode.oneTime:
        return 'Un solo pago en la fecha indicada';
      case TransactionFrequencyMode.daily:
        return 'Todos los días';
      case TransactionFrequencyMode.weekly:
        return 'Cada semana';
      case TransactionFrequencyMode.biweekly:
        return 'Cada 2 semanas (quincenal)';
      case TransactionFrequencyMode.monthly:
        return 'Una vez al mes';
      case TransactionFrequencyMode.quarterly:
        return 'Cada 3 meses (4 veces al año)';
      case TransactionFrequencyMode.semiannual:
        return 'Cada 6 meses (2 veces al año)';
      case TransactionFrequencyMode.yearly:
        return 'Una vez al año';
    }
  }
}

class _UnifiedTransactionDialogState
    extends ConsumerState<UnifiedTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customInstallmentsController = TextEditingController();
  final _paidInstallmentsController = TextEditingController();
  final _uuid = const Uuid();

  late FinanceCategoryType _selectedType;
  TransactionFrequencyMode _frequencyMode = TransactionFrequencyMode.oneTime;
  DateTime _selectedDate = DateTime.now();
  FinanceCategory? _selectedCategory;

  // Parámetros de recurrencia semanal/mensual
  int _selectedDayOfWeek = DateTime.now().weekday;
  int _selectedDayOfMonth = DateTime.now().day;

  // Cuotas (installments)
  int? _totalInstallments; // null = indefinido
  int _paidInstallments = 0;
  String _installmentPaymentMode = 'automatic';
  bool _showCustomInstallments = false;

  // Creador inline de categoría
  bool _showCategoryCreator = false;
  final _newCategoryName = TextEditingController();
  Color _newCategoryColor = const Color(0xFF66BB6A);

  bool get _isEditing =>
      widget.existingRecurringTransaction != null ||
      widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final existingRec = widget.existingRecurringTransaction;
    final existingTx = widget.existingTransaction;

    if (existingRec != null) {
      _selectedType = existingRec.type;
      _titleController.text = existingRec.title;
      _amountController.text = existingRec.amount % 1 == 0
          ? existingRec.amount.toInt().toString()
          : existingRec.amount.toStringAsFixed(2);
      _noteController.text = existingRec.note ?? '';
      _selectedDate = existingRec.recurrence.startDate;
      _totalInstallments = existingRec.totalInstallments;
      _paidInstallments = existingRec.paidInstallments;
      _paidInstallmentsController.text = _paidInstallments.toString();
      _installmentPaymentMode = existingRec.installmentPaymentModeStr;

      // Infer frequency mode
      final rule = existingRec.recurrence;
      if (rule.preset == 'biweekly' || (rule.frequency == RecurrenceFrequency.weekly && rule.interval == 2)) {
        _frequencyMode = TransactionFrequencyMode.biweekly;
      } else if (rule.preset == 'quarterly' || (rule.frequency == RecurrenceFrequency.monthly && rule.interval == 3)) {
        _frequencyMode = TransactionFrequencyMode.quarterly;
      } else if (rule.preset == 'semiannual' || (rule.frequency == RecurrenceFrequency.monthly && rule.interval == 6)) {
        _frequencyMode = TransactionFrequencyMode.semiannual;
      } else if (rule.frequency == RecurrenceFrequency.yearly) {
        _frequencyMode = TransactionFrequencyMode.yearly;
      } else if (rule.frequency == RecurrenceFrequency.daily) {
        _frequencyMode = TransactionFrequencyMode.daily;
      } else if (rule.frequency == RecurrenceFrequency.weekly) {
        _frequencyMode = TransactionFrequencyMode.weekly;
        if (rule.byDays.isNotEmpty) {
          _selectedDayOfWeek = rule.byDays.first.isoValue;
        }
      } else {
        _frequencyMode = TransactionFrequencyMode.monthly;
        if (rule.byMonthDays.isNotEmpty) {
          _selectedDayOfMonth = rule.byMonthDays.first;
        }
      }

      if (_totalInstallments != null && ![3, 6, 12, 24, 36].contains(_totalInstallments)) {
        _showCustomInstallments = true;
        _customInstallmentsController.text = _totalInstallments.toString();
      }
    } else if (existingTx != null) {
      _selectedType = existingTx.type;
      _titleController.text = existingTx.title;
      _amountController.text = existingTx.amount % 1 == 0
          ? existingTx.amount.toInt().toString()
          : existingTx.amount.toStringAsFixed(2);
      _noteController.text = existingTx.note ?? '';
      _selectedDate = existingTx.date;
      _frequencyMode = TransactionFrequencyMode.oneTime;
      _paidInstallmentsController.text = '0';
    } else {
      _selectedType = widget.initialType;
      _paidInstallmentsController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _customInstallmentsController.dispose();
    _paidInstallmentsController.dispose();
    _newCategoryName.dispose();
    super.dispose();
  }

  Color _parseCategoryColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF66BB6A);
    try {
      var cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse('0x$cleanHex'));
    } catch (_) {
      return const Color(0xFF66BB6A);
    }
  }

  void _addQuickAmount(double addition) {
    final current = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final newAmount = current + addition;
    _amountController.text = newAmount % 1 == 0
        ? newAmount.toInt().toString()
        : newAmount.toStringAsFixed(2);
    setState(() {});
  }

  void _clearAmount() {
    _amountController.clear();
    setState(() {});
  }

  RecurrenceRule _buildRecurrenceRule() {
    switch (_frequencyMode) {
      case TransactionFrequencyMode.daily:
        return RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: _selectedDate,
        );
      case TransactionFrequencyMode.weekly:
        return RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          startDate: _selectedDate,
          byDays: [_intToWeekDay(_selectedDayOfWeek)],
        );
      case TransactionFrequencyMode.biweekly:
        return RecurrenceRule.biweekly(
          startDate: _selectedDate,
        );
      case TransactionFrequencyMode.quarterly:
        return RecurrenceRule.quarterly(
          startDate: _selectedDate,
        );
      case TransactionFrequencyMode.semiannual:
        return RecurrenceRule.semiannual(
          startDate: _selectedDate,
        );
      case TransactionFrequencyMode.yearly:
        return RecurrenceRule.yearly(
          startDate: _selectedDate,
        );
      case TransactionFrequencyMode.monthly:
      case TransactionFrequencyMode.oneTime:
        return RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: _selectedDate,
          byMonthDays: [_selectedDayOfMonth],
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    // 1. Modo Edición de Transacción Puntual
    if (widget.existingTransaction != null) {
      final updated = widget.existingTransaction!.copyWith(
        title: title,
        amount: amount,
        date: _selectedDate,
        categoryId: _selectedCategory?.id ?? widget.existingTransaction!.categoryId,
        type: _selectedType,
        note: note,
        lastUpdatedAt: DateTime.now(),
      );
      await ref.read(financeProvider.notifier).updateTransaction(updated);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // 2. Modo Edición de Transacción Recurrente / Cuota
    if (widget.existingRecurringTransaction != null) {
      final rule = _buildRecurrenceRule();
      final isNowComplete = _totalInstallments != null && _paidInstallments >= _totalInstallments!;

      final updated = widget.existingRecurringTransaction!.copyWith(
        title: title,
        amount: amount,
        categoryId: _selectedCategory?.id ?? widget.existingRecurringTransaction!.categoryId,
        type: _selectedType,
        recurrence: rule,
        autoGenerate: _installmentPaymentMode == 'automatic',
        installmentPaymentModeStr: _installmentPaymentMode,
        totalInstallments: _totalInstallments,
        paidInstallments: _paidInstallments,
        active: !isNowComplete,
        note: note,
        lastUpdatedAt: DateTime.now(),
      );

      await ref.read(forecastProvider.notifier).updateRecurringTransaction(updated);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // 3. Creación Nueva: Puntual vs Recurrente
    if (_frequencyMode == TransactionFrequencyMode.oneTime) {
      // Registro puntual (en la fecha seleccionada, pasada, presente o futura)
      await ref.read(financeProvider.notifier).addTransaction(
            title: title,
            amount: amount,
            date: _selectedDate,
            categoryId: _selectedCategory?.id,
            type: _selectedType,
            note: note,
          );
    } else {
      // Registro recurrente o por cuotas
      final rule = _buildRecurrenceRule();
      final isNowComplete = _totalInstallments != null && _paidInstallments >= _totalInstallments!;

      final recurringTx = RecurringTransaction(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        categoryId: _selectedCategory?.id,
        type: _selectedType,
        recurrence: rule,
        autoGenerate: _installmentPaymentMode == 'automatic',
        active: !isNowComplete,
        note: note,
        lastGenerated: _selectedDate.isAfter(DateTime.now()) ? null : _selectedDate,
        createdAt: DateTime.now(),
        totalInstallments: _totalInstallments,
        paidInstallments: _paidInstallments,
        deferredInstallments: 0,
        installmentPaymentModeStr: _installmentPaymentMode,
      );

      // Guardar regla recurrente
      await ref.read(forecastProvider.notifier).addRecurringTransaction(recurringTx);

      // Si la fecha de inicio no es en el futuro y NO se especificaron pagos previos, registrar el primer pago
      final isFutureStart = _selectedDate.isAfter(DateTime.now().add(const Duration(days: 1)));
      if (!isFutureStart && _paidInstallments == 0) {
        await ref.read(financeProvider.notifier).addTransaction(
              title: title,
              amount: amount,
              date: _selectedDate,
              categoryId: _selectedCategory?.id,
              type: _selectedType,
              note: note != null ? '$note (Recurrente)' : 'Inicio de recurrencia',
            );
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  WeekDay _intToWeekDay(int day) {
    switch (day) {
      case 1: return WeekDay.monday;
      case 2: return WeekDay.tuesday;
      case 3: return WeekDay.wednesday;
      case 4: return WeekDay.thursday;
      case 5: return WeekDay.friday;
      case 6: return WeekDay.saturday;
      default: return WeekDay.sunday;
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = widget.isBottomSheet ?? (mediaQuery.size.width < 600);

    final categories = financeState.categories
        .where((c) => c.type == _selectedType)
        .toList();

    final isExpense = _selectedType == FinanceCategoryType.expense;
    final primaryAccentColor = isExpense
        ? const Color(0xFFEF4444) // Rojo vibrante / Coral
        : const Color(0xFF10B981); // Verde esmeralda vibrante
    final surfaceTint = isExpense
        ? (isDark ? const Color(0xFF2C1517) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF132A22) : const Color(0xFFECFDF5));

    final contentWidget = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Selector Tipo (Tabs Gasto / Ingreso)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_selectedType != FinanceCategoryType.expense) {
                        setState(() {
                          _selectedType = FinanceCategoryType.expense;
                          _selectedCategory = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isExpense
                            ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFEF4444))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isExpense
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 18,
                            color: isExpense
                                ? Colors.white
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gasto',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isExpense ? FontWeight.bold : FontWeight.w500,
                              color: isExpense
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_selectedType != FinanceCategoryType.income) {
                        setState(() {
                          _selectedType = FinanceCategoryType.income;
                          _selectedCategory = null;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isExpense
                            ? (isDark ? const Color(0xFF065F46) : const Color(0xFF10B981))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: !isExpense
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: !isExpense
                                ? Colors.white
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ingreso',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: !isExpense ? FontWeight.bold : FontWeight.w500,
                              color: !isExpense
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Hero Amount Input con atajos rápidos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceTint,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primaryAccentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryAccentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '€',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryAccentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: primaryAccentColor,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: primaryAccentColor.withValues(alpha: 0.35),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un monto';
                          }
                          final val = double.tryParse(value.replaceAll(',', '.'));
                          if (val == null || val <= 0) return 'Monto no válido';
                          return null;
                        },
                      ),
                    ),
                    if (_amountController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 20),
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        onPressed: _clearAmount,
                        tooltip: 'Borrar',
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips de adición rápida
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final step in [5.0, 10.0, 20.0, 50.0, 100.0])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _addQuickAmount(step),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800.withValues(alpha: 0.7)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryAccentColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                '+${step.toInt()}€',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Concepto / Título
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Concepto / Título',
              hintText: 'Ej. Supermercado, Nómina, Gasolina...',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryAccentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa un concepto' : null,
          ),
          const SizedBox(height: 14),

          // 4. Categoría
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categoría',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showCategoryCreator = !_showCategoryCreator),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _showCategoryCreator ? Icons.close : Icons.add_circle_outline,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showCategoryCreator ? 'Cerrar' : 'Nueva categoría',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Creador inline de categoría
              if (_showCategoryCreator) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _newCategoryName,
                              decoration: const InputDecoration(
                                hintText: 'Nombre de categoría',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (_newCategoryName.text.trim().isEmpty) return;
                              final newCat = FinanceCategory(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: _newCategoryName.text.trim(),
                                icon: 'category',
                                color: '#${_newCategoryColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                type: _selectedType,
                                isDefault: false,
                              );
                              await ref.read(financeProvider.notifier).addCategory(newCat);
                              if (!mounted) return;
                              setState(() {
                                _showCategoryCreator = false;
                                _selectedCategory = newCat;
                                _newCategoryName.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            child: const Text('Crear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final c in [
                            const Color(0xFFEF5350),
                            const Color(0xFFFF7043),
                            const Color(0xFFFFA726),
                            const Color(0xFF66BB6A),
                            const Color(0xFF26A69A),
                            const Color(0xFF42A5F5),
                            const Color(0xFFAB47BC),
                            const Color(0xFF78909C),
                          ])
                            GestureDetector(
                              onTap: () => setState(() => _newCategoryColor = c),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _newCategoryColor == c
                                        ? (isDark ? Colors.white : Colors.black)
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Categorías chips horizontales / selector fluido
              if (categories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: CircleAvatar(
                              backgroundColor: _parseCategoryColor(cat.color),
                              radius: 6,
                            ),
                            label: Text(cat.name),
                            selected: _selectedCategory?.id == cat.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : null;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            showCheckmark: false,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No hay categorías para este tipo. Crea una arriba.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Selector Frecuencia (Puntual vs Recurrente)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _frequencyMode = TransactionFrequencyMode.oneTime),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _frequencyMode == TransactionFrequencyMode.oneTime
                            ? (isDark ? Colors.grey.shade800 : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _frequencyMode == TransactionFrequencyMode.oneTime
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: 16,
                            color: _frequencyMode == TransactionFrequencyMode.oneTime
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Puntual',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _frequencyMode == TransactionFrequencyMode.oneTime
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _frequencyMode == TransactionFrequencyMode.oneTime
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_frequencyMode == TransactionFrequencyMode.oneTime) {
                        setState(() => _frequencyMode = TransactionFrequencyMode.monthly);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _frequencyMode != TransactionFrequencyMode.oneTime
                            ? (isDark ? Colors.grey.shade800 : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _frequencyMode != TransactionFrequencyMode.oneTime
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 16,
                            color: _frequencyMode != TransactionFrequencyMode.oneTime
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Recurrente',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _frequencyMode != TransactionFrequencyMode.oneTime
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _frequencyMode != TransactionFrequencyMode.oneTime
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 6. Configuración según frecuencia
          if (_frequencyMode == TransactionFrequencyMode.oneTime) ...[
            // Selector de fecha puntual (pasada, presente o futura)
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDate.isAfter(DateTime.now().add(const Duration(days: 1)))
                                ? 'Fecha programada (Gasto a futuro)'
                                : 'Fecha de registro',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedDate.isAfter(DateTime.now().add(const Duration(days: 1)))
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedDate.isAfter(DateTime.now().add(const Duration(days: 1)))
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Panel de configuración recurrente
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.blue.shade50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Periodicidad ampliada
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Periodicidad de pago',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        _frequencyMode.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final mode in [
                          TransactionFrequencyMode.daily,
                          TransactionFrequencyMode.weekly,
                          TransactionFrequencyMode.biweekly,
                          TransactionFrequencyMode.monthly,
                          TransactionFrequencyMode.quarterly,
                          TransactionFrequencyMode.semiannual,
                          TransactionFrequencyMode.yearly,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(
                                mode.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _frequencyMode == mode,
                              onSelected: (_) => setState(() => _frequencyMode = mode),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fecha de inicio / primer cobro
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de inicio / primer cobro',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                                Text(
                                  DateFormat('d MMMM yyyy', 'es').format(_selectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_calendar_rounded, size: 16, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_frequencyMode == TransactionFrequencyMode.weekly)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDayOfWeek,
                      decoration: InputDecoration(
                        labelText: 'Día de cobro/pago semanal',
                        prefixIcon: const Icon(Icons.event_repeat_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Lunes')),
                        DropdownMenuItem(value: 2, child: Text('Martes')),
                        DropdownMenuItem(value: 3, child: Text('Miércoles')),
                        DropdownMenuItem(value: 4, child: Text('Jueves')),
                        DropdownMenuItem(value: 5, child: Text('Viernes')),
                        DropdownMenuItem(value: 6, child: Text('Sábado')),
                        DropdownMenuItem(value: 7, child: Text('Domingo')),
                      ],
                      onChanged: (val) => setState(() => _selectedDayOfWeek = val ?? 1),
                    )
                  else if (_frequencyMode == TransactionFrequencyMode.monthly ||
                      _frequencyMode == TransactionFrequencyMode.quarterly ||
                      _frequencyMode == TransactionFrequencyMode.semiannual)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDayOfMonth,
                      decoration: InputDecoration(
                        labelText: 'Día del mes para el cobro',
                        prefixIcon: const Icon(Icons.calendar_month_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        for (int i = 1; i <= 31; i++)
                          DropdownMenuItem(value: i, child: Text('Día $i')),
                      ],
                      onChanged: (val) => setState(() => _selectedDayOfMonth = val ?? 1),
                    ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Cuotas
                  Text(
                    'Número total de cuotas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final n in [null, 3, 6, 12, 24, 36])
                        ChoiceChip(
                          label: Text(n == null ? 'Sin límite' : '$n cuotas'),
                          selected: n == null
                              ? (_totalInstallments == null && !_showCustomInstallments)
                              : (_totalInstallments == n && !_showCustomInstallments),
                          onSelected: (_) => setState(() {
                            _totalInstallments = n;
                            _showCustomInstallments = false;
                            _customInstallmentsController.clear();
                          }),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ChoiceChip(
                        label: const Text('Otro...'),
                        selected: _showCustomInstallments,
                        onSelected: (_) => setState(() {
                          _showCustomInstallments = true;
                          _totalInstallments = null;
                        }),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),

                  if (_showCustomInstallments) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customInstallmentsController,
                      decoration: InputDecoration(
                        labelText: 'Número exacto de cuotas',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        setState(() => _totalInstallments = parsed);
                      },
                      validator: (val) {
                        if (!_showCustomInstallments) return null;
                        final n = int.tryParse(val ?? '');
                        if (n == null || n < 1) return 'Ingresa un número válido';
                        return null;
                      },
                    ),
                  ],

                  // Campo para editar cuotas ya pagadas / adelantadas
                  if (_totalInstallments != null || _isEditing) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _paidInstallmentsController,
                      decoration: InputDecoration(
                        labelText: 'Cuotas ya pagadas / adelantadas',
                        prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                        helperText: 'Ajusta este número si ya adelantaste pagos',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          setState(() => _paidInstallments = parsed);
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Modo de pago
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _installmentPaymentMode = 'automatic'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _installmentPaymentMode == 'automatic'
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _installmentPaymentMode == 'automatic'
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                const Text('Automático', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _installmentPaymentMode = 'manual'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _installmentPaymentMode == 'manual'
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _installmentPaymentMode == 'manual'
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app_rounded, size: 16, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                const Text('Manual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Resumen total si hay cuotas
                  if (_amountController.text.isNotEmpty && _totalInstallments != null) ...[
                    const SizedBox(height: 10),
                    Builder(builder: (ctx) {
                      final amount = double.tryParse(
                              _amountController.text.replaceAll(',', '.')) ??
                          0;
                      final total = amount * _totalInstallments!;
                      final remaining = (_totalInstallments! - _paidInstallments).clamp(0, _totalInstallments!);
                      final remainingAmt = remaining * amount;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Total: ${NumberFormat.simpleCurrency(locale: 'es_ES').format(total)} en $_totalInstallments cuotas',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_paidInstallments > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Pagado: $_paidInstallments cuotas (${NumberFormat.simpleCurrency(locale: 'es_ES').format(_paidInstallments * amount)}) | Restante: $remaining cuotas (${NumberFormat.simpleCurrency(locale: 'es_ES').format(remainingAmt)})',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 7. Nota opcional
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Nota adicional (opcional)',
              prefixIcon: const Icon(Icons.notes_rounded),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryAccentColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // 8. Botón Principal de Acción
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text(
              _isEditing
                  ? 'Guardar Cambios'
                  : (_frequencyMode == TransactionFrequencyMode.oneTime
                      ? (isExpense ? 'Registrar Gasto' : 'Registrar Ingreso')
                      : 'Programar Recurrente'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccentColor,
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

    // Cabecera compartida
    Widget headerBar = Row(
      children: [
        Icon(
          isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: primaryAccentColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          _isEditing
              ? 'Editar Compromiso'
              : (isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    // Si se muestra como BottomSheet en móvil
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
                // Drag handle
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
                const SizedBox(height: 8),
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

    // Si se muestra como Diálogo flotante (Escritorio / Tablet)
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
            const SizedBox(height: 12),
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
