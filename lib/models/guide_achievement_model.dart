import 'package:hive/hive.dart';

part 'guide_achievement_model.g.dart';

/// Logro narrativo otorgado por un Guía Celestial.
///
/// Los logros NO son objetivos gamificados; son reconocimientos que el guía activo
/// otorga al usuario sin crear presión. Son títulos honoríficos que celebran
/// el progreso sin compararlo con metas pendientes.
@HiveType(typeId: 13)
class GuideAchievement extends HiveObject {
  /// Identificador único del logro (ej. 'aethel_primer_rayo')
  @HiveField(0)
  late String id;

  /// Título poético del logro en español (ej. 'Primer Rayo', 'Guardián de Tres Picos')
  @HiveField(1)
  late String titleEs;

  /// Descripción narrativa del logro
  @HiveField(2)
  late String description;

  /// ID del guía que otorga este logro (ej. 'aethel', 'crono-velo', 'luna-vacia')
  @HiveField(3)
  late String guideId;

  /// Categoría del logro: 'constancia', 'accion', 'equilibrio', 'progreso', 'descubrimiento'
  @HiveField(4)
  late String category;

  /// Descripción de cómo se obtiene (para referencia interna, no se muestra como meta)
  @HiveField(5)
  late String condition;

  /// Fecha y hora en que se obtuvo el logro (null si aún no se ha ganado)
  @HiveField(6)
  DateTime? earnedAt;

  /// Indica si el logro ya fue obtenido
  @HiveField(7)
  late bool isEarned;

  /// Mensaje especial del guía al otorgar el logro
  @HiveField(8)
  String? guideMessage;

  GuideAchievement({
    required this.id,
    required this.titleEs,
    required this.description,
    required this.guideId,
    required this.category,
    required this.condition,
    this.earnedAt,
    this.isEarned = false,
    this.guideMessage,
  });

  /// Marca el logro como obtenido
  void earn({String? message}) {
    isEarned = true;
    earnedAt = DateTime.now();
    if (message != null) {
      guideMessage = message;
    }
  }

  /// Copia el logro con campos modificados
  GuideAchievement copyWith({
    String? id,
    String? titleEs,
    String? description,
    String? guideId,
    String? category,
    String? condition,
    DateTime? earnedAt,
    bool? isEarned,
    String? guideMessage,
  }) {
    return GuideAchievement(
      id: id ?? this.id,
      titleEs: titleEs ?? this.titleEs,
      description: description ?? this.description,
      guideId: guideId ?? this.guideId,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      earnedAt: earnedAt ?? this.earnedAt,
      isEarned: isEarned ?? this.isEarned,
      guideMessage: guideMessage ?? this.guideMessage,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'titleEs': titleEs,
      'description': description,
      'guideId': guideId,
      'category': category,
      'condition': condition,
      'earnedAt': earnedAt?.toIso8601String(),
      'isEarned': isEarned,
      'guideMessage': guideMessage,
    };
  }

  factory GuideAchievement.fromFirestore(Map<String, dynamic> data) {
    return GuideAchievement(
      id: data['id'] as String? ?? '',
      titleEs: data['titleEs'] as String? ?? '',
      description: data['description'] as String? ?? '',
      guideId: data['guideId'] as String? ?? '',
      category: data['category'] as String? ?? 'progreso',
      condition: data['condition'] as String? ?? '',
      earnedAt: data['earnedAt'] != null
          ? DateTime.parse(data['earnedAt'] as String)
          : null,
      isEarned: data['isEarned'] as bool? ?? false,
      guideMessage: data['guideMessage'] as String?,
    );
  }
}
