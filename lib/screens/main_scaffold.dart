import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../services/auth_service.dart';
import '../widgets/navigation/adaptive_navigation.dart';
import '../widgets/dialogs/task_form_dialog.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth initialization provider to ensure anonymous sign-in happens
    final authInit = ref.watch(authInitializationProvider);

    final selectedRoute = ref.watch(selectedRouteProvider);

    // Show loading screen while initializing auth
    return authInit.when(
      data: (_) => _buildScaffold(context, ref, selectedRoute),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        // Even if auth fails, show the app (offline mode)
        return _buildScaffold(context, ref, selectedRoute);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, AppRoute selectedRoute) {
    return AdaptiveNavigation(
      floatingActionButton: _buildFab(context, ref, selectedRoute),
      child: _buildContent(selectedRoute),
    );
  }

  Widget _buildContent(AppRoute route) {
    return switch (route) {
      AppRoute.dashboard => const DashboardScreen(),
      AppRoute.tasks => const TasksScreen(),
      AppRoute.notes => const NotesScreen(),
      AppRoute.calendar => const CalendarScreen(),
      AppRoute.settings => const SettingsScreen(),
      AppRoute.profile => const ProfileScreen(),
    };
  }

  Widget? _buildFab(BuildContext context, WidgetRef ref, AppRoute route) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dashboard: FAB directo que crea tarea diaria
    if (route == AppRoute.dashboard) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddTaskDialog(context, ref, 'daily');
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Tarea'),
      );
    }

    // Tasks: FAB directo que usa el tipo seleccionado actualmente
    if (route == AppRoute.tasks) {
      final selectedType = ref.watch(selectedTaskTypeProvider);
      final typeInfo = TaskTypes.all.firstWhere(
        (t) => t.type == selectedType,
        orElse: () => TaskTypes.all.first,
      );

      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddTaskDialog(context, ref, selectedType);
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text('Tarea ${typeInfo.label}'),
      );
    }

    // Notes: FAB simple para crear nota
    if (route == AppRoute.notes) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _navigateToNoteEditor(context, ref);
        },
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        icon: const Icon(Icons.note_add),
        label: const Text('Nueva Nota'),
      );
    }

    return null;
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    // Show the task form dialog directly
    await showTaskFormDialog(
      context: context,
      ref: ref,
      taskType: type,
    );
  }

  void _navigateToNoteEditor(BuildContext context, WidgetRef ref) {
    // Navigate to notes screen
    ref.read(selectedRouteProvider.notifier).state = AppRoute.notes;
  }
}
