import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist_app/models/guide_achievement_model.dart';
import 'package:checklist_app/features/guides/data/achievement_catalog.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/providers/task_provider.dart';

const _boxName = 'guide_achievements';

/// Tipos de tareas disponibles en la app
const _kTaskTypes = ['daily', 'weekly', 'monthly', 'yearly', 'once'];

/// Categorías disponibles en la app (según CLAUDE.md)
const _kAllCategories = ['Personal', 'Trabajo', 'Hogar', 'Salud', 'Otros'];

/// Claves de SharedPreferences para historial de logros
const _keyAllCompletedDates = 'achievement_all_completed_dates';
const _keyDailyTaskCounts = 'achievement_daily_task_counts';

/// Provider que gestiona los logros del usuario.
///
/// Filosofía del Guardián:
/// - Los logros son reconocimientos, NO objetivos
/// - NUNCA presionar al usuario con "te falta X para Y"
/// - Celebrar sin crear ansiedad
final guideAchievementsProvider =
    StateNotifierProvider<GuideAchievementsNotifier, List<GuideAchievement>>(
        (ref) {
  return GuideAchievementsNotifier(ref);
});

class GuideAchievementsNotifier extends StateNotifier<List<GuideAchievement>> {
  final Ref ref;

  GuideAchievementsNotifier(this.ref) : super([]) {
    _initializeAchievements();
  }

  Box<GuideAchievement>? _box;

  /// Inicializa la caja de Hive y carga los logros
  Future<void> _initializeAchievements() async {
    try {
      _box = await Hive.openBox<GuideAchievement>(_boxName);
      _loadAchievements();
    } catch (e) {
      // Si hay error, trabajar solo con el catálogo en memoria
      state = List.from(kAchievementCatalog);
    }
  }

  /// Carga los logros desde Hive, combinando con el catálogo
  void _loadAchievements() {
    if (_box == null) {
      state = List.from(kAchievementCatalog);
      return;
    }

    final savedAchievements = <String, GuideAchievement>{};
    for (var achievement in _box!.values) {
      savedAchievements[achievement.id] = achievement;
    }

    // Combinar catálogo con logros guardados
    final achievements = kAchievementCatalog.map((catalogAchievement) {
      final saved = savedAchievements[catalogAchievement.id];
      if (saved != null) {
        return saved;
      }
      return catalogAchievement;
    }).toList();

    state = achievements;
  }

  /// Guarda un logro en Hive
  Future<void> _saveAchievement(GuideAchievement achievement) async {
    if (_box == null) return;
    await _box!.put(achievement.id, achievement);
  }

  /// Marca un logro como obtenido y lo persiste
  Future<GuideAchievement?> earnAchievement(
    String achievementId, {
    String? customMessage,
  }) async {
    final index = state.indexWhere((a) => a.id == achievementId);
    if (index == -1) return null;

    final achievement = state[index];
    if (achievement.isEarned) return null; // Ya obtenido

    final updated = achievement.copyWith(
      isEarned: true,
      earnedAt: DateTime.now(),
      guideMessage: customMessage ?? achievement.guideMessage,
    );

    final newState = [...state];
    newState[index] = updated;
    state = newState;

    await _saveAchievement(updated);
    return updated;
  }

