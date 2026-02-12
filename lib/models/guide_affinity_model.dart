/// Modelo de Afinidad con un Guía Celestial.
///
/// Rastrea la conexión y progreso del usuario con un guía específico.
/// El nivel de afinidad se calcula basado en tareas completadas y días activos.
///
/// Filosofía del Guardián: Los niveles NUNCA bajan, solo suben.
/// No hay castigos por inactividad, solo celebración del progreso.
library;

/// Niveles de afinidad del 0 al 5.
/// Cada nivel desbloquea nuevas características y mejora la experiencia.
enum AffinityLevel {
  stranger(0, 'Extraño'),
  acquaintance(1, 'Conocido'),
  companion(2, 'Compañero'),
  ally(3, 'Aliado'),
  bond(4, 'Vínculo'),
  soulmate(5, 'Alma Gemela');

  const AffinityLevel(this.value, this.label);
  final int value;
  final String label;

  /// Descripción de lo que representa cada nivel.
  String get description {
    switch (this) {
      case AffinityLevel.stranger:
        return 'Acabas de conocer a este guía';
      case AffinityLevel.acquaintance:
        return 'El guía comienza a conocerte';
      case AffinityLevel.companion:
        return 'Comparten experiencias juntos';
      case AffinityLevel.ally:
        return 'Una relación de confianza mutua';
      case AffinityLevel.bond:
        return 'Un vínculo profundo se ha formado';
      case AffinityLevel.soulmate:
        return 'Almas que caminan juntas';
    }
  }

  /// Obtener nivel desde valor numérico.
  static AffinityLevel fromValue(int value) {
    return AffinityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => AffinityLevel.stranger,
    );
  }
}

/// Modelo de afinidad con un guía celestial.
class GuideAffinity {
  const GuideAffinity({
    required this.guideId,
    this.connectionLevel = 0,
    this.tasksCompletedWithGuide = 0,
    this.daysWithGuide = 0,
    this.firstActivationDate,
    this.lastActiveDate,
  });

  /// ID del guía al que pertenece esta afinidad.
  final String guideId;

  /// Nivel de conexión (0-5).
  /// 0 = Extraño, 1 = Conocido, 2 = Compañero, 3 = Aliado, 4 = Vínculo, 5 = Alma Gemela
  final int connectionLevel;

  /// Número total de tareas completadas con este guía activo.
  final int tasksCompletedWithGuide;

  /// Número total de días que el guía ha estado activo.
  final int daysWithGuide;

  /// Primera vez que se activó este guía.
  final DateTime? firstActivationDate;

  /// Última vez que el guía estuvo activo.
  final DateTime? lastActiveDate;

  /// Obtener el nivel de afinidad como enum.
  AffinityLevel get level => AffinityLevel.fromValue(connectionLevel);

  /// Nombre del nivel en español.
  String get levelName => level.label;

  /// Descripción del nivel actual.
  String get levelDescription => level.description;

  /// Tareas necesarias para el siguiente nivel.
  /// Progresión: 0→1: 5 tareas, 1→2: 15 tareas, 2→3: 30 tareas,
  /// 3→4: 50 tareas, 4→5: 100 tareas
  int get tasksRequiredForNextLevel {
    switch (connectionLevel) {
      case 0:
        return 5;
      case 1:
        return 15;
      case 2:
        return 30;
      case 3:
        return 50;
      case 4:
        return 100;
      default:
        return 0; // Nivel máximo alcanzado
    }
  }

  /// Días necesarios para el siguiente nivel.
  /// Progresión: 0→1: 1 día, 1→2: 3 días, 2→3: 7 días,
  /// 3→4: 14 días, 4→5: 30 días
  int get daysRequiredForNextLevel {
    switch (connectionLevel) {
      case 0:
        return 1;
      case 1:
        return 3;
      case 2:
        return 7;
      case 3:
        return 14;
      case 4:
        return 30;
      default:
        return 0; // Nivel máximo alcanzado
    }
  }

  /// Progreso hacia el siguiente nivel (0.0 - 1.0).
  /// Calcula el promedio entre progreso de tareas y días.
  double get progressToNextLevel {
    if (connectionLevel >= 5) return 1.0;

    final tasksRequired = tasksRequiredForNextLevel;
    final daysRequired = daysRequiredForNextLevel;

    if (tasksRequired == 0 || daysRequired == 0) return 1.0;

    final taskProgress = (tasksCompletedWithGuide / tasksRequired).clamp(0.0, 1.0);
    final dayProgress = (daysWithGuide / daysRequired).clamp(0.0, 1.0);

    // Ambos deben alcanzarse para avanzar de nivel
    return (taskProgress + dayProgress) / 2;
  }

