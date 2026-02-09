import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// A widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  /// Builder function that receives context and screen size
  final Widget Function(BuildContext context, ScreenSize screenSize)? builder;

  /// Optional specific widgets for each screen size
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  /// Constructor for builder-based responsive widget
  const ResponsiveBuilder({
    super.key,
    required Widget Function(BuildContext, ScreenSize) this.builder,
  })  : mobile = null,
        tablet = null,
        desktop = null;

  /// Constructor for predefined widgets per screen size
  const ResponsiveBuilder.custom({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = null;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    // If using builder function
    if (builder != null) {
      return builder!(context, screenSize);
    }

    // If using custom widgets, fall back gracefully
    return switch (screenSize) {
      ScreenSize.mobile => mobile ?? tablet ?? desktop ?? const SizedBox.shrink(),
      ScreenSize.tablet => tablet ?? desktop ?? mobile ?? const SizedBox.shrink(),
      ScreenSize.desktop ||
      ScreenSize.widescreen =>
        desktop ?? tablet ?? mobile ?? const SizedBox.shrink(),
    };
  }
}

/// Simplified responsive widget for common use cases
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder.custom(
      mobile: mobile,
      tablet: tablet ?? mobile,
      desktop: desktop ?? tablet ?? mobile,
    );
  }
}

/// A widget that shows/hides based on screen size
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.replacement,
  });

  /// Only show on mobile
  const ResponsiveVisibility.mobileOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = true,
        visibleOnTablet = false,
        visibleOnDesktop = false;

  /// Only show on tablet and larger
  const ResponsiveVisibility.tabletUp({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = true,
        visibleOnDesktop = true;

  /// Only show on desktop
  const ResponsiveVisibility.desktopOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : visibleOnMobile = false,
        visibleOnTablet = false,
        visibleOnDesktop = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;
    final isVisible = switch (screenSize) {
      ScreenSize.mobile => visibleOnMobile,
      ScreenSize.tablet => visibleOnTablet,
      ScreenSize.desktop || ScreenSize.widescreen => visibleOnDesktop,
    };

    if (isVisible) {
      return child;
    }
    return replacement ?? const SizedBox.shrink();
  }
}

/// A responsive container that constrains max width based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool center;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Breakpoints.maxContentWidth;

    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (center) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Responsive value selector - returns different values based on screen size
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  return switch (context.screenSize) {
    ScreenSize.mobile => mobile,
    ScreenSize.tablet => tablet ?? mobile,
    ScreenSize.desktop || ScreenSize.widescreen => desktop ?? tablet ?? mobile,
  };
}
