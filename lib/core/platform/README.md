# Platform Detection and Adaptive Styling System

This directory contains utilities for building truly adaptive Flutter apps that work seamlessly across Web, Android, iOS, Windows, macOS, and Linux platforms.

## Overview

The system consists of three main components:

1. **Platform Detection** (`platform_detector.dart`) - Detect the platform and form factor
2. **Adaptive Widgets** (`adaptive_widgets.dart`) - Platform-specific widget implementations
3. **Adaptive Layout** (`adaptive_layout.dart`) - Layout utilities that adapt to platform and screen size

## Quick Start

### 1. Platform Detection

```dart
import 'package:checklist_app/core/platform/platform_detector.dart';

// Check platform
if (PlatformDetector.isWeb) {
  // Web-specific code
}

if (PlatformDetector.isAndroid) {
  // Android-specific code
}

if (PlatformDetector.isMobile) {
  // Code for both Android and iOS
}

// Using BuildContext extension
if (context.isIOS) {
  // iOS-specific code
}
```

### 2. Form Factor Detection

```dart
import 'package:checklist_app/core/platform/platform_detector.dart';

// Check form factor (phone, tablet, desktop)
if (context.isPhoneFormFactor) {
  // Phone layout
}

if (context.isDesktopFormFactor) {
  // Desktop layout
}

// Get form factor
final formFactor = context.formFactor;
switch (formFactor) {
  case FormFactor.phone:
    // ...
  case FormFactor.tablet:
    // ...
  case FormFactor.desktop:
    // ...
}
```

### 3. Platform Capabilities

```dart
import 'package:checklist_app/core/platform/platform_detector.dart';

// Check capabilities
if (PlatformCapabilities.supportsTouchPrimarily) {
  // Show touch-optimized UI
}

if (PlatformCapabilities.supportsKeyboardShortcuts) {
  // Register keyboard shortcuts
}

if (PlatformCapabilities.prefersCupertino) {
  // Use Cupertino widgets
}
```

### 4. Adaptive Widgets

```dart
import 'package:checklist_app/core/platform/adaptive_widgets.dart';

// Adaptive button (Material on Android/Windows, Cupertino on iOS/macOS)
AdaptiveButton(
  onPressed: () {},
  child: Text('Save'),
)

// Adaptive dialog
showAdaptiveDialog(
  context: context,
  builder: (context) => AdaptiveAlertDialog(
    title: 'Confirm',
    content: 'Are you sure?',
    actions: [
      AdaptiveDialogAction(
        text: 'Cancel',
        isDefaultAction: true,
      ),
      AdaptiveDialogAction(
        text: 'Delete',
        isDestructive: true,
        onPressed: () => deleteItem(),
      ),
    ],
  ),
)

// Adaptive text field
AdaptiveTextField(
  placeholder: 'Enter text',
  onChanged: (value) => print(value),
)
```

### 5. Adaptive Layout

```dart
import 'package:checklist_app/core/platform/adaptive_layout.dart';

// Different layouts for different form factors
AdaptiveLayout(
  phone: PhoneLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)

// Adaptive padding
Container(
  padding: context.adaptivePadding, // Larger on desktop, smaller on mobile
  child: Text('Content'),
)

// Adaptive content width (constrains on desktop)
AdaptiveContentWidth(
  child: ListView(...),
)

// Adaptive card
AdaptiveCard(
  onTap: () {},
  child: Text('Card content'),
)

// Adaptive spacing
Column(
  children: [
    Widget1(),
    AdaptiveSpacing.vertical(), // Adjusts based on form factor
    Widget2(),
  ],
)
```

### 6. Adaptive Sizes

```dart
import 'package:checklist_app/core/platform/adaptive_layout.dart';

// Font sizes
Text(
  'Headline',
  style: TextStyle(fontSize: AdaptiveFontSize.headline(context)),
)

// Icon sizes
Icon(
  Icons.star,
  size: AdaptiveIconSize.regular(context),
)

// Border radius (more rounded on iOS/macOS)
Container(
  decoration: BoxDecoration(
    borderRadius: AdaptiveBorderRadius.medium,
  ),
)

// Grid columns
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: AdaptiveGridColumns.of(context),
  ),
)
```

## Common Patterns

### Pattern 1: Platform-Specific Behavior

```dart
void handleAction() {
  if (PlatformDetector.isWeb) {
    // Web: Open in new tab
    html.window.open(url, '_blank');
  } else if (PlatformDetector.isMobile) {
    // Mobile: Use in-app browser
    launchUrl(url);
  } else {
    // Desktop: Open in system browser
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
```

### Pattern 2: Responsive + Platform Adaptive