  /// Verifica si se cumplieron los requisitos para subir de nivel.
  bool get canLevelUp {
    if (connectionLevel >= 5) return false;
    return tasksCompletedWithGuide >= tasksRequiredForNextLevel &&
        daysWithGuide >= daysRequiredForNextLevel;
  }

  /// Nivel máximo alcanzado.
  bool get isMaxLevel => connectionLevel >= 5;

  /// Mensaje de felicitación al subir de nivel.
  String get levelUpMessage {
    switch (connectionLevel + 1) {
      case 1:
        return '¡$levelName! Tu guía comienza a conocerte.';
      case 2:
        return '¡$levelName! Comparten experiencias juntos.';
      case 3:
        return '¡$levelName! Una relación de confianza mutua.';
      case 4:
        return '¡$levelName! Un vínculo profundo se ha formado.';
      case 5:
        return '¡$levelName! Almas que caminan juntas hacia la realización.';
      default:
        return '¡Nivel de afinidad alcanzado!';
    }
  }

  /// Calcular el nuevo nivel basado en tareas y días.
  int calculateLevel() {
    // Nivel 1: 5 tareas + 1 día
    if (tasksCompletedWithGuide >= 5 && daysWithGuide >= 1 && connectionLevel < 1) {
      return 1;
    }
    // Nivel 2: 15 tareas + 3 días
    if (tasksCompletedWithGuide >= 15 && daysWithGuide >= 3 && connectionLevel < 2) {
      return 2;
    }
    // Nivel 3: 30 tareas + 7 días
    if (tasksCompletedWithGuide >= 30 && daysWithGuide >= 7 && connectionLevel < 3) {
      return 3;
    }
    // Nivel 4: 50 tareas + 14 días
    if (tasksCompletedWithGuide >= 50 && daysWithGuide >= 14 && connectionLevel < 4) {
      return 4;
    }
    // Nivel 5: 100 tareas + 30 días
    if (tasksCompletedWithGuide >= 100 && daysWithGuide >= 30 && connectionLevel < 5) {
      return 5;
    }
    return connectionLevel;
  }

  /// Convertir a JSON para persistencia.
  Map<String, dynamic> toJson() {
    return {
      'guideId': guideId,
      'connectionLevel': connectionLevel,
      'tasksCompletedWithGuide': tasksCompletedWithGuide,
      'daysWithGuide': daysWithGuide,
      'firstActivationDate': firstActivationDate?.toIso8601String(),
      'lastActiveDate': lastActiveDate?.toIso8601String(),
    };
  }

  /// Crear desde JSON.
  factory GuideAffinity.fromJson(Map<String, dynamic> json) {
    return GuideAffinity(
      guideId: json['guideId'] as String? ?? '',
      connectionLevel: json['connectionLevel'] as int? ?? 0,
      tasksCompletedWithGuide: json['tasksCompletedWithGuide'] as int? ?? 0,
      daysWithGuide: json['daysWithGuide'] as int? ?? 0,
      firstActivationDate: json['firstActivationDate'] != null
          ? DateTime.parse(json['firstActivationDate'] as String)
          : null,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : null,
    );
  }

  /// Copiar con cambios.
  GuideAffinity copyWith({
    String? guideId,
    int? connectionLevel,
    int? tasksCompletedWithGuide,
    int? daysWithGuide,
    DateTime? firstActivationDate,
    DateTime? lastActiveDate,
  }) {
    return GuideAffinity(
      guideId: guideId ?? this.guideId,
      connectionLevel: connectionLevel ?? this.connectionLevel,
      tasksCompletedWithGuide:
          tasksCompletedWithGuide ?? this.tasksCompletedWithGuide,
      daysWithGuide: daysWithGuide ?? this.daysWithGuide,
      firstActivationDate: firstActivationDate ?? this.firstActivationDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  String toString() {
    return 'GuideAffinity(guideId: $guideId, level: $connectionLevel/$levelName, '
        'tasks: $tasksCompletedWithGuide, days: $daysWithGuide)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuideAffinity &&
        other.guideId == guideId &&
        other.connectionLevel == connectionLevel &&
        other.tasksCompletedWithGuide == tasksCompletedWithGuide &&
        other.daysWithGuide == daysWithGuide &&
        other.firstActivationDate == firstActivationDate &&
        other.lastActiveDate == lastActiveDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      guideId,
      connectionLevel,
      tasksCompletedWithGuide,
      daysWithGuide,
      firstActivationDate,
      lastActiveDate,
    );
  }
}
