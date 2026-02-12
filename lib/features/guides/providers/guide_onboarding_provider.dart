import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';

const _keyHasSeenGuideIntro = 'has_seen_guide_intro';

/// Servicio para manejar el estado de onboarding de Guías Celestiales.
/// Determina si el usuario ya ha visto la introducción a los guías.
class GuideOnboardingService {
  /// Verifica si el usuario ya ha visto la introducción a los guías.
  Future<bool> hasSeenGuideIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenGuideIntro) ?? false;
  }

  /// Marca que el usuario ya ha visto la introducción.
  Future<void> markIntroAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenGuideIntro, true);
  }

  /// Resetea el estado de onboarding (útil para testing).
  Future<void> resetIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasSeenGuideIntro);
  }
}

/// Provider para el servicio de onboarding de guías.
final guideOnboardingServiceProvider = Provider<GuideOnboardingService>((ref) {
  return GuideOnboardingService();
});

/// Provider que determina si se debe mostrar la introducción de guías.
/// Retorna true si:
/// - El usuario NO ha visto la introducción aún
/// - Y NO tiene ningún guía seleccionado
final shouldShowGuideIntroProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(guideOnboardingServiceProvider);
  final activeGuideId = ref.watch(activeGuideIdProvider);

  final hasSeenIntro = await service.hasSeenGuideIntro();
  final hasNoGuide = activeGuideId == null || activeGuideId.isEmpty;

  return !hasSeenIntro && hasNoGuide;
});
