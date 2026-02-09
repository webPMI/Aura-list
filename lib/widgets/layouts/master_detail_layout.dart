import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// Master-detail layout for task lists with side panel on larger screens
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final bool showDetail;
  final double masterMinWidth;
  final double masterMaxWidth;
  final double detailMinWidth;
  final Widget? emptyDetailPlaceholder;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.showDetail = true,
    this.masterMinWidth = 320,
    this.masterMaxWidth = 450,
    this.detailMinWidth = 350,
    this.emptyDetailPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    // Mobile: only show master
    if (screenSize == ScreenSize.mobile) {
      return master;
    }

    // Tablet/Desktop: show master + detail side by side
    return Row(
      children: [
        // Master panel
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: masterMinWidth,
            maxWidth: screenSize == ScreenSize.tablet
                ? context.screenWidth * 0.45
                : masterMaxWidth,
          ),
          child: master,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Detail panel
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: detailMinWidth),
            child: showDetail && detail != null
                ? detail!
                : emptyDetailPlaceholder ?? _DefaultEmptyDetail(),
          ),
        ),
      ],
    );
  }
}

class _DefaultEmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un elemento',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive panel that shows as sheet on mobile, side panel on desktop
class ResponsiveDetailPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  const ResponsiveDetailPanel({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        if (title != null || onClose != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    tooltip: 'Cerrar',
                  ),
              ],
            ),
          ),
        // Content
        Expanded(child: child),
      ],
    );
  }
}

/// Shows content as bottom sheet on mobile, side panel on desktop
Future<T?> showAdaptivePanel<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  String? title,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop: show as dialog on the right side
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black26,
    builder: (context) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        child: SizedBox(
          width: 450,
          height: MediaQuery.of(context).size.height,
          child: ResponsiveDetailPanel(
            title: title,
            onClose: () => Navigator.pop(context),
            child: builder(context),
          ),
        ),
      ),
    ),
  );
}
