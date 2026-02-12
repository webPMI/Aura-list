import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/core/utils/color_utils.dart';
import 'package:checklist_app/features/guides/data/guide_asset_paths.dart';
import 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/widgets/shared/avatar_fallback.dart';

/// Avatar del guía: imagen cuadrada o placeholder con color del guía.
/// Usa [GuideAssetPaths.avatar(guide.id)] si existe el asset; si no, muestra círculo con inicial y color.
class GuideAvatar extends ConsumerWidget {
  const GuideAvatar({
    super.key,
    this.size = 48,
    this.guide,
    this.showBorder = true,
  });

  /// Tamaño del avatar (ancho y alto).
  final double size;

  /// Guía a mostrar. Si null, usa el guía activo del provider.
  final Guide? guide;

  /// Si true, muestra borde con color de acento del guía.
  final bool showBorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = guide ?? ref.watch(activeGuideProvider);
    if (active == null) {
      return _PlaceholderAvatar(size: size, color: Colors.grey);
    }
    final color = parseHexColor(active.themeAccentHex ?? active.themePrimaryHex) ?? Colors.grey;
    final path = GuideAssetPaths.avatar(active.id);
    return _AvatarContent(
      size: size,
      path: path,
      fallbackColor: color,
      name: active.name,
      showBorder: showBorder,
      borderColor: color,
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person_outline, color: color, size: size * 0.5),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.size,
    required this.path,
    required this.fallbackColor,
    required this.name,
    required this.showBorder,
    required this.borderColor,
  });

  final double size;
  final String path;
  final Color fallbackColor;
  final String name;
  final bool showBorder;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: borderColor, width: 2)
            : null,
        boxShadow: [
          if (showBorder)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
        ],
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, Object e, StackTrace? st) => AvatarFallback(
        name: name,
        backgroundColor: fallbackColor,
        size: size,
      ),
    );
  }
}
