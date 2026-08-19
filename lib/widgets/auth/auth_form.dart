import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_manager.dart';
import '../../widgets/dialogs/forgot_password_dialog.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import '../../widgets/auth/unified_google_auth_button.dart';
import '../../widgets/dialogs/legal_document_viewer.dart';
import '../../core/constants/legal/terms_of_service.dart';
import '../../core/constants/legal/privacy_policy.dart';

/// Modo de autenticacion del formulario unificado
enum AuthMode {
  /// Iniciar sesion con cuenta existente
  login,

  /// Crear cuenta nueva
  register,

  /// Vincular cuenta anonima existente
  link,
}

/// Formulario unificado de autenticacion.
/// Maneja login, registro y vinculacion de cuenta en un solo componente.
/// Controla la logica de email/password y Google de forma centralizada.
class AuthForm extends ConsumerStatefulWidget {
  /// Modo de autenticacion (login, register, link)
  final AuthMode mode;

  /// Callback cuando la autenticacion es exitosa
  final VoidCallback? onSuccess;

  /// Mostrar boton de Google
  final bool showGoogleButton;

  /// Mostrar enlace de "Olvidaste tu contrasena?"
  final bool showForgotPassword;

  /// Mostrar checkbox de aceptacion de terminos
  final bool showTermsAcceptance;

  /// Mostrar divisor entre email y Google
  final bool showDivider;

  /// Texto personalizado del boton principal
  final String? submitLabel;

  /// Texto personalizado del boton de Google
  final String? googleLabel;

  /// Texto de ayuda bajo el titulo
  final String? helperText;

  /// Mostrar indicador de fortaleza de contrasena
  final bool showPasswordStrength;

  const AuthForm({
    super.key,
    required this.mode,
    this.onSuccess,
    this.showGoogleButton = true,
    this.showForgotPassword = true,
    this.showTermsAcceptance = false,
    this.showDivider = true,
    this.submitLabel,
    this.googleLabel,
    this.helperText,
    this.showPasswordStrength = false,
  });

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  bool get _isRegisterOrLink =>
      widget.mode == AuthMode.register || widget.mode == AuthMode.link;

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
    if (_isRegisterOrLink) {
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Debe tener al menos una mayuscula';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Debe tener al menos un numero';
      }
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.showTermsAcceptance && !_acceptedTerms) {
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
      final authManager = ref.read(authManagerProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final AuthResult result = switch (widget.mode) {
        AuthMode.login => await authManager.signInWithEmailPassword(
          email,
          password,
        ),
        AuthMode.register => await authManager.registerWithEmailPassword(
          email,
          password,
        ),
        AuthMode.link => await authManager.linkWithEmailPassword(
          email,
          password,
        ),
      };

      if (!mounted) return;

      if (result.success) {
        _showSuccessMessage();
        widget.onSuccess?.call();
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Error de autenticacion';
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

  void _showSuccessMessage() {
    final message = switch (widget.mode) {
      AuthMode.login => 'Bienvenido de vuelta!',
      AuthMode.register => 'Cuenta creada exitosamente',
      AuthMode.link => 'Cuenta vinculada exitosamente',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    await showForgotPasswordDialog(context: context, ref: ref);
  }

  String _getSubmitLabel() {
    if (widget.submitLabel != null) return widget.submitLabel!;

    return switch (widget.mode) {
      AuthMode.login => 'Iniciar sesion',
      AuthMode.register => 'Crear cuenta',
      AuthMode.link => 'Vincular cuenta',
    };
  }

  String _getLoadingLabel() {
    return switch (widget.mode) {
      AuthMode.login => 'Iniciando sesion...',
      AuthMode.register => 'Creando cuenta...',
      AuthMode.link => 'Vinculando cuenta...',
    };
  }

  IconData _getSubmitIcon() {
    return switch (widget.mode) {
      AuthMode.login => Icons.login,
      AuthMode.register => Icons.person_add,
      AuthMode.link => Icons.link,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                textInputAction: _isRegisterOrLink
                    ? TextInputAction.next
                    : TextInputAction.done,
                validator: _validatePassword,
                enabled: !_isLoading,
                onChanged: widget.showPasswordStrength
                    ? (_) => setState(() {})
                    : null,
                onFieldSubmitted: _isRegisterOrLink
                    ? null
                    : (_) => _handleSubmit(),
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
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),

              // Indicador de fortaleza de contrasena
              if (widget.showPasswordStrength)
                PasswordStrengthIndicator(password: _passwordController.text),

              // Campo de confirmar contrasena (solo registro/vinculacion)
              if (_isRegisterOrLink) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _handleSubmit(),
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
              ],

              // Olvidaste tu contrasena (solo login)
              if (widget.showForgotPassword &&
                  widget.mode == AuthMode.login) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: Text(
                      'Olvidaste tu contrasena?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],

              // Checkbox de terminos (solo registro)
              if (widget.showTermsAcceptance) ...[
                const SizedBox(height: 16),
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
              ],

              const SizedBox(height: 24),

              // Boton principal
              FilledButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Icon(_getSubmitIcon()),
                label: Text(
                  _isLoading ? _getLoadingLabel() : _getSubmitLabel(),
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

        // Divider y boton de Google
        if (widget.showGoogleButton) ...[
          const SizedBox(height: 24),

          if (widget.showDivider) ...[
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _getDividerLabel(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          UnifiedGoogleAuthButton(
            requireTermsAcceptance: widget.showTermsAcceptance
                ? _acceptedTerms
                : false,
            customLabel: widget.googleLabel ?? _getGoogleLabel(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSuccess: widget.onSuccess,
          ),
        ],
      ],
    );
  }

  String _getDividerLabel() {
    return switch (widget.mode) {
      AuthMode.login => 'o continua con',
      AuthMode.register => 'o registrate con',
      AuthMode.link => 'o vincula con',
    };
  }

  String _getGoogleLabel() {
    return switch (widget.mode) {
      AuthMode.login => 'Continuar con Google',
      AuthMode.register => 'Registrarse con Google',
      AuthMode.link => 'Vincular con Google',
    };
  }
}

/// Widget de aceptacion de terminos con enlaces clickeables
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



