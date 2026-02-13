import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wellness_suggestion.dart';
import '../core/constants/wellness_catalog.dart';

/// Provider para obtener sugerencias por categoria
final wellnessByCategoryProvider = Provider.autoDispose
    .family<List<WellnessSuggestion>, String>((ref, category) {
      return WellnessCatalog.getByCategory(category);
    });

/// Provider para obtener sugerencias por momento del dia
final wellnessByTimeProvider = Provider.autoDispose
    .family<List<WellnessSuggestion>, String>((ref, timeOfDay) {
      return WellnessCatalog.getByTimeOfDay(timeOfDay);
    });

/// Provider para obtener sugerencias por duracion maxima
final wellnessByDurationProvider = Provider.autoDispose
    .family<List<WellnessSuggestion>, int>((ref, maxMinutes) {
      return WellnessCatalog.getByMaxDuration(maxMinutes);
    });

/// Provider principal para el sistema de bienestar
final wellnessProvider = StateNotifierProvider<WellnessNotifier, WellnessState>(
  (ref) {
    return WellnessNotifier();
  },
);

/// Estado del sistema de bienestar
class WellnessState {
  /// IDs de sugerencias que el usuario ha probado
  final Set<String> triedSuggestionIds;

  /// IDs de sugerencias favoritas del usuario
  final Set<String> favoriteSuggestionIds;

  /// IDs de sugerencias que el usuario ha agregado como tareas
  final Set<String> addedSuggestionIds;

  /// ID de la sugerencia del dia actual
  final String? suggestionOfTheDayId;

  /// Fecha de la sugerencia del dia (para invalidar cache)
  final DateTime? suggestionOfTheDayDate;

  /// Sugerencias diarias recomendadas (3-5 sugerencias variadas)
  final List<String> dailyRecommendationIds;

  /// Fecha de las recomendaciones diarias
  final DateTime? dailyRecommendationsDate;

  /// Indica si el estado ha sido cargado desde persistencia
  final bool isLoaded;

  const WellnessState({
    this.triedSuggestionIds = const {},
    this.favoriteSuggestionIds = const {},
    this.addedSuggestionIds = const {},
    this.suggestionOfTheDayId,
    this.suggestionOfTheDayDate,
    this.dailyRecommendationIds = const [],
    this.dailyRecommendationsDate,
    this.isLoaded = false,
  });

  /// Obtiene la sugerencia del dia
  WellnessSuggestion? get suggestionOfTheDay {
    if (suggestionOfTheDayId == null) return null;
    return WellnessCatalog.getById(suggestionOfTheDayId!);
  }

  /// Obtiene las sugerencias diarias recomendadas
  List<WellnessSuggestion> get dailyRecommendations {
    return dailyRecommendationIds
        .map((id) => WellnessCatalog.getById(id))
        .where((s) => s != null)
        .cast<WellnessSuggestion>()
        .toList();
  }

  /// Verifica si una sugerencia ha sido probada
  bool hasTried(String suggestionId) {
    return triedSuggestionIds.contains(suggestionId);
  }

  /// Verifica si una sugerencia es favorita
  bool isFavorite(String suggestionId) {
    return favoriteSuggestionIds.contains(suggestionId);
  }

  /// Verifica si una sugerencia ha sido agregada a tareas
  bool hasBeenAdded(String suggestionId) {
    return addedSuggestionIds.contains(suggestionId);
  }

  /// Verifica si una sugerencia ya fue usada (probada o agregada)
  bool hasBeenUsed(String suggestionId) {
    return triedSuggestionIds.contains(suggestionId) ||
        addedSuggestionIds.contains(suggestionId);
  }

  /// Numero total de sugerencias probadas
  int get totalTried => triedSuggestionIds.length;

  /// Numero total de sugerencias agregadas a tareas
  int get totalAdded => addedSuggestionIds.length;

  /// Numero total de sugerencias usadas (probadas + agregadas)
  int get totalUsed {
    final combined = <String>{...triedSuggestionIds, ...addedSuggestionIds};
    return combined.length;
  }

  /// Numero total de sugerencias favoritas
  int get totalFavorites => favoriteSuggestionIds.length;

  /// Porcentaje de sugerencias probadas
  double get triedPercentage {
    final total = WellnessCatalog.totalSuggestions;
    if (total == 0) return 0;
    return (triedSuggestionIds.length / total) * 100;
  }

  /// Sugerencias que el usuario ha probado
  List<WellnessSuggestion> get triedSuggestions {
    return triedSuggestionIds
        .map((id) => WellnessCatalog.getById(id))
        .where((s) => s != null)
        .cast<WellnessSuggestion>()
        .toList();
  }

