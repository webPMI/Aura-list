import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_manager.dart';
import 'auth_form.dart';

/// Muestra opciones de autenticacion/vinculacion segun el estado actual
Future<bool?> showAuthActionSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AuthActionSheet(ref: ref),
  );
}

class _AuthActionSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AuthActionSheet({required this.ref});

  @override
  ConsumerState<_AuthActionSheet> createState() => _AuthActionSheetState();
}

class _AuthActionSheetState extends ConsumerState<_AuthActionSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final authManager = widget.ref.read(authManagerProvider);
    final isAnonymous = authManager.currentUser?.isAnonymous ?? true;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAnonymous ? Icons.link : Icons.login,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAnonymous ? 'Vincular Cuenta' : 'Iniciar Sesion',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isAnonymous
                                ? 'Sincroniza y protege tus datos'
                                : 'Accede a tu cuenta',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildContent(isAnonymous, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isAnonymous, ColorScheme colorScheme) {
    // Si es anonimo, mostrar info de beneficios y formulario de vinculacion
    if (isAnonymous) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card de beneficios
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_sync_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Al vincular tu cuenta:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Tus datos se sincronizaran en la nube\n'
                  '• Podras acceder desde otros dispositivos\n'
                  '• Tus datos actuales se mantendran',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Formulario unificado de vinculacion
          AuthForm(
            mode: AuthMode.link,
            onSuccess: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    }

    // Si ya esta vinculado, mostrar formulario de login
    return AuthForm(
      mode: AuthMode.login,
      onSuccess: () {
        Navigator.pop(context, true);
      },
    );
  }
}



