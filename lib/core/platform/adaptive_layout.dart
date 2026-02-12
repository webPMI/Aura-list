import 'package:flutter/material.dart';
import 'platform_detector.dart';
import '../responsive/breakpoints.dart';

/// Adaptive layout that adjusts based on platform and screen size
///
/// Combines platform detection with responsive breakpoints to create
/// truly adaptive layouts that respect both platform conventions and screen size.
///
/// Example:
/// ```dart
/// AdaptiveLayout(
///   phone: PhoneLayout(),
///   tablet: TabletLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  final Widget? phone;
  final Widget? tablet;
  final Widget? desktop;
  final WidgetBuilder? builder;

  const AdaptiveLayout({
    super.key,
    this.phone,
    this.tablet,
    this.desktop,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (builder != null) {
      return builder!(context);
    }

    final formFactor = FormFactorDetector.getFormFactor(context);

    return switch (formFactor) {
      FormFactor.phone => phone ?? tablet ?? desktop ?? const SizedBox.shrink(),
      FormFactor.tablet => tablet ?? desktop ?? phone ?? const SizedBox.shrink(),
      FormFactor.desktop => desktop ?? tablet ?? phone ?? const SizedBox.shrink(),
    };
  }
}

/// Adaptive padding that adjusts based on platform and form factor
class AdaptivePadding {
  AdaptivePadding._();

  /// Get adaptive padding for a given context
  static EdgeInsets of(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    // Desktop gets more padding, mobile gets less
    return switch (formFactor) {
      FormFactor.phone => const EdgeInsets.all(16),
      FormFactor.tablet => const EdgeInsets.all(24),
      FormFactor.desktop => const EdgeInsets.all(32),
    };
  }

  /// Get horizontal padding only
  static EdgeInsets horizontal(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    return switch (formFactor) {
      FormFactor.phone => const EdgeInsets.symmetric(horizontal: 16),
      FormFactor.tablet => const EdgeInsets.symmetric(horizontal: 24),
      FormFactor.desktop => const EdgeInsets.symmetric(horizontal: 32),
    };
  }

  /// Get vertical padding only
  static EdgeInsets vertical(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    return switch (formFactor) {
      FormFactor.phone => const EdgeInsets.symmetric(vertical: 16),
      FormFactor.tablet => const EdgeInsets.symmetric(vertical: 24),
      FormFactor.desktop => const EdgeInsets.symmetric(vertical: 32),
    };
  }

  /// Get item spacing (gap between elements)
  static double spacing(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    return switch (formFactor) {
      FormFactor.phone => 12,
      FormFactor.tablet => 16,
      FormFactor.desktop => 20,
    };
  }

  /// Get compact padding (smaller than default)
  static EdgeInsets compact(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    return switch (formFactor) {
      FormFactor.phone => const EdgeInsets.all(8),
      FormFactor.tablet => const EdgeInsets.all(12),
      FormFactor.desktop => const EdgeInsets.all(16),
    };
  }
}

/// Adaptive spacing that provides consistent gaps based on platform
class AdaptiveSpacing extends StatelessWidget {
  final Axis direction;

  const AdaptiveSpacing({
    super.key,
    this.direction = Axis.vertical,
  });

  const AdaptiveSpacing.vertical({super.key}) : direction = Axis.vertical;
  const AdaptiveSpacing.horizontal({super.key}) : direction = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final spacing = AdaptivePadding.spacing(context);

    if (direction == Axis.horizontal) {
      return SizedBox(width: spacing);
    }
    return SizedBox(height: spacing);
  }
}

/// Adaptive content width that constrains content appropriately
class AdaptiveContentWidth extends StatelessWidget {
  final Widget child;
  final bool center;

  const AdaptiveContentWidth({
    super.key,
    required this.child,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final formFactor = FormFactorDetector.getFormFactor(context);

    // Desktop: constrain to readable width
    if (formFactor == FormFactor.desktop) {
      Widget content = ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: Breakpoints.maxContentWidth,
        ),
        child: child,
      );

      if (center) {
        content = Center(child: content);
      }

      return content;
    }

    // Mobile/tablet: use full width
    return child;
  }
}