  /// Sugerencias favoritas del usuario
  List<WellnessSuggestion> get favoriteSuggestions {
    return favoriteSuggestionIds
        .map((id) => WellnessCatalog.getById(id))
        .where((s) => s != null)
        .cast<WellnessSuggestion>()
        .toList();
  }

  /// Sugerencias que el usuario no ha probado
  List<WellnessSuggestion> get untriedSuggestions {
    return WellnessCatalog.allSuggestions
        .where((s) => !triedSuggestionIds.contains(s.id))
        .toList();
  }

  /// Sugerencias que el usuario ha agregado a tareas
  List<WellnessSuggestion> get addedSuggestions {
    return addedSuggestionIds
        .map((id) => WellnessCatalog.getById(id))
        .where((s) => s != null)
        .cast<WellnessSuggestion>()
        .toList();
  }

  /// Sugerencias disponibles (no probadas ni agregadas)
  List<WellnessSuggestion> get availableSuggestions {
    return WellnessCatalog.allSuggestions
        .where((s) =>
            !triedSuggestionIds.contains(s.id) &&
            !addedSuggestionIds.contains(s.id))
        .toList();
  }

  /// Porcentaje de sugerencias usadas (probadas + agregadas)
  double get usedPercentage {
    final total = WellnessCatalog.totalSuggestions;
    if (total == 0) return 0;
    return (totalUsed / total) * 100;
  }

