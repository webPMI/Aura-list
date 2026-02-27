import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/task_template.dart';
import '../../providers/template_provider.dart';
import '../../core/constants/task_constants.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/dialog_utils.dart';
import '../finance/task_finance_section.dart';

const _uuid = Uuid();

/// Shows a bottom sheet dialog for creating or editing a template
Future<void> showTemplateFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  TaskTemplate? template,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TemplateFormDialog(
      template: template,
      ref: ref,
    ),
  );
}

class TemplateFormDialog extends StatefulWidget {
  final TaskTemplate? template;
  final WidgetRef ref;

  const TemplateFormDialog({
    super.key,
    required this.ref,
    this.template,
  });

  @override
  State<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<TemplateFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _titleController;
  late final TextEditingController _motivationController;
  late final TextEditingController _rewardController;

  late String _selectedTaskType;
  late String _selectedCategory;
  late int _selectedPriority;
  TimeOfDay? _selectedTime;
  int? _daysOffset;
  int? _recurrenceDay;

  // Finance state variables
  double? _financialCost;
  double? _financialBenefit;
  String? _financialCategoryId;
  String? _financialNote;
  bool _autoGenerateTransaction = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _titleController = TextEditingController(text: widget.template?.title ?? '');
    _motivationController = TextEditingController(text: widget.template?.motivation ?? '');
    _rewardController = TextEditingController(text: widget.template?.reward ?? '');

    _selectedTaskType = widget.template?.taskType ?? 'daily';
    _selectedCategory = widget.template?.category ?? 'Personal';
    _selectedPriority = widget.template?.priority ?? 1;
    _daysOffset = widget.template?.daysOffset;
    _recurrenceDay = widget.template?.recurrenceDay;

    if (widget.template?.dueTimeMinutes != null) {
      final minutes = widget.template!.dueTimeMinutes!;
      _selectedTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }

    // Initialize finance fields
    _financialCost = widget.template?.financialCost;
    _financialBenefit = widget.template?.financialBenefit;
    _financialCategoryId = widget.template?.financialCategoryId;
    _financialNote = widget.template?.financialNote;
    _autoGenerateTransaction = widget.template?.autoGenerateTransaction ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _motivationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.template != null;

  String get _formTitle => _isEditing ? 'Editar Plantilla' : 'Nueva Plantilla';

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveTemplate() async {
    // Validate template name
    if (_nameController.text.trim().isEmpty) {
      DialogUtils.showSnackBar(context, 'El nombre de la plantilla es requerido', isError: true);
      return;
    }

    // Validate task title
    final validationError = DialogUtils.validateTaskTitle(_titleController.text.trim());
    if (validationError != null) {
      DialogUtils.showSnackBar(context, validationError, isError: true);
      return;
    }

    // Validate finance fields
    if ((_financialCost != null || _financialBenefit != null) && _financialCategoryId == null) {
      DialogUtils.showSnackBar(context, 'Selecciona una categoría financiera', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();

      // Convert time to minutes since midnight
      int? dueTimeMinutes;
      if (_selectedTime != null) {
        dueTimeMinutes = TimeUtils.timeOfDayToMinutes(_selectedTime!);
      }

      final template = TaskTemplate(
        id: widget.template?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        taskType: _selectedTaskType,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        motivation: _motivationController.text.trim().isNotEmpty
            ? _motivationController.text.trim()
            : null,
        reward: _rewardController.text.trim().isNotEmpty
            ? _rewardController.text.trim()
            : null,
        dueTimeMinutes: dueTimeMinutes,
        daysOffset: _daysOffset,
        recurrenceDay: _recurrenceDay,
        financialCost: _financialCost,
        financialBenefit: _financialBenefit,
        financialCategoryId: _financialCategoryId,
        financialNote: _financialNote,
        autoGenerateTransaction: _autoGenerateTransaction,
        linkedRecurringTransactionId: widget.template?.linkedRecurringTransactionId,
        createdAt: widget.template?.createdAt,
        lastUsedAt: widget.template?.lastUsedAt,
        usageCount: widget.template?.usageCount ?? 0,
        firestoreId: widget.template?.firestoreId ?? '',
        lastUpdatedAt: DateTime.now(),
        isPinned: widget.template?.isPinned ?? false,
        tags: widget.template?.tags,
      );

      if (_isEditing) {
        await widget.ref.read(templatesProvider.notifier).updateTemplate(template);
      } else {
        await widget.ref.read(templatesProvider.notifier).createTemplate(template);
      }

      if (mounted) {
        Navigator.of(context).pop();
        DialogUtils.showSnackBar(
          context,
          _isEditing ? 'Plantilla actualizada' : 'Plantilla creada',
        );
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showSnackBar(
          context,
          'Error al guardar plantilla: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template Name
                      Text(
                        'Información de la Plantilla',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la plantilla *',
                          hintText: 'Ej: Reunión semanal de equipo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Describe cuándo usar esta plantilla',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 24),

                      // Task Details
                      Text(
                        'Detalles de la Tarea',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Task Title
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título de la tarea *',
                          hintText: 'Ej: Revisar reportes semanales',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.task_alt),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Task Type
                      DropdownButtonFormField<String>(
                        value: _selectedTaskType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de tarea',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: TaskConstants.taskTypes.map((typeRecord) {
                          final (type, label, icon) = typeRecord;
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 8),
                                Text(label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTaskType = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: TaskConstants.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<int>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Baja')),
                          DropdownMenuItem(value: 1, child: Text('Media')),
                          DropdownMenuItem(value: 2, child: Text('Alta')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Due Time
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Hora sugerida'),
                        subtitle: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Sin hora específica',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedTime != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _selectedTime = null),
                              ),
                            IconButton(
                              icon: const Icon(Icons.schedule),
                              onPressed: _selectTime,
                            ),
                          ],
                        ),
                      ),

                      // Days Offset (for 'once' tasks)
                      if (_selectedTaskType == 'once') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Días desde hoy',
                            hintText: 'Ej: 7 (para una semana después)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: _daysOffset?.toString() ?? '',
                          onChanged: (value) {
                            setState(() {
                              _daysOffset = int.tryParse(value);
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Motivation
                      TextField(
                        controller: _motivationController,
                        decoration: const InputDecoration(
                          labelText: 'Motivación',
                          hintText: '¿Por qué es importante esta tarea?',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.favorite_outline),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Reward
                      TextField(
                        controller: _rewardController,
                        decoration: const InputDecoration(
                          labelText: 'Recompensa',
                          hintText: 'Me premiaré con...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.emoji_events_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 24),

                      // Finance Section
                      TaskFinanceSection(
                        initialCost: _financialCost,
                        initialBenefit: _financialBenefit,
                        initialCategoryId: _financialCategoryId,
                        initialNote: _financialNote,
                        initialAutoGenerate: _autoGenerateTransaction,
                        onDataChanged: (data) {
                          setState(() {
                            _financialCost = data.cost;
                            _financialBenefit = data.benefit;
                            _financialCategoryId = data.categoryId;
                            _financialNote = data.note;
                            _autoGenerateTransaction = data.autoGenerateTransaction;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTemplate,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isEditing ? 'Actualizar Plantilla' : 'Crear Plantilla'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
