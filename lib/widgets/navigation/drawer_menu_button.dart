import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive/breakpoints.dart';
import '../../providers/navigation_provider.dart';

/// A menu button that opens the drawer on mobile devices.
/// On tablet/desktop, this widget is hidden since navigation is visible.
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    // Only show on mobile where drawer is hidden
    if (screenSize != ScreenSize.mobile) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => _openDrawer(context),
      tooltip: 'Menu',
    );
  }

  void _openDrawer(BuildContext context) {
    // Find all scaffolds in the tree and open the one with a drawer
    ScaffoldState? targetScaffold;

    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Scaffold) {
        // Check if this scaffold has a drawer by looking at its state
        try {
          final state = (element as StatefulElement).state;
          if (state is ScaffoldState && state.hasDrawer) {
            targetScaffold = state;
            return false; // Stop searching
          }
        } catch (_) {
          // Continue if we can't access the state
        }
      }
      return true; // Continue searching
    });

    if (targetScaffold != null) {
      targetScaffold!.openDrawer();
    }
  }
}

/// A reusable AppBar that includes drawer menu button or back button intelligently
class DrawerAwareAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final double? elevation;
  final Color? backgroundColor;
  final double? scrolledUnderElevation;
  final bool? showBackButton;

  const DrawerAwareAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.bottom,
    this.flexibleSpace,
    this.elevation,
    this.backgroundColor,
    this.scrolledUnderElevation,
    this.showBackButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = context.screenSize;
    final isMobile = screenSize == ScreenSize.mobile;
    final canGoBack = ref.watch(canGoBackProvider);

    Widget? effectiveLeading = leading;

    if (effectiveLeading == null) {
      if (showBackButton == true || (showBackButton == null && canGoBack)) {
        // Show Back Button that pops AppRoute history first, then Navigator
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Atrás',
          onPressed: () {
            final popped = ref.read(navigationHistoryProvider.notifier).goBack();
            if (!popped) {
              Navigator.maybePop(context);
            }
          },
        );
      } else if (isMobile) {
        effectiveLeading = const DrawerMenuButton();
      }
    }

    return AppBar(
      leading: effectiveLeading,
      automaticallyImplyLeading: effectiveLeading == null,
      title: title,
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
      elevation: elevation,
      backgroundColor: backgroundColor,
      scrolledUnderElevation: scrolledUnderElevation,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