  WellnessState copyWith({
    Set<String>? triedSuggestionIds,
    Set<String>? favoriteSuggestionIds,
    Set<String>? addedSuggestionIds,
    String? suggestionOfTheDayId,
    DateTime? suggestionOfTheDayDate,
    List<String>? dailyRecommendationIds,
    DateTime? dailyRecommendationsDate,
    bool? isLoaded,
  }) {
    return WellnessState(
      triedSuggestionIds: triedSuggestionIds ?? this.triedSuggestionIds,
      favoriteSuggestionIds:
          favoriteSuggestionIds ?? this.favoriteSuggestionIds,
      addedSuggestionIds: addedSuggestionIds ?? this.addedSuggestionIds,
      suggestionOfTheDayId: suggestionOfTheDayId ?? this.suggestionOfTheDayId,
      suggestionOfTheDayDate:
          suggestionOfTheDayDate ?? this.suggestionOfTheDayDate,
      dailyRecommendationIds:
          dailyRecommendationIds ?? this.dailyRecommendationIds,
      dailyRecommendationsDate:
          dailyRecommendationsDate ?? this.dailyRecommendationsDate,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Notifier para gestionar el estado del sistema de bienestar
class WellnessNotifier extends StateNotifier<WellnessState> {
  static const String _triedKey = 'wellness_tried_suggestions';
  static const String _favoritesKey = 'wellness_favorite_suggestions';
  static const String _addedKey = 'wellness_added_suggestions';
  static const String _sotdIdKey = 'wellness_sotd_id';
  static const String _sotdDateKey = 'wellness_sotd_date';
  static const String _dailyIdsKey = 'wellness_daily_ids';
  static const String _dailyDateKey = 'wellness_daily_date';

  final Random _random = Random();

  WellnessNotifier() : super(const WellnessState()) {
    _loadState();
  }

  /// Carga el estado desde SharedPreferences
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar sugerencias probadas
      final triedList = prefs.getStringList(_triedKey) ?? [];
      final triedSet = Set<String>.from(triedList);

      // Cargar favoritos
      final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
      final favoritesSet = Set<String>.from(favoritesList);

      // Cargar sugerencias agregadas a tareas
      final addedList = prefs.getStringList(_addedKey) ?? [];
      final addedSet = Set<String>.from(addedList);

      // Cargar sugerencia del dia
      final sotdId = prefs.getString(_sotdIdKey);
      final sotdDateStr = prefs.getString(_sotdDateKey);
      DateTime? sotdDate;
      if (sotdDateStr != null) {
        sotdDate = DateTime.tryParse(sotdDateStr);
      }

      // Cargar recomendaciones diarias
      final dailyIds = prefs.getStringList(_dailyIdsKey) ?? [];
      final dailyDateStr = prefs.getString(_dailyDateKey);
      DateTime? dailyDate;
      if (dailyDateStr != null) {
        dailyDate = DateTime.tryParse(dailyDateStr);
      }

      state = state.copyWith(
        triedSuggestionIds: triedSet,
        favoriteSuggestionIds: favoritesSet,
        addedSuggestionIds: addedSet,
        suggestionOfTheDayId: sotdId,
        suggestionOfTheDayDate: sotdDate,
        dailyRecommendationIds: dailyIds,
        dailyRecommendationsDate: dailyDate,
        isLoaded: true,
      );

      // Actualizar sugerencia del dia y recomendaciones si es necesario
      await _refreshDailyContent();
    } catch (e) {
      // En caso de error, establecer estado como cargado para evitar bloqueos
      state = state.copyWith(isLoaded: true);
    }
  }

  /// Guarda el estado en SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(_triedKey, state.triedSuggestionIds.toList());
      await prefs.setStringList(
        _favoritesKey,
        state.favoriteSuggestionIds.toList(),
      );
      await prefs.setStringList(_addedKey, state.addedSuggestionIds.toList());

      if (state.suggestionOfTheDayId != null) {
        await prefs.setString(_sotdIdKey, state.suggestionOfTheDayId!);
      }
      if (state.suggestionOfTheDayDate != null) {
        await prefs.setString(
          _sotdDateKey,
          state.suggestionOfTheDayDate!.toIso8601String(),
        );
      }

      await prefs.setStringList(_dailyIdsKey, state.dailyRecommendationIds);
      if (state.dailyRecommendationsDate != null) {
        await prefs.setString(
          _dailyDateKey,
          state.dailyRecommendationsDate!.toIso8601String(),
        );
      }
    } catch (e) {
      // Silenciar errores de persistencia
    }
  }

  /// Refresca el contenido diario si es un nuevo dia
  Future<void> _refreshDailyContent() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool needsRefresh = false;

    // Verificar si la sugerencia del dia necesita actualizarse
    if (state.suggestionOfTheDayDate == null) {
      needsRefresh = true;
    } else {
      final sotdDay = DateTime(
        state.suggestionOfTheDayDate!.year,
        state.suggestionOfTheDayDate!.month,
        state.suggestionOfTheDayDate!.day,
      );
      if (sotdDay.isBefore(today)) {
        needsRefresh = true;
      }
    }

    if (needsRefresh) {
      await _generateDailyContent();
    }
  }

  /// Genera nuevo contenido diario
  Future<void> _generateDailyContent() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Generar sugerencia del dia
    // Usar el dia del ano como semilla para consistencia durante el dia
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final seededRandom = Random(dayOfYear + today.year * 1000);
    final allSuggestions = WellnessCatalog.allSuggestions;
    final sotdIndex = seededRandom.nextInt(allSuggestions.length);
    final sotdId = allSuggestions[sotdIndex].id;

    // Generar recomendaciones diarias (3-5 variadas)
    final dailyRecommendations = _generateDailyRecommendations(
      excludeId: sotdId,
    );

    state = state.copyWith(
      suggestionOfTheDayId: sotdId,
      suggestionOfTheDayDate: today,
      dailyRecommendationIds: dailyRecommendations.map((s) => s.id).toList(),
      dailyRecommendationsDate: today,
    );

    await _saveState();
  }

  /// Genera una lista de recomendaciones diarias variadas
  List<WellnessSuggestion> _generateDailyRecommendations({String? excludeId}) {
    final recommendations = <WellnessSuggestion>[];
    final usedCategories = <String>{};

    // Determinar el momento actual del dia
    final hour = DateTime.now().hour;
    String currentTimeOfDay;
    if (hour >= 5 && hour < 12) {
      currentTimeOfDay = 'morning';
    } else if (hour >= 12 && hour < 18) {
      currentTimeOfDay = 'afternoon';
    } else {
      currentTimeOfDay = 'evening';
    }

    // Obtener sugerencias relevantes para el momento del dia
    final relevantSuggestions = WellnessCatalog.getByTimeOfDay(
      currentTimeOfDay,
    ).where((s) => s.id != excludeId).toList();

    // Priorizar sugerencias no probadas
    final untried = relevantSuggestions
        .where((s) => !state.triedSuggestionIds.contains(s.id))
        .toList();

    final pool = untried.isNotEmpty ? untried : relevantSuggestions;

    // Seleccionar 4-5 sugerencias de diferentes categorias
    final shuffled = List<WellnessSuggestion>.from(pool)..shuffle(_random);

    for (final suggestion in shuffled) {
      if (recommendations.length >= 5) break;

      // Intentar diversificar categorias
      if (recommendations.length < 3 ||
          !usedCategories.contains(suggestion.category)) {
        recommendations.add(suggestion);
        usedCategories.add(suggestion.category);
      }
    }

    // Si no tenemos suficientes, agregar mas sin restriccion de categoria
    if (recommendations.length < 4) {
      for (final suggestion in shuffled) {
        if (recommendations.length >= 4) break;
        if (!recommendations.contains(suggestion)) {
          recommendations.add(suggestion);
        }
      }
    }

    return recommendations;
  }

  /// Marca una sugerencia como probada
  Future<void> markAsTried(String suggestionId) async {
    if (state.triedSuggestionIds.contains(suggestionId)) return;

    final newTried = Set<String>.from(state.triedSuggestionIds)
      ..add(suggestionId);

    state = state.copyWith(triedSuggestionIds: newTried);
    await _saveState();
  }

  /// Desmarca una sugerencia como probada
  Future<void> markAsNotTried(String suggestionId) async {
    if (!state.triedSuggestionIds.contains(suggestionId)) return;

    final newTried = Set<String>.from(state.triedSuggestionIds)
      ..remove(suggestionId);

    state = state.copyWith(triedSuggestionIds: newTried);
    await _saveState();
  }

  /// Alterna el estado de probado de una sugerencia
  Future<void> toggleTried(String suggestionId) async {
    if (state.triedSuggestionIds.contains(suggestionId)) {
      await markAsNotTried(suggestionId);
    } else {
      await markAsTried(suggestionId);
    }
  }

  /// Agrega una sugerencia a favoritos
  Future<void> addToFavorites(String suggestionId) async {
    if (state.favoriteSuggestionIds.contains(suggestionId)) return;

    final newFavorites = Set<String>.from(state.favoriteSuggestionIds)
      ..add(suggestionId);

    state = state.copyWith(favoriteSuggestionIds: newFavorites);
    await _saveState();
  }

  /// Quita una sugerencia de favoritos
  Future<void> removeFromFavorites(String suggestionId) async {
    if (!state.favoriteSuggestionIds.contains(suggestionId)) return;

    final newFavorites = Set<String>.from(state.favoriteSuggestionIds)
      ..remove(suggestionId);

    state = state.copyWith(favoriteSuggestionIds: newFavorites);
    await _saveState();
  }

  /// Alterna el estado de favorito de una sugerencia
  Future<void> toggleFavorite(String suggestionId) async {
    if (state.favoriteSuggestionIds.contains(suggestionId)) {
      await removeFromFavorites(suggestionId);
    } else {
      await addToFavorites(suggestionId);
    }
  }

  /// Marca una sugerencia como agregada a tareas
  Future<void> markAsAdded(String suggestionId) async {
    if (state.addedSuggestionIds.contains(suggestionId)) return;

    final newAdded = Set<String>.from(state.addedSuggestionIds)
      ..add(suggestionId);

    state = state.copyWith(addedSuggestionIds: newAdded);
    await _saveState();
  }

  /// Desmarca una sugerencia como agregada
  Future<void> markAsNotAdded(String suggestionId) async {
    if (!state.addedSuggestionIds.contains(suggestionId)) return;

    final newAdded = Set<String>.from(state.addedSuggestionIds)
      ..remove(suggestionId);

    state = state.copyWith(addedSuggestionIds: newAdded);
    await _saveState();
  }

  /// Obtiene una sugerencia aleatoria, opcionalmente filtrada
  WellnessSuggestion? getRandomSuggestion({
    String? category,
    String? timeOfDay,
    int? maxDuration,
    bool preferUntried = true,
  }) {
    var pool = WellnessCatalog.allSuggestions.toList();

    // Aplicar filtros
    if (category != null) {
      pool = pool.where((s) => s.category == category).toList();
    }
    if (timeOfDay != null) {
      pool = pool
          .where(
            (s) => s.bestTimeOfDay == timeOfDay || s.bestTimeOfDay == 'anytime',
          )
          .toList();
    }
    if (maxDuration != null) {
      pool = pool.where((s) => s.durationMinutes <= maxDuration).toList();
    }

    if (pool.isEmpty) return null;

    // Preferir sugerencias no probadas
    if (preferUntried) {
      final untried = pool
          .where((s) => !state.triedSuggestionIds.contains(s.id))
          .toList();
      if (untried.isNotEmpty) {
        pool = untried;
      }
    }

    return pool[_random.nextInt(pool.length)];
  }

  /// Obtiene sugerencias para un momento especifico del dia
  List<WellnessSuggestion> getSuggestionsForNow({int limit = 5}) {
    final hour = DateTime.now().hour;
    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 18) {
      timeOfDay = 'afternoon';
    } else {
      timeOfDay = 'evening';
    }

    final suggestions = WellnessCatalog.getByTimeOfDay(timeOfDay);

    // Ordenar por no probadas primero
    suggestions.sort((a, b) {
      final aUntried = !state.triedSuggestionIds.contains(a.id);
      final bUntried = !state.triedSuggestionIds.contains(b.id);
      if (aUntried && !bUntried) return -1;
      if (!aUntried && bUntried) return 1;
      return 0;
    });

    return suggestions.take(limit).toList();
  }

  /// Obtiene estadisticas de bienestar por categoria
  Map<String, Map<String, int>> getStatsByCategory() {
    final stats = <String, Map<String, int>>{};

    for (final category in WellnessCategory.all) {
      final categorySuggestions = WellnessCatalog.getByCategory(category);
      final tried = categorySuggestions
          .where((s) => state.triedSuggestionIds.contains(s.id))
          .length;

      stats[category] = {'total': categorySuggestions.length, 'tried': tried};
    }

    return stats;
  }

  /// Fuerza la regeneracion del contenido diario
  Future<void> forceRefreshDailyContent() async {
    await _generateDailyContent();
  }

  /// Limpia todo el historial de sugerencias probadas
  Future<void> clearTriedHistory() async {
    state = state.copyWith(triedSuggestionIds: {});
    await _saveState();
  }

  /// Limpia todos los favoritos
  Future<void> clearFavorites() async {
    state = state.copyWith(favoriteSuggestionIds: {});
    await _saveState();
  }
}

