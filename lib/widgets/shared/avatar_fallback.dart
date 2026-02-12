import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar avatar fallback con iniciales.
///
/// Soporta dos modos:
/// - [useDoubleInitials: false] Solo primer caracter (para guias)
/// - [useDoubleInitials: true] Dos iniciales (para usuarios)
class AvatarFallback extends StatelessWidget {
  final String? name;
  final Color backgroundColor;
  final Color? textColor;
  final double size;
  final bool useDoubleInitials;

  const AvatarFallback({
    super.key,
    required this.name,
    required this.backgroundColor,
    this.textColor,
    required this.size,
    this.useDoubleInitials = false,
  });

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    if (!useDoubleInitials) {
      return name![0].toUpperCase();
    }
    final parts = name!.trim().split(' ');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    final effectiveTextColor = textColor ??
        (backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: effectiveTextColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