```dart
Widget buildButton(BuildContext context) {
  // Combine responsive size with platform-specific styling
  if (context.isDesktopFormFactor) {
    return AdaptiveButton(
      onPressed: () {},
      child: Text('Click Me'),
    );
  } else {
    return AdaptiveButton(
      onPressed: () {},
      child: Icon(Icons.add), // Icon only on mobile
    );
  }
}
```

### Pattern 3: Navigation Adaptation

```dart
Widget buildNavigation(BuildContext context) {
  // Desktop: Permanent drawer
  if (context.isDesktopFormFactor) {
    return Row(
      children: [
        SizedBox(
          width: Breakpoints.permanentDrawerWidth,
          child: NavigationDrawer(...),
        ),
        Expanded(child: content),
      ],
    );
  }

  // Tablet: Navigation rail
  if (context.isTabletFormFactor) {
    return Row(
      children: [
        NavigationRail(...),
        Expanded(child: content),
      ],
    );
  }

  // Phone: Bottom navigation
  return Scaffold(
    body: content,
    bottomNavigationBar: NavigationBar(...),
  );
}
```

### Pattern 4: Dialog vs Bottom Sheet

```dart
Future<void> showOptions(BuildContext context) {
  // Mobile: Bottom sheet
  if (context.isPhoneFormFactor) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => OptionsSheet(),
    );
  }

  // Desktop/Tablet: Dialog
  return showDialog(
    context: context,
    builder: (context) => OptionsDialog(),
  );
}

// Or use the built-in adaptive version:
showAdaptiveModalBottomSheet(
  context: context,
  builder: (context) => Options(), // Auto-converts to dialog on desktop
)
```

## Best Practices

1. **Always consider both platform and form factor** - A tablet running Android should behave differently than a phone, even on the same platform.

2. **Use extensions for cleaner code** - `context.isDesktopFormFactor` is more readable than `FormFactorDetector.isDesktop(context)`.

3. **Respect platform conventions** - Use Cupertino widgets on iOS/macOS, Material on Android/Windows, adapt spacing and sizing appropriately.

4. **Test on all platforms** - Different platforms have different quirks and behaviors.

5. **Combine with responsive design** - Use both platform detection and responsive breakpoints for the best UX.

6. **Optimize for input method** - Desktop (mouse/keyboard) needs different interactions than mobile (touch).

## Platform-Specific Notes

### Android
- Use Material Design 3 components
- Respect system back button (handled automatically)
- Support dark theme
- Use 48dp minimum touch targets

### iOS
- Use Cupertino widgets where appropriate
- Implement swipe-back gesture (handled automatically by Navigator)
- Use 44pt minimum touch targets
- Respect iOS design patterns (bottom sheets, action sheets)

### Web
- Support keyboard shortcuts
- Make clickable areas obvious (cursor changes)
- Use responsive layouts that work from mobile to desktop widths
- Consider SEO and accessibility

### Windows
- Use larger tap targets (48-56dp)
- Support keyboard navigation
- Consider mouse hover states
- Use title bar and window controls appropriately

### Desktop (Windows/macOS/Linux)
- Provide keyboard shortcuts
- Use hover states
- Larger touch targets (but mouse-optimized)
- Consider multi-window support

## Integration with Existing Code

This system works seamlessly with the existing responsive system:

```dart
// Combine screen size (responsive) with platform (adaptive)
Widget build(BuildContext context) {
  // Get both screen size and form factor
  final screenSize = context.screenSize;
  final formFactor = context.formFactor;

  // Desktop platform with desktop screen size
  if (context.isDesktopPlatform && context.isDesktopFormFactor) {
    return DesktopLayout();
  }

  // Mobile platform or mobile form factor
  if (context.isMobilePlatform || context.isPhoneFormFactor) {
    return MobileLayout();
  }

  // Default
  return TabletLayout();
}
```

## Examples in the App

See these files for real-world usage:

- `lib/widgets/navigation/adaptive_navigation.dart` - Platform-adaptive navigation
- `lib/widgets/layouts/master_detail_layout.dart` - Responsive master-detail
- `lib/widgets/dialogs/add_task_dialog.dart` - Adaptive dialog/bottom sheet
- `lib/core/responsive/responsive_builder.dart` - Responsive components

## Testing

Test your adaptive UI on:

1. **Phones** (Android, iOS) - < 600dp width
2. **Tablets** (Android, iOS) - 600-900dp width
3. **Desktop** (Windows, macOS, Linux) - > 900dp width
4. **Web** - All widths from 320px to 1920px+

Use Flutter DevTools to test different screen sizes and platforms without needing physical devices.