/// Provider para obtener la sugerencia del dia
final suggestionOfTheDayProvider = Provider.autoDispose<WellnessSuggestion?>((
  ref,
) {
  final state = ref.watch(wellnessProvider);
  return state.suggestionOfTheDay;
});

/// Provider para obtener las recomendaciones diarias
final dailyRecommendationsProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
      final state = ref.watch(wellnessProvider);
      return state.dailyRecommendations;
    });

/// Provider para obtener sugerencias favoritas
final favoriteSuggestionsProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
      final state = ref.watch(wellnessProvider);
      return state.favoriteSuggestions;
    });

/// Provider para obtener sugerencias probadas
final triedSuggestionsProvider = Provider.autoDispose<List<WellnessSuggestion>>(
  (ref) {
    final state = ref.watch(wellnessProvider);
    return state.triedSuggestions;
  },
);

/// Provider para obtener sugerencias no probadas
final untriedSuggestionsProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
      final state = ref.watch(wellnessProvider);
      return state.untriedSuggestions;
    });

/// Provider para obtener sugerencias relevantes para el momento actual
final suggestionsForNowProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
      final notifier = ref.read(wellnessProvider.notifier);
      return notifier.getSuggestionsForNow();
    });

/// Provider para verificar si una sugerencia ha sido probada
final hasSuggestionBeenTriedProvider = Provider.autoDispose
    .family<bool, String>((ref, suggestionId) {
      final state = ref.watch(wellnessProvider);
      return state.hasTried(suggestionId);
    });

