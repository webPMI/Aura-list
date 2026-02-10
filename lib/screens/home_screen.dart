import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../widgets/task_list.dart';
import '../widgets/date_header.dart';
import '../widgets/calendar_view.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _taskController = TextEditingController();
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initAuth();
    _updateSyncCount();
  }

  Future<void> _initAuth() async {
    // Auto-login anónimo si no hay usuario
    final authService = ref.read(authServiceProvider);
    if (authService.currentUser == null) {
      await authService.signInAnonymously();
    }
  }

  Future<void> _updateSyncCount() async {
    final count = await ref.read(databaseServiceProvider).getPendingSyncCount();
    if (mounted) {
      setState(() => _pendingSyncCount = count);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isUndo = false, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
        duration: Duration(seconds: isUndo ? 4 : 2),
        action: isUndo && onUndo != null
            ? SnackBarAction(
                label: 'Deshacer',
                textColor: Colors.white,
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    String selectedType = _getCurrentType();
    int selectedPriority = 1; // Medium
    String selectedCategory = 'Personal';
    DateTime? selectedDueDate;
    TimeOfDay? selectedDueTime;
    final motivationController = TextEditingController();
    final rewardController = TextEditingController();
    DateTime? selectedDeadline;
    String? errorMessage;
    final categories = ['Personal', 'Trabajo', 'Hogar', 'Salud', 'Otros'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Nueva Tarea',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Tipo de tarea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        final isSelected = selectedType == item.$1;
                        return ChoiceChip(
                          avatar: Icon(item.$3, size: 16),
                          label: Text(item.$2),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => selectedType = item.$1);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: '¿Qué hay que hacer?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fecha de vencimiento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDueDate = date);
                        }
                      },
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
                              color: selectedDueDate != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDueDate != null
                                  ? DateFormat('dd/MM/yyyy').format(selectedDueDate!)
                                  : 'Sin fecha (opcional)',
                              style: TextStyle(
                                color: selectedDueDate != null ? null : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDueDate != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  selectedDueDate = null;
                                  selectedDueTime = null;
                                }),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedDueDate != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedDueTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedDueTime = time);
                          }
                        },
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
                                color: selectedDueTime != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedDueTime != null
                                    ? '${selectedDueTime!.hour.toString().padLeft(2, '0')}:${selectedDueTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Sin hora (opcional)',
                                style: TextStyle(
                                  color: selectedDueTime != null ? null : Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              if (selectedDueTime != null)
                                GestureDetector(
                                  onTap: () => setState(() => selectedDueTime = null),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Prioridad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                        final isSelected = selectedPriority == index;
                        return Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                            child: InkWell(
                              onTap: () => setState(() => selectedPriority = index),
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
                                  style: TextStyle(
                                    color: isSelected ? colors[index] : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categoría',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('💪 Motivación (opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: motivationController,
                      decoration: InputDecoration(
                        hintText: '¿Por qué quieres lograr esto?',
                        prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rewardController,
                      decoration: InputDecoration(
                        hintText: '🎁 ¿Cómo te premiarás al completarla?',
                        prefixIcon: const Icon(Icons.card_giftcard_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('⏰ Fecha límite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() => selectedDeadline = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm, color: selectedDeadline != null ? Colors.redAccent : Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedDeadline != null
                                  ? 'Límite: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                  : 'Sin fecha límite',
                              style: TextStyle(color: selectedDeadline != null ? Colors.redAccent : Colors.grey),
                            ),
                            const Spacer(),
                            if (selectedDeadline != null)
                              GestureDetector(
                                onTap: () => setState(() => selectedDeadline = null),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _taskController.clear();
                    motivationController.dispose();
                    rewardController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = _taskController.text.trim();
                    if (title.length < 3) {
                      setState(() => errorMessage = 'El título debe tener al menos 3 caracteres');
                      return;
                    }
                    int? dueTimeMinutes;
                    if (selectedDueTime != null) {
                      dueTimeMinutes = selectedDueTime!.hour * 60 + selectedDueTime!.minute;
                    }
                    ref
                        .read(tasksProvider(selectedType).notifier)
                        .addTask(
                          title,
                          priority: selectedPriority,
                          category: selectedCategory,
                          dueDate: selectedDueDate,
                          dueTimeMinutes: dueTimeMinutes,
                          motivation: motivationController.text.isNotEmpty ? motivationController.text : null,
                          reward: rewardController.text.isNotEmpty ? rewardController.text : null,
                          deadline: selectedDeadline,
                        );
                    _taskController.clear();
                    motivationController.dispose();
                    rewardController.dispose();
                    Navigator.pop(context);
                    _showSnackBar('🎉 ¡Tarea creada!');
                    _updateSyncCount();
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCurrentType() {
    switch (_tabController.index) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      case 2:
        return 'monthly';
      case 3:
        return 'yearly';
      case 4:
        return 'once';
      default:
        return 'daily';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authServiceProvider).signOut();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    _taskController.text = task.title;
    int selectedPriority = task.priority;
    String selectedCategory = task.category;
    DateTime? selectedDueDate = task.dueDate;
    TimeOfDay? selectedDueTime;
    if (task.dueTimeMinutes != null) {
      final hours = task.dueTimeMinutes! ~/ 60;
      final minutes = task.dueTimeMinutes! % 60;
      selectedDueTime = TimeOfDay(hour: hours, minute: minutes);
    }
    final motivationController = TextEditingController(text: task.motivation ?? '');
    final rewardController = TextEditingController(text: task.reward ?? '');
    DateTime? selectedDeadline = task.deadline;
    String? errorMessage;
    final categories = ['Personal', 'Trabajo', 'Hogar', 'Salud', 'Otros'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Editar Tarea',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Tipo de tarea', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            task.type == 'daily' ? Icons.wb_sunny_outlined :
                            task.type == 'weekly' ? Icons.calendar_view_week_outlined :
                            task.type == 'monthly' ? Icons.calendar_month_outlined :
                            task.type == 'yearly' ? Icons.event_outlined :
                            Icons.push_pin_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.type == 'daily' ? 'Diaria' :
                            task.type == 'weekly' ? 'Semanal' :
                            task.type == 'monthly' ? 'Mensual' :
                            task.type == 'yearly' ? 'Anual' :
                            'Única',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: '¿Qué hay que hacer?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fecha de vencimiento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDueDate = date);
                        }
                      },
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
                              color: selectedDueDate != null
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDueDate != null
                                  ? DateFormat('dd/MM/yyyy').format(selectedDueDate!)
                                  : 'Sin fecha (opcional)',
                              style: TextStyle(
                                color: selectedDueDate != null ? null : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDueDate != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  selectedDueDate = null;
                                  selectedDueTime = null;
                                }),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedDueDate != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedDueTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() => selectedDueTime = time);
                          }
                        },
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
                                color: selectedDueTime != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedDueTime != null
                                    ? '${selectedDueTime!.hour.toString().padLeft(2, '0')}:${selectedDueTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Sin hora (opcional)',
                                style: TextStyle(
                                  color: selectedDueTime != null ? null : Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              if (selectedDueTime != null)
                                GestureDetector(
                                  onTap: () => setState(() => selectedDueTime = null),
                                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Prioridad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                        final isSelected = selectedPriority == index;
                        return Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                            child: InkWell(
                              onTap: () => setState(() => selectedPriority = index),
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
                                  style: TextStyle(
                                    color: isSelected ? colors[index] : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Categoría',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('💪 Motivación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: motivationController,
                      decoration: InputDecoration(
                        hintText: '¿Por qué quieres lograr esto?',
                        prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rewardController,
                      decoration: InputDecoration(
                        hintText: '🎁 ¿Cómo te premiarás al completarla?',
                        prefixIcon: const Icon(Icons.card_giftcard_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('⏰ Fecha límite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() => selectedDeadline = date);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm, color: selectedDeadline != null ? Colors.redAccent : Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedDeadline != null
                                  ? 'Límite: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                  : 'Sin fecha límite',
                              style: TextStyle(color: selectedDeadline != null ? Colors.redAccent : Colors.grey),
                            ),
                            const Spacer(),
                            if (selectedDeadline != null)
                              GestureDetector(
                                onTap: () => setState(() => selectedDeadline = null),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _taskController.clear();
                    motivationController.dispose();
                    rewardController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = _taskController.text.trim();
                    if (title.length < 3) {
                      setState(() => errorMessage = 'El título debe tener al menos 3 caracteres');
                      return;
                    }
                    int? dueTimeMinutes;
                    if (selectedDueTime != null) {
                      dueTimeMinutes = selectedDueTime!.hour * 60 + selectedDueTime!.minute;
                    }

                    // Determinar qué campos limpiar
                    final motivationText = motivationController.text.trim();
                    final rewardText = rewardController.text.trim();

                    // Update the original task in-place (preserves Hive reference)
                    task.updateInPlace(
                      title: title,
                      priority: selectedPriority,
                      category: selectedCategory,
                      dueDate: selectedDueDate,
                      clearDueDate: selectedDueDate == null && task.dueDate != null,
                      dueTimeMinutes: dueTimeMinutes,
                      clearDueTime: dueTimeMinutes == null && task.dueTimeMinutes != null,
                      motivation: motivationText.isNotEmpty ? motivationText : null,
                      clearMotivation: motivationText.isEmpty && task.motivation != null,
                      reward: rewardText.isNotEmpty ? rewardText : null,
                      clearReward: rewardText.isEmpty && task.reward != null,
                      deadline: selectedDeadline,
                      clearDeadline: selectedDeadline == null && task.deadline != null,
                      lastUpdatedAt: DateTime.now(),
                    );
                    ref
                        .read(tasksProvider(task.type).notifier)
                        .updateTask(task);
                    _taskController.clear();
                    motivationController.dispose();
                    rewardController.dispose();
                    Navigator.pop(context);
                    _showSnackBar('✅ Tarea actualizada');
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AuraList',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          // Indicador de sincronización pendiente
          if (_pendingSyncCount > 0)
            Tooltip(
              message: '$_pendingSyncCount tareas pendientes de sincronizar',
              child: IconButton(
                icon: Badge(
                  label: Text('$_pendingSyncCount'),
                  child: const Icon(Icons.cloud_upload_outlined),
                ),
                onPressed: () async {
                  _showSnackBar('Sincronizando...');
                  await ref.read(databaseServiceProvider).forceSyncPendingTasks();
                  await _updateSyncCount();
                  if (mounted) {
                    _showSnackBar(_pendingSyncCount == 0
                        ? 'Todo sincronizado'
                        : '$_pendingSyncCount pendientes');
                  }
                },
              ),
            ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            tooltip: 'Cambiar Tema',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'DÍA', icon: Icon(Icons.wb_sunny_outlined, size: 20)),
            Tab(
              text: 'SEMANA',
              icon: Icon(Icons.calendar_view_week_outlined, size: 20),
            ),
            Tab(
              text: 'MES',
              icon: Icon(Icons.calendar_month_outlined, size: 20),
            ),
            Tab(text: 'AÑO', icon: Icon(Icons.event_outlined, size: 20)),
            Tab(text: 'ÚNICAS', icon: Icon(Icons.push_pin_outlined, size: 20)),
            Tab(text: 'CALENDARIO', icon: Icon(Icons.calendar_today, size: 20)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                const DateHeader(type: 'daily'),
                Expanded(child: TaskList(type: 'daily', onEditTask: _showEditTaskDialog, onFeedback: _showSnackBar)),
              ],
            ),
            Column(
              children: [
                const DateHeader(type: 'weekly'),
                Expanded(child: TaskList(type: 'weekly', onEditTask: _showEditTaskDialog, onFeedback: _showSnackBar)),
              ],
            ),
            Column(
              children: [
                const DateHeader(type: 'monthly'),
                Expanded(child: TaskList(type: 'monthly', onEditTask: _showEditTaskDialog, onFeedback: _showSnackBar)),
              ],
            ),
            Column(
              children: [
                const DateHeader(type: 'yearly'),
                Expanded(child: TaskList(type: 'yearly', onEditTask: _showEditTaskDialog, onFeedback: _showSnackBar)),
              ],
            ),
            Column(
              children: [
                const DateHeader(type: 'once'),
                Expanded(child: TaskList(type: 'once', onEditTask: _showEditTaskDialog, onFeedback: _showSnackBar)),
              ],
            ),
            SingleChildScrollView(
              child: CalendarView(
                onDateSelected: (date) {
                  // Opcionalmente hacer algo cuando se selecciona una fecha
                },
                onTaskTap: (task) => _showEditTaskDialog(task),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        label: const Text(
          'Nueva Tarea',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_task_rounded),
      ),
    );
  }
}
