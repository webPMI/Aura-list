import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves de SharedPreferences para persistencia de rachas
const _keyLastCompletionDate = 'last_task_completion_date';
const _keyCurrentStreak = 'current_streak';

/// Estado de la racha del usuario
class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.lastCompletionDate,
  });

  /// Dias consecutivos con al menos una tarea completada
  final int currentStreak;

  /// Fecha de la ultima tarea completada (formato: 'yyyy-MM-dd')
  final String? lastCompletionDate;

  /// Estado inicial vacio
  factory StreakState.empty() {
    return const StreakState(currentStreak: 0, lastCompletionDate: null);
  }

  StreakState copyWith({
    int? currentStreak,
    String? lastCompletionDate,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
    );
  }
}

/// Notifier que gestiona el estado de la racha del usuario
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier() : super(StreakState.empty()) {
    _loadStreak();
  }

  /// Carga la racha guardada desde SharedPreferences
  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastCompletionDate);
    final streak = prefs.getInt(_keyCurrentStreak) ?? 0;

    // Verificar si la racha sigue activa
    if (lastDate != null) {
      final today = _formatDate(DateTime.now());
      final yesterday = _formatDate(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      if (lastDate == today || lastDate == yesterday) {
        // La racha sigue activa
        state = StreakState(
          currentStreak: streak,
          lastCompletionDate: lastDate,
        );
      } else {
        // La racha se rompio (mas de un dia sin completar)
        state = StreakState.empty();
        await _saveStreak();
      }
    }
  }

  /// Guarda la racha actual en SharedPreferences
  Future<void> _saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentStreak, state.currentStreak);
    if (state.lastCompletionDate != null) {
      await prefs.setString(_keyLastCompletionDate, state.lastCompletionDate!);
    } else {
      await prefs.remove(_keyLastCompletionDate);
    }
  }

  /// Formatea una fecha como 'yyyy-MM-dd'
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Verifica y actualiza la racha cuando se completa una tarea.
  /// Retorna el nuevo valor de la racha si hubo incremento, null si ya estaba contabilizado hoy.
  Future<int?> checkAndUpdateStreak() async {
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Si ya completamos una tarea hoy, no incrementar
    if (state.lastCompletionDate == today) {
      return null;
    }

    int newStreak;
    if (state.lastCompletionDate == yesterday) {
      // Continuamos la racha desde ayer
      newStreak = state.currentStreak + 1;
    } else {
      // Nueva racha (primera vez o despues de un gap)
      newStreak = 1;
    }

    state = StreakState(
      currentStreak: newStreak,
      lastCompletionDate: today,
    );

    await _saveStreak();
    return newStreak;
  }

  /// Reinicia la racha manualmente (para pruebas o reset)
  Future<void> resetStreak() async {
    state = StreakState.empty();
    await _saveStreak();
  }
}

/// Provider principal del estado de la racha
final streakProvider = StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier();
});

/// Provider que expone solo el contador de dias de racha actual
final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(streakProvider).currentStreak;
});

/// Provider que permite verificar y actualizar la racha cuando se completa una tarea.
/// Uso: `ref.read(checkStreakProvider)()` devuelve `Future<int?>` con el nuevo valor si cambio.
final checkStreakProvider = Provider<Future<int?> Function()>((ref) {
  return () => ref.read(streakProvider.notifier).checkAndUpdateStreak();
});

/// Hitos de racha que merecen celebracion
const streakMilestones = [3, 7, 14, 21, 30, 60, 90, 180, 365];

/// Verifica si un valor de racha es un hito celebrable
bool isStreakMilestone(int streak) {
  return streakMilestones.contains(streak);
}

/// Obtiene el siguiente hito de racha a alcanzar
int getNextMilestone(int currentStreak) {
  for (final milestone in streakMilestones) {
    if (milestone > currentStreak) {
      return milestone;
    }
  }
  // Si supero todos los hitos definidos, cada 100 dias mas
  return ((currentStreak ~/ 100) + 1) * 100;
}
