import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// A responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;
  final double? childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
    this.childAspectRatio,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.screenSize) {
      ScreenSize.mobile => mobileColumns ?? Breakpoints.mobileColumns,
      ScreenSize.tablet => tabletColumns ?? Breakpoints.tabletColumns,
      ScreenSize.desktop ||
      ScreenSize.widescreen =>
        desktopColumns ?? Breakpoints.desktopColumns,
    };

    if (childAspectRatio != null) {
      return GridView.builder(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: childAspectRatio!,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return SingleChildScrollView(
          physics: physics,
          padding: padding,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// A sliver-based responsive grid for use in CustomScrollView
class SliverResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const SliverResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.screenSize) {
      ScreenSize.mobile => mobileColumns ?? Breakpoints.mobileColumns,
      ScreenSize.tablet => tabletColumns ?? Breakpoints.tabletColumns,
      ScreenSize.desktop ||
      ScreenSize.widescreen =>
        desktopColumns ?? Breakpoints.desktopColumns,
    };

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }
}

/// A responsive row/column that switches between horizontal and vertical
/// layout based on screen size
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final bool rowOnMobile;
  final bool rowOnTablet;
  final bool rowOnDesktop;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.rowOnMobile = false,
    this.rowOnTablet = true,
    this.rowOnDesktop = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isRow = switch (context.screenSize) {
      ScreenSize.mobile => rowOnMobile,
      ScreenSize.tablet => rowOnTablet,
      ScreenSize.desktop || ScreenSize.widescreen => rowOnDesktop,
    };

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(
          width: isRow ? spacing : 0,
          height: isRow ? 0 : spacing,
        ));
      }
    }

    if (isRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: spacedChildren,
      );
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
}

/// Responsive flex that adjusts flex values based on screen size
class ResponsiveFlex extends StatelessWidget {
  final Widget child;
  final int mobileFlex;
  final int tabletFlex;
  final int desktopFlex;

  const ResponsiveFlex({
    super.key,
    required this.child,
    this.mobileFlex = 1,
    this.tabletFlex = 1,
    this.desktopFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final flex = switch (context.screenSize) {
      ScreenSize.mobile => mobileFlex,
      ScreenSize.tablet => tabletFlex,
      ScreenSize.desktop || ScreenSize.widescreen => desktopFlex,
    };

    return Expanded(flex: flex, child: child);
  }
}
