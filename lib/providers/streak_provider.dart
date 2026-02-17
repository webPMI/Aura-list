import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Claves de SharedPreferences para persistencia de rachas
const _keyLastCompletionDate = 'last_task_completion_date';
const _keyCurrentStreak = 'current_streak';
const _keyGraceDaysUsed = 'streak_grace_days_used';
const _keyGraceMonth = 'streak_grace_month';

/// Dias de gracia disponibles por mes
const _graceDaysPerMonth = 2;

/// Estado de la racha del usuario
class StreakState {
  const StreakState({
    required this.currentStreak,
    required this.lastCompletionDate,
    this.needsGraceDayOffer = false,
    this.graceDaysRemainingThisMonth = _graceDaysPerMonth,
    this.graceMonth,
  });

  /// Dias consecutivos con al menos una tarea completada
  final int currentStreak;

  /// Fecha de la ultima tarea completada (formato: 'yyyy-MM-dd')
  final String? lastCompletionDate;

  /// true cuando se detecta un dia perdido y quedan dias de gracia disponibles
  final bool needsGraceDayOffer;

  /// Dias de gracia restantes en el mes actual (maximo 2)
  final int graceDaysRemainingThisMonth;

  /// Mes en que se registraron los dias de gracia usados (1-12)
  final int? graceMonth;

  /// Estado inicial vacio
  factory StreakState.empty() {
    return const StreakState(currentStreak: 0, lastCompletionDate: null);
  }

  StreakState copyWith({
    int? currentStreak,
    String? lastCompletionDate,
    bool? needsGraceDayOffer,
    int? graceDaysRemainingThisMonth,
    int? graceMonth,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      needsGraceDayOffer: needsGraceDayOffer ?? this.needsGraceDayOffer,
      graceDaysRemainingThisMonth:
          graceDaysRemainingThisMonth ?? this.graceDaysRemainingThisMonth,
      graceMonth: graceMonth ?? this.graceMonth,
    );
  }
}

/// Notifier que gestiona el estado de la racha del usuario
class StreakNotifier extends StateNotifier<StreakState> {
  final Completer<void> _initCompleter = Completer<void>();

  StreakNotifier() : super(StreakState.empty()) {
    _loadStreak();
  }

  /// Completes when the initial load from SharedPreferences finishes.
  /// Await this before reading state that depends on persisted data
  /// (e.g., [StreakState.needsGraceDayOffer]).
  Future<void> ensureInitialized() => _initCompleter.future;

  /// Formatea una fecha como 'yyyy-MM-dd'
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Carga la racha guardada desde SharedPreferences
  Future<void> _loadStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDate = prefs.getString(_keyLastCompletionDate);
      final streak = prefs.getInt(_keyCurrentStreak) ?? 0;

      // Cargar dias de gracia con reset mensual automatico
      final now = DateTime.now();
      final savedMonth = prefs.getInt(_keyGraceMonth);
      int graceDaysUsed;
      if (savedMonth == null || savedMonth != now.month) {
        // Nuevo mes: resetear dias de gracia
        graceDaysUsed = 0;
        await prefs.setInt(_keyGraceMonth, now.month);
        await prefs.setInt(_keyGraceDaysUsed, 0);
      } else {
        graceDaysUsed = prefs.getInt(_keyGraceDaysUsed) ?? 0;
      }
      final graceDaysRemaining = (_graceDaysPerMonth - graceDaysUsed).clamp(0, _graceDaysPerMonth);

      if (lastDate != null && streak > 0) {
        final today = _formatDate(now);
        final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
        final dayBeforeYesterday = _formatDate(now.subtract(const Duration(days: 2)));

        if (lastDate == today || lastDate == yesterday) {
          // La racha sigue activa
          state = StreakState(
            currentStreak: streak,
            lastCompletionDate: lastDate,
            graceDaysRemainingThisMonth: graceDaysRemaining,
            graceMonth: now.month,
          );
        } else if (lastDate == dayBeforeYesterday && graceDaysRemaining > 0) {
          // Falto exactamente 1 dia y hay dias de gracia disponibles: ofrecer rescate
          state = StreakState(
            currentStreak: streak,
            lastCompletionDate: lastDate,
            needsGraceDayOffer: true,
            graceDaysRemainingThisMonth: graceDaysRemaining,
            graceMonth: now.month,
          );
        } else {
          // La racha se rompio (mas de un dia sin completar, o sin dias de gracia)
          state = StreakState(
            currentStreak: 0,
            lastCompletionDate: null,
            graceDaysRemainingThisMonth: graceDaysRemaining,
            graceMonth: now.month,
          );
          await _saveStreak();
        }
      } else {
        state = StreakState(
          currentStreak: streak,
          lastCompletionDate: lastDate,
          graceDaysRemainingThisMonth: graceDaysRemaining,
          graceMonth: now.month,
        );
      }
    } finally {
      // Always signal readiness so callers awaiting ensureInitialized()
      // are never permanently blocked, even if loading fails.
      if (!_initCompleter.isCompleted) _initCompleter.complete();
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

  /// Verifica y actualiza la racha cuando se completa una tarea.
  /// Retorna el nuevo valor de la racha si hubo incremento, null si ya estaba contabilizado hoy.
  Future<int?> checkAndUpdateStreak() async {
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Si hay una oferta de dia de gracia pendiente y el usuario completa una tarea,
    // declinar la oferta implicitamente y comenzar nueva racha desde hoy.
    if (state.needsGraceDayOffer) {
      state = state.copyWith(
        needsGraceDayOffer: false,
        currentStreak: 1,
        lastCompletionDate: today,
      );
      await _saveStreak();
      return 1;
    }

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

    state = state.copyWith(
      currentStreak: newStreak,
      lastCompletionDate: today,
      needsGraceDayOffer: false,
    );

    await _saveStreak();
    return newStreak;
  }

  /// Acepta el dia de gracia: preserva la racha actual como si ayer se hubiera completado.
  Future<void> acceptGraceDay() async {
    if (!state.needsGraceDayOffer) return;

    final prefs = await SharedPreferences.getInstance();
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));
    final newGraceDaysUsed = (_graceDaysPerMonth - state.graceDaysRemainingThisMonth) + 1;

    await prefs.setInt(_keyGraceDaysUsed, newGraceDaysUsed);

    state = state.copyWith(
      needsGraceDayOffer: false,
      lastCompletionDate: yesterday,
      graceDaysRemainingThisMonth: state.graceDaysRemainingThisMonth - 1,
    );

    await _saveStreak();
  }

  /// Declina el dia de gracia: reinicia la racha.
  Future<void> declineGraceDay() async {
    if (!state.needsGraceDayOffer) return;

    state = StreakState(
      currentStreak: 0,
      lastCompletionDate: null,
      needsGraceDayOffer: false,
      graceDaysRemainingThisMonth: state.graceDaysRemainingThisMonth,
      graceMonth: state.graceMonth,
    );

    await _saveStreak();
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
