import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist_app/models/guide_affinity_model.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';

const _keyAffinityPrefix = 'guide_affinity_';

/// Provider para acceder a la afinidad de un guía específico.
/// Retorna null si no hay datos de afinidad para ese guía.
final guideAffinityProvider =
    FutureProvider.family<GuideAffinity?, String>((ref, guideId) async {
  final notifier = ref.watch(guideAffinityNotifierProvider.notifier);
  return notifier.getAffinity(guideId);
});

/// Provider que proporciona la afinidad del guía activo actual.
/// Retorna null si no hay guía activo o no hay datos de afinidad.
final activeGuideAffinityProvider = FutureProvider<GuideAffinity?>((ref) async {
  final activeGuideId = ref.watch(activeGuideIdProvider);
  if (activeGuideId == null || activeGuideId.isEmpty) return null;

  final notifier = ref.watch(guideAffinityNotifierProvider.notifier);
  return notifier.getAffinity(activeGuideId);
});

/// Provider que proporciona todas las afinidades guardadas.
/// Retorna un mapa de guideId -> GuideAffinity.
final allAffinitiesProvider =
    FutureProvider<Map<String, GuideAffinity>>((ref) async {
  final notifier = ref.watch(guideAffinityNotifierProvider.notifier);
  return notifier.getAllAffinities();
});

/// StateNotifierProvider para gestionar el estado de afinidades.
final guideAffinityNotifierProvider =
    StateNotifierProvider<GuideAffinityNotifier, AsyncValue<void>>((ref) {
  return GuideAffinityNotifier(ref);
});

/// Notifier que gestiona la lógica de afinidad y persistencia.
class GuideAffinityNotifier extends StateNotifier<AsyncValue<void>> {
  GuideAffinityNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Obtener la afinidad de un guía específico.
  Future<GuideAffinity?> getAffinity(String guideId) async {
    if (guideId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyAffinityPrefix$guideId';
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      // Si no existe, crear una afinidad inicial
      return GuideAffinity(guideId: guideId);
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GuideAffinity.fromJson(json);
    } catch (e) {
      // En caso de error, retornar afinidad inicial
      return GuideAffinity(guideId: guideId);
    }
  }

  /// Obtener todas las afinidades guardadas.
  Future<Map<String, GuideAffinity>> getAllAffinities() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final affinityKeys =
        allKeys.where((key) => key.startsWith(_keyAffinityPrefix));

    final affinities = <String, GuideAffinity>{};

    for (final key in affinityKeys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final affinity = GuideAffinity.fromJson(json);
          affinities[affinity.guideId] = affinity;
        } catch (e) {
          // Ignorar entradas corruptas
          continue;
        }
      }
    }

    return affinities;
  }

  /// Guardar afinidad en SharedPreferences.
  Future<void> _saveAffinity(GuideAffinity affinity) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyAffinityPrefix${affinity.guideId}';
    final jsonString = jsonEncode(affinity.toJson());
    await prefs.setString(key, jsonString);
  }

  /// Incrementar el contador de tareas completadas para el guía activo.
  /// Automáticamente verifica si se puede subir de nivel.
  /// Retorna el nuevo nivel si hubo cambio, null si no.
  Future<int?> incrementTaskCount() async {
    final activeGuideId = ref.read(activeGuideIdProvider);
    if (activeGuideId == null || activeGuideId.isEmpty) return null;

    state = const AsyncValue.loading();

    try {
      // Obtener afinidad actual
      var affinity = await getAffinity(activeGuideId);
      affinity ??= GuideAffinity(
          guideId: activeGuideId,
          firstActivationDate: DateTime.now(),
          lastActiveDate: DateTime.now(),
        );

      // Incrementar contador de tareas
      affinity = affinity.copyWith(
        tasksCompletedWithGuide: affinity.tasksCompletedWithGuide + 1,
        lastActiveDate: DateTime.now(),
      );

      // Calcular nuevo nivel
      final newLevel = affinity.calculateLevel();
      final leveledUp = newLevel > affinity.connectionLevel;

      if (leveledUp) {
        affinity = affinity.copyWith(connectionLevel: newLevel);
      }

      // Guardar
      await _saveAffinity(affinity);

      state = const AsyncValue.data(null);
      return leveledUp ? newLevel : null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Registrar un día activo con el guía.
  /// Debe llamarse una vez por día cuando el guía está activo.
  /// Retorna true si se registró un nuevo día, false si ya se había registrado hoy.
  Future<bool> recordActiveDay(String guideId) async {
    if (guideId.isEmpty) return false;

    state = const AsyncValue.loading();

    try {
      // Obtener afinidad actual
      var affinity = await getAffinity(guideId);
      if (affinity == null) {
        affinity = GuideAffinity(
          guideId: guideId,
          firstActivationDate: DateTime.now(),
          lastActiveDate: DateTime.now(),
          daysWithGuide: 1,
        );
        await _saveAffinity(affinity);
        state = const AsyncValue.data(null);
        return true;
      }

      // Verificar si ya se registró hoy
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (affinity.lastActiveDate != null) {
        final lastActive = affinity.lastActiveDate!;
        final lastActiveDay =
            DateTime(lastActive.year, lastActive.month, lastActive.day);

        if (lastActiveDay == today) {
          // Ya se registró hoy
          state = const AsyncValue.data(null);
          return false;
        }
      }

      // Registrar nuevo día
      affinity = affinity.copyWith(
        daysWithGuide: affinity.daysWithGuide + 1,
        lastActiveDate: now,
        firstActivationDate: affinity.firstActivationDate ?? now,
      );

      // Calcular nuevo nivel
      final newLevel = affinity.calculateLevel();
      if (newLevel > affinity.connectionLevel) {
        affinity = affinity.copyWith(connectionLevel: newLevel);
      }

      await _saveAffinity(affinity);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Resetear la afinidad de un guía específico.
  /// CUIDADO: Esta operación es destructiva.
  /// Solo debe usarse en casos excepcionales (ej. debug, solicitud del usuario).
  Future<void> resetAffinity(String guideId) async {
    if (guideId.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyAffinityPrefix$guideId';
      await prefs.remove(key);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Resetear todas las afinidades.
  /// CUIDADO: Esta operación es destructiva.
  /// Solo debe usarse en casos excepcionales.
  Future<void> resetAllAffinities() async {
    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final affinityKeys =
          allKeys.where((key) => key.startsWith(_keyAffinityPrefix));

      for (final key in affinityKeys) {
        await prefs.remove(key);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Verificar y registrar día activo para el guía actual.
  /// Llamar al inicio de la sesión o cuando se activa un guía.
  Future<void> checkAndRecordDailyActivity() async {
    final activeGuideId = ref.read(activeGuideIdProvider);
    if (activeGuideId == null || activeGuideId.isEmpty) return;

    await recordActiveDay(activeGuideId);
  }
}

/// Provider conveniente para incrementar el contador de tareas.
/// Retorna el nuevo nivel si hubo subida de nivel, null si no.
final incrementTaskCountProvider = Provider<Future<int?> Function()>((ref) {
  return () async {
    return ref.read(guideAffinityNotifierProvider.notifier).incrementTaskCount();
  };
});

/// Provider conveniente para verificar y registrar actividad diaria.
final checkDailyActivityProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    return ref
        .read(guideAffinityNotifierProvider.notifier)
        .checkAndRecordDailyActivity();
  };
});
