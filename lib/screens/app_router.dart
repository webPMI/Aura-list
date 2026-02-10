import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';
import 'welcome_screen.dart';
import 'main_scaffold.dart';

/// Router principal que decide que pantalla mostrar al inicio
/// Muestra WelcomeScreen en el primer uso, MainScaffold despues
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowWelcome = ref.watch(shouldShowWelcomeProvider);

    return shouldShowWelcome.when(
      data: (showWelcome) {
        if (showWelcome) {
          // Primera vez - mostrar pantalla de bienvenida
          // Marcar como visto despues de mostrar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(onboardingServiceProvider).markWelcomeAsSeen();
          });
          return const WelcomeScreen();
        } else {
          // Usuario recurrente - mostrar pantalla principal
          return const MainScaffold();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) {
        // En caso de error, mostrar la pantalla principal
        return const MainScaffold();
      },
    );
  }
}
