import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';

/// Shows a dialog to create a new task.
///
/// This can be displayed as either a regular dialog or a bottom sheet
/// depending on screen size and context.
///
/// Example usage:
/// ```dart
/// showAddTaskDialog(
///   context: context,
///   ref: ref,
///   defaultType: 'daily',
///   onTaskCreated: () => ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text('Tarea creada')),
///   ),
/// );
/// ```
Future<void> showAddTaskDialog({
  required BuildContext context,
  required WidgetRef ref,
  String defaultType = 'daily',
  VoidCallback? onTaskCreated,
}) async {
  // Use bottom sheet on smaller screens, dialog on larger screens
  final screenHeight = MediaQuery.of(context).size.height;
  final useBottomSheet = screenHeight < 800;

  if (useBottomSheet) {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskDialogContent(
        ref: ref,
        defaultType: defaultType,
        onTaskCreated: onTaskCreated,
        isBottomSheet: true,
      ),
    );
  } else {
    await showDialog(
      context: context,
      builder: (context) => _AddTaskDialogContent(
        ref: ref,
        defaultType: defaultType,
        onTaskCreated: onTaskCreated,
        isBottomSheet: false,
      ),
    );
  }
}

class _AddTaskDialogContent extends StatefulWidget {
  final WidgetRef ref;
  final String defaultType;
  final VoidCallback? onTaskCreated;
  final bool isBottomSheet;

  const _AddTaskDialogContent({
    required this.ref,
    required this.defaultType,
    this.onTaskCreated,
    this.isBottomSheet = false,
  });

  @override
  State<_AddTaskDialogContent> createState() => _AddTaskDialogContentState();
}

class _AddTaskDialogContentState extends State<_AddTaskDialogContent> {
  final _titleController = TextEditingController();
  final _motivationController = TextEditingController();
  final _rewardController = TextEditingController();

  late String _selectedType;
  int _selectedPriority = 1; // Medium
  String _selectedCategory = 'Personal';
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  DateTime? _selectedDeadline;
  String? _errorMessage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Personal',
    'Trabajo',
    'Hogar',
    'Salud',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _motivationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _pickDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (time != null && mounted) {
      setState(() => _selectedDueTime = time);
    }
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDeadline = date);
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
      _selectedDueTime = null;
    });
  }

  void _clearDueTime() {
    setState(() => _selectedDueTime = null);
  }

  void _clearDeadline() {
    setState(() => _selectedDeadline = null);
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();

    // Validation
    if (title.length < 3) {
      setState(() => _errorMessage = 'El título debe tener al menos 3 caracteres');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      // Convert TimeOfDay to minutes
      int? dueTimeMinutes;
      if (_selectedDueTime != null) {
        dueTimeMinutes = _selectedDueTime!.hour * 60 + _selectedDueTime!.minute;
      }

      // Add task through provider
      await widget.ref.read(tasksProvider(_selectedType).notifier).addTask(
            title,
            priority: _selectedPriority,
            category: _selectedCategory,
            dueDate: _selectedDueDate,
            dueTimeMinutes: dueTimeMinutes,
            motivation: _motivationController.text.isNotEmpty
                ? _motivationController.text
                : null,
            reward: _rewardController.text.isNotEmpty
                ? _rewardController.text
                : null,
            deadline: _selectedDeadline,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al crear la tarea. Inténtalo de nuevo.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Task type selector
          const Text(
            'Tipo de tarea',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('daily', 'Diaria', Icons.wb_sunny_outlined),
              ('weekly', 'Semanal', Icons.calendar_view_week_outlined),
              ('monthly', 'Mensual', Icons.calendar_month_outlined),
              ('yearly', 'Anual', Icons.event_outlined),
              ('once', 'Única', Icons.push_pin_outlined),
            ].map((item) {
              final isSelected = _selectedType == item.$1;
              return ChoiceChip(
                avatar: Icon(item.$3, size: 16),
                label: Text(item.$2),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedType = item.$1);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '¿Qué hay que hacer?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submitTask(),
          ),
          const SizedBox(height: 20),

          // Due date picker
          const Text(
            'Fecha de vencimiento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: _selectedDueDate != null
                        ? colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDueDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
                        : 'Sin fecha (opcional)',
                    style: TextStyle(
                      color: _selectedDueDate != null ? null : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDueDate != null)
                    GestureDetector(
                      onTap: _clearDueDate,
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),

          // Due time picker (only shown if due date is selected)
          if (_selectedDueDate != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: _selectedDueTime != null
                          ? colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDueTime != null
                          ? '${_selectedDueTime!.hour.toString().padLeft(2, '0')}:${_selectedDueTime!.minute.toString().padLeft(2, '0')}'
                          : 'Sin hora (opcional)',
                      style: TextStyle(
                        color: _selectedDueTime != null ? null : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDueTime != null)
                      GestureDetector(
                        onTap: _clearDueTime,
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Priority selector
          const Text(
            'Prioridad',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final colors = [
                Colors.blueAccent,
                Colors.orangeAccent,
                Colors.redAccent,
              ];
              final labels = ['Baja', 'Media', 'Alta'];
              final isSelected = _selectedPriority == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 2 ? 0 : 4,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPriority = index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors[index].withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colors[index]
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? colors[index] : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Category selector
          const Text(
            'Categoría',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = cat);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Motivation field
          const Text(
            '💪 Motivación (opcional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _motivationController,
            decoration: InputDecoration(
              hintText: '¿Por qué quieres lograr esto?',
              prefixIcon: const Icon(Icons.emoji_emotions_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),

          // Reward field
          TextField(
            controller: _rewardController,
            decoration: InputDecoration(
              hintText: '🎁 ¿Cómo te premiarás al completarla?',
              prefixIcon: const Icon(Icons.card_giftcard_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Deadline picker
          const Text(
            '⏰ Fecha límite',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDeadline,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.alarm,
                    color: _selectedDeadline != null
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDeadline != null
                        ? 'Límite: ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                        : 'Sin fecha límite',
                    style: TextStyle(
                      color: _selectedDeadline != null
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDeadline != null)
                    GestureDetector(
                      onTap: _clearDeadline,
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap content differently for bottom sheet vs dialog
    if (widget.isBottomSheet) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const Text(
                    'Nueva Tarea',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: content,
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitTask,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Dialog layout
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Nueva Tarea',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: content,
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitTask,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Agregar'),
          ),
        ],
      );
    }
  }
}
