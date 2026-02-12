import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:checklist_app/features/guides/guides.dart';

import '../core/responsive/breakpoints.dart';
import '../providers/theme_provider.dart';
import '../providers/update_provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/navigation/drawer_menu_button.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = context.isMobile;
    final horizontalPadding = context.horizontalPadding;

    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: const Text('Ajustes'),
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
              // Profile Section
              const _ProfileTile(),

              const Divider(),

              // Appearance Section
              _SectionHeader('Apariencia'),
              const _GuideCelestialTile(),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Tema'),
                subtitle: Text(_getThemeName(themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeProvider.notifier).setThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistema'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Claro'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Oscuro'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Data Section
              _SectionHeader('Datos'),
              const _CloudSyncToggle(),
              const _SyncStatusTile(),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Exportar datos'),
                subtitle: const Text('Descargar tus tareas y notas'),
                onTap: () => _showExportDialog(context),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Borrar todos los datos',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text('Esta accion no se puede deshacer'),
                onTap: () => _showDeleteConfirmDialog(context, ref),
              ),

              const Divider(),

              // Account Section
              _SectionHeader('Cuenta'),
              const _AccountTile(),

              const Divider(),

              // About Section
              _SectionHeader('Acerca de'),
              const _VersionTile(),
              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: const Text('Buscar actualizaciones'),
                subtitle: const Text('Verificar si hay nuevas versiones'),
                onTap: () => checkForUpdatesManually(ref, context),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licencias'),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'AuraList',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Seguir sistema',
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
    };
  }

  Future<void> _showExportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar datos'),
        content: const Text(
          'Esta funcion estara disponible proximamente. '
          'Podras exportar tus tareas y notas en formato JSON.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar todos los datos?'),
        content: const Text(
          'Esta accion eliminara todas tus tareas, notas e historial. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllData(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;

      // Delete all cloud data if user is authenticated
      if (user != null) {
        await dbService.deleteAllUserDataFromCloud(user.uid);
      }

      // Clear all local data
      await dbService.clearAllLocalData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los datos han sido eliminados'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar datos: $e'),
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

class _GuideCelestialTile extends ConsumerWidget {
  const _GuideCelestialTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(activeGuideProvider);

    return ListTile(
      leading: GuideAvatar(size: 40, showBorder: guide != null),
      title: const Text('Guía celestial'),
      subtitle: Text(
        guide?.title ?? 'Toca para elegir tu guía',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showGuideSelectorSheet(context),
    );
  }
}

class _CloudSyncToggle extends ConsumerStatefulWidget {
  const _CloudSyncToggle();

  @override
  ConsumerState<_CloudSyncToggle> createState() => _CloudSyncToggleState();
}

class _CloudSyncToggleState extends ConsumerState<_CloudSyncToggle> {
  bool _isLoading = true;
  bool _syncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSyncPreference();
  }

  Future<void> _loadSyncPreference() async {
    final dbService = ref.read(databaseServiceProvider);
    final enabled = await dbService.isCloudSyncEnabled();
    if (mounted) {
      setState(() {
        _syncEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSync(bool value) async {
    setState(() => _isLoading = true);

    final dbService = ref.read(databaseServiceProvider);
    await dbService.setCloudSyncEnabled(value);

    // If enabling sync, trigger initial sync
    if (value) {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        await dbService.performFullSync(user.uid);
      }
    }

    if (mounted) {
      setState(() {
        _syncEnabled = value;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Sincronizacion a la nube activada'
                : 'Sincronizacion a la nube desactivada',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _syncEnabled ? Icons.cloud_outlined : Icons.cloud_off_outlined,
      ),
      title: const Text('Sincronizar a la nube'),
      subtitle: Text(
        _syncEnabled
            ? 'Tus datos se sincronizan con Firebase'
            : 'Tus datos solo se guardan localmente',
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _syncEnabled,
              onChanged: _toggleSync,
            ),
    );
  }
}

class _SyncStatusTile extends ConsumerWidget {
  const _SyncStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbService = ref.watch(databaseServiceProvider);

    return FutureBuilder<int>(
      future: dbService.getTotalPendingSyncCount(),
      builder: (context, snapshot) {
        final syncCount = snapshot.data ?? 0;

        return ListTile(
          leading: syncCount > 0
              ? Badge(
                  label: Text('$syncCount'),
                  child: const Icon(Icons.cloud_sync_outlined),
                )
              : Icon(Icons.cloud_done_outlined, color: Colors.green.shade600),
          title: const Text('Sincronizacion'),
          subtitle: Text(
            syncCount > 0
                ? '$syncCount elementos pendientes'
                : 'Todo sincronizado',
          ),
          trailing: syncCount > 0
              ? TextButton(
                  onPressed: () async {
                    await dbService.forceSyncPendingTasks();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sincronizando...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Sincronizar'),
                )
              : null,
        );
      },
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return authState.when(
      data: (user) => ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.person_outline, color: colorScheme.primary),
        ),
        title: Text(user != null ? 'Usuario conectado' : 'Sin cuenta'),
        subtitle: Text(
          user?.isAnonymous == true ? 'Modo anonimo' : 'No autenticado',
        ),
        trailing: user != null
            ? TextButton(
                onPressed: () => _showLogoutDialog(context, ref),
                child: const Text('Cerrar sesion'),
              )
            : TextButton(
                onPressed: () => _showSignInDialog(context, ref),
                child: const Text('Iniciar sesion'),
              ),
      ),
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Cargando...'),
      ),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: const Text('Error de autenticacion'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text(
          'Los datos locales se mantendran. Deseas cerrar sesion?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar sesion'),
        content: const Text(
          'Para iniciar sesion con una cuenta existente, '
          've a la pantalla de Perfil y vincula tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const Text('Ir a Perfil'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return authState.when(
      data: (user) {
        final isAnonymous = user?.isAnonymous ?? true;
        final email = user?.email;
        final subtitle = isAnonymous
            ? 'Cuenta anonima'
            : (email ?? 'Cuenta vinculada');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, color: colorScheme.primary),
          ),
          title: const Text('Mi Perfil'),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        );
      },
      loading: () => ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        title: const Text('Mi Perfil'),
        subtitle: const Text('Cargando...'),
      ),
      error: (_, _) => ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.errorContainer,
          child: Icon(Icons.person, color: colorScheme.error),
        ),
        title: const Text('Mi Perfil'),
        subtitle: const Text('Error al cargar'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    );
  }
}

class _VersionTile extends ConsumerWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        final buildNumber = snapshot.data?.buildNumber ?? '1';

        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: Text('$version+$buildNumber'),
        );
      },
    );
  }
}