/// Adaptive card that adjusts elevation and margins based on platform
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = AdaptivePadding.of(context);
    final defaultMargin = AdaptivePadding.compact(context);

    // iOS/macOS: use lower elevation
    final elevation = PlatformCapabilities.prefersCupertino ? 1.0 : 2.0;

    Widget card = Card(
      elevation: elevation,
      margin: margin ?? defaultMargin,
      child: Padding(
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

/// Adaptive icon size that scales with form factor
class AdaptiveIconSize {
  AdaptiveIconSize._();

  /// Small icon size
  static double small(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 16 : 18;
  }

  /// Regular icon size
  static double regular(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 24 : 28;
  }

  /// Large icon size
  static double large(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 32 : 40;
  }

  /// Extra large icon size
  static double extraLarge(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 48 : 64;
  }
}

/// Adaptive font size that scales with form factor
class AdaptiveFontSize {
  AdaptiveFontSize._();

  /// Body text size
  static double body(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 14 : 16;
  }

  /// Caption text size
  static double caption(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 12 : 14;
  }

  /// Headline text size
  static double headline(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 24 : 32;
  }

  /// Title text size
  static double title(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 18 : 22;
  }

  /// Subtitle text size
  static double subtitle(BuildContext context) {
    return FormFactorDetector.isPhone(context) ? 14 : 16;
  }
}

/// Adaptive grid columns based on screen size and platform
class AdaptiveGridColumns {
  AdaptiveGridColumns._();

  /// Get recommended number of columns for a grid
  static int of(BuildContext context, {int? min, int? max}) {
    final screenSize = context.screenSize;
    final formFactor = FormFactorDetector.getFormFactor(context);

    int columns = switch (screenSize) {
      ScreenSize.mobile => 1,
      ScreenSize.tablet => 2,
      ScreenSize.desktop => 3,
      ScreenSize.widescreen => 4,
    };

    // Adjust for platform conventions
    if (PlatformDetector.isDesktop && formFactor == FormFactor.desktop) {
      columns = (columns * 1.5).round(); // Desktop can show more columns
    }

    // Apply constraints
    if (min != null && columns < min) columns = min;
    if (max != null && columns > max) columns = max;

    return columns;
  }
}

/// Adaptive tap target size based on platform
class AdaptiveTapTarget {
  AdaptiveTapTarget._();

  /// Minimum tap target size for the platform
  static double get minSize {
    // Material Design: 48dp, iOS Human Interface Guidelines: 44pt
    return PlatformCapabilities.prefersCupertino ? 44 : 48;
  }

  /// Comfortable tap target size for the platform
  static double get comfortableSize {
    return PlatformCapabilities.prefersCupertino ? 48 : 56;
  }

  /// Large tap target size for the platform
  static double get largeSize {
    return PlatformCapabilities.prefersCupertino ? 56 : 64;
  }
}

/// Adaptive border radius based on platform conventions
class AdaptiveBorderRadius {
  AdaptiveBorderRadius._();

  /// Small border radius
  static BorderRadius get small {
    return BorderRadius.circular(
      PlatformCapabilities.prefersCupertino ? 8 : 4,
    );
  }

  /// Medium border radius (default)
  static BorderRadius get medium {
    return BorderRadius.circular(
      PlatformCapabilities.prefersCupertino ? 12 : 8,
    );
  }

  /// Large border radius
  static BorderRadius get large {
    return BorderRadius.circular(
      PlatformCapabilities.prefersCupertino ? 16 : 12,
    );
  }

  /// Extra large border radius
  static BorderRadius get extraLarge {
    return BorderRadius.circular(
      PlatformCapabilities.prefersCupertino ? 24 : 16,
    );
  }
}

/// Extension on BuildContext for easy adaptive layout access
extension AdaptiveLayoutExtension on BuildContext {
  /// Get adaptive padding
  EdgeInsets get adaptivePadding => AdaptivePadding.of(this);

  /// Get adaptive horizontal padding
  EdgeInsets get adaptiveHorizontalPadding => AdaptivePadding.horizontal(this);

  /// Get adaptive vertical padding
  EdgeInsets get adaptiveVerticalPadding => AdaptivePadding.vertical(this);

  /// Get adaptive spacing
  double get adaptiveSpacing => AdaptivePadding.spacing(this);

  /// Get adaptive compact padding
  EdgeInsets get adaptiveCompactPadding => AdaptivePadding.compact(this);
}
