import 'package:flutter/material.dart' hide showAdaptiveDialog;
import 'adaptive_widgets.dart';
import 'adaptive_layout.dart';
import 'platform_detector.dart';
import '../responsive/breakpoints.dart';

/// Example widget demonstrating platform detection and adaptive styling
///
/// This widget shows how to combine:
/// - Platform detection (Web, Android, iOS, Windows, etc.)
/// - Form factor detection (phone, tablet, desktop)
/// - Responsive breakpoints
/// - Adaptive widgets and layouts
///
/// Use this as a reference for implementing adaptive UI in your app.
class AdaptiveExample extends StatelessWidget {
  const AdaptiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive UI Example'),
        actions: [
          // Adaptive icon button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPlatformInfo(context),
            tooltip: 'Platform Info',
          ),
        ],
      ),
      body: AdaptiveLayout(
        phone: const _PhoneLayout(),
        tablet: const _TabletLayout(),
        desktop: const _DesktopLayout(),
      ),
    );
  }

  void _showPlatformInfo(BuildContext context) {
    final platform = context.platformName;
    final formFactor = context.formFactor.name;
    final screenSize = context.screenSize.name;
    final width = context.screenWidth.toStringAsFixed(0);
    final height = context.screenHeight.toStringAsFixed(0);

    showAdaptiveDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: 'Platform Information',
        content: '''
Platform: $platform
Form Factor: $formFactor
Screen Size: $screenSize
Resolution: ${width}x$height
Touch Primary: ${PlatformCapabilities.supportsTouchPrimarily}
Keyboard Shortcuts: ${PlatformCapabilities.supportsKeyboardShortcuts}
Prefers Cupertino: ${PlatformCapabilities.prefersCupertino}
        ''',
        actions: const [
          AdaptiveDialogAction(
            text: 'OK',
            isDefaultAction: true,
          ),
        ],
      ),
    );
  }
}

/// Phone layout - optimized for small screens and touch
class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.adaptivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Phone Layout',
            style: TextStyle(
              fontSize: AdaptiveFontSize.headline(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          AdaptiveSpacing.vertical(),

          // Platform badge
          _PlatformBadge(),
          AdaptiveSpacing.vertical(),

          // Content cards (single column)
          ..._buildContentCards(context, columns: 1),

          AdaptiveSpacing.vertical(),

          // Actions
          _ActionButtons(),
        ],
      ),
    );
  }
}

