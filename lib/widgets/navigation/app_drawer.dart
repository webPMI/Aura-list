import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final themeMode = ref.watch(themeProvider);

    return NavigationDrawer(
      selectedIndex: selectedRoute.index,
      onDestinationSelected: (index) {
        final route = AppRouteExtension.fromIndex(index);
        ref.read(selectedRouteProvider.notifier).state = route;
        onNavigate?.call();
      },
      children: [
        // Beautiful gradient header
        _DrawerHeader(),
        const SizedBox(height: 16),

        // Main Navigation
        const NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Inicio'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.checklist_outlined),
          selectedIcon: Icon(Icons.checklist),
          label: Text('Mis Tareas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.note_outlined),
          selectedIcon: Icon(Icons.note),
          label: Text('Notas'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: Text('Calendario'),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Divider(height: 1),
        ),

        // Settings Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _SectionHeader(
            icon: Icons.settings_outlined,
            title: 'Configuracion',
          ),
        ),

        // Theme Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AnimatedListTile(
            leading: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Tema'),
            subtitle: Text(
              themeMode == ThemeMode.dark ? 'Oscuro' : 'Claro',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
            ),
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ),

        // Sync Status
        _SyncStatusTile(),

        // Settings Navigation
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Ajustes'),
        ),

        const SizedBox(height: 8),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(height: 1),
        ),

        // Profile Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _SectionHeader(
            icon: Icons.person_outline,
            title: 'Perfil',
          ),
        ),

        // Account Section
        _AccountSection(onNavigate: onNavigate),

        const SizedBox(height: 24),

        // About Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _SectionHeader(
            icon: Icons.info_outline,
            title: 'Acerca de',
          ),
        ),

        _AboutSection(),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get today's tasks to show completion stats
    final dailyTasks = ref.watch(tasksProvider('daily'));
    final completedToday = dailyTasks.where((task) => task.isCompleted).length;
    final totalToday = dailyTasks.length;
    final progressPercent = totalToday > 0 ? completedToday / totalToday : 0.0;

    // Motivational messages based on completion
    String motivationalMessage;
    IconData motivationIcon;
    if (completedToday == 0 && totalToday > 0) {
      motivationalMessage = 'Comienza tu dia!';
      motivationIcon = Icons.wb_sunny;
    } else if (completedToday == totalToday && totalToday > 0) {
      motivationalMessage = 'Todo listo!';
      motivationIcon = Icons.celebration;
    } else if (completedToday > 0) {
      motivationalMessage = 'Sigue asi!';
      motivationIcon = Icons.trending_up;
    } else {
      motivationalMessage = 'Listo para empezar';
      motivationIcon = Icons.rocket_launch;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.secondary.withValues(alpha: 0.2),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.secondary.withValues(alpha: 0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative circles (smaller)
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon/Logo + Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AuraList',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMM', 'es_ES')
                                  .format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalToday > 0
                                  ? '$completedToday de $totalToday tareas'
                                  : 'Sin tareas hoy',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  motivationIcon,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  motivationalMessage,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (totalToday > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercent,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedListTile extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _AnimatedListTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<_AnimatedListTile> createState() => _AnimatedListTileState();
}

class _AnimatedListTileState extends State<_AnimatedListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(databaseServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<int>(
      future: dbService.getTotalPendingSyncCount(),
      builder: (context, snapshot) {
        final syncCount = snapshot.data ?? 0;
        final isSyncing = snapshot.connectionState == ConnectionState.waiting;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AnimatedListTile(
            leading: isSyncing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : syncCount > 0
                    ? Badge(
                        label: Text('$syncCount'),
                        backgroundColor: colorScheme.error,
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: colorScheme.onSurface,
                        ),
                      )
                    : Icon(
                        Icons.cloud_done_outlined,
                        color: Colors.green.shade600,
                      ),
            title: Text(
              syncCount > 0
                  ? 'Sincronizacion'
                  : isSyncing
                      ? 'Verificando...'
                      : 'Todo sincronizado',
            ),
            subtitle: syncCount > 0
                ? Text(
                    '$syncCount pendientes - Toca para sincronizar',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                : null,
            onTap: syncCount > 0
                ? () async {
                    await dbService.forceSyncPendingTasks();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Sincronizando...'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    }
                  }
                : null,
          ),
        );
      },
    );
  }
}

class _AccountSection extends ConsumerWidget {
  final VoidCallback? onNavigate;

  const _AccountSection({this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: authState.when(
        data: (user) {
          final isAnonymous = user?.isAnonymous ?? true;
          final email = authService.linkedEmail;
          final userName = isAnonymous
              ? 'Usuario Anonimo'
              : (email ?? 'Usuario');
          final firstLetter = userName[0].toUpperCase();

          return _AnimatedListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              radius: 24,
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: user != null ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.isAnonymous == true
                          ? 'Solo en este dispositivo'
                          : user != null
                              ? 'Sincronizado en la nube'
                              : 'Sin conexion',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca para ver tu perfil',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              ref.read(selectedRouteProvider.notifier).state = AppRoute.profile;
              onNavigate?.call();
            },
          );
        },
        loading: () => const ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Cargando...'),
        ),
        error: (error, stackTrace) => _AnimatedListTile(
          leading: Icon(Icons.error_outline, color: colorScheme.error),
          title: const Text('Error de autenticacion'),
          subtitle: const Text(
            'Toca para ver perfil',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            ref.read(selectedRouteProvider.notifier).state = AppRoute.profile;
            onNavigate?.call();
          },
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final buildNumber = snapshot.data?.buildNumber ?? '1';

          return _AnimatedListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            title: const Text(
              'AuraList',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version $version ($buildNumber)',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hecho con Flutter',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAboutDialog(context, version, buildNumber),
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String version, String build) {
    final colorScheme = Theme.of(context).colorScheme;

    showAboutDialog(
      context: context,
      applicationName: 'AuraList',
      applicationVersion: 'Version $version ($build)',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.check_circle,
          size: 32,
          color: Colors.white,
        ),
      ),
      applicationLegalese: '© 2026 AuraList',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Tu gestor de tareas offline-first con sincronizacion en la nube.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Hecho con Flutter y Riverpod',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          'Creado por ink.enzo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Contacto: servicioweb.pmi@gmail.com',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