  /// Verifica y otorga logros basados en condiciones actuales
  Future<List<GuideAchievement>> checkAndAwardAchievements({
    required String? activeGuideId,
    required Task? lastCompletedTask,
    required int currentStreak,
    required int totalTasksCompletedToday,
    required int totalTasksWithGuide,
    required Set<String> categoriesCompletedToday,
    required int totalRecurrentTasks,
    required bool allTasksCompleted,
    required int daysWithGuide,
  }) async {
    if (activeGuideId == null) return [];

    // Registrar datos de historial cuando todas las tareas estén completadas
    if (allTasksCompleted) {
      await _recordAllTasksCompletedToday();
    }

    // Registrar recuento de tareas completadas hoy para historial de rachas
    if (totalTasksCompletedToday > 0) {
      await _recordDailyTaskCount(totalTasksCompletedToday);
    }

    final newlyEarned = <GuideAchievement>[];

    // Verificar condiciones para cada logro no obtenido del guía activo
    final guideAchievements = state.where(
      (a) => a.guideId == activeGuideId && !a.isEarned,
    );

    for (final achievement in guideAchievements) {
      bool shouldEarn = false;

      switch (achievement.id) {
        // ===== AETHEL =====
        case 'aethel_primer_rayo':
          shouldEarn = lastCompletedTask?.priority == 2; // Alta prioridad
          break;
        case 'aethel_amanecer_constante':
          shouldEarn = currentStreak >= 7;
          break;
        case 'aethel_fuego_eterno':
          shouldEarn = totalTasksWithGuide >= 30;
          break;
        case 'aethel_guardian_tres_picos':
          shouldEarn = _countHighPriorityTasksToday() >= 3;
          break;
        case 'aethel_sol_de_medianoche':
          shouldEarn = currentStreak >= 14;
          break;

        // ===== CRONO-VELO =====
        case 'crono_primer_hilo':
          shouldEarn = lastCompletedTask != null &&
              ['daily', 'weekly', 'monthly'].contains(lastCompletedTask.type);
          break;
        case 'crono_tejedor_novato':
          shouldEarn = currentStreak >= 7;
          break;
        case 'crono_manto_completo':
          shouldEarn = currentStreak >= 21;
          break;
        case 'crono_arquitecto_del_ciclo':
          shouldEarn = totalRecurrentTasks >= 5;
          break;

        // ===== LUNA-VACÍA =====
        case 'luna_primera_calma':
          shouldEarn = allTasksCompleted;
          break;
        case 'luna_guerrero_silencio':
          shouldEarn = _getAllTasksCompletedCount() >= 3;
          break;
        case 'luna_paz_interior':
          shouldEarn = daysWithGuide >= 14;
          break;
        case 'luna_vacio_pleno':
          shouldEarn = _getConsecutiveDaysAllCompleted() >= 7;
          break;

        // ===== HELIOFORJA =====
        case 'helioforja_primer_golpe':
          shouldEarn = lastCompletedTask != null;
          break;
        case 'helioforja_herrero_constante':
          shouldEarn = currentStreak >= 7;
          break;
        case 'helioforja_acero_forjado':
          shouldEarn = totalTasksWithGuide >= 30;
          break;

        // ===== LEONA-NOVA =====
        case 'leona_primera_gema':
          shouldEarn = lastCompletedTask != null;
          break;
        case 'leona_corona_semanal':
          shouldEarn = currentStreak >= 7;
          break;
        case 'leona_soberania_lunar':
          shouldEarn = currentStreak >= 30;
          break;

        // ===== CHISPA-AZUL =====
        case 'chispa_primera_chispa':
          shouldEarn = lastCompletedTask != null;
          break;
        case 'chispa_tormenta_cinco':
          shouldEarn = totalTasksCompletedToday >= 5;
          break;
        case 'chispa_relampago_constante':
          shouldEarn = _getConsecutiveDaysWithMinTasks(3) >= 7;
          break;

        // ===== GLORIA-SINCRO =====
        case 'gloria_primer_logro':
          shouldEarn = lastCompletedTask != null;
          break;
        case 'gloria_tejedora':
          shouldEarn = totalTasksWithGuide >= 10;
          break;
        case 'gloria_corona_consciente':
          shouldEarn = currentStreak >= 21;
          break;

        // ===== PACHA-NEXO =====
        case 'pacha_primer_nexo':
          shouldEarn = categoriesCompletedToday.length >= 2;
          break;
        case 'pacha_ecosistema_equilibrado':
          shouldEarn = categoriesCompletedToday.length >= 3;
          break;
        case 'pacha_tejedor_completo':
          shouldEarn = _getAllCategoriesCompleted();
          break;

        // ===== GEA-MÉTRICA =====
        case 'gea_primera_semilla':
          shouldEarn = lastCompletedTask != null;
          break;
        case 'gea_jardinero_constante':
          shouldEarn = currentStreak >= 7;
          break;
        case 'gea_cosecha_primera':
          shouldEarn = currentStreak >= 21;
          break;
      }

      if (shouldEarn) {
        final earned = await earnAchievement(achievement.id);
        if (earned != null) {
          newlyEarned.add(earned);
        }
      }
    }

    return newlyEarned;
  }

