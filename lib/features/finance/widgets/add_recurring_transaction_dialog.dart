import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/finance_category.dart';
import '../../../models/recurrence_rule.dart';

/// Dialog para crear/editar transacciones recurrentes
class AddRecurringTransactionDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingTransaction;

  const AddRecurringTransactionDialog({
    super.key,
    this.existingTransaction,
  });

  @override
  ConsumerState<AddRecurringTransactionDialog> createState() =>
      _AddRecurringTransactionDialogState();
}

class _AddRecurringTransactionDialogState
    extends ConsumerState<AddRecurringTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _startDate = DateTime.now();
  FinanceCategory? _selectedCategory;
  FinanceCategoryType _selectedType = FinanceCategoryType.expense;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int _interval = 1;
  List<WeekDay> _selectedWeekDays = [];
  int? _selectedMonthDay;
  DateTime? _endDate;
  String? _linkedTaskId;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _loadExistingTransaction();
    }
  }

  void _loadExistingTransaction() {
    final transaction = widget.existingTransaction!;
    _titleController.text = transaction['title'] ?? '';
    _amountController.text = (transaction['amount'] ?? 0.0).toString();
    _noteController.text = transaction['note'] ?? '';
    _selectedType = transaction['type'] ?? FinanceCategoryType.expense;
    _startDate = transaction['startDate'] ?? DateTime.now();
    // TODO: Cargar más campos cuando el modelo esté completo
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Conectar con financeProvider cuando esté disponible
    final categories = <FinanceCategory>[];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existingTransaction == null
                  ? 'Nueva Transacción Recurrente'
                  : 'Editar Transacción Recurrente',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tipo: Ingreso/Gasto
                SegmentedButton<FinanceCategoryType>(
                  segments: const [
                    ButtonSegment(
                      value: FinanceCategoryType.expense,
                      label: Text('Gasto'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: FinanceCategoryType.income,
                      label: Text('Ingreso'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<FinanceCategoryType> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),

                // Cantidad
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (double.tryParse(value) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Categoría
                DropdownButtonFormField<FinanceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) => value == null ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                // Sección de Recurrencia
                Text(
                  'Recurrencia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Frecuencia
                DropdownButtonFormField<RecurrenceFrequency>(
                  value: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: RecurrenceFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq.spanishName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                        _selectedWeekDays = [];
                        _selectedMonthDay = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Intervalo
                if (_frequency != RecurrenceFrequency.daily)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cada $_interval ${_getIntervalLabel()}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _interval > 1
                                ? () => setState(() => _interval--)
                                : null,
                          ),
                          Text(
                            '$_interval',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _interval++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Selector de días (semanal)
                if (_frequency == RecurrenceFrequency.weekly)
                  _buildWeekDaySelector(),

                // Selector de día del mes (mensual)
                if (_frequency == RecurrenceFrequency.monthly)
                  _buildMonthDaySelector(),

                // Fecha de inicio
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Fecha de inicio'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),

                // Fecha de fin (opcional)
                SwitchListTile(
                  title: const Text('Fecha de fin'),
                  subtitle: _endDate != null
                      ? Text(DateFormat('dd/MM/yyyy').format(_endDate!))
                      : const Text('Sin fecha de fin'),
                  value: _endDate != null,
                  onChanged: (value) async {
                    if (value) {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate.add(const Duration(days: 365)),
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    } else {
                      setState(() => _endDate = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Nota
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Añade una descripción',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Vincular con tarea (opcional)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Vincular con tarea'),
                  subtitle: _linkedTaskId != null
                      ? const Text('Tarea vinculada')
                      : const Text('Sin vincular'),
                  trailing: _linkedTaskId != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _linkedTaskId = null),
                        )
                      : null,
                  onTap: () {
                    // TODO: Abrir selector de tareas
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selector de tareas próximamente'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Días de la semana:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: WeekDay.values.map((day) {
            final isSelected = _selectedWeekDays.contains(day);
            return FilterChip(
              label: Text(day.spanishShortName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekDays.add(day);
                  } else {
                    _selectedWeekDays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMonthDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          value: _selectedMonthDay,
          decoration: const InputDecoration(
            labelText: 'Día del mes',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Mismo día que inicio'),
            ),
            ...List.generate(31, (i) => i + 1).map((day) {
              return DropdownMenuItem(
                value: day,
                child: Text('Día $day'),
              );
            }),
            const DropdownMenuItem(
              value: -1,
              child: Text('Último día del mes'),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedMonthDay = value);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getIntervalLabel() {
    switch (_frequency) {
      case RecurrenceFrequency.weekly:
        return _interval == 1 ? 'semana' : 'semanas';
      case RecurrenceFrequency.monthly:
        return _interval == 1 ? 'mes' : 'meses';
      case RecurrenceFrequency.yearly:
        return _interval == 1 ? 'año' : 'años';
      default:
        return '';
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Guardar transacción recurrente
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transacción recurrente guardada'),
        ),
      );
    }
  }
}
