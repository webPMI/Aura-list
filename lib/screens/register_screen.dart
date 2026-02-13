import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/auth/password_strength_indicator.dart';
import '../widgets/auth/unified_google_auth_button.dart';
import '../widgets/dialogs/legal_document_viewer.dart';
import '../core/constants/legal/terms_of_service.dart';
import '../core/constants/legal/privacy_policy.dart';
import 'main_scaffold.dart';

/// Pantalla de registro con email y contrasena
/// Incluye validacion completa de campos
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

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
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electronico valido';
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
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe tener al menos una mayuscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe tener al menos un numero';
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los terminos y condiciones';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Primero, asegurarse de que hay un usuario anonimo
      var currentUser = authService.currentUser;
      if (currentUser == null) {
        // Crear usuario anonimo primero
        final anonResult = await authService.signInAnonymously();
        if (anonResult == null) {
          throw Exception('No se pudo crear sesion inicial');
        }
        currentUser = anonResult.user;
      }

      // Ahora vincular con email/password
      final result = await authService.linkWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result != null) {
          // Enable cloud sync automatically when account is linked
          final dbService = ref.read(databaseServiceProvider);
          await dbService.setCloudSyncEnabled(true);

          if (!mounted) return;

          // Registro exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navegar a la pantalla principal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScaffold()),
          );
        } else {
          setState(() {
            _errorMessage = 'No se pudo crear la cuenta. Intenta de nuevo.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al crear cuenta: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = context.horizontalPadding;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Breakpoints.maxFormWidth + (horizontalPadding * 2),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Registrate en AuraList',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una cuenta para sincronizar tus tareas en todos tus dispositivos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mensaje de error
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
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

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Correo electronico',
                            hintText: 'tu@correo.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo de contrasena
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          enabled: !_isLoading,
                          onChanged: (_) =>
                              setState(() {}), // Actualizar indicador
                          decoration: InputDecoration(
                            labelText: 'Contrasena',
                            hintText: 'Minimo 6 caracteres',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                        // Indicador de fortaleza de contrasena
                        PasswordStrengthIndicator(
                          password: _passwordController.text,
                        ),
                        const SizedBox(height: 16),

                        // Campo de confirmar contrasena
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
                          enabled: !_isLoading,
                          onFieldSubmitted: (_) => _handleRegister(),
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
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Checkbox de terminos con enlaces clickeables
                        _TermsAcceptanceWidget(
                          value: _acceptedTerms,
                          enabled: !_isLoading,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value;
                              if (_acceptedTerms) {
                                _errorMessage = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Boton de registro
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _handleRegister,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            _isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                          ),
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
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o registrate con',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Boton de Google
                  UnifiedGoogleAuthButton(
                    requireTermsAcceptance: _acceptedTerms,
                    customLabel: 'Registrarse con Google',
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSuccess: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MainScaffold(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Ya tienes cuenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ya tienes cuenta?',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Inicia sesion'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget mejorado para aceptacion de terminos con enlaces clickeables
class _TermsAcceptanceWidget extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TermsAcceptanceWidget({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  void _showTermsOfService(BuildContext context) {
    showLegalDocumentDialog(
      context: context,
      title: 'Terminos y Condiciones',
      content: termsOfServiceEs,
      summary: termsSummaryEs,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showLegalDocumentDialog(
      context: context,
      title: 'Politica de Privacidad',
      content: privacyPolicyEs,
      summary: privacySummaryEs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Acepto los terminos y condiciones y la politica de privacidad',
      checked: value,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox mas grande y accesible
              SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? (val) => onChanged(val ?? false) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Texto con enlaces clickeables
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: enabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'Terminos y Condiciones',
                          style: TextStyle(
                            color: enabled
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.38),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: enabled
                              ? (TapGestureRecognizer()
                                  ..onTap = () => _showTermsOfService(context))
                              : null,
                        ),
                        const TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'Politica de Privacidad',
                          style: TextStyle(
                            color: enabled
                                ? colorScheme.primary
                                : colorScheme.primary.withValues(alpha: 0.38),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: enabled
                              ? (TapGestureRecognizer()
                                  ..onTap = () => _showPrivacyPolicy(context))
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