  // ===== Funciones auxiliares para condiciones =====

  /// Cuenta las tareas de alta prioridad (priority == 2) completadas HOY
  /// a través de todos los tipos de tareas.
  int _countHighPriorityTasksToday() {
    try {
      final today = DateTime.now();
      int count = 0;

      for (final type in _kTaskTypes) {
        // Usar ref.read para obtener el estado actual sin suscribirse
        final tasks = ref.read(tasksProvider(type));
        for (final task in tasks) {
          if (task.isCompleted &&
              task.priority == 2 &&
              _isCompletedToday(task, today)) {
            count++;
          }
        }
      }

      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Cuenta cuántas veces se han completado TODAS las tareas del día.
  /// Lee el historial persistido en SharedPreferences.
  int _getAllTasksCompletedCount() {
    try {
      // Este valor se actualiza cuando checkAndAwardAchievements detecta allTasksCompleted
      // y se persiste en SharedPreferences via _recordAllTasksCompletedToday()
      return _cachedAllCompletedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Calcula los días consecutivos en que se completaron TODAS las tareas del día.
  int _getConsecutiveDaysAllCompleted() {
    try {
      return _calculateConsecutiveDaysFromDates(_cachedAllCompletedDates);
    } catch (_) {
      return 0;
    }
  }

  /// Calcula los días consecutivos en que se completaron al menos [minTasks] tareas.
  int _getConsecutiveDaysWithMinTasks(int minTasks) {
    try {
      return _calculateConsecutiveDaysWithMinCount(
        _cachedDailyTaskCounts,
        minTasks,
      );
    } catch (_) {
      return 0;
    }
  }

  /// Verifica que todas las categorías definidas tienen al menos
  /// una tarea completada hoy.
  bool _getAllCategoriesCompleted() {
    try {
      final today = DateTime.now();
      final completedCategories = <String>{};

      for (final type in _kTaskTypes) {
        final tasks = ref.read(tasksProvider(type));
        for (final task in tasks) {
          if (task.isCompleted && _isCompletedToday(task, today)) {
            completedCategories.add(task.category);
          }
        }
      }

      // Verificar que todas las categorías estén representadas
      return _kAllCategories
          .every((category) => completedCategories.contains(category));
    } catch (_) {
      return false;
    }
  }

  // ===== Métodos de soporte para cálculos temporales =====

  /// Verifica si una tarea fue completada hoy.
  /// Usa lastUpdatedAt como indicador del momento de completado;
  /// si no existe, usa createdAt como fallback.
  bool _isCompletedToday(Task task, DateTime today) {
    if (!task.isCompleted) return false;

    final referenceDate = task.lastUpdatedAt ?? task.createdAt;
    return referenceDate.year == today.year &&
        referenceDate.month == today.month &&
        referenceDate.day == today.day;
  }

  /// Formatea una fecha como 'yyyy-MM-dd'
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===== Cache en memoria para datos de SharedPreferences =====
  // Se cargan en la inicialización y se actualizan en cada llamada de registro.

  int _cachedAllCompletedCount = 0;
  Set<String> _cachedAllCompletedDates = {};
  Map<String, int> _cachedDailyTaskCounts = {};
  bool _prefsLoaded = false;

  /// Carga los datos de historial desde SharedPreferences al cache en memoria.
  Future<void> _ensurePrefsLoaded() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Fechas en que se completaron todas las tareas del día
      final datesJson = prefs.getStringList(_keyAllCompletedDates) ?? [];
      _cachedAllCompletedDates = datesJson.toSet();
      _cachedAllCompletedCount = _cachedAllCompletedDates.length;

      // Recuentos de tareas completadas por día
      final countsRaw = prefs.getStringList(_keyDailyTaskCounts) ?? [];
      _cachedDailyTaskCounts = {};
      for (final entry in countsRaw) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final count = int.tryParse(parts[1]);
          if (count != null) {
            _cachedDailyTaskCounts[parts[0]] = count;
          }
        }
      }

      _prefsLoaded = true;
    } catch (_) {
      _prefsLoaded = true; // Evitar reintentos infinitos
    }
  }

