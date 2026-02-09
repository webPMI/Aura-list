import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// Dashboard layout with configurable grid sections
class DashboardLayout extends StatelessWidget {
  final Widget? header;
  final List<Widget> cards;
  final Widget? sidePanel;
  final EdgeInsets? padding;

  const DashboardLayout({
    super.key,
    this.header,
    required this.cards,
    this.sidePanel,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;
    final effectivePadding = padding ?? context.responsivePadding;

    return switch (screenSize) {
      ScreenSize.mobile => _buildMobileLayout(context, effectivePadding),
      ScreenSize.tablet => _buildTabletLayout(context, effectivePadding),
      ScreenSize.desktop ||
      ScreenSize.widescreen =>
        _buildDesktopLayout(context, effectivePadding),
    };
  }

  Widget _buildMobileLayout(BuildContext context, EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: 16),
          ],
          ...cards.map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: card,
              )),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, EdgeInsets padding) {
    // 2-column grid for tablets
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: 16),
          ],
          _ResponsiveGrid(
            columns: 2,
            spacing: 16,
            children: cards,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, EdgeInsets padding) {
    if (sidePanel != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content (3-column grid)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) ...[
                    header!,
                    const SizedBox(height: 16),
                  ],
                  _ResponsiveGrid(
                    columns: 2, // 2 columns when side panel is present
                    spacing: 16,
                    children: cards,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Side panel
          SizedBox(
            width: 320,
            child: sidePanel!,
          ),
        ],
      );
    }

    // No side panel: 3-column grid
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: 16),
          ],
          _ResponsiveGrid(
            columns: 3,
            spacing: 16,
            children: cards,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int columns;
  final double spacing;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < columns && i + j < children.length; j++) {
        if (j > 0) {
          rowChildren.add(SizedBox(width: spacing));
        }
        rowChildren.add(Expanded(child: children[i + j]));
      }
      // Fill empty spaces in the last row
      final remaining = columns - (children.length - i).clamp(0, columns);
      for (var j = 0; j < remaining; j++) {
        rowChildren.add(SizedBox(width: spacing));
        rowChildren.add(const Expanded(child: SizedBox()));
      }
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ));
      if (i + columns < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }
    return Column(children: rows);
  }
}

/// Dashboard card wrapper with consistent styling
class DashboardCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final EdgeInsets? padding;
  final double? height;

  const DashboardCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.onTap,
    this.onMoreTap,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onMoreTap != null)
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: onMoreTap,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Ver mas',
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick stats card for dashboard
class QuickStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final double? progress;
  final VoidCallback? onTap;

  const QuickStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Card(
      elevation: 0,
      color: effectiveColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: effectiveColor),
                  ),
                  const Spacer(),
                  if (progress != null)
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor:
                                effectiveColor.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(effectiveColor),
                          ),
                          Text(
                            '${(progress! * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: effectiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
