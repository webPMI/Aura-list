import 'package:flutter/material.dart';

/// Parses a hex color string to a Color.
///
/// Accepts formats '#RRGGBB' or 'RRGGBB'.
/// Returns null if the input is null, empty, or invalid.
///
/// Example:
/// ```dart
/// final color = parseHexColor('#FF5733'); // Returns Color(0xFFFF5733)
/// final invalid = parseHexColor('invalid'); // Returns null
/// ```
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  String h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length != 6) return null;
  final r = int.tryParse(h.substring(0, 2), radix: 16);
  final g = int.tryParse(h.substring(2, 4), radix: 16);
  final b = int.tryParse(h.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return null;
  return Color.fromARGB(255, r, g, b);
}

class ColorUtils {
  /// Parse hex color string to Color
  @Deprecated('Use parseHexColor instead for nullable support')
  static Color parseHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }

  /// Get appropriate text color for background
  static Color getTextColorFor(Color backgroundColor) {
    final isDark = ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  /// Check if color is dark
  static bool isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }
}
