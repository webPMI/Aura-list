import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_template.dart';
import '../providers/template_provider.dart';
import '../providers/task_provider.dart';
import '../core/constants/task_constants.dart';
import '../widgets/dialogs/template_form_dialog.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(filteredTemplatesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Tareas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar plantillas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(templateSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                ref.read(templateSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: templates.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateCard(
                  template: template,
                  onUse: () => _useTemplate(template),
                  onEdit: () => _editTemplate(template),
                  onDelete: () => _deleteTemplate(template),
                  onTogglePin: () => _togglePin(template),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Plantilla'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(templateSearchQueryProvider);

    if (query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron plantillas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes plantillas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea plantillas para reutilizar tareas frecuentes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewTemplate,
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Plantilla'),
          ),
        ],
      ),
    );
  }

  Future<void> _useTemplate(TaskTemplate template) async {
    try {
      // Mark template as used
      await ref
          .read(templatesProvider.notifier)
          .useTemplate(template);

      // Create task from template
      final task = template.toTask();

      // Save task
      await ref
          .read(tasksProvider(task.type).notifier)
          .addTask(
            task.title,
            category: task.category,
            priority: task.priority,
            dueDate: task.dueDate,
            dueTimeMinutes: task.dueTimeMinutes,
            motivation: task.motivation,
            reward: task.reward,
            deadline: task.deadline,
            financialCost: task.financialCost,
            financialBenefit: task.financialBenefit,
            financialCategoryId: task.financialCategoryId,
            financialNote: task.financialNote,
            autoGenerateTransaction: task.autoGenerateTransaction,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarea creada desde plantilla "${template.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al usar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNewTemplate() async {
    await showTemplateFormDialog(
      context: context,
      ref: ref,
    );
  }

  Future<void> _editTemplate(TaskTemplate template) async {
    await showTemplateFormDialog(
      context: context,
      ref: ref,
      template: template,
    );
  }

  Future<void> _deleteTemplate(TaskTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plantilla'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la plantilla "${template.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(templatesProvider.notifier).deleteTemplate(template);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plantilla eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar plantilla: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePin(TaskTemplate template) async {
    try {
      await ref.read(templatesProvider.notifier).togglePin(template);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al fijar/desfijar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final TaskTemplate template;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _TemplateCard({
    required this.template,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onUse,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Pin button
              Row(
                children: [
                  if (template.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      template.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    onPressed: onTogglePin,
                    tooltip: template.isPinned ? 'Desfijar' : 'Fijar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),

              // Description
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  template.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Task details
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Type badge
                  _Badge(
                    icon: TaskConstants.getTaskTypeIcon(template.taskType),
                    label: template.typeLabel,
                    color: Colors.blue,
                  ),

                  // Category badge
                  _Badge(
                    icon: Icons.category_outlined,
                    label: template.category,
                    color: Colors.purple,
                  ),

                  // Priority badge
                  _Badge(
                    icon: Icons.flag_outlined,
                    label: _getPriorityLabel(template.priority),
                    color: _getPriorityColor(template.priority),
                  ),

                  // Usage count
                  if (template.usageCount > 0)
                    _Badge(
                      icon: Icons.repeat,
                      label: '${template.usageCount}x usado',
                      color: Colors.green,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Use button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUse,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Usar Plantilla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Baja';
      case 1:
        return 'Media';
      case 2:
        return 'Alta';
      default:
        return 'Media';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
