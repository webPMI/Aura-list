import 'dart:convert';

/// Rangos Celestiales según el Aura Total acumulada
enum AuraRank {
  novice('Iniciado del Foco', '🌱', 0, 200),
  explorer('Explorador Consciente', '🧭', 201, 800),
  guardian('Guardián de la Productividad', '⚡', 801, 2000),
  seer('Vidente del Tiempo', '🔮', 2001, 5000),
  celestialMaster('Maestro Celestial', '👑', 5001, 999999);

  final String title;
  final String icon;
  final int minPoints;
  final int maxPoints;

  const AuraRank(this.title, this.icon, this.minPoints, this.maxPoints);

  static AuraRank fromPoints(int points) {
    for (final rank in AuraRank.values) {
      if (points <= rank.maxPoints) {
        return rank;
      }
    }
    return AuraRank.celestialMaster;
  }
}

/// Estado inmutable del Aura del Usuario
class AuraState {
  final int totalPoints;          // Puntos históricos acumulados (para nivel/rango)
  final int availablePoints;      // Puntos disponibles para canjear en el Santuario
  final int streakShields;        // Escudos de racha comprados activos
  final List<String> unlockedThemes; // IDs de temas cósmicos desbloqueados
  final List<String> recentActivity; // Últimas acciones que sumaron o gastaron Aura

  const AuraState({
    this.totalPoints = 50, // Puntos de bienvenida iniciales
    this.availablePoints = 50,
    this.streakShields = 0,
    this.unlockedThemes = const ['default'],
    this.recentActivity = const ['¡Bienvenido a AuraList! (+50 pts)'],
  });

  /// Nivel numérico derivado (1 - 50)
  int get level => (totalPoints / 100).floor() + 1;

  /// Rango celestial actual
  AuraRank get rank => AuraRank.fromPoints(totalPoints);

  /// Progreso porcentual hacia el siguiente nivel (0.0 a 1.0)
  double get progressToNextLevel {
    final currentLevelBase = (level - 1) * 100;
    final progressInLevel = totalPoints - currentLevelBase;
    return (progressInLevel / 100).clamp(0.0, 1.0);
  }

  /// Puntos necesarios para el siguiente nivel
  int get pointsToNextLevel {
    final nextLevelTarget = level * 100;
    return nextLevelTarget - totalPoints;
  }

  AuraState copyWith({
    int? totalPoints,
    int? availablePoints,
    int? streakShields,
    List<String>? unlockedThemes,
    List<String>? recentActivity,
  }) {
    return AuraState(
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      streakShields: streakShields ?? this.streakShields,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  Map<String, dynamic> toMap() => {
    'totalPoints': totalPoints,
    'availablePoints': availablePoints,
    'streakShields': streakShields,
    'unlockedThemes': unlockedThemes,
    'recentActivity': recentActivity,
  };

  factory AuraState.fromMap(Map<String, dynamic> map) {
    return AuraState(
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 50,
      availablePoints: (map['availablePoints'] as num?)?.toInt() ?? 50,
      streakShields: (map['streakShields'] as num?)?.toInt() ?? 0,
      unlockedThemes: (map['unlockedThemes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['default'],
      recentActivity: (map['recentActivity'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AuraState.fromJson(String source) => AuraState.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
