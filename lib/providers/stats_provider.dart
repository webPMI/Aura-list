import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

/// Represents the statistics for a task's completion history
class TaskStats {
  final int currentStreak;
  final int longestStreak;
  final int completedThisWeek;
  final int totalThisWeek;
  final int completedThisMonth;
  final int totalThisMonth;
  final double completionRateWeek;
  final double completionRateMonth;
  final List<bool?> last7Days; // Monday to Sunday, null = future day

  const TaskStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedThisWeek,
    required this.totalThisWeek,
    required this.completedThisMonth,
    required this.totalThisMonth,
    required this.completionRateWeek,
    required this.completionRateMonth,
    required this.last7Days,
  });

  /// Creates an empty/default stats object
  factory TaskStats.empty() {
    return TaskStats(
      currentStreak: 0,
      longestStreak: 0,
      completedThisWeek: 0,
      totalThisWeek: 0,
      completedThisMonth: 0,
      totalThisMonth: 0,
      completionRateWeek: 0.0,
      completionRateMonth: 0.0,
      last7Days: List.filled(7, null),
    );
  }

  /// Creates TaskStats from a map (from DatabaseService)
  factory TaskStats.fromMap(Map<String, dynamic> map) {
    return TaskStats(
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      completedThisWeek: map['completedThisWeek'] as int? ?? 0,
      totalThisWeek: map['totalThisWeek'] as int? ?? 0,
      completedThisMonth: map['completedThisMonth'] as int? ?? 0,
      totalThisMonth: map['totalThisMonth'] as int? ?? 0,
      completionRateWeek:
          (map['completionRateWeek'] as num?)?.toDouble() ?? 0.0,
      completionRateMonth:
          (map['completionRateMonth'] as num?)?.toDouble() ?? 0.0,
      last7Days:
          (map['last7Days'] as List?)?.cast<bool?>() ?? List.filled(7, null),
    );
  }

  /// Returns a motivational message based on the current stats
  String get motivationalMessage {
    // Streak-based messages
    if (currentStreak >= 30) {
      return '30+ dias seguidos! Eres imparable!';
    } else if (currentStreak >= 21) {
      return 'Tres semanas seguidas! El habito ya es tuyo!';
    } else if (currentStreak >= 14) {
      return 'Dos semanas de racha! Estas en fuego!';
    } else if (currentStreak >= 7) {
      return 'Una semana completa! Sigue asi!';
    } else if (currentStreak >= 3) {
      return '$currentStreak dias seguidos! No pares ahora!';
    } else if (currentStreak == 2) {
      return 'Dos dias seguidos! Un dia mas y tienes una racha!';
    } else if (currentStreak == 1) {
      return 'Buen comienzo! Manana sera el dia 2!';
    }

    // Completion rate based messages
    if (completionRateWeek >= 0.8) {
      return 'Excelente semana! Mas del 80% completado!';
    } else if (completionRateWeek >= 0.6) {
      return 'Buena semana! Sigue mejorando!';
    } else if (completionRateWeek >= 0.4) {
      return 'Vas por buen camino! No te rindas!';
    } else if (completedThisWeek > 0) {
      return 'Cada dia cuenta! Tu puedes mejorar!';
    }

    // New task or no history
    if (longestStreak > 0) {
      return 'Tu mejor racha fue de $longestStreak dias. Superala!';
    }

    return 'Comienza hoy y construye tu racha!';
  }

  /// Returns the streak status emoji
  String get streakEmoji {
    if (currentStreak >= 30) return '!!!';
    if (currentStreak >= 21) return '!!';
    if (currentStreak >= 14) return '!';
    if (currentStreak >= 7) return '';
    if (currentStreak >= 3) return '';
    return '';
  }

  /// Returns whether the user is on a hot streak (7+ days)
  bool get isOnFire => currentStreak >= 7;

  /// Returns whether the task is being neglected (0 completions this week)
  bool get isNeglected => completedThisWeek == 0 && totalThisWeek > 2;

  @override
  String toString() {
    return 'TaskStats(streak: $currentStreak, weekRate: ${(completionRateWeek * 100).toStringAsFixed(0)}%)';
  }
}

/// Provider to fetch task stats for a specific task
final taskStatsProvider = FutureProvider.autoDispose.family<TaskStats, String>((
  ref,
  taskId,
) async {
  final dbService = ref.read(databaseServiceProvider);
  final statsMap = await dbService.getCompletionStats(taskId);
  return TaskStats.fromMap(statsMap);
});

/// Provider to refresh stats (invalidates the cache)
final refreshStatsProvider = Provider.autoDispose((ref) {
  return (String taskId) {
    ref.invalidate(taskStatsProvider(taskId));
  };
});

/// Provider to record task completion and refresh stats
final recordCompletionProvider = Provider.autoDispose((ref) {
  return (String taskId, bool completed) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.recordTaskCompletion(taskId, completed);
    ref.invalidate(taskStatsProvider(taskId));
  };
});
