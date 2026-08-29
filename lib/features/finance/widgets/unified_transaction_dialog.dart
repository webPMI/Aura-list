import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/recurrence_rule.dart';
import '../models/finance_category.dart';
import '../models/recurring_transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/forecast_provider.dart';

/// Modal unificado y responsivo para registrar gastos e ingresos (puntuales o recurrentes).
class UnifiedTransactionDialog extends ConsumerStatefulWidget {
  final FinanceCategoryType initialType;
  final bool? isBottomSheet;

  const UnifiedTransactionDialog({
    super.key,
    this.initialType = FinanceCategoryType.expense,
    this.isBottomSheet,
  });

  /// Muestra el modal de manera adaptativa:
  /// - En pantallas móviles (< 600px): Modal Bottom Sheet con esquinas redondeadas y padding optimizado.
  /// - En pantallas de escritorio / tablet (>= 600px): Diálogo flotante centrado.
  static Future<bool?> show(
    BuildContext context, {
    FinanceCategoryType initialType = FinanceCategoryType.expense,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => UnifiedTransactionDialog(
          initialType: initialType,
          isBottomSheet: true,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => UnifiedTransactionDialog(
          initialType: initialType,
          isBottomSheet: false,
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
  oneTime, // Puntual (por defecto)
  daily,   // Diario
  weekly,  // Semanal
  monthly, // Mensual
}

class _UnifiedTransactionDialogState
    extends ConsumerState<UnifiedTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customInstallmentsController = TextEditingController();
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
  String _installmentPaymentMode = 'automatic';
  bool _showCustomInstallments = false;

  // Creador inline de categoría
  bool _showCategoryCreator = false;
  final _newCategoryName = TextEditingController();
  Color _newCategoryColor = const Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _customInstallmentsController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    if (_frequencyMode == TransactionFrequencyMode.oneTime) {
      // 1. Registro puntual (por defecto)
      await ref.read(financeProvider.notifier).addTransaction(
            title: title,
            amount: amount,
            date: _selectedDate,
            categoryId: _selectedCategory?.id,
            type: _selectedType,
            note: note,
          );
    } else {
      // 2. Registro recurrente
      late RecurrenceRule rule;
      if (_frequencyMode == TransactionFrequencyMode.daily) {
        rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: _selectedDate,
        );
      } else if (_frequencyMode == TransactionFrequencyMode.weekly) {
        rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          startDate: _selectedDate,
          byDays: [_intToWeekDay(_selectedDayOfWeek)],
        );
      } else {
        rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: _selectedDate,
          byMonthDays: [_selectedDayOfMonth],
        );
      }

      final recurringTx = RecurringTransaction(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        categoryId: _selectedCategory?.id,
        type: _selectedType,
        recurrence: rule,
        autoGenerate: _installmentPaymentMode == 'automatic',
        active: true,
        note: note,
        lastGenerated: _selectedDate,
        createdAt: DateTime.now(),
        totalInstallments: _totalInstallments,
        paidInstallments: 0,
        deferredInstallments: 0,
        installmentPaymentModeStr: _installmentPaymentMode,
      );

      // Guardar regla recurrente
      await ref.read(forecastProvider.notifier).addRecurringTransaction(recurringTx);

      // Registrar también la primera transacción del período actual
      await ref.read(financeProvider.notifier).addTransaction(
            title: title,
            amount: amount,
            date: _selectedDate,
            categoryId: _selectedCategory?.id,
            type: _selectedType,
            note: note != null ? '$note (Recurrente)' : 'Inicio de recurrencia',
          );
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
            // Selector de fecha puntual
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
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
                            'Fecha de registro',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
                  // Periodicidad (Diario / Semanal / Mensual)
                  Text(
                    'Periodicidad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final mode in [
                        TransactionFrequencyMode.daily,
                        TransactionFrequencyMode.weekly,
                        TransactionFrequencyMode.monthly,
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(
                                  mode == TransactionFrequencyMode.daily
                                      ? 'Diario'
                                      : (mode == TransactionFrequencyMode.weekly ? 'Semanal' : 'Mensual'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              selected: _frequencyMode == mode,
                              onSelected: (_) => setState(() => _frequencyMode = mode),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                  else if (_frequencyMode == TransactionFrequencyMode.monthly)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDayOfMonth,
                      decoration: InputDecoration(
                        labelText: 'Día del mes',
                        prefixIcon: const Icon(Icons.calendar_month_rounded, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        for (int i = 1; i <= 31; i++)
                          DropdownMenuItem(value: i, child: Text('Día $i de cada mes')),
                      ],
                      onChanged: (val) => setState(() => _selectedDayOfMonth = val ?? 1),
                    ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Cuotas
                  Text(
                    'Número de cuotas',
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
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
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
              _frequencyMode == TransactionFrequencyMode.oneTime
                  ? (isExpense ? 'Registrar Gasto' : 'Registrar Ingreso')
                  : 'Programar Recurrente',
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
          isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso',
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
