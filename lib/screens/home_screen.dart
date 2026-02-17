import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../widgets/task_list.dart';
import '../widgets/date_header.dart';
import '../widgets/calendar_view.dart';
import '../widgets/dialogs/add_task_dialog.dart';
import '../widgets/dialogs/task_form_dialog.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/utils/dialog_utils.dart';

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
    DialogUtils.showSnackBar(context, message, isError: isError, isUndo: isUndo, onUndo: onUndo);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    showAddTaskDialog(
      context: context,
      ref: ref,
      defaultType: _getCurrentType(),
      onTaskCreated: () {
        _showSnackBar('🎉 ¡Tarea creada!');
        _updateSyncCount();
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
    showTaskFormDialog(
      context: context,
      ref: ref,
      taskType: task.type,
      task: task,
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
            IconButton(
              icon: Badge(
                label: Text('$_pendingSyncCount'),
                child: const Icon(Icons.cloud_upload_outlined),
              ),
              tooltip: '$_pendingSyncCount tareas pendientes de sincronizar',
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
            tooltip: 'Más opciones',
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
