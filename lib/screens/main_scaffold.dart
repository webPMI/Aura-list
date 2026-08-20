import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/update_provider.dart';
import '../services/auth_service.dart';
import '../widgets/navigation/adaptive_navigation.dart';
import '../widgets/dialogs/task_form_dialog.dart';
import '../widgets/guide_greeting_widget.dart';
import '../widgets/guide_farewell_widget.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'notes_screen.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_editor.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import '../features/finance/screens/finance_screen.dart';
import '../features/finance/widgets/unified_transaction_dialog.dart';
import '../features/guides/providers/guide_onboarding_provider.dart';

import '../features/guides/widgets/guide_intro_modal.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  bool _hasCheckedIntro = false;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    // Check if we should show the guide intro modal after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGuideIntro();
    });
  }

  Future<void> _checkAndShowGuideIntro() async {
    if (_hasCheckedIntro || !mounted) return;
    _hasCheckedIntro = true;

    // Wait for the shouldShowGuideIntroProvider to resolve
    final shouldShow = await ref.read(shouldShowGuideIntroProvider.future);

    if (shouldShow && mounted) {
      // Wait a bit for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        showGuideIntroModal(context, ref);
      }
    }
  }

  void _handlePop(BuildContext context) {
    // 1. If search is active, close search
    if (ref.read(isSearchActiveProvider)) {
      ref.read(isSearchActiveProvider.notifier).state = false;
      ref.read(taskSearchQueryProvider.notifier).state = '';
      return;
    }

    // 2. If a task detail is selected in master-detail on mobile, clear it
    if (ref.read(selectedTaskIdProvider) != null) {
      ref.read(selectedTaskIdProvider.notifier).state = null;
      return;
    }

    // 3. If navigation history can go back, pop history
    final popped = ref.read(navigationHistoryProvider.notifier).goBack();
    if (popped) {
      return;
    }

    // 4. If on another root tab without history, return to dashboard
    final currentRoute = ref.read(selectedRouteProvider);
    if (currentRoute != AppRoute.dashboard) {
      ref.read(navigationHistoryProvider.notifier).goTo(AppRoute.dashboard);
      return;
    }

    // 5. If already on Dashboard, implement double-back-to-exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Presiona atrás de nuevo para salir'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Double pressed within 2 seconds -> close the app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth initialization provider to ensure anonymous sign-in happens
    final authInit = ref.watch(authInitializationProvider);

    final selectedRoute = ref.watch(selectedRouteProvider);

    // Show loading screen while initializing auth
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handlePop(context);
        }
      },
      child: authInit.when(
        data: (_) => _buildScaffold(context, ref, selectedRoute),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) {
          // Even if auth fails, show the app (offline mode)
          return _buildScaffold(context, ref, selectedRoute);
        },
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    AppRoute selectedRoute,
  ) {
    return UpdateChecker(
      child: GuideFarewellListener(
        child: Stack(
          children: [
            AdaptiveNavigation(
              floatingActionButton: _buildFab(context, ref, selectedRoute),
              child: _buildContent(selectedRoute),
            ),
            // Greeting overlay - visible en cualquier pantalla al abrir la app
            const GuideGreetingWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppRoute route) {
    return switch (route) {
      AppRoute.dashboard => const DashboardScreen(),
      AppRoute.tasks => const TasksScreen(),
      AppRoute.finance => const FinanceScreen(),
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
        heroTag: 'main_fab_dashboard',
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
        heroTag: 'main_fab_tasks',
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
        heroTag: 'main_fab_notes',
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showNoteEditor(context, ref);
        },
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        icon: const Icon(Icons.note_add),
        label: const Text('Nueva Nota'),
      );
    }

    // Finance: FAB para nueva transaccion
    if (route == AppRoute.finance) {
      return FloatingActionButton.extended(
        heroTag: 'main_fab_finance',
        onPressed: () {
          HapticFeedback.mediumImpact();
          showDialog(
            context: context,
            builder: (context) => const UnifiedTransactionDialog(),
          );
        },
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Transaccion'),
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
    await showTaskFormDialog(context: context, ref: ref, taskType: type);
  }

  void _showNoteEditor(BuildContext context, WidgetRef ref) {
    // Determine which provider to use for adding notes
    // In NotesScreen it uses independentNotesProvider.notifier
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          onSave:
              (
                title,
                content,
                color,
                tags,
                checklist, {
                String? richContent,
                String contentType = 'plain',
              }) async {
                try {
                  await ref
                      .read(independentNotesProvider.notifier)
                      .addNote(
                        title: title,
                        content: content,
                        color: color,
                        tags: tags,
                        checklist: checklist,
                        richContent: richContent,
                        contentType: contentType,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nota creada'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al guardar nota'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
        ),
      ),
    );
  }
}



