/// Modelo para sugerencias de bienestar y rutinas saludables.
///
/// Representa una actividad o habito que promueve el bienestar fisico,
/// mental, social, nutricional, del sueno o de productividad.
class WellnessSuggestion {
  /// Identificador unico de la sugerencia
  final String id;

  /// Titulo corto y descriptivo de la actividad
  final String title;

  /// Descripcion detallada de como realizar la actividad
  final String description;

  /// Categoria de bienestar:
  /// - 'physical': Actividad fisica
  /// - 'mental': Bienestar mental
  /// - 'social': Conexiones sociales
  /// - 'nutrition': Alimentacion saludable
  /// - 'sleep': Higiene del sueno
  /// - 'productivity': Productividad y organizacion
  final String category;

  /// Explicacion motivacional de por que esta actividad es beneficiosa.
  /// Incluye datos cientificos o psicologicos cuando es posible.
  final String motivation;

  /// Nombre del icono de Material Icons para representar la actividad
  final String icon;

  /// Duracion estimada en minutos para completar la actividad
  final int durationMinutes;

  /// Mejor momento del dia para realizar la actividad:
  /// - 'morning': Por la manana
  /// - 'afternoon': Por la tarde
  /// - 'evening': Por la noche
  /// - 'anytime': Cualquier momento
  final String bestTimeOfDay;

  /// Lista de beneficios especificos que aporta esta actividad
  final List<String> benefits;

  /// Lista de 5 recomendaciones variadas para realizar la actividad
  final List<String> recommendations;

  const WellnessSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.motivation,
    required this.icon,
    required this.durationMinutes,
    required this.bestTimeOfDay,
    required this.benefits,
    this.recommendations = const [],
  });

  /// Obtiene la etiqueta en espanol para la categoria
  String get categoryLabel {
    switch (category) {
      case 'physical':
        return 'Fisico';
      case 'mental':
        return 'Mental';
      case 'social':
        return 'Social';
      case 'nutrition':
        return 'Nutricion';
      case 'sleep':
        return 'Sueno';
      case 'productivity':
        return 'Productividad';
      default:
        return 'General';
    }
  }

  /// Obtiene la etiqueta en espanol para el momento del dia
  String get bestTimeLabel {
    switch (bestTimeOfDay) {
      case 'morning':
        return 'Manana';
      case 'afternoon':
        return 'Tarde';
      case 'evening':
        return 'Noche';
      case 'anytime':
        return 'Cualquier momento';
      default:
        return 'Cualquier momento';
    }
  }

  /// Formatea la duracion de forma legible
  String get durationLabel {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) {
        return '$hours h';
      }
      return '$hours h $mins min';
    }
  }

  /// Crea una copia con campos modificados
  WellnessSuggestion copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? motivation,
    String? icon,
    int? durationMinutes,
    String? bestTimeOfDay,
    List<String>? benefits,
    List<String>? recommendations,
  }) {
    return WellnessSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      motivation: motivation ?? this.motivation,
      icon: icon ?? this.icon,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bestTimeOfDay: bestTimeOfDay ?? this.bestTimeOfDay,
      benefits: benefits ?? this.benefits,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  /// Convierte a mapa para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'motivation': motivation,
      'icon': icon,
      'durationMinutes': durationMinutes,
      'bestTimeOfDay': bestTimeOfDay,
      'benefits': benefits,
      'recommendations': recommendations,
    };
  }

  /// Crea una instancia desde un mapa
  factory WellnessSuggestion.fromMap(Map<String, dynamic> map) {
    return WellnessSuggestion(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      motivation: map['motivation'] as String,
      icon: map['icon'] as String,
      durationMinutes: map['durationMinutes'] as int,
      bestTimeOfDay: map['bestTimeOfDay'] as String,
      benefits: List<String>.from(map['benefits'] as List),
      recommendations: map['recommendations'] != null
          ? List<String>.from(map['recommendations'] as List)
          : const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WellnessSuggestion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WellnessSuggestion(id: $id, title: $title, category: $category)';
  }
}

/// Categorias disponibles de bienestar
class WellnessCategory {
  static const String physical = 'physical';
  static const String mental = 'mental';
  static const String social = 'social';
  static const String nutrition = 'nutrition';
  static const String sleep = 'sleep';
  static const String productivity = 'productivity';

  static const List<String> all = [
    physical,
    mental,
    social,
    nutrition,
    sleep,
    productivity,
  ];

  /// Obtiene el icono asociado a cada categoria
  static String getIcon(String category) {
    switch (category) {
      case physical:
        return 'fitness_center';
      case mental:
        return 'self_improvement';
      case social:
        return 'people';
      case nutrition:
        return 'restaurant';
      case sleep:
        return 'bedtime';
      case productivity:
        return 'task_alt';
      default:
        return 'favorite';
    }
  }

  /// Obtiene el label en espanol para cada categoria
  static String getLabel(String category) {
    switch (category) {
      case physical:
        return 'Fisico';
      case mental:
        return 'Mental';
      case social:
        return 'Social';
      case nutrition:
        return 'Nutricion';
      case sleep:
        return 'Sueno';
      case productivity:
        return 'Productividad';
      default:
        return 'General';
    }
  }
}

/// Momentos del dia disponibles para actividades de bienestar.
/// Renombrado de TimeOfDay para evitar conflicto con Flutter's TimeOfDay.
class BestTimeOfDay {
  static const String morning = 'morning';
  static const String afternoon = 'afternoon';
  static const String evening = 'evening';
  static const String anytime = 'anytime';

  static const List<String> all = [
    morning,
    afternoon,
    evening,
    anytime,
  ];

  /// Obtiene el label en espanol para el momento del dia
  static String getLabel(String time) {
    switch (time) {
      case morning:
        return 'Manana';
      case afternoon:
        return 'Tarde';
      case evening:
        return 'Noche';
      case anytime:
        return 'Cualquier momento';
      default:
        return 'Cualquier momento';
    }
  }
}
