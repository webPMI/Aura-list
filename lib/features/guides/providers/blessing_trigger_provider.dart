import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/services/blessing_trigger_service.dart';
import 'package:checklist_app/services/guide_blessing_registry.dart';

/// Provider singleton del servicio de triggers de bendiciones.
///
/// Mantiene el estado de las tareas completadas hoy y las bendiciones
/// ya mostradas en la sesion actual.
final blessingTriggerServiceProvider = Provider<BlessingTriggerService>((ref) {
  return BlessingTriggerService();
});

/// Provider que evalua y retorna el resultado de bendicion para una tarea.
///
/// Uso despues de completar una tarea:
/// ```dart
/// final result = ref.read(blessingTriggerProvider(task));
/// if (result.triggered) {
///   showBlessingFeedback(result);
/// }
/// ```
final blessingTriggerProvider =
    Provider.family<BlessingTriggerResult, Task>((ref, task) {
  final guide = ref.watch(activeGuideProvider);
  final service = ref.read(blessingTriggerServiceProvider);
  return service.evaluateTaskCompletion(task: task, activeGuide: guide);
});

/// Provider que evalua bendiciones con contexto de racha.
///
/// Uso cuando se tiene acceso a estadisticas de racha:
/// ```dart
/// final result = ref.read(blessingTriggerWithStreakProvider((
///   task: completedTask,
///   currentStreak: 5,
/// )));
/// ```
final blessingTriggerWithStreakProvider =
    Provider.family<BlessingTriggerResult, ({Task task, int currentStreak})>(
        (ref, params) {
  final guide = ref.watch(activeGuideProvider);
  final service = ref.read(blessingTriggerServiceProvider);
  return service.evaluateTaskCompletion(
    task: params.task,
    activeGuide: guide,
    currentStreak: params.currentStreak,
  );
});

/// Provider para obtener las bendiciones activas del guia actual.
///
/// Retorna una lista de [BlessingDefinition] para las bendiciones
/// asignadas al guia activo.
final activeGuideBlessingsProvider = Provider<List<BlessingDefinition>>((ref) {
  final guide = ref.watch(activeGuideProvider);
  if (guide == null) return [];

  return guide.blessingIds
      .map((id) => getBlessingById(id))
      .whereType<BlessingDefinition>()
      .toList();
});

/// Provider para obtener IDs de bendiciones que se activan con el contexto actual.
///
/// Uso para verificar que bendiciones estan disponibles:
/// ```dart
/// final triggered = ref.watch(triggeredBlessingIdsProvider((
///   tasksCompletedToday: 3,
///   currentStreak: 5,
///   taskCategory: 'Personal',
/// )));
/// ```
final triggeredBlessingIdsProvider = Provider.family<List<String>,
    ({int tasksCompletedToday, int currentStreak, String? taskCategory})>(
  (ref, params) {
    final guide = ref.watch(activeGuideProvider);
    if (guide == null) return [];

    final service = ref.read(blessingTriggerServiceProvider);
    return service.getTriggeredBlessings(
      guide,
      tasksCompletedToday: params.tasksCompletedToday,
      currentStreak: params.currentStreak,
      taskCategory: params.taskCategory,
    );
  },
);

/// Provider para obtener bendiciones activadas con informacion detallada.
///
/// Retorna una lista de [TriggeredBlessing] con intensidad y mensaje
/// personalizados segun el contexto.
final triggeredBlessingsDetailedProvider =
    Provider.family<List<TriggeredBlessing>, BlessingTriggerContext>(
  (ref, context) {
    final guide = ref.watch(activeGuideProvider);
    if (guide == null) return [];

    final service = ref.read(blessingTriggerServiceProvider);
    return service.getTriggeredBlessingsDetailed(
      guide,
      context: context,
    );
  },
);

/// Provider para verificar si una bendicion especifica esta activa.
///
/// Retorna `true` si el guia activo tiene la bendicion asignada.
final hasBlessingProvider = Provider.family<bool, String>((ref, blessingId) {
  final guide = ref.watch(activeGuideProvider);
  if (guide == null) return false;
  return guide.blessingIds.contains(blessingId);
});

/// Provider para obtener una bendicion especifica por ID.
///
/// Retorna null si la bendicion no existe en el registro.
final blessingByIdProvider =
    Provider.family<BlessingDefinition?, String>((ref, blessingId) {
  return getBlessingById(blessingId);
});

/// Notifier para controlar el estado de bendiciones mostradas en la sesion.
///
/// Permite resetear el estado cuando cambia el dia o el usuario.
class BlessingSessionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  /// Marca una bendicion como mostrada en esta sesion.
  void markShown(String blessingId) {
    state = {...state, blessingId};
  }

  /// Verifica si una bendicion ya fue mostrada.
  bool isShown(String blessingId) {
    return state.contains(blessingId);
  }

  /// Resetea todas las bendiciones mostradas (nuevo dia o sesion).
  void reset() {
    state = {};
  }
}

/// Provider del notifier de sesion de bendiciones.
final blessingSessionProvider =
    NotifierProvider<BlessingSessionNotifier, Set<String>>(
  BlessingSessionNotifier.new,
);

/// Provider que verifica si se debe mostrar una bendicion (no mostrada aun).
final shouldShowBlessingProvider =
    Provider.family<bool, String>((ref, blessingId) {
  final shownBlessings = ref.watch(blessingSessionProvider);
  final hasBlessing = ref.watch(hasBlessingProvider(blessingId));
  return hasBlessing && !shownBlessings.contains(blessingId);
});
