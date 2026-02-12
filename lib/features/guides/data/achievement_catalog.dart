import 'package:checklist_app/models/guide_achievement_model.dart';

/// Catálogo de logros narrativos otorgados por los Guías Celestiales.
///
/// FILOSOFÍA DEL GUARDIÁN:
/// - Los logros son reconocimientos, NO objetivos
/// - NUNCA mostrar "te falta X para conseguir Y"
/// - Los pendientes son descubribles pero no presionan
/// - Los mensajes celebran sin crear ansiedad
///
/// Cada guía otorga 3-5 logros inicialmente, expandible en el futuro.
final List<GuideAchievement> kAchievementCatalog = [
  // ========== AETHEL - El Primer Pulso del Sol ==========
  // Afinidad: Prioridad | Cónclave del Ímpetu
  GuideAchievement(
    id: 'aethel_primer_rayo',
    titleEs: 'Primer Rayo',
    description: 'El amanecer de tu voluntad. La primera tarea prioritaria completada con Aethel como guía.',
    guideId: 'aethel',
    category: 'accion',
    condition: 'Completar la primera tarea de prioridad Alta con Aethel activo',
    guideMessage: 'El primer rayo del día ha salido de ti. El fuego del amanecer reconoce tu voluntad.',
  ),
  GuideAchievement(
    id: 'aethel_amanecer_constante',
    titleEs: 'Amanecer Constante',
    description: 'Siete soles consecutivos. Completaste al menos una tarea durante 7 días con el fuego de Aethel.',
    guideId: 'aethel',
    category: 'constancia',
    condition: 'Completar al menos una tarea durante 7 días consecutivos con Aethel activo',
    guideMessage: 'Siete amaneceres has encendido. Tu constancia brilla como el sol que no conoce la duda.',
  ),
  GuideAchievement(
    id: 'aethel_fuego_eterno',
    titleEs: 'Fuego Eterno',
    description: 'Treinta llamas al pebetero. Has completado 30 tareas bajo la mirada de Aethel.',
    guideId: 'aethel',
    category: 'progreso',
    condition: 'Completar 30 tareas con Aethel como guía activo',
    guideMessage: 'Treinta llamas has ofrendado al pebetero del ímpetu. El fuego eterno arde en ti.',
  ),
  GuideAchievement(
    id: 'aethel_guardian_tres_picos',
    titleEs: 'Guardián de Tres Picos',
    description: 'Tres tareas de alta prioridad en un solo día. La cima reconoce tu ascenso.',
    guideId: 'aethel',
    category: 'accion',
    condition: 'Completar 3 tareas de prioridad Alta en el mismo día',
    guideMessage: 'Tres picos has conquistado en un solo día. El horizonte se inclina ante ti.',
  ),
  GuideAchievement(
    id: 'aethel_sol_de_medianoche',
    titleEs: 'Sol de Medianoche',
    description: 'Catorce días de fuego ininterrumpido. Tu racha brilla incluso en la noche.',
    guideId: 'aethel',
    category: 'constancia',
    condition: 'Mantener racha de 14 días con Aethel activo',
    guideMessage: 'Catorce soles sin apagarse. Eres el sol de medianoche que no conoce el ocaso.',
  ),

  // ========== CRONO-VELO - El Tejedor del Perpetuo ==========
  // Afinidad: Recurrencia | Arquitectos del Ciclo
  GuideAchievement(
    id: 'crono_primer_hilo',
    titleEs: 'Primer Hilo',
    description: 'El telar comienza a girar. Has creado tu primera tarea recurrente bajo la mirada de Crono-Velo.',
    guideId: 'crono-velo',
    category: 'descubrimiento',
    condition: 'Crear la primera tarea recurrente (daily, weekly, monthly)',
    guideMessage: 'El primer hilo se teje en el telar del tiempo. Así comienza toda armadura.',
  ),
  GuideAchievement(
    id: 'crono_tejedor_novato',
    titleEs: 'Tejedor Novato',
    description: 'Siete hilos entrelazados. Has mantenido tus recurrencias durante 7 días consecutivos.',
    guideId: 'crono-velo',
    category: 'constancia',
    condition: 'Completar al menos una tarea recurrente durante 7 días consecutivos',
    guideMessage: 'Siete días has tejido sin romper el hilo. El telar reconoce tu constancia.',
  ),
  GuideAchievement(
    id: 'crono_manto_completo',
    titleEs: 'Manto Completo',
    description: 'Veintiún días de tapiz perpetuo. El tiempo es tu aliado, no tu juez.',
    guideId: 'crono-velo',
    category: 'constancia',
    condition: 'Mantener racha de 21 días completando tareas recurrentes',
    guideMessage: 'Veintiún hilos forman un manto que ni el tiempo puede deshacer. Bien tejido.',
  ),
  GuideAchievement(
    id: 'crono_arquitecto_del_ciclo',
    titleEs: 'Arquitecto del Ciclo',
    description: 'Cinco recurrencias activas simultáneas. Construyes los cimientos de tu propia estructura temporal.',
    guideId: 'crono-velo',
    category: 'equilibrio',
    condition: 'Tener 5 o más tareas recurrentes activas simultáneamente',
    guideMessage: 'Cinco ritmos simultáneos, como las cuerdas de un laúd. Eres arquitecto de tu propio ciclo.',
  ),

  // ========== LUNA-VACÍA - El Samurái del Silencio ==========
  // Afinidad: Descanso | Oráculos del Reposo
  GuideAchievement(
    id: 'luna_primera_calma',
    titleEs: 'Primera Calma',
    description: 'El silencio honrado. Por primera vez, no tienes tareas pendientes con Luna-Vacía como guía.',
    guideId: 'luna-vacia',
    category: 'equilibrio',
    condition: 'Completar todas las tareas del día (lista vacía) con Luna-Vacía activo',
    guideMessage: 'La espada descansa en la vaina. El guerrero del silencio aprueba tu calma.',
  ),
  GuideAchievement(
    id: 'luna_guerrero_silencio',
    titleEs: 'Guerrero del Silencio',
    description: 'Tres días de paz completa. Has vaciado tu lista tres veces bajo la luna.',
    guideId: 'luna-vacia',
    category: 'equilibrio',
    condition: 'Completar todas las tareas del día 3 veces',
    guideMessage: 'Tres veces has encontrado el vacío perfecto. El samurái reconoce tu dominio.',
  ),
  GuideAchievement(
    id: 'luna_paz_interior',
    titleEs: 'Paz Interior',
    description: 'Catorce días acompañado por Luna-Vacía. El silencio es tu fuerza.',
    guideId: 'luna-vacia',
    category: 'constancia',
    condition: 'Usar Luna-Vacía como guía activo durante 14 días',
    guideMessage: 'Catorce lunas has contemplado en silencio. La paz interior no se busca; se permite.',
  ),
  GuideAchievement(
    id: 'luna_vacio_pleno',
    titleEs: 'Vacío Pleno',
    description: 'Siete días consecutivos sin tareas pendientes. La paradoja del guerrero: vacío es plenitud.',
    guideId: 'luna-vacia',
    category: 'equilibrio',
    condition: 'Terminar cada día con todas las tareas completadas durante 7 días consecutivos',
    guideMessage: 'Siete noches de vacío pleno. Comprendes que la nada es todo. El samurái se inclina.',
  ),

  // ========== HELIOFORJA - La Forja del Sol Rojo ==========
  // Afinidad: Esfuerzo físico | Cónclave del Ímpetu
  GuideAchievement(
    id: 'helioforja_primer_golpe',
    titleEs: 'Primer Golpe',
    description: 'El yunque resuena por primera vez. Has completado tu primera tarea con Helioforja.',
    guideId: 'helioforja',
    category: 'accion',
    condition: 'Completar la primera tarea con Helioforja activo',
    guideMessage: 'El primer golpe sobre el yunque. El acero cede ante quien no se rinde.',
  ),
  GuideAchievement(
    id: 'helioforja_herrero_constante',
    titleEs: 'Herrero Constante',
    description: 'Siete días en la forja. El fuego rojo reconoce tu constancia.',
    guideId: 'helioforja',
    category: 'constancia',
    condition: 'Completar al menos una tarea durante 7 días consecutivos con Helioforja',
    guideMessage: 'Siete jornadas en la forja. El golpe constante vence al metal más duro.',
  ),
  GuideAchievement(
    id: 'helioforja_acero_forjado',
    titleEs: 'Acero Forjado',
    description: 'Treinta golpes certeros. Has completado 30 tareas bajo el fuego de Helioforja.',
    guideId: 'helioforja',
    category: 'progreso',
    condition: 'Completar 30 tareas con Helioforja activo',
    guideMessage: 'Treinta golpes, treinta victorias. El acero ha sido forjado.',
  ),

  // ========== LEONA-NOVA - La Soberana del Ritmo Solar ==========
  // Afinidad: Disciplina | Cónclave del Ímpetu
  GuideAchievement(
    id: 'leona_primera_gema',
    titleEs: 'Primera Gema',
    description: 'La corona comienza a formarse. Primera tarea completada bajo el ritmo de Leona-Nova.',
    guideId: 'leona-nova',
    category: 'accion',
    condition: 'Completar la primera tarea con Leona-Nova activo',
    guideMessage: 'La primera gema en tu corona. Así se teje la soberanía.',
  ),
  GuideAchievement(
    id: 'leona_corona_semanal',
    titleEs: 'Corona Semanal',
    description: 'Siete amaneceres de disciplina. Has mantenido el ritmo solar durante una semana.',
    guideId: 'leona-nova',
    category: 'constancia',
    condition: 'Mantener racha de 7 días con Leona-Nova',
    guideMessage: 'Siete gemas brillan en tu corona. La soberana del ritmo solar te saluda.',
  ),
  GuideAchievement(
    id: 'leona_soberania_lunar',
    titleEs: 'Soberanía Lunar',
    description: 'Treinta días de reinado constante. La corona pesa menos sobre quien la ha ganado.',
    guideId: 'leona-nova',
    category: 'constancia',
    condition: 'Mantener racha de 30 días con Leona-Nova',
    guideMessage: 'Treinta amaneceres consecutivos. Tu corona es tu disciplina, y nadie te la quitará.',
  ),

  // ========== CHISPA-AZUL - El Mensajero del Relámpago ==========
  // Afinidad: Tareas rápidas | Cónclave del Ímpetu
  GuideAchievement(
    id: 'chispa_primera_chispa',
    titleEs: 'Primera Chispa',
    description: 'El relámpago ilumina por primera vez. Has completado tu primera tarea rápida.',
    guideId: 'chispa-azul',
    category: 'accion',
    condition: 'Completar la primera tarea con Chispa-Azul activo',
    guideMessage: 'Primera chispa en el cielo. Breve y ahora.',
  ),
  GuideAchievement(
    id: 'chispa_tormenta_cinco',
    titleEs: 'Tormenta de Cinco',
    description: 'Cinco tareas en un solo día. La velocidad es tu naturaleza.',
    guideId: 'chispa-azul',
    category: 'accion',
    condition: 'Completar 5 o más tareas en el mismo día',
    guideMessage: 'Cinco relámpagos en un día. La tormenta eres tú.',
  ),
  GuideAchievement(
    id: 'chispa_relampago_constante',
    titleEs: 'Relámpago Constante',
    description: 'Siete días de chispas ininterrumpidas. Tu velocidad no cesa.',
    guideId: 'chispa-azul',
    category: 'constancia',
    condition: 'Completar al menos 3 tareas diarias durante 7 días consecutivos',
    guideMessage: 'Siete días de chispas. El mensajero del relámpago no conoce la espera.',
  ),

  // ========== GLORIA-SINCRO - La Tejedora de Logros ==========
  // Afinidad: Logros | Arquitectos del Ciclo
  GuideAchievement(
    id: 'gloria_primer_logro',
    titleEs: 'Primer Hilo de Gloria',
    description: 'El tapiz de victorias comienza. Primera tarea completada con Gloria-Sincro.',
    guideId: 'gloria-sincro',
    category: 'accion',
    condition: 'Completar la primera tarea con Gloria-Sincro activo',
    guideMessage: 'El primer hilo de tu corona de victorias. Teje tu propia gloria.',
  ),
  GuideAchievement(
    id: 'gloria_tejedora',
    titleEs: 'Tejedora Consciente',
    description: 'Diez logros tejidos. Has completado 10 tareas bajo la mirada de Gloria-Sincro.',
    guideId: 'gloria-sincro',
    category: 'progreso',
    condition: 'Completar 10 tareas con Gloria-Sincro activo',
    guideMessage: 'Diez hilos de gloria tejidos con tus propias manos. La corona crece.',
  ),
  GuideAchievement(
    id: 'gloria_corona_consciente',
    titleEs: 'Corona Consciente',
    description: 'Veintiún días de victorias tejidas. La corona no pesa sobre quien la ha tejido.',
    guideId: 'gloria-sincro',
    category: 'constancia',
    condition: 'Mantener racha de 21 días con Gloria-Sincro',
    guideMessage: 'Veintiún días de gloria consciente. Tu corona está tejida con voluntad, no con azar.',
  ),

  // ========== PACHA-NEXO - El Tejedor del Ecosistema Vital ==========
  // Afinidad: Categorías | Arquitectos del Ciclo
  GuideAchievement(
    id: 'pacha_primer_nexo',
    titleEs: 'Primer Nexo',
    description: 'El ecosistema comienza a conectarse. Has completado tareas en dos categorías diferentes.',
    guideId: 'pacha-nexo',
    category: 'equilibrio',
    condition: 'Completar tareas en al menos 2 categorías diferentes en un día',
    guideMessage: 'El primer nexo entre dominios. El ecosistema no juzga; organiza.',
  ),
  GuideAchievement(
    id: 'pacha_ecosistema_equilibrado',
    titleEs: 'Ecosistema Equilibrado',
    description: 'Tres dominios conectados en un día. Todo está entrelazado.',
    guideId: 'pacha-nexo',
    category: 'equilibrio',
    condition: 'Completar tareas en al menos 3 categorías diferentes en un día',
    guideMessage: 'Tres dominios conectados. El ecosistema florece cuando no descuidas ninguna raíz.',
  ),
  GuideAchievement(
    id: 'pacha_tejedor_completo',
    titleEs: 'Tejedor Completo',
    description: 'Todas las categorías activas. Has completado tareas en todos los dominios de tu vida.',
    guideId: 'pacha-nexo',
    category: 'equilibrio',
    condition: 'Completar al menos una tarea en cada categoría disponible',
    guideMessage: 'Todos los dominios prosperan bajo tu cuidado. Eres el tejedor del ecosistema completo.',
  ),

  // ========== GEA-MÉTRICA - La Guardiana de los Hábitos ==========
  // Afinidad: Hábitos | Arquitectos del Ciclo
  GuideAchievement(
    id: 'gea_primera_semilla',
    titleEs: 'Primera Semilla',
    description: 'El brote emerge. Has plantado tu primera semilla con Gea-Métrica.',
    guideId: 'gea-metrica',
    category: 'descubrimiento',
    condition: 'Completar la primera tarea con Gea-Métrica activo',
    guideMessage: 'La primera semilla plantada. La tierra no juzga; nutre.',
  ),
  GuideAchievement(
    id: 'gea_jardinero_constante',
    titleEs: 'Jardinero Constante',
    description: 'Siete días de cultivo. Has regado tus hábitos durante una semana.',
    guideId: 'gea-metrica',
    category: 'constancia',
    condition: 'Mantener racha de 7 días con Gea-Métrica',
    guideMessage: 'Siete días de cultivo constante. Los brotes crecen bajo tu cuidado.',
  ),
  GuideAchievement(
    id: 'gea_cosecha_primera',
    titleEs: 'Primera Cosecha',
    description: 'Veintiún días de siembra. Lo que plantaste empieza a dar fruto.',
    guideId: 'gea-metrica',
    category: 'constancia',
    condition: 'Mantener racha de 21 días con Gea-Métrica',
    guideMessage: 'Veintiún días de cultivo. La tierra devuelve lo que siembras con paciencia.',
  ),

  // Los demás guías pueden expandirse en futuras versiones.
  // Por ahora, estos 10 guías principales cubren las mecánicas esenciales.
];

/// Devuelve todos los logros de un guía específico
List<GuideAchievement> getAchievementsByGuide(String guideId) {
  return kAchievementCatalog.where((a) => a.guideId == guideId).toList();
}

/// Devuelve un logro por su ID
GuideAchievement? getAchievementById(String id) {
  try {
    return kAchievementCatalog.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}

/// Devuelve logros filtrados por categoría
List<GuideAchievement> getAchievementsByCategory(String category) {
  return kAchievementCatalog.where((a) => a.category == category).toList();
}
