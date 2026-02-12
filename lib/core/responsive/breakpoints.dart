import 'package:flutter/material.dart';

/// Breakpoint values for responsive layouts
///
/// These breakpoints follow Material Design guidelines:
/// - Mobile: < 600dp (phones)
/// - Tablet: 600-900dp (tablets, large phones)
/// - Desktop: 900-1200dp (small laptops, tablets in landscape)
/// - Widescreen: > 1200dp (desktop monitors)
class Breakpoints {
  // Private constructor to prevent instantiation
  Breakpoints._();

  // Screen width breakpoints
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1600;

  // Content max widths for readability
  static const double maxContentWidth = 1400;
  static const double maxFormWidth = 600;
  static const double maxCardWidth = 400;
  static const double maxDialogWidth = 560;
  static const double maxDrawerWidth = 360;

  // Grid columns per breakpoint
  static const int mobileColumns = 1;
  static const int tabletColumns = 2;
  static const int desktopColumns = 3;
  static const int widescreenColumns = 4;

  // Navigation rail widths
  static const double navigationRailWidth = 72;
  static const double navigationRailExtendedWidth = 256;
  static const double permanentDrawerWidth = 280;

  // Minimum touch target sizes
  static const double minTouchTarget = 48;
  static const double minIOSTouchTarget = 44;
}

/// Enum for screen size categories
enum ScreenSize { mobile, tablet, desktop, widescreen }

/// Extension to easily get screen size from BuildContext
extension ResponsiveExtension on BuildContext {
  /// Get current screen size category
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    if (width < Breakpoints.mobile) return ScreenSize.mobile;
    if (width < Breakpoints.tablet) return ScreenSize.tablet;
    if (width < Breakpoints.desktop) return ScreenSize.desktop;
    return ScreenSize.widescreen;
  }

  /// Convenience getters for common checks
  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop =>
      screenSize == ScreenSize.desktop || screenSize == ScreenSize.widescreen;
  bool get isWidescreen => screenSize == ScreenSize.widescreen;

  /// Check if screen is at least tablet size
  bool get isTabletOrLarger =>
      screenSize == ScreenSize.tablet ||
      screenSize == ScreenSize.desktop ||
      screenSize == ScreenSize.widescreen;

  /// Get screen dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get recommended grid columns for current screen
  int get gridColumns {
    return switch (screenSize) {
      ScreenSize.mobile => Breakpoints.mobileColumns,
      ScreenSize.tablet => Breakpoints.tabletColumns,
      ScreenSize.desktop => Breakpoints.desktopColumns,
      ScreenSize.widescreen => Breakpoints.widescreenColumns,
    };
  }

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    return switch (screenSize) {
      ScreenSize.mobile => const EdgeInsets.all(16),
      ScreenSize.tablet => const EdgeInsets.all(24),
      ScreenSize.desktop => const EdgeInsets.all(32),
      ScreenSize.widescreen => const EdgeInsets.all(40),
    };
  }

  /// Get responsive horizontal padding
  double get horizontalPadding {
    return switch (screenSize) {
      ScreenSize.mobile => 16,
      ScreenSize.tablet => 24,
      ScreenSize.desktop => 32,
      ScreenSize.widescreen => 48,
    };
  }

  /// Get responsive spacing between items
  double get itemSpacing {
    return switch (screenSize) {
      ScreenSize.mobile => 12,
      ScreenSize.tablet => 16,
      ScreenSize.desktop => 20,
      ScreenSize.widescreen => 24,
    };
  }
}
