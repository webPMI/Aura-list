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
        heroTag: 'categories_fab',
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
    final newCat = await _CategoryEditorDialog.show(
      context,
      initialType: _filterType,
    );
    if (newCat != null) {
      await ref.read(financeProvider.notifier).addCategory(newCat);
    }
  }

  Future<void> _editCategory(BuildContext context, FinanceCategory cat) async {
    final updated = await _CategoryEditorDialog.show(
      context,
      category: cat,
    );
    if (updated != null) {
      await ref.read(financeProvider.notifier).updateCategory(updated);
    }
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  final FinanceCategory? category;
  final FinanceCategoryType initialType;
  final bool isBottomSheet;

  const _CategoryEditorDialog({
    this.category,
    this.initialType = FinanceCategoryType.expense,
    this.isBottomSheet = false,
  });

  static Future<FinanceCategory?> show(
    BuildContext context, {
    FinanceCategory? category,
    FinanceCategoryType initialType = FinanceCategoryType.expense,
  }) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return showModalBottomSheet<FinanceCategory>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => _CategoryEditorDialog(
          category: category,
          initialType: initialType,
          isBottomSheet: true,
        ),
      );
    } else {
      return showDialog<FinanceCategory>(
        context: context,
        builder: (ctx) => _CategoryEditorDialog(
          category: category,
          initialType: initialType,
          isBottomSheet: false,
        ),
      );
    }
  }

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Color _selectedColor;

  static const List<Color> _palette = [
    Color(0xFFEF5350),
    Color(0xFFFF7043),
    Color(0xFFFFA726),
    Color(0xFFFFCA28),
    Color(0xFF42A5F5),
    Color(0xFF2196F3),
    Color(0xFF66BB6A),
    Color(0xFF26A69A),
    Color(0xFF78909C),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF9E9E9E),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    if (widget.category != null) {
      try {
        _selectedColor = Color(int.parse(
            widget.category!.color.replaceFirst('#', 'FF'),
            radix: 16));
      } catch (_) {
        _selectedColor = const Color(0xFF66BB6A);
      }
    } else {
      _selectedColor = const Color(0xFF66BB6A);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    if (widget.category != null) {
      final updated = widget.category!.copyWith(
        name: name,
        color: colorHex,
      );
      Navigator.pop(context, updated);
    } else {
      final newCat = FinanceCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        icon: 'category',
        color: colorHex,
        type: widget.initialType,
        isDefault: false,
      );
      Navigator.pop(context, newCat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isEditing = widget.category != null;

    final contentWidget = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre
          TextFormField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre de la categoría',
              hintText: 'Ej: Supermercado, Transporte, Gimnasio',
              prefixIcon: const Icon(Icons.category_outlined),
              filled: true,
              fillColor: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.6)
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
          ),
          const SizedBox(height: 16),

          // Paleta de colores
          Text(
            'Color de la categoría',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == c
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: _selectedColor == c
                          ? [
                              BoxShadow(
                                color: c.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: _selectedColor == c
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),

          // Botón Principal
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text(
              isEditing ? 'Guardar Cambios' : 'Crear Categoría',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
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
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _selectedColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          isEditing ? 'Editar Categoría' : 'Nueva Categoría',
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

    if (widget.isBottomSheet) {
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
          maxHeight: mediaQuery.size.height * 0.85,
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
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
        width: 440,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.85,
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



