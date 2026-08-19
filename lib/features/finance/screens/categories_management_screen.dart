import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/finance_category.dart';

class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends ConsumerState<CategoriesManagementScreen> {
  FinanceCategoryType _filterType = FinanceCategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(financeProvider).categories
        .where((c) => c.type == _filterType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
        actions: [
          SegmentedButton<FinanceCategoryType>(
            segments: const [
              ButtonSegment(
                value: FinanceCategoryType.expense,
                label: Text('Gastos'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: FinanceCategoryType.income,
                label: Text('Ingresos'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_filterType},
            onSelectionChanged: (Set<FinanceCategoryType> newSelection) {
              setState(() => _filterType = newSelection.first);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterType == FinanceCategoryType.expense
                        ? Icons.receipt_long
                        : Icons.trending_up,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay categorías de ${_filterType == FinanceCategoryType.expense ? "gasto" : "ingreso"}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Dismissible(
                  key: Key(cat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar categoría'),
                        content: Text(
                            '¿Eliminar "${cat.name}"? Esto no eliminará las transacciones existentes.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await ref
                        .read(financeProvider.notifier)
                        .deleteCategory(cat.id);
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: _getIcon(
                        cat.icon,
                        cat.color,
                        size: 32,
                      ),
                      title: Text(cat.name),
                      subtitle: Text(
                        cat.isDefault
                            ? 'Categoría predeterminada'
                            : 'Categoría personalizada',
                      ),
                      trailing: cat.isDefault
                          ? Chip(
                              label: const Text('Predet.'),
                              backgroundColor: const Color(0xFF1F2024),
                            )
                          : IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editCategory(context, cat),
                            ),
                      onTap: cat.isDefault
                          ? null
                          : () => _editCategory(context, cat),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getIcon(String iconName, String colorHex, {double size = 40}) {
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
      size: size,
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final nameController = TextEditingController();
    Color selectedColor = const Color(0xFF66BB6A);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Categoría'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
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
                        onTap: () => setState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c ? Colors.black : Colors.grey,
                              width: selectedColor == c ? 2 : 1,
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newCat = FinanceCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text,
        icon: 'category',
        color:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        type: _filterType,
        isDefault: false,
      );
      await ref.read(financeProvider.notifier).addCategory(newCat);
    }
  }

  Future<void> _editCategory(BuildContext context, FinanceCategory cat) async {
    final nameController =
        TextEditingController(text: cat.name);
    Color selectedColor = Color(
        int.parse(cat.color.replaceFirst('#', 'FF'), radix: 16));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Categoría'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
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
                        onTap: () => setState(() => selectedColor = c),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == c
                                  ? Colors.black
                                  : Colors.grey,
                              width: selectedColor == c ? 2 : 1,
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final updated = FinanceCategory(
        id: cat.id,
        name: nameController.text,
        icon: cat.icon,
        color:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        type: cat.type,
        isDefault: cat.isDefault,
      );
      await ref
          .read(financeProvider.notifier)
          .updateCategory(updated);
    }
  }
}



