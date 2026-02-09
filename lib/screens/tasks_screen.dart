import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/navigation/task_type_selector.dart';
import '../widgets/navigation/drawer_menu_button.dart';
import '../widgets/date_header.dart';
import '../widgets/task_list.dart';
import '../widgets/dialogs/task_form_dialog.dart';
import '../models/task_model.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedTaskTypeProvider);
    final isWideScreen = context.isTabletOrLarger;
    final horizontalPadding = context.horizontalPadding;
    final screenWidth = context.screenWidth;

    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: const Text('Mis Tareas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth,
          ),
          child: Column(
            children: [
              // Task type selector with responsive padding
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: context.isMobile ? 8 : 12,
                ),
                child: isWideScreen
                    ? const TaskTypeSelector(showLabels: true)
                    : const TaskTypeSelector(showLabels: false, scrollable: true),
              ),

              // Date header
              DateHeader(type: selectedType),

              // Task list with responsive layout
              Expanded(
                child: screenWidth > Breakpoints.tablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TaskList(
                              type: selectedType,
                              onEditTask: (task) => _showEditTaskDialog(context, task),
                              onFeedback: (message) => _showSnackBar(message),
                            ),
                          ),
                        ],
                      )
                    : TaskList(
                        type: selectedType,
                        onEditTask: (task) => _showEditTaskDialog(context, task),
                        onFeedback: (message) => _showSnackBar(message),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showTaskFormDialog(
      context: context,
      ref: ref,
      taskType: task.type,
      task: task,
    );
  }
}
