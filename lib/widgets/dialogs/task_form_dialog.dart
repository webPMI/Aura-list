import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

/// Shows a bottom sheet dialog for creating or editing a task
Future<void> showTaskFormDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String taskType,
  Task? task,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskFormDialog(
      taskType: taskType,
      task: task,
      ref: ref,
    ),
  );
}

class TaskFormDialog extends StatefulWidget {
  final String taskType;
  final Task? task;
  final WidgetRef ref;

  const TaskFormDialog({
    super.key,
    required this.taskType,
    required this.ref,
    this.task,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _motivationController;
  late final TextEditingController _rewardController;

  late String _selectedCategory;
  late int _selectedPriority;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDeadline;

  final List<String> _categories = [
    'Personal',
    'Trabajo',
    'Hogar',
    'Salud',
    'Otros',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _motivationController = TextEditingController(text: widget.task?.motivation ?? '');
    _rewardController = TextEditingController(text: widget.task?.reward ?? '');
    _selectedCategory = widget.task?.category ?? 'Personal';
    _selectedPriority = widget.task?.priority ?? 1;
    _selectedDueDate = widget.task?.dueDate;
    _selectedTime = widget.task?.dueTime;
    _selectedDeadline = widget.task?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.task != null;

  String get _formTitle => _isEditing ? 'Editar Tarea' : 'Nueva Tarea';

  String get _taskTypeLabel {
    switch (widget.taskType) {
      case 'daily':
        return 'Diaria';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      case 'once':
        return 'Única';
      default:
        return 'Tarea';
    }
  }

  IconData get _taskTypeIcon {
    switch (widget.taskType) {
      case 'daily':
        return Icons.wb_sunny_outlined;
      case 'weekly':
        return Icons.calendar_view_week_outlined;
      case 'monthly':
        return Icons.calendar_month_outlined;
      case 'yearly':
        return Icons.event_outlined;
      case 'once':
        return Icons.push_pin_outlined;
      default:
        return Icons.task_outlined;
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título es obligatorio'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();

      // Convert time to minutes since midnight
      int? dueTimeMinutes;
      if (_selectedTime != null) {
        dueTimeMinutes = _selectedTime!.hour * 60 + _selectedTime!.minute;
      }

      if (_isEditing) {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
          dueTimeMinutes: dueTimeMinutes,
          motivation: _motivationController.text.trim().isEmpty
              ? null
              : _motivationController.text.trim(),
          reward: _rewardController.text.trim().isEmpty
              ? null
              : _rewardController.text.trim(),
          deadline: _selectedDeadline,
        );
        await widget.ref
            .read(tasksProvider(widget.taskType).notifier)
            .updateTask(updatedTask);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarea actualizada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Create new task
        await widget.ref
            .read(tasksProvider(widget.taskType).notifier)
            .addTask(
              _titleController.text.trim(),
              category: _selectedCategory,
              priority: _selectedPriority,
              dueDate: _selectedDueDate,
              dueTimeMinutes: dueTimeMinutes,
              motivation: _motivationController.text.trim().isEmpty
                  ? null
                  : _motivationController.text.trim(),
              reward: _rewardController.text.trim().isEmpty
                  ? null
                  : _rewardController.text.trim(),
              deadline: _selectedDeadline,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tarea creada'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _taskTypeIcon,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Tarea $_taskTypeLabel',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: '¿Qué quieres hacer?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: !_isEditing,
              ),
              const SizedBox(height: 16),

              // Category and Priority
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Due Date and Time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDueDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDueDate == null
                            ? 'Fecha'
                            : DateFormat('dd/MM/yyyy').format(_selectedDueDate!),
                      ),
                    ),
                  ),
                  if (_selectedDueDate != null) ...[
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selectedDueDate = null),
                      tooltip: 'Quitar fecha',
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Hora'
                            : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  if (_selectedTime != null) ...[
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selectedTime = null),
                      tooltip: 'Quitar hora',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Deadline
              OutlinedButton.icon(
                onPressed: _selectDeadline,
                icon: const Icon(Icons.alarm),
                label: Text(
                  _selectedDeadline == null
                      ? 'Fecha límite (opcional)'
                      : 'Límite: ${DateFormat('dd/MM/yyyy').format(_selectedDeadline!)}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedDeadline != null
                      ? Colors.orange
                      : colorScheme.onSurface,
                ),
              ),
              if (_selectedDeadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedDeadline = null),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Quitar límite'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Motivation
              TextField(
                controller: _motivationController,
                decoration: const InputDecoration(
                  labelText: 'Motivación (opcional)',
                  hintText: '¿Por qué es importante?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Reward
              TextField(
                controller: _rewardController,
                decoration: const InputDecoration(
                  labelText: 'Recompensa (opcional)',
                  hintText: '¿Qué te premiarás al completar?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save button
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveTask,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Tarea'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
