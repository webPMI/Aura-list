import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/constants/legal/terms_of_service.dart';
import '../core/constants/legal/privacy_policy.dart';
import '../providers/task_provider.dart';
import '../widgets/navigation/drawer_menu_button.dart';
import '../widgets/auth/auth_action_sheet.dart';
import '../widgets/auth/sync_toggle_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;
    final horizontalPadding = context.horizontalPadding;

    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: const Text('Perfil'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxFormWidth + (horizontalPadding * 2),
          ),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : horizontalPadding,
            ),
            children: [
              // Account Section
              _SectionHeader('Cuenta'),
              _AccountSection(),

              const Divider(),

              // Statistics Section
              _SectionHeader('Tus Estadisticas'),
              _UserStatistics(),

              const Divider(),

              // Legal Section
              _SectionHeader('Legal'),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terminos y Condiciones'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLegalDocument(
                  context,
                  'Terminos y Condiciones',
                  termsOfServiceEs,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Politica de Privacidad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLegalDocument(
                  context,
                  'Politica de Privacidad',
                  privacyPolicyEs,
                ),
              ),

              const Divider(),

              // Privacy Controls Section
              _SectionHeader('Privacidad'),
              const SyncToggleTile(),
              ListTile(
                leading: Icon(
                  Icons.remove_circle_outline,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Revocar consentimientos',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text('Desactiva sincronizacion y elimina datos en la nube'),
                onTap: () => _showRevokeConsentsDialog(context, ref),
              ),

              const Divider(),

              // Danger Zone Section
              _SectionHeader('Zona de Peligro'),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Eliminar cuenta',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text('Esta accion no se puede deshacer'),
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),

              const Divider(),

              // About Section
              _SectionHeader('Acerca de'),
              _AboutSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegalDocument(
    BuildContext context,
    String title,
    String content,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _LegalDocumentScreen(
          title: title,
          content: content,
        ),
      ),
    );
  }

  void _showRevokeConsentsDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 48),
        title: const Text('Revocar consentimientos?'),
        content: const Text(
          'Esta accion desactivara la sincronizacion en la nube y eliminara '
          'tus datos del servidor. Tus datos locales se mantendran en este dispositivo.\n\n'
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _revokeConsents(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeConsents(BuildContext context, WidgetRef ref) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;

      if (user != null) {
        // Delete cloud data but keep local data
        await dbService.deleteAllUserDataFromCloud(user.uid);
      }

      // Update user preferences to disable cloud sync
      final prefs = await dbService.getUserPreferences();
      prefs.cloudSyncEnabled = false;
      await prefs.save();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consentimientos revocados. Tus datos locales se mantienen.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al revocar consentimientos: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever, color: colorScheme.error, size: 48),
        title: const Text('Eliminar cuenta?'),
        content: const Text(
          'Esta accion eliminara permanentemente:\n\n'
          '- Todas tus tareas\n'
          '- Todas tus notas\n'
          '- Tu historial de progreso\n'
          '- Tu cuenta de usuario\n\n'
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 48),
        title: const Text('Confirmacion final'),
        content: const Text(
          'Escribe "ELIMINAR" para confirmar que deseas eliminar tu cuenta y todos tus datos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    // Use a separate dialog with text field for confirmation
    showDialog(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () => _deleteAccount(context, ref),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);

      final success = await authService.deleteAccount(dbService);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta eliminada exitosamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Navigate to home or show onboarding
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la cuenta. Intenta de nuevo.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return authState.when(
      data: (user) {
        final isAnonymous = user?.isAnonymous ?? true;
        final email = authService.linkedEmail;
        final provider = authService.linkedProvider;

        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                radius: 24,
                child: Icon(
                  isAnonymous ? Icons.person_outline : Icons.person,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              title: Text(
                isAnonymous ? 'Cuenta anonima' : (email ?? 'Usuario vinculado'),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                isAnonymous
                    ? 'Tus datos solo estan en este dispositivo'
                    : 'Vinculada con ${_getProviderName(provider)}',
              ),
            ),
            if (isAnonymous)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showLinkAccountOptions(context, ref),
                    icon: const Icon(Icons.link),
                    label: const Text('Vincular cuenta'),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Cargando...'),
      ),
      error: (error, stackTrace) => ListTile(
        leading: Icon(Icons.error_outline, color: colorScheme.error),
        title: const Text('Error de autenticacion'),
      ),
    );
  }

  String _getProviderName(String? provider) {
    return switch (provider) {
      'email' => 'correo electronico',
      'google' => 'Google',
      _ => 'cuenta externa',
    };
  }

  void _showLinkAccountOptions(BuildContext context, WidgetRef ref) {
    showAuthActionSheet(context: context, ref: ref);
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const _LegalDocumentScreen({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxFormWidth + (horizontalPadding * 2),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserStatistics extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Get all tasks
    final dailyTasks = ref.watch(tasksProvider('daily'));
    final weeklyTasks = ref.watch(tasksProvider('weekly'));
    final monthlyTasks = ref.watch(tasksProvider('monthly'));
    final yearlyTasks = ref.watch(tasksProvider('yearly'));
    final onceTasks = ref.watch(tasksProvider('once'));

    // Calculate totals
    final allTasks = [
      ...dailyTasks,
      ...weeklyTasks,
      ...monthlyTasks,
      ...yearlyTasks,
      ...onceTasks
    ];
    final totalTasks = allTasks.length;
    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;

    // Calculate completion rate
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).toInt() : 0;

    // Priority breakdown
    final highPriority = allTasks.where((t) => t.priority == 2).length;
    final mediumPriority = allTasks.where((t) => t.priority == 1).length;
    final lowPriority = allTasks.where((t) => t.priority == 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Main stats card
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Completion rate circle
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: completionRate / 100,
                            strokeWidth: 12,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            color: _getCompletionColor(completionRate, colorScheme),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$completionRate%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Completado',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.check_circle,
                        label: 'Completadas',
                        value: '$completedTasks',
                        color: Colors.green,
                      ),
                      _StatItem(
                        icon: Icons.pending_outlined,
                        label: 'Pendientes',
                        value: '$pendingTasks',
                        color: Colors.orange,
                      ),
                      _StatItem(
                        icon: Icons.list_alt,
                        label: 'Total',
                        value: '$totalTasks',
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priority breakdown
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tareas por Prioridad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PriorityBar(
                    label: 'Alta',
                    count: highPriority,
                    total: totalTasks,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _PriorityBar(
                    label: 'Media',
                    count: mediumPriority,
                    total: totalTasks,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _PriorityBar(
                    label: 'Baja',
                    count: lowPriority,
                    total: totalTasks,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Task types breakdown
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tareas por Tipo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TypeRow(icon: Icons.wb_sunny, label: 'Diarias', count: dailyTasks.length),
                  _TypeRow(icon: Icons.calendar_view_week, label: 'Semanales', count: weeklyTasks.length),
                  _TypeRow(icon: Icons.calendar_month, label: 'Mensuales', count: monthlyTasks.length),
                  _TypeRow(icon: Icons.event, label: 'Anuales', count: yearlyTasks.length),
                  _TypeRow(icon: Icons.push_pin, label: 'Unicas', count: onceTasks.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(int rate, ColorScheme colorScheme) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return colorScheme.primary;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _PriorityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? count / total : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _TypeRow({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({required this.onConfirm});

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canConfirm = _controller.text.trim().toUpperCase() == 'ELIMINAR';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 48),
      title: const Text('Confirmacion final'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escribe "ELIMINAR" para confirmar que deseas eliminar tu cuenta y todos tus datos permanentemente.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'ELIMINAR',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _canConfirm
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}

/// Seccion "Acerca de" con informacion del creador
class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App icon/logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // App name
              Text(
                'AuraList',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu gestor de tareas inteligente',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              // Divider
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              // Creator info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Creado por ',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'ink.enzo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Contact
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  SelectableText(
                    'servicioweb.pmi@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Made with love
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hecho con ',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  Text(
                    ' en Flutter',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
