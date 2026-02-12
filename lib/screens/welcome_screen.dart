import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/dialogs/legal_document_viewer.dart';
import '../core/constants/legal/terms_of_service.dart';
import '../core/constants/legal/privacy_policy.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'main_scaffold.dart';
import '../services/auth_service.dart';

/// Pantalla de bienvenida que se muestra la primera vez que se abre la app
/// Permite elegir entre iniciar sesion, registrarse o continuar sin cuenta
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  Future<void> _continueWithoutAccount(BuildContext context, WidgetRef ref) async {
    // Iniciar sesion anonima y navegar a la pantalla principal
    final authService = ref.read(authServiceProvider);

    // Si Firebase esta disponible, iniciar sesion anonima
    if (authService.isFirebaseAvailable) {
      await authService.signInAnonymously();
    }

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScaffold(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = context.horizontalPadding;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Breakpoints.maxFormWidth + (horizontalPadding * 2),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Logo grande
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titulo
                  Text(
                    'Bienvenido a',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AuraList',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Descripcion
                  Text(
                    'Tu gestor de tareas inteligente que te ayuda a ser mas productivo sin estres',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Caracteristicas
                  _FeatureItem(
                    icon: Icons.cloud_sync,
                    title: 'Sincronizacion en la nube',
                    description: 'Accede a tus tareas desde cualquier dispositivo',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.offline_bolt,
                    title: 'Funciona sin internet',
                    description: 'Tus datos siempre disponibles, con o sin conexion',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.psychology,
                    title: 'Inteligente y adaptable',
                    description: 'Se adapta a tu forma de trabajar',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 48),

                  // Boton de registro
                  FilledButton.icon(
                    onPressed: () => _navigateToRegister(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Crear cuenta'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Boton de login
                  OutlinedButton.icon(
                    onPressed: () => _navigateToLogin(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Ya tengo cuenta'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continuar sin cuenta
                  TextButton(
                    onPressed: () => _continueWithoutAccount(context, ref),
                    child: Text(
                      'Continuar sin cuenta',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nota de privacidad con enlaces clickeables
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        children: [
                          const TextSpan(text: 'Al continuar, aceptas nuestros '),
                          TextSpan(
                            text: 'Terminos y Condiciones',
                            style: TextStyle(
                              color: colorScheme.primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showLegalDocumentDialog(
                                  context: context,
                                  title: 'Terminos y Condiciones',
                                  content: termsOfServiceEs,
                                  summary: termsSummaryEs,
                                );
                              },
                          ),
                          const TextSpan(text: ' y '),
                          TextSpan(
                            text: 'Politica de Privacidad',
                            style: TextStyle(
                              color: colorScheme.primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showLegalDocumentDialog(
                                  context: context,
                                  title: 'Politica de Privacidad',
                                  content: privacyPolicyEs,
                                  summary: privacySummaryEs,
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
