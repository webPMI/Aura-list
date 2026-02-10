import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar el estado de onboarding
/// Determina si es la primera vez que el usuario abre la app
class OnboardingService {
  static const String _keyHasSeenWelcome = 'has_seen_welcome';

  /// Verifica si el usuario ya ha visto la pantalla de bienvenida
  Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenWelcome) ?? false;
  }

  /// Marca que el usuario ya ha visto la pantalla de bienvenida
  Future<void> markWelcomeAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenWelcome, true);
  }

  /// Resetea el estado de onboarding (util para testing)
  Future<void> resetWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasSeenWelcome);
  }
}

/// Provider para el servicio de onboarding
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Provider que verifica si se debe mostrar la pantalla de bienvenida
final shouldShowWelcomeProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  final hasSeenWelcome = await service.hasSeenWelcome();
  return !hasSeenWelcome;
});
