import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:checklist_app/features/guides/data/guide_asset_paths.dart';
import 'package:checklist_app/features/guides/data/guide_catalog.dart';

/// Servicio para precargar avatares de guías en memoria.
///
/// Precarga solo los avatares que existen, ignorando los faltantes
/// para evitar errores innecesarios en el log.
class AvatarPreloadService {
  AvatarPreloadService._();

  static final AvatarPreloadService instance = AvatarPreloadService._();

  /// Avatares precargados en memoria (cache).
  final Set<String> _preloadedAvatars = {};

  /// Indica si ya se completó la precarga inicial.
  bool _isPreloaded = false;

  bool get isPreloaded => _isPreloaded;

  /// Precarga todos los avatares disponibles en assets.
  ///
  /// **Uso:**
  /// ```dart
  /// await AvatarPreloadService.instance.preloadAvailableAvatars(context);
  /// ```
  ///
  /// **Cuándo usar:**
  /// - Al iniciar la app (splash screen o main)
  /// - Antes de mostrar la pantalla de selección de guías
  ///
  /// **Notas:**
  /// - Solo precarga avatares que existen
  /// - Usa [rootBundle] para verificar existencia antes de precargar
  /// - No lanza errores si un avatar falta
  Future<void> preloadAvailableAvatars(BuildContext context) async {
    if (_isPreloaded) return; // Ya precargado

    final guideIds = kGuideCatalog.map((g) => g.id).toList();

    for (final id in guideIds) {
      await _preloadSingleAvatar(context, id);
    }

    _isPreloaded = true;
  }

  /// Precarga un avatar individual si existe.
  Future<void> _preloadSingleAvatar(BuildContext context, String guideId) async {
    if (_preloadedAvatars.contains(guideId)) return; // Ya precargado

    final path = GuideAssetPaths.avatar(guideId);

    try {
      // Verificar si el asset existe
      await rootBundle.load(path);

      // Si existe, precargarlo en la cache de imágenes
      if (context.mounted) {
        await precacheImage(AssetImage(path), context);
        _preloadedAvatars.add(guideId);
      }
    } catch (e) {
      // Avatar no existe, ignorar silenciosamente
      // El sistema de fallback se encargará de mostrarlo
    }
  }

  /// Precarga un avatar específico por demanda.
  ///
  /// **Uso:**
  /// ```dart
  /// await AvatarPreloadService.instance.preloadAvatar(context, 'aethel');
  /// ```
  ///
  /// **Cuándo usar:**
  /// - Cuando el usuario selecciona un guía específico
  /// - Antes de mostrar una pantalla que usa ese avatar
  Future<void> preloadAvatar(BuildContext context, String guideId) async {
    await _preloadSingleAvatar(context, guideId);
  }

  /// Limpia la cache de avatares precargados.
  ///
  /// **Uso:**
  /// ```dart
  /// AvatarPreloadService.instance.clearCache();
  /// ```
  ///
  /// **Cuándo usar:**
  /// - Al cerrar sesión
  /// - Al cambiar de usuario
  /// - Para liberar memoria (raro)
  void clearCache() {
    _preloadedAvatars.clear();
    _isPreloaded = false;
  }

  /// Verifica si un avatar está precargado.
  bool isAvatarPreloaded(String guideId) {
    return _preloadedAvatars.contains(guideId);
  }

  /// Obtiene estadísticas de precarga.
  ({int total, int preloaded, int missing}) getStats() {
    final total = kGuideCatalog.length;
    final preloaded = _preloadedAvatars.length;
    final missing = total - preloaded;

    return (total: total, preloaded: preloaded, missing: missing);
  }
}
