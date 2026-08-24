import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/dialogs/legal_document_viewer.dart';
import '../widgets/dialogs/legal_acceptance_dialog.dart';
import '../core/constants/legal/terms_of_service.dart';
import '../core/constants/legal/privacy_policy.dart';
import '../services/database_service.dart';
import '../widgets/promo/servicios_mallorca_promo.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'main_scaffold.dart';

/// Pantalla de bienvenida que se muestra la primera vez que se abre la app
/// Permite elegir entre iniciar sesion, registrarse o continuar sin cuenta
/// REQUISITO: Todos los usuarios deben aceptar términos y condiciones antes de acceder
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  /// Verifica si el usuario ha aceptado los términos y condiciones
  /// Si no ha aceptado, muestra el diálogo de aceptación
  /// Retorna true si el usuario aceptó, false si rechazó o cerró el diálogo
  Future<bool> _checkAndRequestLegalAcceptance(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final hasAccepted = await dbService.hasAcceptedLegal();

      if (!hasAccepted) {
        if (!context.mounted) return false;
        // Mostrar diálogo de aceptación legal
        final accepted = await showLegalAcceptanceDialog(
          context: context,
          ref: ref,
        );
        return accepted;
      }

      return true;
    } catch (e) {
      // En caso de error, asumimos que no ha aceptado para ser conservadores
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar aceptación legal: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _navigateToLogin(BuildContext context, WidgetRef ref) async {
    // Verificar aceptación legal antes de permitir acceso
    final accepted = await _checkAndRequestLegalAcceptance(context, ref);
    if (!accepted || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  Future<void> _navigateToRegister(BuildContext context, WidgetRef ref) async {
    // Verificar aceptación legal antes de permitir acceso
    final accepted = await _checkAndRequestLegalAcceptance(context, ref);
    if (!accepted || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  Future<void> _continueWithoutAccount(BuildContext context, WidgetRef ref) async {
    // Verificar aceptación legal antes de permitir acceso
    final accepted = await _checkAndRequestLegalAcceptance(context, ref);
    if (!accepted || !context.mounted) return;

    // Continuar en modo local sin crear cuenta
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainScaffold(),
      ),
    );
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
                    icon: Icons.shield_outlined,
                    title: 'Privacidad y Cifrado Total',
                    description: 'Tus datos se guardan cifrados con AES-256 (Zero-Knowledge)',
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
                    onPressed: () => _navigateToRegister(context, ref),
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
                    onPressed: () => _navigateToLogin(context, ref),
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
                  const SizedBox(height: 24),

                  // Banner de Servicios Mallorca
                  const ServiciosMallorcaWelcomeBanner(),
                  const SizedBox(height: 20),

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



