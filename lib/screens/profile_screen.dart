import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/constants/legal/terms_of_service.dart';
import '../core/constants/legal/privacy_policy.dart';
import '../widgets/navigation/drawer_menu_button.dart';

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
              _CloudSyncToggle(),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vincular cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Vincula tu cuenta para sincronizar tus datos entre dispositivos '
                'y no perderlos si cambias de telefono.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Vincular con correo electronico'),
              onTap: () {
                Navigator.pop(context);
                _showEmailLinkDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.g_mobiledata),
              title: const Text('Vincular con Google'),
              onTap: () async {
                Navigator.pop(context);
                await _linkWithGoogle(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEmailLinkDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular con correo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electronico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Correo invalido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contrasena',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una contrasena';
                  }
                  if (value.length < 6) {
                    return 'Minimo 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _linkWithEmail(
                  context,
                  ref,
                  emailController.text,
                  passwordController.text,
                );
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkWithEmail(
    BuildContext context,
    WidgetRef ref,
    String email,
    String password,
  ) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.linkWithEmailPassword(email, password);

    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta vinculada exitosamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo vincular la cuenta'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _linkWithGoogle(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.linkWithGoogle();

    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta vinculada con Google exitosamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo vincular con Google'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _CloudSyncToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CloudSyncToggle> createState() => _CloudSyncToggleState();
}

class _CloudSyncToggleState extends ConsumerState<_CloudSyncToggle> {
  bool _cloudSyncEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final dbService = ref.read(databaseServiceProvider);
    final prefs = await dbService.getUserPreferences();
    if (mounted) {
      setState(() {
        _cloudSyncEnabled = prefs.cloudSyncEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCloudSync(bool value) async {
    final dbService = ref.read(databaseServiceProvider);
    final prefs = await dbService.getUserPreferences();
    prefs.cloudSyncEnabled = value;
    await prefs.save();

    if (mounted) {
      setState(() {
        _cloudSyncEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Sincronizacion en la nube activada'
                : 'Sincronizacion en la nube desactivada',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Sincronizacion en la nube'),
      );
    }

    return SwitchListTile(
      secondary: const Icon(Icons.cloud_sync_outlined),
      title: const Text('Sincronizacion en la nube'),
      subtitle: Text(
        _cloudSyncEnabled
            ? 'Tus datos se sincronizan automaticamente'
            : 'Tus datos solo estan en este dispositivo',
      ),
      value: _cloudSyncEnabled,
      onChanged: _toggleCloudSync,
    );
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
