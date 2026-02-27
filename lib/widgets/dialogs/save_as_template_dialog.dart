import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/task_model.dart';
import '../../models/task_template.dart';
import '../../providers/template_provider.dart';

const _uuid = Uuid();

/// Shows a dialog asking if the user wants to save a task as a template
Future<void> showSaveAsTemplateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Task task,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _SaveAsTemplateDialog(task: task, ref: ref),
  );

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantilla guardada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _SaveAsTemplateDialog extends StatefulWidget {
  final Task task;
  final WidgetRef ref;

  const _SaveAsTemplateDialog({
    required this.task,
    required this.ref,
  });

  @override
  State<_SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends State<_SaveAsTemplateDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with task title
    _nameController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la plantilla es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final template = TaskTemplate.fromTask(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        task: widget.task,
        daysOffset: widget.task.type == 'once' && widget.task.dueDate != null
            ? widget.task.dueDate!.difference(DateTime.now()).inDays
            : null,
      );

      await widget.ref.read(templatesProvider.notifier).createTemplate(template);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar plantilla: $e'),
            backgroundColor: Colors.red,
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('¿Guardar como plantilla?'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta tarea parece útil. ¿Quieres guardarla como plantilla para reutilizarla?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la plantilla *',
                hintText: 'Ej: Reunión semanal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Describe cuándo usar esta plantilla',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Ahora no'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTemplate,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar Plantilla'),
        ),
      ],
    );
  }
}