/// Tablet layout - more spacious, 2-column grid
class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Optional side navigation on tablet
        if (FormFactorDetector.isTabletOrLarger(context))
          Container(
            width: Breakpoints.navigationRailWidth,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const _SideNav(),
          ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: context.adaptivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tablet Layout',
                  style: TextStyle(
                    fontSize: AdaptiveFontSize.headline(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AdaptiveSpacing.vertical(),

                _PlatformBadge(),
                AdaptiveSpacing.vertical(),

                // Content in 2-column grid
                _buildGrid(context, columns: 2),

                AdaptiveSpacing.vertical(),

                _ActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Desktop layout - maximum screen real estate utilization
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Permanent sidebar on desktop
        Container(
          width: Breakpoints.permanentDrawerWidth,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const _SideNav(extended: true),
        ),

        // Main content area with max width constraint
        Expanded(
          child: AdaptiveContentWidth(
            child: SingleChildScrollView(
              padding: context.adaptivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desktop Layout',
                    style: TextStyle(
                      fontSize: AdaptiveFontSize.headline(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AdaptiveSpacing.vertical(),

                  _PlatformBadge(),
                  AdaptiveSpacing.vertical(),

                  // Content in 3-column grid
                  _buildGrid(context, columns: 3),

                  AdaptiveSpacing.vertical(),

                  _ActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Platform information badge
class _PlatformBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final platform = context.platformName;
    final formFactor = context.formFactor.name;

    return AdaptiveCard(
      child: Row(
        children: [
          Icon(
            _getPlatformIcon(context),
            size: AdaptiveIconSize.large(context),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running on $platform',
                  style: TextStyle(
                    fontSize: AdaptiveFontSize.title(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Form factor: $formFactor',
                  style: TextStyle(
                    fontSize: AdaptiveFontSize.caption(context),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(BuildContext context) {
    if (context.isWeb) return Icons.web;
    if (context.isAndroid) return Icons.android;
    if (context.isIOS) return Icons.phone_iphone;
    if (context.isWindows) return Icons.desktop_windows;
    if (context.isMacOS) return Icons.laptop_mac;
    if (context.isLinux) return Icons.computer;
    return Icons.devices;
  }
}

/// Action buttons section
class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Adaptive button (Material on Android/Windows, Cupertino on iOS/macOS)
        AdaptiveButton(
          onPressed: () => _showSuccessMessage(context),
          child: const Text('Test Adaptive Button'),
        ),

        AdaptiveSpacing.vertical(),

        // Regular button with adaptive styling
        ElevatedButton.icon(
          onPressed: () => _showAdaptiveMenu(context),
          icon: const Icon(Icons.menu),
          label: const Text('Show Context Menu'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(
              double.infinity,
              AdaptiveTapTarget.comfortableSize,
            ),
          ),
        ),

        AdaptiveSpacing.vertical(),

        // Text field with adaptive styling
        AdaptiveTextField(
          placeholder: 'Enter some text',
          onSubmitted: (value) => _showMessage(context, 'Submitted: $value'),
        ),

        AdaptiveSpacing.vertical(),

        // Switch with adaptive styling
        Row(
          children: [
            Expanded(
              child: Text(
                'Enable notifications',
                style: TextStyle(fontSize: AdaptiveFontSize.body(context)),
              ),
            ),
            AdaptiveSwitch(
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ],
    );
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adaptive button pressed!')),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAdaptiveMenu(BuildContext context) async {
    final value = await showAdaptiveContextMenu(
      context: context,
      items: [
        const AdaptiveMenuItem(
          label: 'Edit',
          value: 'edit',
          icon: Icons.edit,
        ),
        const AdaptiveMenuItem(
          label: 'Share',
          value: 'share',
          icon: Icons.share,
        ),
        const AdaptiveMenuItem(
          label: 'Delete',
          value: 'delete',
          icon: Icons.delete,
          isDestructive: true,
        ),
      ],
    );

    if (value != null && context.mounted) {
      _showMessage(context, 'Selected: $value');
    }
  }
}

/// Side navigation for tablet/desktop
class _SideNav extends StatelessWidget {
  final bool extended;

  const _SideNav({this.extended = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (extended) ...[
          const Text(
            'Navigation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _NavItem(icon: Icons.home, label: 'Home', extended: extended),
          _NavItem(icon: Icons.settings, label: 'Settings', extended: extended),
          _NavItem(icon: Icons.info, label: 'About', extended: extended),
        ] else ...[
          _NavItem(icon: Icons.home, label: 'Home', extended: extended),
          _NavItem(icon: Icons.settings, label: 'Settings', extended: extended),
          _NavItem(icon: Icons.info, label: 'About', extended: extended),
        ],
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool extended;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {},
        borderRadius: AdaptiveBorderRadius.medium,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: extended
              ? Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 12),
                    Text(label),
                  ],
                )
              : Icon(icon),
        ),
      ),
    );
  }
}

/// Helper to build content cards
List<Widget> _buildContentCards(BuildContext context, {required int columns}) {
  return List.generate(6, (index) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.adaptiveSpacing),
      child: AdaptiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card ${index + 1}',
              style: TextStyle(
                fontSize: AdaptiveFontSize.title(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is an adaptive card that adjusts its padding and elevation based on the platform.',
              style: TextStyle(fontSize: AdaptiveFontSize.body(context)),
            ),
          ],
        ),
      ),
    );
  });
}

/// Helper to build grid
Widget _buildGrid(BuildContext context, {required int columns}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: context.adaptiveSpacing,
      mainAxisSpacing: context.adaptiveSpacing,
      childAspectRatio: 1.5,
    ),
    itemCount: 6,
    itemBuilder: (context, index) {
      return AdaptiveCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: AdaptiveIconSize.large(context),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Item ${index + 1}',
              style: TextStyle(
                fontSize: AdaptiveFontSize.body(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    },
  );
}
