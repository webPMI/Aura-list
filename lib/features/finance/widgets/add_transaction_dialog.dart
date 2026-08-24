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

  bool _showCategoryCreator = false;
  final _newCategoryName = TextEditingController();
  Color _newCategoryColor = const Color(0xFF66BB6A);

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _newCategoryName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final categories = financeState.categories
        .where((c) => c.type == _selectedType)
        .toList();

    // Dialog de creación de categoría
    if (_showCategoryCreator) {
      return AlertDialog(
        title: const Text('Crear Categoría'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newCategoryName,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in [
                    const Color(0xFFEF5350),
                    const Color(0xFFFF7043),
                    const Color(0xFFFFA726),
                    const Color(0xFFFFCA28),
                    const Color(0xFF42A5F5),
                    const Color(0xFF2196F3),
                    const Color(0xFF66BB6A),
                    const Color(0xFF26A69A),
                    const Color(0xFF78909C),
                    const Color(0xFFAB47BC),
                    const Color(0xFF5C6BC0),
                    const Color(0xFF9E9E9E),
                  ])
                    GestureDetector(
                      onTap: () =>
                          setState(() => _newCategoryColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _newCategoryColor == c
                                ? Colors.black
                                : Colors.grey,
                            width: _newCategoryColor == c ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showCategoryCreator = false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newCategoryName.text.isEmpty) return;
              final newCat = FinanceCategory(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _newCategoryName.text,
                icon: 'category',
                color: '#${_newCategoryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                type: _selectedType,
                isDefault: false,
              );
              await ref.read(financeProvider.notifier).addCategory(newCat);
              setState(() {
                _showCategoryCreator = false;
                _selectedCategory = newCat;
                _newCategoryName.clear();
              });
              if (mounted) Navigator.pop(context, newCat);
            },
            child: const Text('Crear'),
          ),
        ],
      );
    }

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
                  if (double.tryParse(value) == null)
                    return 'Número inválido';
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
                items: [
                  ...categories.map((c) {
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
                  }),
                  const DropdownMenuItem(
                    value: null,
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Crear categoría...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null && categories.isNotEmpty) {
                    setState(() => _showCategoryCreator = true);
                  } else {
                    setState(() => _selectedCategory = value);
                  }
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
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
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
      ref.read(financeProvider.notifier).addTransaction(
            title: _titleController.text,
            amount: double.parse(_amountController.text),
            date: _selectedDate,
            categoryId: _selectedCategory?.id,
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
      case 'shopping_cart':
        iconData = Icons.shopping_cart;
        break;
      case 'bolt':
        iconData = Icons.bolt;
        break;
      case 'school':
        iconData = Icons.school;
        break;
      case 'flight':
        iconData = Icons.flight;
        break;
      case 'local_restaurant':
        iconData = Icons.local_restaurant;
        break;
      case 'person':
        iconData = Icons.person;
        break;
      case 'subscriptions':
        iconData = Icons.subscriptions;
        break;
      case 'category':
        iconData = Icons.category;
        break;
      case 'work':
        iconData = Icons.work;
        break;
      case 'star':
        iconData = Icons.star;
        break;
      default:
        iconData = Icons.category;
    }

    return Icon(
      iconData,
      color: Color(
          int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16)),
    );
  }
}



