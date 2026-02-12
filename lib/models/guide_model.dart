/// Modelo de Guía Celestial (Heredero del Panteón AuraList).
///
/// Definido por el Consejo de los Pilares — Arquitecto.
/// Persistencia: Firestore colección `guides`; preferencia activa en usuario.
/// Hive typeId 8 reservado para futura caché local.
library;

/// Definición de una Bendición: poder que el guía otorga cuando está activo.
///
/// En código: el [id] se resuelve en [GuideBlessingRegistry] para ejecutar
/// la lógica (cambio de tema, haptics, animaciones, reducción de fricción).
class BlessingDefinition {
  const BlessingDefinition({
    required this.id,
    required this.name,
    required this.trigger,
    required this.effect,
  });

  final String id;
  final String name;
  /// Cuándo se activa: ej. "Al activar al guía", "Al completar las 3 primeras tareas del día".
  final String trigger;
  /// Qué hace en la app: ej. "Reduce contraste visual", "Emite pulsación azul".
  final String effect;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trigger': trigger,
        'effect': effect,
      };

  factory BlessingDefinition.fromJson(Map<String, dynamic> json) {
    return BlessingDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      effect: json['effect'] as String? ?? '',
    );
  }
}

/// Guía Celestial (Heredero): personaje del Panteón con afinidad, bendiciones y sinergias.
///
/// El tema de la app puede reaccionar a [id] vía Stream/Provider:
/// `activeGuideProvider` → `themeProvider` / haptics / animaciones.
class Guide {
  const Guide({
    required this.id,
    required this.name,
    required this.title,
    required this.affinity,
    this.classFamily = '',
    this.archetype = '',
    this.powerSentence = '',
    this.blessingIds = const [],
    this.synergyIds = const [],
    this.themePrimaryHex,
    this.themeSecondaryHex,
    this.themeAccentHex,
    this.descriptionShort,
    this.mythologyOrigin,
    this.blessings = const [],
  });

  /// Identificador estable (ej. `aethel`, `helioforja`).
  final String id;
  /// Nombre de fantasía (ej. "Aethel", "Helioforja").
  final String name;
  /// Título poético (ej. "El Primer Pulso del Sol").
  final String title;
  /// Afinidad funcional en la app (ej. "Prioridad", "Esfuerzo físico").
  final String affinity;
  /// Clase del Cónclave (ej. "Cónclave del Ímpetu").
  final String classFamily;
  /// Arquetipo jungiano (ej. "Guerrero de la Luz").
  final String archetype;
  /// Sentencia de poder (frase icónica).
  final String powerSentence;
  /// IDs de bendiciones que este guía otorga (resueltos en código).
  final List<String> blessingIds;
  /// IDs de guías con los que tiene sinergia.
  final List<String> synergyIds;
  /// Color primario del tema cuando este guía está activo (#RRGGBB).
  final String? themePrimaryHex;
  final String? themeSecondaryHex;
  final String? themeAccentHex;
  /// Descripción breve para UI.
  final String? descriptionShort;
  /// Origen mitológico (referencia Historiador).
  final String? mythologyOrigin;
  /// Definiciones de bendiciones (opcional; si vacío, usar [blessingIds] + registro global).
  final List<BlessingDefinition> blessings;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'affinity': affinity,
      'classFamily': classFamily,
      'archetype': archetype,
      'powerSentence': powerSentence,
      'blessingIds': blessingIds,
      'synergyIds': synergyIds,
      'themePrimaryHex': themePrimaryHex,
      'themeSecondaryHex': themeSecondaryHex,
      'themeAccentHex': themeAccentHex,
      'descriptionShort': descriptionShort,
      'mythologyOrigin': mythologyOrigin,
      'blessings': blessings.map((e) => e.toJson()).toList(),
    };
  }

  factory Guide.fromFirestore(Map<String, dynamic> data) {
    final list = data['blessings'] as List<dynamic>?;
    return Guide(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      title: data['title'] as String? ?? '',
      affinity: data['affinity'] as String? ?? '',
      classFamily: data['classFamily'] as String? ?? '',
      archetype: data['archetype'] as String? ?? '',
      powerSentence: data['powerSentence'] as String? ?? '',
      blessingIds: (data['blessingIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      synergyIds: (data['synergyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      themePrimaryHex: data['themePrimaryHex'] as String?,
      themeSecondaryHex: data['themeSecondaryHex'] as String?,
      themeAccentHex: data['themeAccentHex'] as String?,
      descriptionShort: data['descriptionShort'] as String?,
      mythologyOrigin: data['mythologyOrigin'] as String?,
      blessings: list
              ?.map((e) => BlessingDefinition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Guide copyWith({
    String? id,
    String? name,
    String? title,
    String? affinity,
    String? classFamily,
    String? archetype,
    String? powerSentence,
    List<String>? blessingIds,
    List<String>? synergyIds,
    String? themePrimaryHex,
    String? themeSecondaryHex,
    String? themeAccentHex,
    String? descriptionShort,
    String? mythologyOrigin,
    List<BlessingDefinition>? blessings,
  }) {
    return Guide(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      affinity: affinity ?? this.affinity,
      classFamily: classFamily ?? this.classFamily,
      archetype: archetype ?? this.archetype,
      powerSentence: powerSentence ?? this.powerSentence,
      blessingIds: blessingIds ?? this.blessingIds,
      synergyIds: synergyIds ?? this.synergyIds,
      themePrimaryHex: themePrimaryHex ?? this.themePrimaryHex,
      themeSecondaryHex: themeSecondaryHex ?? this.themeSecondaryHex,
      themeAccentHex: themeAccentHex ?? this.themeAccentHex,
      descriptionShort: descriptionShort ?? this.descriptionShort,
      mythologyOrigin: mythologyOrigin ?? this.mythologyOrigin,
      blessings: blessings ?? this.blessings,
    );
  }
}
