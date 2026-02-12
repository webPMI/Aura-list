import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/providers/theme_provider.dart';

/// Provider que indica si el tema del guia esta habilitado.
/// Cuando es true, se usara el tema personalizado del guia activo.
/// Cuando es false, se usara el tema por defecto de la app.
final guideThemeEnabledProvider = StateProvider<bool>((ref) => true);

/// Color primario del guia activo (para aplicar como override en pantallas que lo deseen).
final guidePrimaryColorProvider = Provider<Color?>((ref) {
  final guide = ref.watch(activeGuideProvider);
  return parseHexColor(guide?.themePrimaryHex);
});

/// Color secundario del guia activo.
final guideSecondaryColorProvider = Provider<Color?>((ref) {
  final guide = ref.watch(activeGuideProvider);
  return parseHexColor(guide?.themeSecondaryHex);
});

/// Color de acento del guia activo.
final guideAccentColorProvider = Provider<Color?>((ref) {
  final guide = ref.watch(activeGuideProvider);
  return parseHexColor(guide?.themeAccentHex);
});

/// Provider que genera ThemeData basado en el guia activo.
/// Retorna null si no hay guia activo o si el tema del guia esta deshabilitado.
/// En ese caso, se debe usar el tema por defecto de la app.
final guideThemeDataProvider = Provider<ThemeData?>((ref) {
  // Verificar si el tema del guia esta habilitado
  final isEnabled = ref.watch(guideThemeEnabledProvider);
  if (!isEnabled) return null;

  // Obtener el guia activo y su color primario
  final guide = ref.watch(activeGuideProvider);
  if (guide?.themePrimaryHex == null || guide!.themePrimaryHex!.isEmpty) {
    return null;
  }

  // Obtener el modo de tema del usuario (light/dark/system)
  final baseThemeMode = ref.watch(themeProvider);

  // Parsear el color primario del guia
  final seedColor = parseHexColor(guide.themePrimaryHex!) ?? Colors.grey;

  // Determinar brightness basado en el themeMode
  // Para ThemeMode.system, usamos light como default ya que no tenemos
  // acceso al BuildContext aqui. El main.dart manejara la seleccion final.
  final brightness = baseThemeMode == ThemeMode.dark
      ? Brightness.dark
      : Brightness.light;

  // Crear el ColorScheme con el color del guia como seed
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  // Crear el TextTheme con Google Fonts Outfit
  final textTheme = brightness == Brightness.dark
      ? GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
      : GoogleFonts.outfitTextTheme();

  // Construir y retornar el ThemeData
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
  );
});

/// Provider que genera ThemeData para modo claro basado en el guia activo.
/// Util cuando se necesita el tema light especificamente.
final guideLightThemeDataProvider = Provider<ThemeData?>((ref) {
  final isEnabled = ref.watch(guideThemeEnabledProvider);
  if (!isEnabled) return null;

  final guide = ref.watch(activeGuideProvider);
  if (guide?.themePrimaryHex == null || guide!.themePrimaryHex!.isEmpty) {
    return null;
  }

  final seedColor = parseHexColor(guide.themePrimaryHex!) ?? Colors.grey;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.outfitTextTheme(),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
  );
});

/// Provider que genera ThemeData para modo oscuro basado en el guia activo.
/// Util cuando se necesita el tema dark especificamente.
final guideDarkThemeDataProvider = Provider<ThemeData?>((ref) {
  final isEnabled = ref.watch(guideThemeEnabledProvider);
  if (!isEnabled) return null;

  final guide = ref.watch(activeGuideProvider);
  if (guide?.themePrimaryHex == null || guide!.themePrimaryHex!.isEmpty) {
    return null;
  }

  final seedColor = parseHexColor(guide.themePrimaryHex!) ?? Colors.grey;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
  );
});
