import 'package:checklist_app/models/guide_model.dart';

/// Registro de bendiciones por ID. Permite conocer nombre, trigger y efecto
/// de cada bendición para UI y, más adelante, conectar triggers (completar tarea, etc.).
///
/// Las bendiciones NUNCA castigan; solo refuerzan (animación, haptic, mensaje).
/// Ver docs/personajes-misticos/implementacion-bendiciones.md y consejo-pilares (Guardian).
final Map<String, BlessingDefinition> kGuideBlessingRegistry = {
  // Aethel
  'gracia_accion_inmediata': const BlessingDefinition(
    id: 'gracia_accion_inmediata',
    name: 'Gracia de la Acción Inmediata',
    trigger: 'Primeras 3 tareas completadas del día',
    effect: 'Ecos de Aura (reducción visual de carga)',
  ),
  'escudo_termico': const BlessingDefinition(
    id: 'escudo_termico',
    name: 'Escudo Térmico',
    trigger: 'Mucho tiempo en lista sin actuar',
    effect: 'Suavizar contrastes para reducir fatiga visual',
  ),
  // Crono-Velo
  'manto_constancia': const BlessingDefinition(
    id: 'manto_constancia',
    name: 'Manto de la Constancia',
    trigger: 'Fallar un día en racha larga',
    effect: 'Racha no se rompe visualmente; una oportunidad de redención',
  ),
  'sincronia_ritmos': const BlessingDefinition(
    id: 'sincronia_ritmos',
    name: 'Sincronía de Ritmos',
    trigger: 'Crear tarea recurrente',
    effect: 'Sugerir horarios según patrones históricos',
  ),
  // Luna-Vacía
  'escudo_vacio_mental': const BlessingDefinition(
    id: 'escudo_vacio_mental',
    name: 'Escudo del Vacío Mental',
    trigger: 'Sesión Foco Profundo activa',
    effect: 'Bloquear notificaciones externas temporalmente',
  ),
  'aliento_plata': const BlessingDefinition(
    id: 'aliento_plata',
    name: 'Aliento de Plata',
    trigger: 'Metas de bienestar completadas al final del día',
    effect: 'Sello de Paz visual; refuerzo para despertar',
  ),
  // Helioforja
  'gracia_primer_golpe': const BlessingDefinition(
    id: 'gracia_primer_golpe',
    name: 'Gracia del Primer Golpe',
    trigger: 'Primeras 2 tareas de esfuerzo físico del día',
    effect: 'Ecos de Aura + haptic celebración',
  ),
  'escudo_termico_forjador': const BlessingDefinition(
    id: 'escudo_termico_forjador',
    name: 'Escudo Térmico del Forjador',
    trigger: 'Semana con muchas tareas de esfuerzo completadas',
    effect: 'Suavizar rojos en paleta',
  ),
  // Leona-Nova
  'gracia_corona': const BlessingDefinition(
    id: 'gracia_corona',
    name: 'Gracia de la Corona',
    trigger: 'Primer día con al menos una tarea en cada bloque horario',
    effect: 'Sello Solar visual',
  ),
  // Chispa-Azul
  'gracia_mensajero': const BlessingDefinition(
    id: 'gracia_mensajero',
    name: 'Gracia del Mensajero',
    trigger: 'Completar las 5 primeras tareas rápidas del día',
    effect: 'Eco de Chispa + haptic en cadencia',
  ),
  'viento_favor': const BlessingDefinition(
    id: 'viento_favor',
    name: 'Viento a Favor',
    trigger: 'Crear tarea con título corto',
    effect: 'Sugerir etiqueta rápida + atajo para añadir otra',
  ),
  // Gloria-Sincro
  'tejido_fama': const BlessingDefinition(
    id: 'tejido_fama',
    name: 'Tejido de Fama',
    trigger: 'Siempre',
    effect: 'Vista resumida de hitos últimos 7 días (sin ranking)',
  ),
  // Pacha-Nexo
  'gracia_nexo': const BlessingDefinition(
    id: 'gracia_nexo',
    name: 'Gracia del Nexo',
    trigger: 'Primera vez que organizan 5 tareas en categorías en un día',
    effect: 'Mapa del Día (resumen visual por dominio)',
  ),
  'equilibrio_dominios': const BlessingDefinition(
    id: 'equilibrio_dominios',
    name: 'Equilibrio de Dominios',
    trigger: 'Siempre (opción)',
    effect: 'Vista de balance por categoría (orientación)',
  ),
  // Gea-Métrica
  'gracia_brote': const BlessingDefinition(
    id: 'gracia_brote',
    name: 'Gracia del Brote',
    trigger: 'Primer hábito con racha de 3 días consecutivos',
    effect: 'Brote visual (animación de crecimiento)',
  ),
  'cuenco_estaciones': const BlessingDefinition(
    id: 'cuenco_estaciones',
    name: 'Cuenco de Estaciones',
    trigger: 'Siempre (vista)',
    effect: 'Estación personal según tendencia de hábitos (orientativo)',
  ),
  // Resto: stubs por ID (nombre genérico; ampliar cuando se implementen triggers)
  'gracia_creciente': const BlessingDefinition(
    id: 'gracia_creciente',
    name: 'Gracia de la Creciente',
    trigger: 'Primer avance visible en un proyecto',
    effect: 'Animación luna creciente',
  ),
  'espejo_fases': const BlessingDefinition(
    id: 'espejo_fases',
    name: 'Espejo de Fases',
    trigger: 'Siempre (vista)',
    effect: 'Fase actual según tendencia (orientativo)',
  ),
  'gracia_timon': const BlessingDefinition(
    id: 'gracia_timon',
    name: 'Gracia del Timón',
    trigger: 'Primera vez que planifica 3 días seguidos',
    effect: 'Viento a Favor (animación vela)',
  ),
  'estacion_actual': const BlessingDefinition(
    id: 'estacion_actual',
    name: 'Estación Actual',
    trigger: 'Siempre (vista)',
    effect: 'Estación personal según fecha/carga (orientativo)',
  ),
  'gracia_sustentador': const BlessingDefinition(
    id: 'gracia_sustentador',
    name: 'Gracia del Sustentador',
    trigger: 'Primera sincronización exitosa del día',
    effect: 'Órbita Completa (animación)',
  ),
  'manto_respaldo': const BlessingDefinition(
    id: 'manto_respaldo',
    name: 'Manto de Respaldo',
    trigger: 'Siempre (vista)',
    effect: 'Estado de sincronización y respaldo (orientativo)',
  ),
  'gracia_oraculo': const BlessingDefinition(
    id: 'gracia_oraculo',
    name: 'Gracia del Oráculo',
    trigger: 'Primera vez que usa modo calma o una sola tarea',
    effect: 'Refugio Activo (animación calma)',
  ),
  'hilo_orden': const BlessingDefinition(
    id: 'hilo_orden',
    name: 'Hilo de Orden',
    trigger: 'Tarea grande sin desglose',
    effect: 'Sugerencia de desglose en pasos (orientativo)',
  ),
  'gracia_susurro': const BlessingDefinition(
    id: 'gracia_susurro',
    name: 'Gracia del Susurro',
    trigger: 'Primeras 3 notificaciones del día',
    effect: 'Plantilla suave (texto y sonido)',
  ),
  'farol_anima': const BlessingDefinition(
    id: 'farol_anima',
    name: 'Farol de la Anima',
    trigger: 'Siempre (vista)',
    effect: 'Lista de próximos recordatorios (suave)',
  ),
  'gracia_tejedor': const BlessingDefinition(
    id: 'gracia_tejedor',
    name: 'Gracia del Tejedor',
    trigger: 'Primera nota guardada del día o noche',
    effect: 'Hilo de Sueño (animación)',
  ),
  'huso_ideas': const BlessingDefinition(
    id: 'huso_ideas',
    name: 'Huso de Ideas',
    trigger: 'Nota con formato de acción',
    effect: 'Sugerencia de convertir en tarea (orientativo)',
  ),
  'gracia_danzante': const BlessingDefinition(
    id: 'gracia_danzante',
    name: 'Gracia del Danzante',
    trigger: 'Primera vez que mueve/pospone tarea en la sesión',
    effect: 'Danza Aceptada (animación fluida)',
  ),
  'circulo_transformacion': const BlessingDefinition(
    id: 'circulo_transformacion',
    name: 'Círculo de Transformación',
    trigger: 'Después de mover/posponer',
    effect: 'Opción deshacer último cambio (una vez por sesión)',
  ),
  'gracia_tramoyista': const BlessingDefinition(
    id: 'gracia_tramoyista',
    name: 'Gracia del Tramoyista',
    trigger: 'Primer error recuperable en la sesión',
    effect: 'Mensaje sereno + animación suave',
  ),
  'dado_destino': const BlessingDefinition(
    id: 'dado_destino',
    name: 'Dado del Destino',
    trigger: 'Fin del día con varios imprevistos recuperados',
    effect: 'Mensaje motivador opcional',
  ),
  'gracia_centella': const BlessingDefinition(
    id: 'gracia_centella',
    name: 'Gracia de la Centella',
    trigger: 'Primera nota/tarea marcada como idea o proyecto personal',
    effect: 'Centella Encendida (animación)',
  ),
  'manzana_cambio': const BlessingDefinition(
    id: 'manzana_cambio',
    name: 'Manzana del Cambio',
    trigger: 'Nota larga o tarea con descripción muy abierta',
    effect: 'Sugerencia de guardar como idea (orientativo)',
  ),
  'gracia_guardian': const BlessingDefinition(
    id: 'gracia_guardian',
    name: 'Gracia del Guardián',
    trigger: 'Primera vez que abre Privacidad/Cuenta en la sesión',
    effect: 'Umbral Claro (animación balanza)',
  ),
  'cetro_vinculo': const BlessingDefinition(
    id: 'cetro_vinculo',
    name: 'Cetro del Vínculo',
    trigger: 'Recordatorio opcional (ej. anual)',
    effect: 'Sugerencia de revisar privacidad (no forzado)',
  ),
  'gracia_cartografo': const BlessingDefinition(
    id: 'gracia_cartografo',
    name: 'Gracia del Cartógrafo',
    trigger: 'Primera vez que abre Estadísticas en el día',
    effect: 'Mapa Actualizado (animación)',
  ),
  'astrolabio_progreso': const BlessingDefinition(
    id: 'astrolabio_progreso',
    name: 'Astrolabio del Progreso',
    trigger: 'Siempre (vista)',
    effect: 'Resumen progreso semana (orientativo)',
  ),
  'gracia_flujo': const BlessingDefinition(
    id: 'gracia_flujo',
    name: 'Gracia del Flujo',
    trigger: 'Primera vez que completa 3 tareas seguidas sin salir de la app',
    effect: 'Corriente Activa (animación)',
  ),
  'cantaro_bit': const BlessingDefinition(
    id: 'cantaro_bit',
    name: 'Cántaro del Bit',
    trigger: 'Muchas tareas pendientes + rato en lista',
    effect: 'Sugerencia de modo foco (orientativo)',
  ),
};

/// Devuelve la definición de una bendición por ID, o null.
BlessingDefinition? getBlessingById(String id) => kGuideBlessingRegistry[id];
