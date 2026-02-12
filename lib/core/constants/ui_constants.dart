import 'package:flutter/material.dart';

/// Constantes de UI para mantener consistencia visual en toda la app.
class UIConstants {
  UIConstants._();

  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  // Border width
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
  static const double borderWidthThicker = 3.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;

  // Avatar sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 48.0;
  static const double avatarSizeXLarge = 64.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Shadows
  static List<BoxShadow> shadowSmall(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// Sombra con color del guia para elementos destacados
  static List<BoxShadow> shadowForGuideColor(Color guideColor) => [
    BoxShadow(
      color: guideColor.withValues(alpha: 0.3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}
