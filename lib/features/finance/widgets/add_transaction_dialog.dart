import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/finance_category.dart';
import '../providers/finance_provider.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  FinanceCategory? _selectedCategory;
  FinanceCategoryType _selectedType = FinanceCategoryType.expense;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final categories = financeState.categories
        .where((c) => c.type == _selectedType)
        .toList();

    return AlertDialog(
      title: const Text('Nueva Transacción'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (double.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FinanceCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        _getIcon(c.icon, c.color),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Añade una descripción o comentario',
                ),
                maxLines: 2,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == null) return;

      ref
          .read(financeProvider.notifier)
          .addTransaction(
            title: _titleController.text,
            amount: double.parse(_amountController.text),
            date: _selectedDate,
            categoryId: _selectedCategory!.id,
            type: _selectedType,
            note: _noteController.text,
          );

      Navigator.pop(context);
    }
  }

  Widget _getIcon(String iconName, String colorHex) {
    IconData iconData;
    switch (iconName) {
      case 'restaurant':
        iconData = Icons.restaurant;
        break;
      case 'directions_car':
        iconData = Icons.directions_car;
        break;
      case 'home':
        iconData = Icons.home;
        break;
      case 'movie':
        iconData = Icons.movie;
        break;
      case 'medical_services':
        iconData = Icons.medical_services;
        break;
      case 'shopping_bag':
        iconData = Icons.shopping_bag;
        break;
      case 'payments':
        iconData = Icons.payments;
        break;
      case 'trending_up':
        iconData = Icons.trending_up;
        break;
      case 'redeem':
        iconData = Icons.redeem;
        break;
      case 'add_circle':
        iconData = Icons.add_circle;
        break;
      default:
        iconData = Icons.category;
    }

    return Icon(
      iconData,
      color: Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16)),
    );
  }
}
