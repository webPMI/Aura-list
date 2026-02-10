import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    final isSearchActive = ref.read(isSearchActiveProvider);
    if (isSearchActive) {
      // Close search and clear query
      ref.read(isSearchActiveProvider.notifier).state = false;
      ref.read(taskSearchQueryProvider.notifier).state = '';
      _searchController.clear();
    } else {
      // Open search
      ref.read(isSearchActiveProvider.notifier).state = true;
      // Focus the search field after the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _onSearchChanged(String value) {
    ref.read(taskSearchQueryProvider.notifier).state = value;
  }

  PreferredSizeWidget _buildAppBar(bool isSearchActive) {
    if (isSearchActive) {
      return _SearchAppBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onClose: _toggleSearch,
      );
    }

    return DrawerAwareAppBar(
      title: const Text('Mis Tareas'),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
          tooltip: 'Buscar',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedTaskTypeProvider);
    final isSearchActive = ref.watch(isSearchActiveProvider);
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final filteredTasks = ref.watch(filteredTasksProvider(selectedType));
    final isWideScreen = context.isTabletOrLarger;
    final horizontalPadding = context.horizontalPadding;
    final screenWidth = context.screenWidth;

    return Scaffold(
      appBar: _buildAppBar(isSearchActive),
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
                              filteredTasks: isSearchActive ? filteredTasks : null,
                              isSearching: isSearchActive,
                              searchQuery: searchQuery,
                              onEditTask: (task) => _showEditTaskDialog(context, task),
                              onFeedback: (message) => _showSnackBar(message),
                            ),
                          ),
                        ],
                      )
                    : TaskList(
                        type: selectedType,
                        filteredTasks: isSearchActive ? filteredTasks : null,
                        isSearching: isSearchActive,
                        searchQuery: searchQuery,
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

/// Custom AppBar for search mode with text field and close button
class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onClose,
        tooltip: 'Cerrar busqueda',
      ),
      title: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar tareas...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        textInputAction: TextInputAction.search,
      ),
      actions: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                onChanged('');
                focusNode.requestFocus();
              },
              tooltip: 'Limpiar',
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