  /// Registra en SharedPreferences que hoy se completaron TODAS las tareas.
  Future<void> _recordAllTasksCompletedToday() async {
    try {
      await _ensurePrefsLoaded();
      final today = _formatDate(DateTime.now());

      if (_cachedAllCompletedDates.contains(today)) return; // Ya registrado

      _cachedAllCompletedDates.add(today);
      _cachedAllCompletedCount = _cachedAllCompletedDates.length;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _keyAllCompletedDates,
        _cachedAllCompletedDates.toList(),
      );
    } catch (_) {
      // Silenciar errores para no interrumpir el flujo principal
    }
  }

  /// Registra en SharedPreferences el número de tareas completadas hoy.
  /// Si ya existe un registro para hoy, actualiza solo si el nuevo valor
  /// es mayor (para capturar el máximo del día).
  Future<void> _recordDailyTaskCount(int count) async {
    try {
      await _ensurePrefsLoaded();
      final today = _formatDate(DateTime.now());

      final existing = _cachedDailyTaskCounts[today] ?? 0;
      if (count <= existing) return; // No actualizar si el valor es menor

      _cachedDailyTaskCounts[today] = count;

      final prefs = await SharedPreferences.getInstance();
      final countsRaw = _cachedDailyTaskCounts.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      await prefs.setStringList(_keyDailyTaskCounts, countsRaw);
    } catch (_) {
      // Silenciar errores para no interrumpir el flujo principal
    }
  }

  /// Calcula el número de días consecutivos hasta hoy a partir de
  /// un conjunto de fechas en formato 'yyyy-MM-dd'.
  int _calculateConsecutiveDaysFromDates(Set<String> dates) {
    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime current = DateTime.now();

    while (true) {
      final dateStr = _formatDate(current);
      if (dates.contains(dateStr)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calcula el número de días consecutivos hasta hoy en que el recuento
  /// de tareas completadas fue mayor o igual a [minCount].
  int _calculateConsecutiveDaysWithMinCount(
    Map<String, int> dailyCounts,
    int minCount,
  ) {
    if (dailyCounts.isEmpty) return 0;

    int streak = 0;
    DateTime current = DateTime.now();

    while (true) {
      final dateStr = _formatDate(current);
      final count = dailyCounts[dateStr] ?? 0;
      if (count >= minCount) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Reinicia todos los logros (para pruebas)
  Future<void> resetAllAchievements() async {
    if (_box == null) return;
    await _box!.clear();
    _loadAchievements();
  }
}

/// Provider de logros obtenidos
final earnedAchievementsProvider = Provider<List<GuideAchievement>>((ref) {
  final achievements = ref.watch(guideAchievementsProvider);
  return achievements.where((a) => a.isEarned).toList();
});

/// Provider de logros pendientes (no obtenidos)
final pendingAchievementsProvider = Provider<List<GuideAchievement>>((ref) {
  final achievements = ref.watch(guideAchievementsProvider);
  return achievements.where((a) => !a.isEarned).toList();
});

/// Provider de logros del guía activo
final activeGuideAchievementsProvider =
    Provider<List<GuideAchievement>>((ref) {
  final achievements = ref.watch(guideAchievementsProvider);
  final activeGuide = ref.watch(activeGuideProvider);
  if (activeGuide == null) return [];
  return achievements.where((a) => a.guideId == activeGuide.id).toList();
});

/// Provider de logros obtenidos del guía activo
final activeGuideEarnedAchievementsProvider =
    Provider<List<GuideAchievement>>((ref) {
  final achievements = ref.watch(activeGuideAchievementsProvider);
  return achievements.where((a) => a.isEarned).toList();
});

/// Provider de logros pendientes del guía activo
final activeGuidePendingAchievementsProvider =
    Provider<List<GuideAchievement>>((ref) {
  final achievements = ref.watch(activeGuideAchievementsProvider);
  return achievements.where((a) => !a.isEarned).toList();
});
