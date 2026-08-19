import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/recurrence_rule.dart';
import '../models/finance_category.dart';
import '../models/recurring_transaction.dart';
import '../providers/finance_provider.dart';
import '../providers/forecast_provider.dart';

/// Modal unificado para registrar gastos e ingresos (puntuales o recurrentes).
class UnifiedTransactionDialog extends ConsumerStatefulWidget {
  final FinanceCategoryType initialType;

  const UnifiedTransactionDialog({
    super.key,
    this.initialType = FinanceCategoryType.expense,
  });

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
  final _uuid = const Uuid();

  late FinanceCategoryType _selectedType;
  TransactionFrequencyMode _frequencyMode = TransactionFrequencyMode.oneTime;
  DateTime _selectedDate = DateTime.now();
  FinanceCategory? _selectedCategory;

  // Parámetros de recurrencia semanal/mensual
  int _selectedDayOfWeek = DateTime.now().weekday;
  int _selectedDayOfMonth = DateTime.now().day;

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
    _newCategoryName.dispose();
    super.dispose();
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
        autoGenerate: true,
        active: true,
        note: note,
        lastGenerated: _selectedDate,
        createdAt: DateTime.now(),
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
    final categories = financeState.categories
        .where((c) => c.type == _selectedType)
        .toList();

    // Vista de creación inline de categoría
    if (_showCategoryCreator) {
      return AlertDialog(
        title: const Text('Nueva Categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _newCategoryName,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _newCategoryColor == c ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showCategoryCreator = false),
            child: const Text('Cancelar'),
          ),
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
            child: const Text('Guardar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(_selectedType == FinanceCategoryType.expense ? 'Nuevo Gasto' : 'Nuevo Ingreso'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector Tipo: Gasto / Ingreso
              SegmentedButton<FinanceCategoryType>(
                segments: const [
                  ButtonSegment(
                    value: FinanceCategoryType.expense,
                    label: Text('Gasto'),
                    icon: Icon(Icons.arrow_downward, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: FinanceCategoryType.income,
                    label: Text('Ingreso'),
                    icon: Icon(Icons.arrow_upward, color: Colors.green),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedType = set.first;
                    _selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. Selector Frecuencia (Puntual por defecto vs Recurrentes)
              const Text(
                'Frecuencia',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              SegmentedButton<TransactionFrequencyMode>(
                segments: const [
                  ButtonSegment(
                    value: TransactionFrequencyMode.oneTime,
                    label: Text('Puntual'),
                    icon: Icon(Icons.flash_on, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionFrequencyMode.daily,
                    label: Text('Diario'),
                  ),
                  ButtonSegment(
                    value: TransactionFrequencyMode.weekly,
                    label: Text('Sem.'),
                  ),
                  ButtonSegment(
                    value: TransactionFrequencyMode.monthly,
                    label: Text('Mens.'),
                  ),
                ],
                selected: {_frequencyMode},
                onSelectionChanged: (set) {
                  setState(() => _frequencyMode = set.first);
                },
              ),
              const SizedBox(height: 16),

              // 3. Monto y Título
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad (€)',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa un monto';
                  final val = double.tryParse(value.replaceAll(',', '.'));
                  if (val == null || val <= 0) return 'Monto no válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Concepto / Título',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa un concepto' : null,
              ),
              const SizedBox(height: 12),

              // 4. Categoría
              DropdownButtonFormField<FinanceCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      )),
                  DropdownMenuItem(
                    value: null,
                    child: Row(
                      children: const [
                        Icon(Icons.add, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text('Nueva categoría...', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ],
                onChanged: (cat) {
                  if (cat == null && categories.isNotEmpty) {
                    setState(() => _showCategoryCreator = true);
                  } else {
                    setState(() => _selectedCategory = cat);
                  }
                },
              ),
              const SizedBox(height: 12),

              // 5. Configuración según frecuencia
              if (_frequencyMode == TransactionFrequencyMode.oneTime)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate)),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                )
              else if (_frequencyMode == TransactionFrequencyMode.weekly)
                DropdownButtonFormField<int>(
                  initialValue: _selectedDayOfWeek,
                  decoration: const InputDecoration(
                    labelText: 'Día de cobro/pago semanal',
                    prefixIcon: Icon(Icons.event_repeat),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Día del mes (1 - 31)',
                    prefixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (int i = 1; i <= 31; i++)
                      DropdownMenuItem(value: i, child: Text('Día $i de cada mes')),
                  ],
                  onChanged: (val) => setState(() => _selectedDayOfMonth = val ?? 1),
                ),

              const SizedBox(height: 12),

              // 6. Nota opcional
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota adicional (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: Text(
            _frequencyMode == TransactionFrequencyMode.oneTime
                ? 'Registrar'
                : 'Programar Recurrente',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedType == FinanceCategoryType.expense
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
          ),
        ),
      ],
    );
  }
}
