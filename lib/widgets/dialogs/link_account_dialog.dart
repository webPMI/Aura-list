import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

/// Shows a modal bottom sheet for linking an anonymous account to
/// email/password or Google Sign-In.
///
/// Example usage:
/// ```dart
/// showLinkAccountDialog(context: context, ref: ref);
/// ```
Future<void> showLinkAccountDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LinkAccountDialogContent(ref: ref),
  );
}

class _LinkAccountDialogContent extends StatefulWidget {
  final WidgetRef ref;

  const _LinkAccountDialogContent({required this.ref});

  @override
  State<_LinkAccountDialogContent> createState() =>
      _LinkAccountDialogContentState();
}

class _LinkAccountDialogContentState extends State<_LinkAccountDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showEmailForm = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es obligatoria';
    }
    if (value.length < 6) {
      return 'Minimo 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contrasena';
    }
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _linkWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = widget.ref.read(authServiceProvider);
      final result = await authService.linkWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _successMessage = 'Cuenta vinculada exitosamente';
            _isLoading = false;
          });
          // Close dialog after showing success message
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage = 'No se pudo vincular la cuenta. Intenta de nuevo.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al vincular cuenta: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _linkWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = widget.ref.read(authServiceProvider);
      final (:credential, :error) = await authService.linkWithGoogle();

      if (mounted) {
        if (credential != null) {
          setState(() {
            _successMessage = 'Cuenta vinculada con Google exitosamente';
            _isLoading = false;
          });
          // Close dialog after showing success message
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else if (error != null) {
          // Show specific error from the service
          setState(() {
            _errorMessage = error;
            _isLoading = false;
          });
        } else {
          // User cancelled - just reset loading state
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al vincular con Google: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
                  color: Colors.grey.withValues(alpha: 0.3),
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
                        Icons.link,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vincular Cuenta',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Protege tus datos y sincroniza entre dispositivos',
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
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
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
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
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
                child: _showEmailForm ? _buildEmailForm() : _buildOptions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 32),
              const SizedBox(height: 8),
              Text(
                'Al vincular tu cuenta:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '- Tus datos se sincronizaran en la nube\n'
                '- Podras acceder desde otros dispositivos\n'
                '- Tus datos actuales se mantendran',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Google Sign-In button
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _linkWithGoogle,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                ),
          label: const Text('Continuar con Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 16),

        // Email/Password button
        FilledButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() => _showEmailForm = true);
                },
          icon: const Icon(Icons.email_outlined),
          label: const Text('Vincular con correo y contrasena'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(16),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _showEmailForm = false;
                      _errorMessage = null;
                    });
                  },
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
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
            onPressed: _isLoading ? null : _linkWithEmail,
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
}
