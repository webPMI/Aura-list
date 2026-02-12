import 'package:flutter/material.dart';

/// Colores semánticos para las categorías de logros de los guías.
///
/// Usar estas constantes en lugar de literales hex en los widgets
/// garantiza coherencia visual y facilita futuros cambios de paleta.
class GuideColors {
  GuideColors._();

  // Colores de categoría de logros
  static const Color constancia = Color(0xFF1976D2);
  static const Color accion = Color(0xFFE65100);
  static const Color equilibrio = Color(0xFF2E7D32);
  static const Color progreso = Color(0xFF7B1FA2);
  static const Color descubrimiento = Color(0xFFFFA000);

  // Colores de afinidad entre guías (constelación)
  static const Color affinityHigh = Color(0xFFFFD700);
  static const Color affinityMedium = Color(0xFF64B5F6);
  static const Color affinityLow = Color(0xFF90A4AE);

  /// Devuelve el color asociado a la [category] de un logro.
  /// Retorna [Colors.grey] para categorías desconocidas.
  static Color forCategory(String category) {
    switch (category) {
      case 'constancia':
        return constancia;
      case 'accion':
        return accion;
      case 'equilibrio':
        return equilibrio;
      case 'progreso':
        return progreso;
      case 'descubrimiento':
        return descubrimiento;
      default:
        return Colors.grey;
    }
  }

  /// Devuelve el icono asociado a la [category] de un logro.
  static IconData iconForCategory(String category) {
    switch (category) {
      case 'constancia':
        return Icons.repeat;
      case 'accion':
        return Icons.flash_on;
      case 'equilibrio':
        return Icons.balance;
      case 'progreso':
        return Icons.trending_up;
      case 'descubrimiento':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }

  /// Devuelve el nombre legible en español de una [category].
  static String labelForCategory(String category) {
    switch (category) {
      case 'constancia':
        return 'Constancia';
      case 'accion':
        return 'Acción';
      case 'equilibrio':
        return 'Equilibrio';
      case 'progreso':
        return 'Progreso';
      case 'descubrimiento':
        return 'Descubrimiento';
      default:
        return category;
    }
  }
}
