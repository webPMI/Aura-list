import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/task_constants.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/dialog_utils.dart';

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

  String get _taskTypeLabel => TaskConstants.getTaskTypeLabel(widget.taskType);

  IconData get _taskTypeIcon => TaskConstants.getTaskTypeIcon(widget.taskType);

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
    final validationError = DialogUtils.validateTaskTitle(_titleController.text.trim());
    if (validationError != null) {
      DialogUtils.showSnackBar(context, validationError, isError: true);
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

      if (_isEditing) {
        // Update existing task IN-PLACE to avoid duplication
        // The original task object is already in Hive, so we update it directly
        final originalTask = widget.task!;

        // Determinar qué campos limpiar
        final motivationText = _motivationController.text.trim();
        final rewardText = _rewardController.text.trim();

        // Update the original task in-place (preserves Hive reference)
        originalTask.updateInPlace(
          title: _titleController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
          clearDueDate: _selectedDueDate == null && originalTask.dueDate != null,
          dueTimeMinutes: dueTimeMinutes,
          clearDueTime: dueTimeMinutes == null && originalTask.dueTimeMinutes != null,
          motivation: motivationText.isNotEmpty ? motivationText : null,
          clearMotivation: motivationText.isEmpty && originalTask.motivation != null,
          reward: rewardText.isNotEmpty ? rewardText : null,
          clearReward: rewardText.isEmpty && originalTask.reward != null,
          deadline: _selectedDeadline,
          clearDeadline: _selectedDeadline == null && originalTask.deadline != null,
          lastUpdatedAt: DateTime.now(),
        );

        await widget.ref
            .read(tasksProvider(widget.taskType).notifier)
            .updateTask(originalTask);

        if (mounted) {
          Navigator.pop(context);
          DialogUtils.showSnackBar(context, 'Tarea actualizada');
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
          DialogUtils.showSnackBar(context, 'Tarea creada');
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showSnackBar(context, 'Error al guardar: $e', isError: true);
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
                            : TimeUtils.formatTimeOfDay(_selectedTime!),
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
