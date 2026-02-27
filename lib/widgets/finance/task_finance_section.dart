import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/finance/providers/finance_provider.dart';
import '../../features/finance/models/finance_category.dart';

/// Data class to hold finance information from the task form
class TaskFinanceData {
  final double? cost;
  final double? benefit;
  final String? categoryId;
  final String? note;
  final bool autoGenerateTransaction;
  final DateTime? transactionDate;

  bool get hasFinancialImpact => cost != null || benefit != null;

  double? get netImpact {
    if (cost == null && benefit == null) return null;
    return (benefit ?? 0) - (cost ?? 0);
  }

  TaskFinanceData({
    this.cost,
    this.benefit,
    this.categoryId,
    this.note,
    this.autoGenerateTransaction = false,
    this.transactionDate,
  });
}

/// Reusable finance section component for task forms
class TaskFinanceSection extends ConsumerStatefulWidget {
  final double? initialCost;
  final double? initialBenefit;
  final String? initialCategoryId;
  final String? initialNote;
  final bool initialAutoGenerate;
  final DateTime? initialTransactionDate;
  final void Function(TaskFinanceData data) onDataChanged;

  const TaskFinanceSection({
    super.key,
    required this.onDataChanged,
    this.initialCost,
    this.initialBenefit,
    this.initialCategoryId,
    this.initialNote,
    this.initialAutoGenerate = false,
    this.initialTransactionDate,
  });

  @override
  ConsumerState<TaskFinanceSection> createState() => _TaskFinanceSectionState();
}

class _TaskFinanceSectionState extends ConsumerState<TaskFinanceSection> {
  late final TextEditingController _costController;
  late final TextEditingController _benefitController;
  late final TextEditingController _noteController;

  String _impactType = 'none'; // 'none', 'expense', 'income', 'both'
  String? _selectedCategoryId;
  bool _autoGenerate = false;
  DateTime? _transactionDate;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _costController = TextEditingController(
      text: widget.initialCost != null ? widget.initialCost.toString() : '',
    );
    _benefitController = TextEditingController(
      text: widget.initialBenefit != null ? widget.initialBenefit.toString() : '',
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');

    // Initialize state
    _selectedCategoryId = widget.initialCategoryId;
    _autoGenerate = widget.initialAutoGenerate;
    _transactionDate = widget.initialTransactionDate;

    // Determine initial impact type
    if (widget.initialCost != null && widget.initialBenefit != null) {
      _impactType = 'both';
      _isExpanded = true;
    } else if (widget.initialCost != null) {
      _impactType = 'expense';
      _isExpanded = true;
    } else if (widget.initialBenefit != null) {
      _impactType = 'income';
      _isExpanded = true;
    }

    // Listen for changes
    _costController.addListener(_notifyChange);
    _benefitController.addListener(_notifyChange);
    _noteController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _costController.dispose();
    _benefitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onDataChanged(TaskFinanceData(
      cost: _parseCost(),
      benefit: _parseBenefit(),
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      autoGenerateTransaction: _autoGenerate,
      transactionDate: _transactionDate,
    ));
  }

  double? _parseCost() {
    if (_impactType == 'none' || _impactType == 'income') return null;
    final text = _costController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  double? _parseBenefit() {
    if (_impactType == 'none' || _impactType == 'expense') return null;
    final text = _benefitController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final financeState = ref.watch(financeProvider);

    return Card(
      child: Column(
        children: [
          // Header with toggle
          ListTile(
            leading: Icon(Icons.attach_money, color: colorScheme.primary),
            title: const Text('Impacto Financiero'),
            subtitle: _buildSubtitle(),
            trailing: Switch(
              value: _isExpanded,
              onChanged: (value) {
                setState(() {
                  _isExpanded = value;
                  if (!value) {
                    _impactType = 'none';
                    _costController.clear();
                    _benefitController.clear();
                    _selectedCategoryId = null;
                    _noteController.clear();
                    _autoGenerate = false;
                    _notifyChange();
                  }
                });
              },
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Impact Type Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Gasto'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'income',
                        label: Text('Ingreso'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'both',
                        label: Text('Ambos'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {_impactType == 'none' ? 'expense' : _impactType},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _impactType = selection.first;
                        // Clear inappropriate fields
                        if (_impactType == 'expense') _benefitController.clear();
                        if (_impactType == 'income') _costController.clear();
                        _notifyChange();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cost Field
                  if (_impactType == 'expense' || _impactType == 'both') ...[
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Costo',
                        hintText: '0.00',
                        prefixText: '€ ',
                        helperText: 'Gasto al realizar esta tarea',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Benefit Field
                  if (_impactType == 'income' || _impactType == 'both') ...[
                    TextFormField(
                      controller: _benefitController,
                      decoration: const InputDecoration(
                        labelText: 'Beneficio',
                        hintText: '0.00',
                        prefixText: '€ ',
                        helperText: 'Ingreso al completar esta tarea',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category Selector
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _getFilteredCategories(financeState.categories)
                        .map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconData(category.icon),
                                    color: _getColor(category.color),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                        _notifyChange();
                      });
                    },
                    validator: (value) {
                      if ((_parseCost() != null || _parseBenefit() != null) && value == null) {
                        return 'Selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Auto-generate checkbox
                  CheckboxListTile(
                    value: _autoGenerate,
                    onChanged: (value) {
                      setState(() {
                        _autoGenerate = value ?? false;
                        _notifyChange();
                      });
                    },
                    title: const Text('Crear transacción automáticamente al completar'),
                    subtitle: const Text('La transacción se añadirá a tus finanzas al marcar la tarea como completada'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),

                  // Financial Note
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Nota financiera (opcional)',
                      hintText: 'Detalles adicionales...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildSubtitle() {
    if (!_isExpanded || _impactType == 'none') return null;

    final cost = _parseCost();
    final benefit = _parseBenefit();

    if (cost == null && benefit == null) return null;

    final formatter = NumberFormat.currency(symbol: '€');

    if (cost != null && benefit != null) {
      final net = benefit - cost;
      return Text('Neto: ${formatter.format(net)}');
    } else if (cost != null) {
      return Text('Gasto: ${formatter.format(cost)}');
    } else {
      return Text('Ingreso: ${formatter.format(benefit!)}');
    }
  }

  List<FinanceCategory> _getFilteredCategories(List<FinanceCategory> allCategories) {
    if (_impactType == 'expense') {
      return allCategories.where((c) => c.type == FinanceCategoryType.expense).toList();
    } else if (_impactType == 'income') {
      return allCategories.where((c) => c.type == FinanceCategoryType.income).toList();
    } else {
      // Show all categories for 'both' mode
      return allCategories;
    }
  }

  IconData _getIconData(String iconString) {
    try {
      final codePoint = int.parse(iconString);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.attach_money;
    }
  }

  Color _getColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
