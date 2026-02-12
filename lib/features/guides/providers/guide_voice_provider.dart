import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/services/guide_voice_service.dart';

/// Provider para el servicio de voz del guia
final guideVoiceServiceProvider = Provider<GuideVoiceService>((ref) {
  return GuideVoiceService.instance;
});

/// Provider para obtener un mensaje del guia activo
final guideMessageProvider =
    Provider.family<String?, GuideVoiceMoment>((ref, moment) {
  final guide = ref.watch(activeGuideProvider);
  final service = ref.watch(guideVoiceServiceProvider);
  return service.getMessage(guide, moment);
});

/// Provider para obtener un mensaje con contexto de racha
final guideStreakMessageProvider =
    Provider.family<String?, int>((ref, streakDays) {
  final guide = ref.watch(activeGuideProvider);
  final service = ref.watch(guideVoiceServiceProvider);
  return service.getMessage(
    guide,
    GuideVoiceMoment.streakAchieved,
    streakDays: streakDays,
  );
});

/// Provider para obtener un mensaje con contexto de tareas completadas
final guideTaskCompletedMessageProvider =
    Provider.family<String?, int>((ref, tasksCompleted) {
  final guide = ref.watch(activeGuideProvider);
  final service = ref.watch(guideVoiceServiceProvider);
  return service.getMessage(
    guide,
    GuideVoiceMoment.taskCompleted,
    tasksCompleted: tasksCompleted,
  );
});
