import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_manager.dart';

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

class _AuthActionSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AuthActionSheet({required this.ref});

  @override
  State<_AuthActionSheet> createState() => _AuthActionSheetState();
}

class _AuthActionSheetState extends State<_AuthActionSheet> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showEmailForm = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authManager = widget.ref.read(authManagerProvider);
      final isAnonymous = authManager.currentUser?.isAnonymous ?? true;

      final result = isAnonymous
          ? await authManager.linkWithGoogle()
          : await authManager.signInWithGoogle();

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _successMessage = isAnonymous
              ? 'Cuenta vinculada con Google'
              : 'Sesion iniciada con Google';
          _isLoading = false;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else if (result.cancelled) {
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Error desconocido';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authManager = widget.ref.read(authManagerProvider);
      final result = await authManager.linkWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _successMessage = 'Cuenta vinculada exitosamente';
          _isLoading = false;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Error al vincular cuenta';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isAnonymous
                                ? 'Sincroniza y protege tus datos'
                                : 'Accede a tu cuenta',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
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

              // Feedback messages
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _showEmailForm
                    ? _buildEmailForm(colorScheme)
                    : _buildOptions(isAnonymous, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(bool isAnonymous, ColorScheme colorScheme) {
    return Column(
      children: [
        // Info card (solo si es vinculacion)
        if (isAnonymous)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_sync_outlined,
                    size: 32, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Al vincular tu cuenta:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

        // Google button
        OutlinedButton(
          onPressed: _isLoading ? null : _handleGoogleAuth,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                ),
              const SizedBox(width: 12),
              Text(
                isAnonymous ? 'Continuar con Google' : 'Iniciar con Google',
              ),
            ],
          ),
        ),

        // Solo mostrar opcion de email para vincular (no login)
        if (isAnonymous) ...[
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: colorScheme.onSurface.withValues(alpha: 0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('o',
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
              Expanded(
                  child: Divider(
                      color: colorScheme.onSurface.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(height: 16),

          // Email button
          FilledButton.icon(
            onPressed:
                _isLoading ? null : () => setState(() => _showEmailForm = true),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Vincular con correo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmailForm(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _showEmailForm = false;
                      _errorMessage = null;
                    }),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver'),
          ),
          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Correo electronico',
              hintText: 'tu@correo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              hintText: 'Minimo 6 caracteres',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Al menos 6 caracteres, una mayuscula y un numero',
              helperMaxLines: 2,
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar contrasena',
              hintText: 'Repite tu contrasena',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),

          // Submit button
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleEmailAuth,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.link),
            label: const Text('Vincular Cuenta'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electronico valido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contrasena es obligatoria';
    if (value.length < 6) return 'Minimo 6 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe tener al menos una mayuscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe tener al menos un numero';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contrasena';
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }
}
