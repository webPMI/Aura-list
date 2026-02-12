import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Platform detection utility for adaptive UI design
///
/// Provides comprehensive platform detection including:
/// - Web detection (kIsWeb)
/// - Operating system detection (Android, iOS, Windows, macOS, Linux)
/// - Form factor detection (mobile, tablet, desktop)
/// - Platform-specific capabilities
///
/// Example usage:
/// ```dart
/// if (PlatformDetector.isWeb) {
///   // Web-specific code
/// } else if (PlatformDetector.isAndroid) {
///   // Android-specific code
/// }
///
/// if (PlatformDetector.isMobile) {
///   // Mobile layout
/// } else if (PlatformDetector.isDesktop) {
///   // Desktop layout
/// }
/// ```
class PlatformDetector {
  // Private constructor to prevent instantiation
  PlatformDetector._();

  /// Whether the app is running on the web
  static bool get isWeb => kIsWeb;

  /// Whether the app is running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Whether the app is running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Whether the app is running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  /// Whether the app is running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Whether the app is running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Whether the app is running on any mobile platform (Android or iOS)
  static bool get isMobile => isAndroid || isIOS;

  /// Whether the app is running on any desktop platform (Windows, macOS, Linux)
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Whether the app is running on any Apple platform (iOS or macOS)
  static bool get isApple => isIOS || isMacOS;

  /// Get the current platform as a string for logging/debugging
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Get the target platform
  static TargetPlatform? get targetPlatform {
    if (kIsWeb) return null;
    return defaultTargetPlatform;
  }
}

/// Form factor detection based on screen dimensions
///
/// Detects whether device is a phone, tablet, or desktop
/// based on physical screen size and platform
class FormFactorDetector {
  // Private constructor
  FormFactorDetector._();

  /// Phone breakpoint (typically < 600dp)
  static const double phoneBreakpoint = 600.0;

  /// Tablet breakpoint (typically 600-900dp)
  static const double tabletBreakpoint = 900.0;

  /// Desktop breakpoint (typically > 900dp)
  static const double desktopBreakpoint = 900.0;

  /// Get form factor from screen width and platform
  static FormFactor getFormFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    // Web and Desktop platforms: base on width only
    if (PlatformDetector.isWeb || PlatformDetector.isDesktop) {
      if (width < phoneBreakpoint) {
        return FormFactor.phone;
      } else if (width < tabletBreakpoint) {
        return FormFactor.tablet;
      } else {
        return FormFactor.desktop;
      }
    }

    // Mobile platforms: use shortestSide for better orientation handling
    if (shortestSide < phoneBreakpoint) {
      return FormFactor.phone;
    } else {
      return FormFactor.tablet;
    }
  }

  /// Check if device is a phone
  static bool isPhone(BuildContext context) {
    return getFormFactor(context) == FormFactor.phone;
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    return getFormFactor(context) == FormFactor.tablet;
  }

  /// Check if device is desktop (or web in desktop mode)
  static bool isDesktop(BuildContext context) {
    return getFormFactor(context) == FormFactor.desktop;
  }

  /// Check if device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) {
    final factor = getFormFactor(context);
    return factor == FormFactor.tablet || factor == FormFactor.desktop;
  }

  /// Check if device is phone or tablet (not desktop)
  static bool isMobileFormFactor(BuildContext context) {
    final factor = getFormFactor(context);
    return factor == FormFactor.phone || factor == FormFactor.tablet;
  }
}

/// Form factor enum
enum FormFactor {
  /// Phone: typically < 600dp shortest side
  phone,

  /// Tablet: typically 600-900dp width or > 600dp shortest side
  tablet,

  /// Desktop: typically > 900dp width
  desktop,
}

/// Platform-specific capabilities
class PlatformCapabilities {
  PlatformCapabilities._();

  /// Whether platform supports touch input primarily
  static bool get supportsTouchPrimarily {
    return PlatformDetector.isMobile || PlatformDetector.isWeb;
  }

  /// Whether platform supports mouse/trackpad primarily
  static bool get supportsMousePrimarily {
    return PlatformDetector.isDesktop;
  }

  /// Whether platform supports keyboard shortcuts
  static bool get supportsKeyboardShortcuts {
    return PlatformDetector.isDesktop || PlatformDetector.isWeb;
  }

  /// Whether platform supports file system access
  static bool get supportsFileSystem {
    return !PlatformDetector.isWeb;
  }

  /// Whether platform supports native notifications
  static bool get supportsNativeNotifications {
    return !PlatformDetector.isWeb;
  }

  /// Whether platform supports haptic feedback
  static bool get supportsHaptics {
    return PlatformDetector.isMobile;
  }

  /// Whether platform should use Cupertino (iOS-style) widgets
  static bool get prefersCupertino {
    return PlatformDetector.isIOS || PlatformDetector.isMacOS;
  }

  /// Whether platform should use Material Design widgets
  static bool get prefersMaterial {
    return PlatformDetector.isAndroid ||
           PlatformDetector.isWindows ||
           PlatformDetector.isLinux ||
           PlatformDetector.isWeb;
  }

  /// Whether platform has a physical back button
  static bool get hasPhysicalBackButton {
    return PlatformDetector.isAndroid;
  }

  /// Whether platform typically uses bottom navigation
  static bool get prefersBottomNavigation {
    return PlatformDetector.isMobile;
  }

  /// Whether platform typically uses side navigation
  static bool get prefersSideNavigation {
    return PlatformDetector.isDesktop;
  }
}

/// Extension on BuildContext for easy platform detection
extension PlatformExtension on BuildContext {
  /// Whether the app is running on the web
  bool get isWeb => PlatformDetector.isWeb;

  /// Whether the app is running on Android
  bool get isAndroid => PlatformDetector.isAndroid;

  /// Whether the app is running on iOS
  bool get isIOS => PlatformDetector.isIOS;

  /// Whether the app is running on Windows
  bool get isWindows => PlatformDetector.isWindows;

  /// Whether the app is running on macOS
  bool get isMacOS => PlatformDetector.isMacOS;

  /// Whether the app is running on Linux
  bool get isLinux => PlatformDetector.isLinux;

  /// Whether the app is running on any mobile platform
  bool get isMobilePlatform => PlatformDetector.isMobile;

  /// Whether the app is running on any desktop platform
  bool get isDesktopPlatform => PlatformDetector.isDesktop;

  /// Whether the app is running on any Apple platform
  bool get isApplePlatform => PlatformDetector.isApple;

  /// Get the current form factor
  FormFactor get formFactor => FormFactorDetector.getFormFactor(this);

  /// Whether device is a phone form factor
  bool get isPhoneFormFactor => FormFactorDetector.isPhone(this);

  /// Whether device is a tablet form factor
  bool get isTabletFormFactor => FormFactorDetector.isTablet(this);

  /// Whether device is desktop form factor
  bool get isDesktopFormFactor => FormFactorDetector.isDesktop(this);

  /// Whether device is tablet or larger
  bool get isTabletOrLarger => FormFactorDetector.isTabletOrLarger(this);

  /// Get platform name
  String get platformName => PlatformDetector.platformName;
}
