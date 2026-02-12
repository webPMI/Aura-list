/// Rutas centralizadas de assets para el feature Guías Celestiales (personajes místicos).
///
/// Uso: importar desde el barrel del feature y usar [GuideAssetPaths.avatar], etc.
/// Los assets deben estar en [assets/guides/] (ver pubspec.yaml).
class GuideAssetPaths {
  GuideAssetPaths._();

  static const String _base = 'assets/guides';
  static const String _avatars = '$_base/avatars';
  static const String _animations = '$_base/animations';

  /// Avatar del guía: imagen cuadrada (ej. 1x1). Nombre: [guideId].png
  /// Ej: assets/guides/avatars/aethel.png
  static String avatar(String guideId) => '$_avatars/$guideId.png';

  /// Animación idle del guía (estado neutro). Opcional: Lottie .json
  /// Ej: assets/guides/animations/aethel_idle.json
  static String animationIdle(String guideId) =>
      '$_animations/${guideId}_idle.json';

  /// Animación celebración (al completar tarea). Opcional: Lottie .json
  /// Ej: assets/guides/animations/aethel_celebration.json
  static String animationCelebration(String guideId) =>
      '$_animations/${guideId}_celebration.json';

  /// Animación motivación (tareas pendientes). Opcional: Lottie .json
  /// Ej: assets/guides/animations/aethel_motivation.json
  static String animationMotivation(String guideId) =>
      '$_animations/${guideId}_motivation.json';

  /// Imagen vertical (pantallas de bienvenida). Opcional: .png
  /// Ej: assets/guides/avatars/aethel_vertical.png
  static String avatarVertical(String guideId) =>
      '$_avatars/${guideId}_vertical.png';

  /// Lista de todos los paths de avatares que la app puede precargar (opcional).
  static List<String> allAvatarPaths(List<String> guideIds) =>
      guideIds.map(avatar).toList();
}