/// Provider para verificar si una sugerencia es favorita
final isSuggestionFavoriteProvider = Provider.autoDispose.family<bool, String>((
  ref,
  suggestionId,
) {
  final state = ref.watch(wellnessProvider);
  return state.isFavorite(suggestionId);
});

/// Provider para obtener estadisticas de bienestar
final wellnessStatsProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final state = ref.watch(wellnessProvider);
  final notifier = ref.read(wellnessProvider.notifier);

  return {
    'totalSuggestions': WellnessCatalog.totalSuggestions,
    'totalTried': state.totalTried,
    'totalAdded': state.totalAdded,
    'totalUsed': state.totalUsed,
    'totalFavorites': state.totalFavorites,
    'triedPercentage': state.triedPercentage,
    'usedPercentage': state.usedPercentage,
    'byCategory': notifier.getStatsByCategory(),
  };
});

/// Provider para obtener sugerencias disponibles (no usadas)
final availableSuggestionsProvider =
    Provider.autoDispose<List<WellnessSuggestion>>((ref) {
      final state = ref.watch(wellnessProvider);
      return state.availableSuggestions;
    });

/// Provider para verificar si una sugerencia ha sido agregada a tareas
final hasSuggestionBeenAddedProvider = Provider.autoDispose
    .family<bool, String>((ref, suggestionId) {
      final state = ref.watch(wellnessProvider);
      return state.hasBeenAdded(suggestionId);
    });

/// Provider para verificar si una sugerencia ya fue usada
final hasSuggestionBeenUsedProvider = Provider.autoDispose
    .family<bool, String>((ref, suggestionId) {
      final state = ref.watch(wellnessProvider);
      return state.hasBeenUsed(suggestionId);
    });
