import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/services/synergy_messages.dart';

/// Servicio que gestiona las sinergias entre Guías Celestiales.
///
/// Las sinergias representan afinidades naturales entre guías que
/// comparten filosofías complementarias. Este servicio ayuda a los usuarios
/// a descubrir guías que trabajan bien juntos.
///
/// Filosofía:
/// - Las sinergias son sugerencias, no imposiciones
/// - El usuario siempre elige libremente
/// - Los mensajes son motivacionales, no críticos
class GuideSynergyService {
  GuideSynergyService._();
  static final instance = GuideSynergyService._();

  /// Obtiene la lista de guías aliados recomendados para el guía dado.
  ///
  /// Retorna la lista de guías que están en [guide.synergyIds] y existen
  /// en el catálogo. Si el guía no tiene sinergias, retorna lista vacía.
  List<Guide> getRecommendedAllies(String guideId) {
    final guide = getGuideById(guideId);
    if (guide == null || guide.synergyIds.isEmpty) {
      return [];
    }

    final allies = <Guide>[];
    for (final allyId in guide.synergyIds) {
      final ally = getGuideById(allyId);
      if (ally != null) {
        allies.add(ally);
      }
    }

    return allies;
  }

  /// Verifica si dos guías tienen sinergia entre sí.
  ///
  /// La sinergia es bidireccional: retorna true si guide1 tiene a guide2
  /// en sus synergyIds, o viceversa.
  bool hasSynergy(String guideId1, String guideId2) {
    final guide1 = getGuideById(guideId1);
    final guide2 = getGuideById(guideId2);

    if (guide1 == null || guide2 == null) return false;

    return guide1.synergyIds.contains(guideId2) ||
        guide2.synergyIds.contains(guideId1);
  }

  /// Calcula el nivel de afinidad entre dos guías (0.0 a 1.0).
  ///
  /// Actualmente usa un sistema simple:
  /// - 1.0 si hay sinergia directa declarada
  /// - 0.6 si comparten la misma familia (clase)
  /// - 0.3 si tienen afinidades relacionadas
  /// - 0.0 sin relación
  ///
  /// Este cálculo puede expandirse en el futuro con más métricas.
  double calculateAffinityLevel(String guideId1, String guideId2) {
    if (guideId1 == guideId2) return 1.0;

    final guide1 = getGuideById(guideId1);
    final guide2 = getGuideById(guideId2);

    if (guide1 == null || guide2 == null) return 0.0;

    // Sinergia directa: máxima afinidad
    if (guide1.synergyIds.contains(guideId2) ||
        guide2.synergyIds.contains(guideId1)) {
      return 1.0;
    }

    // Misma familia: afinidad media-alta
    if (guide1.classFamily == guide2.classFamily &&
        guide1.classFamily.isNotEmpty) {
      return 0.6;
    }

    // Afinidades relacionadas: afinidad media-baja
    if (_hasRelatedAffinities(guide1, guide2)) {
      return 0.3;
    }

    return 0.0;
  }

  /// Calcula un bonus multiplicador basado en la sinergia (1.0 a 1.3).
  ///
  /// Este bonus puede usarse en el futuro para:
  /// - Aumentar puntos de experiencia
  /// - Mejorar efectos de bendiciones
  /// - Desbloquear mensajes especiales
  ///
  /// Actualmente:
  /// - 1.3x para sinergia directa
  /// - 1.15x para misma familia
  /// - 1.05x para afinidades relacionadas
  /// - 1.0x (sin bonus) para otros casos
  double calculateSynergyBonus(String guideId1, String guideId2) {
    final affinity = calculateAffinityLevel(guideId1, guideId2);

    if (affinity >= 1.0) return 1.3;
    if (affinity >= 0.6) return 1.15;
    if (affinity >= 0.3) return 1.05;
    return 1.0;
  }

  /// Obtiene una descripción poética de la sinergia entre dos guías.
  ///
  /// Para sinergias específicas, retorna un mensaje personalizado.
  /// Para otras combinaciones, genera un mensaje genérico basado en
  /// las afinidades de los guías.
  String getSynergyDescription(Guide guide1, Guide guide2) {
    // Intentar obtener descripción específica del registro de mensajes
    final specificMessage = _getSpecificSynergyMessage(guide1.id, guide2.id);
    if (specificMessage != null) {
      return specificMessage;
    }

    // Mensaje genérico basado en afinidades
    return _generateGenericSynergyMessage(guide1, guide2);
  }

  /// Obtiene todos los guías que tienen sinergia con el guía dado,
  /// ordenados por nivel de afinidad (mayor a menor).
  List<Guide> getAllSynergyGuides(String guideId) {
    final guide = getGuideById(guideId);
    if (guide == null) return [];

    final synergyGuides = <({Guide guide, double affinity})>[];

    for (final otherGuide in kGuideCatalog) {
      if (otherGuide.id == guideId) continue;

      final affinity = calculateAffinityLevel(guideId, otherGuide.id);
      if (affinity > 0) {
        synergyGuides.add((guide: otherGuide, affinity: affinity));
      }
    }

    // Ordenar por afinidad descendente
    synergyGuides.sort((a, b) => b.affinity.compareTo(a.affinity));

    return synergyGuides.map((e) => e.guide).toList();
  }

  // ==================== Métodos privados ====================

  bool _hasRelatedAffinities(Guide guide1, Guide guide2) {
    // Definir grupos de afinidades relacionadas
    const affinityGroups = [
      ['Prioridad', 'Esfuerzo físico', 'Disciplina', 'Tareas rápidas'],
      ['Recurrencia', 'Hábitos', 'Progreso', 'Planificación'],
      ['Descanso', 'Notas', 'Ansiedad', 'Notificaciones'],
      ['Cambio de planes', 'Imprevistos', 'Creatividad'],
      ['Privacidad', 'Sincronización', 'Estadísticas'],
    ];

    for (final group in affinityGroups) {
      if (group.contains(guide1.affinity) && group.contains(guide2.affinity)) {
        return true;
      }
    }

    return false;
  }

  String? _getSpecificSynergyMessage(String guideId1, String guideId2) {
    return getSynergyMessage(guideId1, guideId2);
  }

  String _generateGenericSynergyMessage(Guide guide1, Guide guide2) {
    final affinity = calculateAffinityLevel(guide1.id, guide2.id);

    if (affinity >= 1.0) {
      return '${guide1.name} y ${guide2.name} comparten un vínculo ancestral. '
          'Juntos, ${guide1.affinity.toLowerCase()} y ${guide2.affinity.toLowerCase()} '
          'se entrelazan como hilos del mismo destino.';
    } else if (affinity >= 0.6) {
      return '${guide1.name} y ${guide2.name} pertenecen a ${guide1.classFamily}. '
          'Su energía fluye en armonía, reforzando tu camino.';
    } else if (affinity >= 0.3) {
      return '${guide1.name} (${guide1.affinity}) y ${guide2.name} (${guide2.affinity}) '
          'pueden complementarse en tu jornada.';
    }

    return '${guide1.name} y ${guide2.name} observan tu camino desde perspectivas distintas.';
  }
}
