import 'package:flutter/services.dart';
import 'package:checklist_app/models/guide_model.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/services/guide_blessing_registry.dart';

/// Contexto para evaluar si una bendicion debe activarse.
///
/// Contiene las metricas de la sesion actual que se comparan contra
/// los triggers de cada bendicion.
class BlessingTriggerContext {
  const BlessingTriggerContext({
    required this.tasksCompletedToday,
    required this.currentStreak,
    this.taskCategory,
    this.physicalEffortTasksToday = 0,
    this.quickTasksToday = 0,
    this.categoriesUsedToday = const [],
    this.habitStreakDays = 0,
    this.lastCompletedTask,
  });

  /// Numero de tareas completadas hoy (cualquier tipo).
  final int tasksCompletedToday;

  /// Racha actual de dias consecutivos con tareas completadas.
  final int currentStreak;

  /// Categoria de la ultima tarea completada (opcional).
  final String? taskCategory;

  /// Tareas de esfuerzo fisico completadas hoy.
  final int physicalEffortTasksToday;

  /// Tareas rapidas completadas hoy (titulo corto / duracion estimada baja).
  final int quickTasksToday;

  /// Categorias distintas usadas hoy.
  final List<String> categoriesUsedToday;

  /// Dias consecutivos del habito especifico (para Gea-Metrica).
  final int habitStreakDays;

  /// Ultima tarea completada (para evaluacion contextual).
  final Task? lastCompletedTask;

  /// Crea una copia con valores actualizados.
  BlessingTriggerContext copyWith({
    int? tasksCompletedToday,
    int? currentStreak,
    String? taskCategory,
    int? physicalEffortTasksToday,
    int? quickTasksToday,
    List<String>? categoriesUsedToday,
    int? habitStreakDays,
    Task? lastCompletedTask,
  }) {
    return BlessingTriggerContext(
      tasksCompletedToday: tasksCompletedToday ?? this.tasksCompletedToday,
      currentStreak: currentStreak ?? this.currentStreak,
      taskCategory: taskCategory ?? this.taskCategory,
      physicalEffortTasksToday:
          physicalEffortTasksToday ?? this.physicalEffortTasksToday,
      quickTasksToday: quickTasksToday ?? this.quickTasksToday,
      categoriesUsedToday: categoriesUsedToday ?? this.categoriesUsedToday,
      habitStreakDays: habitStreakDays ?? this.habitStreakDays,
      lastCompletedTask: lastCompletedTask ?? this.lastCompletedTask,
    );
  }
}

/// Resultado de verificar si una bendicion se activa al completar una tarea.
class BlessingTriggerResult {
  const BlessingTriggerResult({
    required this.triggered,
    this.blessing,
    this.message,
    this.intensity = 0.7,
  });

  /// Si se activo alguna bendicion.
  final bool triggered;

  /// La bendicion que se activo (si hay).
  final BlessingDefinition? blessing;

  /// Mensaje para mostrar al usuario.
  final String? message;

  /// Intensidad del efecto (0.0 - 1.0). Puede usarse para escalar animaciones.
  final double intensity;

  static const none = BlessingTriggerResult(triggered: false);
}

/// Resultado de una bendicion activada (para lista de bendiciones).
class TriggeredBlessing {
  const TriggeredBlessing({
    required this.blessing,
    this.intensity = 1.0,
    this.message,
  });

  /// Definicion de la bendicion activada.
  final BlessingDefinition blessing;

  /// Intensidad del efecto (0.0 - 1.0). Puede usarse para escalar animaciones.
  final double intensity;

  /// Mensaje personalizado (si difiere del trigger estandar).
  final String? message;
}

/// Estado interno del servicio para tracking de completions del dia.
class _DailyCompletionState {
  int completionsToday = 0;
  int physicalEffortCompletionsToday = 0;
  int quickTasksToday = 0;
  Set<String> categoriesUsedToday = {};
  DateTime lastCompletionDate = DateTime(1970);

  void recordCompletion({
    bool isPhysicalEffort = false,
    bool isQuickTask = false,
    String? category,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastCompletionDate.year,
      lastCompletionDate.month,
      lastCompletionDate.day,
    );

    // Si es un nuevo dia, resetear contadores
    if (today.isAfter(lastDate)) {
      completionsToday = 0;
      physicalEffortCompletionsToday = 0;
      quickTasksToday = 0;
      categoriesUsedToday = {};
    }

    completionsToday++;
    if (isPhysicalEffort) physicalEffortCompletionsToday++;
    if (isQuickTask) quickTasksToday++;
    if (category != null) categoriesUsedToday.add(category);
    lastCompletionDate = now;
  }

  int getCompletionsToday() {
    _checkNewDay();
    return completionsToday;
  }

  int getPhysicalEffortCompletionsToday() {
    _checkNewDay();
    return physicalEffortCompletionsToday;
  }

  int getQuickTasksToday() {
    _checkNewDay();
    return quickTasksToday;
  }

  List<String> getCategoriesUsedToday() {
    _checkNewDay();
    return categoriesUsedToday.toList();
  }

  void _checkNewDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastCompletionDate.year,
      lastCompletionDate.month,
      lastCompletionDate.day,
    );

    if (today.isAfter(lastDate)) {
      completionsToday = 0;
      physicalEffortCompletionsToday = 0;
      quickTasksToday = 0;
      categoriesUsedToday = {};
    }
  }
}

/// Servicio para verificar y ejecutar triggers de bendiciones del guia activo.
///
/// Las bendiciones NUNCA castigan; solo refuerzan positivamente (animacion,
/// haptic, mensaje motivacional). Ver guide_blessing_registry.dart para el
/// catalogo completo de bendiciones.
///
/// Uso tipico:
/// ```dart
/// final service = BlessingTriggerService();
/// final result = service.evaluateTaskCompletion(
///   task: completedTask,
///   activeGuide: guide,
///   currentStreak: 5,
/// );
/// if (result.triggered) {
///   showBlessingFeedback(result);
/// }
/// ```
class BlessingTriggerService {
  BlessingTriggerService();

  final _dailyState = _DailyCompletionState();

  /// Conjunto de bendiciones ya mostradas en esta sesion (evita spam).
  final Set<String> _shownThisSession = {};

  /// Verifica si una bendicion especifica debe activarse dado el contexto.
  ///
  /// Retorna `true` si la bendicion cumple su condicion de trigger.
  /// No considera si ya fue mostrada (usar [shouldShowBlessing] para eso).
  bool shouldTrigger(
    String blessingId, {
    required int tasksCompletedToday,
    required int currentStreak,
    String? taskCategory,
  }) {
    final context = BlessingTriggerContext(
      tasksCompletedToday: tasksCompletedToday,
      currentStreak: currentStreak,
      taskCategory: taskCategory,
      physicalEffortTasksToday: _dailyState.getPhysicalEffortCompletionsToday(),
      quickTasksToday: _dailyState.getQuickTasksToday(),
      categoriesUsedToday: _dailyState.getCategoriesUsedToday(),
    );
    return _evaluateTriggerCondition(blessingId, context);
  }

  /// Obtiene todas las bendiciones que se activan dado el contexto actual.
  ///
  /// Filtra por las bendiciones que el [guide] tiene asignadas (via [blessingIds])
  /// y verifica cuales cumplen su trigger.
  ///
  /// Si [filterShown] es `true` (default), excluye las ya mostradas en sesion.
  List<String> getTriggeredBlessings(
    Guide guide, {
    required int tasksCompletedToday,
    required int currentStreak,
    String? taskCategory,
    bool filterShown = true,
  }) {
    final triggered = <String>[];

    for (final blessingId in guide.blessingIds) {
      if (filterShown && _shownThisSession.contains(blessingId)) continue;

      if (shouldTrigger(
        blessingId,
        tasksCompletedToday: tasksCompletedToday,
        currentStreak: currentStreak,
        taskCategory: taskCategory,
      )) {
        triggered.add(blessingId);
      }
    }

    return triggered;
  }

  /// Obtiene bendiciones activadas con informacion completa.
  List<TriggeredBlessing> getTriggeredBlessingsDetailed(
    Guide guide, {
    required BlessingTriggerContext context,
    bool filterShown = true,
  }) {
    final triggered = <TriggeredBlessing>[];

    for (final blessingId in guide.blessingIds) {
      if (filterShown && _shownThisSession.contains(blessingId)) continue;

      if (_evaluateTriggerCondition(blessingId, context)) {
        final blessing = getBlessingById(blessingId);
        if (blessing != null) {
          triggered.add(TriggeredBlessing(
            blessing: blessing,
            intensity: _calculateIntensity(blessingId, context),
            message: _getCustomMessage(blessingId, context, guideId: guide.id),
          ));
        }
      }
    }

    return triggered;
  }

  /// Evalua si completar una tarea activa alguna bendicion del guia activo.
  ///
  /// Retorna [BlessingTriggerResult] con la bendicion activada (si hay).
  /// Las bendiciones se evaluan en orden de prioridad.
  BlessingTriggerResult evaluateTaskCompletion({
    required Task task,
    required Guide? activeGuide,
    int currentStreak = 0,
  }) {
    if (activeGuide == null) {
      return BlessingTriggerResult.none;
    }

    // Determinar caracteristicas de la tarea
    final isPhysicalEffort =
        task.category == 'Salud' || task.category == 'Hogar';
    final isQuickTask = task.title.length <= 30; // Titulo corto = tarea rapida

    // Registrar completion antes de evaluar
    _dailyState.recordCompletion(
      isPhysicalEffort: isPhysicalEffort,
      isQuickTask: isQuickTask,
      category: task.category,
    );

    final context = BlessingTriggerContext(
      tasksCompletedToday: _dailyState.getCompletionsToday(),
      currentStreak: currentStreak,
      taskCategory: task.category,
      physicalEffortTasksToday: _dailyState.getPhysicalEffortCompletionsToday(),
      quickTasksToday: _dailyState.getQuickTasksToday(),
      categoriesUsedToday: _dailyState.getCategoriesUsedToday(),
      habitStreakDays: currentStreak,
      lastCompletedTask: task,
    );

    // Evaluar bendiciones del guia activo
    for (final blessingId in activeGuide.blessingIds) {
      if (_shownThisSession.contains(blessingId)) continue;

      final result = _evaluateBlessing(
        blessingId: blessingId,
        context: context,
        guide: activeGuide,
      );

      if (result.triggered) {
        _shownThisSession.add(blessingId);
        return result;
      }
    }

    return BlessingTriggerResult.none;
  }

  /// Marca una bendicion como mostrada para evitar repeticion.
  void markAsShown(String blessingId) {
    _shownThisSession.add(blessingId);
  }

  /// Resetea las bendiciones mostradas (nuevo dia o cambio de sesion).
  void resetSession() {
    _shownThisSession.clear();
  }

  /// Resetea el estado diario (para testing o nuevo dia).
  void resetDailyState() {
    _dailyState.completionsToday = 0;
    _dailyState.physicalEffortCompletionsToday = 0;
    _dailyState.quickTasksToday = 0;
    _dailyState.categoriesUsedToday = {};
    _dailyState.lastCompletionDate = DateTime(1970);
    _shownThisSession.clear();
  }

  /// Ejecuta el haptic feedback correspondiente a una bendicion.
  void executeHapticFeedback(BlessingDefinition blessing) {
    // Haptic diferenciado segun el tipo de bendicion
    if (blessing.id.contains('gracia')) {
      // Las "gracias" tienen haptic mas fuerte
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
    } else if (blessing.id.contains('escudo') ||
        blessing.id.contains('manto')) {
      // Escudos y mantos tienen haptic suave y reconfortante
      HapticFeedback.lightImpact();
    } else {
      // Default: medium
      HapticFeedback.mediumImpact();
    }
  }

  // ---------------------------------------------------------------------------
  // Logica de evaluacion de triggers
  // ---------------------------------------------------------------------------

  /// Evalua si un trigger especifico se cumple dado el contexto.
  bool _evaluateTriggerCondition(
      String blessingId, BlessingTriggerContext context) {
    switch (blessingId) {
      // =======================================================================
      // Aethel - Accion inmediata
      // =======================================================================
      case 'gracia_accion_inmediata':
        // Primeras 3 tareas completadas del dia
        return context.tasksCompletedToday >= 1 &&
            context.tasksCompletedToday <= 3;

      case 'escudo_termico':
        // Este trigger es pasivo (mucho tiempo sin actuar); no se evalua aqui
        return false;

      // =======================================================================
      // Crono-Velo - Constancia y tiempo
      // =======================================================================
      case 'manto_constancia':
        // Racha de 3+ dias (se activa al mantener la racha)
        return context.currentStreak >= 3;

      case 'sincronia_ritmos':
        // Este trigger es al crear tarea recurrente; no se evalua aqui
        return false;

      // =======================================================================
      // Luna-Vacia - Bienestar y enfoque
      // =======================================================================
      case 'escudo_vacio_mental':
        // Este trigger es durante Sesion Foco Profundo; no se evalua aqui
        return false;

      case 'aliento_plata':
        // Metas de bienestar al final del dia
        if (context.taskCategory == 'Salud') {
          final hour = DateTime.now().hour;
          return hour >= 20 || hour < 6;
        }
        return false;

      // =======================================================================
      // Helioforja - Esfuerzo fisico
      // =======================================================================
      case 'gracia_primer_golpe':
        // Primeras 2 tareas de esfuerzo fisico del dia
        return context.physicalEffortTasksToday >= 1 &&
            context.physicalEffortTasksToday <= 2;

      case 'escudo_termico_forjador':
        // Este trigger es semanal; no se evalua aqui
        return false;

      // =======================================================================
      // Leona-Nova - Organizacion por bloques
      // =======================================================================
      case 'gracia_corona':
        // Tarea de alta prioridad completada
        final task = context.lastCompletedTask;
        return task != null && task.priority == 2;

      // =======================================================================
      // Chispa-Azul - Velocidad y tareas rapidas
      // =======================================================================
      case 'gracia_mensajero':
        // Completar las 5 primeras tareas rapidas del dia
        return context.quickTasksToday >= 1 && context.quickTasksToday <= 5;

      case 'viento_favor':
        // Este trigger es al crear tarea con titulo corto; no se evalua aqui
        return false;

      // =======================================================================
      // Pacha-Nexo - Organizacion por categorias
      // =======================================================================
      case 'gracia_nexo':
        // Primera vez que organizan 5 tareas en categorias en un dia
        return context.categoriesUsedToday.length >= 5;

      case 'equilibrio_dominios':
        // Siempre disponible (vista)
        return true;

      // =======================================================================
      // Gea-Metrica - Habitos y crecimiento
      // =======================================================================
      case 'gracia_brote':
        // Habito con racha de 3 dias consecutivos
        return context.habitStreakDays >= 3;

      case 'cuenco_estaciones':
        // Siempre disponible (vista)
        return true;

      // =======================================================================
      // Gloria-Sincro - Resumen y logros
      // =======================================================================
      case 'tejido_fama':
        // Siempre disponible (vista de hitos)
        return true;

      // =======================================================================
      // Triggers genericos basados en contexto
      // =======================================================================
      case 'gracia_flujo':
        // 3 tareas completadas en la sesion
        return context.tasksCompletedToday >= 3;

      default:
        // Bendiciones no implementadas o pasivas
        return false;
    }
  }

  /// Evalua una bendicion especifica y retorna el resultado.
  BlessingTriggerResult _evaluateBlessing({
    required String blessingId,
    required BlessingTriggerContext context,
    required Guide guide,
  }) {
    final blessing = getBlessingById(blessingId);
    if (blessing == null) return BlessingTriggerResult.none;

    if (!_evaluateTriggerCondition(blessingId, context)) {
      return BlessingTriggerResult.none;
    }

    return BlessingTriggerResult(
      triggered: true,
      blessing: blessing,
      message: _getCustomMessage(blessingId, context, guideId: guide.id) ??
          '${guide.name}: ${blessing.name}',
      intensity: _calculateIntensity(blessingId, context),
    );
  }

  /// Calcula la intensidad del efecto segun el contexto.
  double _calculateIntensity(
      String blessingId, BlessingTriggerContext context) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        // Intensidad crece con cada tarea completada (1, 2, 3)
        return (context.tasksCompletedToday / 3).clamp(0.3, 1.0);

      case 'manto_constancia':
        // Intensidad crece con la racha
        if (context.currentStreak >= 30) return 1.0;
        if (context.currentStreak >= 14) return 0.9;
        if (context.currentStreak >= 7) return 0.8;
        if (context.currentStreak >= 3) return 0.6;
        return 0.5;

      case 'gracia_primer_golpe':
        return context.physicalEffortTasksToday == 2 ? 1.0 : 0.7;

      case 'gracia_mensajero':
        // Intensidad crece hasta completar las 5 tareas rapidas
        return (context.quickTasksToday / 5).clamp(0.4, 1.0);

      case 'gracia_brote':
        // Intensidad segun dias de racha del habito
        if (context.habitStreakDays >= 21) return 1.0;
        if (context.habitStreakDays >= 7) return 0.8;
        return 0.6;

      default:
        return 0.7;
    }
  }

  /// Genera un mensaje personalizado segun el contexto y el guia activo.
  ///
  /// Si hay un guia especifico, intenta usar mensajes personalizados para ese guia.
  /// Si no hay guia o no hay mensaje personalizado, usa el mensaje generico.
  String? _getCustomMessage(
    String blessingId,
    BlessingTriggerContext context, {
    String? guideId,
  }) {
    // Si hay guia especifico, intentar usar mensaje personalizado
    if (guideId != null) {
      final guideMessage =
          _getGuideSpecificMessage(blessingId, context, guideId);
      if (guideMessage != null) return guideMessage;
    }

    // Fallback a mensaje generico
    return _getGenericMessage(blessingId, context);
  }

  /// Genera mensajes personalizados segun el guia activo.
  ///
  /// Cada guia tiene su propio estilo de celebracion:
  /// - Aethel: Fuego, energia, impulso
  /// - Crono-Velo: Hilos, patrones, constancia
  /// - Luna-Vacia: Paz, serenidad, silencio
  /// - Helioforja: Forja, martillo, acero
  /// - Chispa-Azul: Velocidad, relampagos, destellos
  String? _getGuideSpecificMessage(
    String blessingId,
    BlessingTriggerContext context,
    String guideId,
  ) {
    final n = context.tasksCompletedToday;
    final streak = context.currentStreak;
    final physicalTasks = context.physicalEffortTasksToday;
    final quickTasks = context.quickTasksToday;
    final habitDays = context.habitStreakDays;

    switch (guideId) {
      case 'aethel':
        return _getAethelMessage(
            blessingId, n, streak, physicalTasks, quickTasks, habitDays);

      case 'crono-velo':
        return _getCronoVeloMessage(
            blessingId, n, streak, physicalTasks, quickTasks, habitDays);

      case 'luna-vacia':
        return _getLunaVaciaMessage(
            blessingId, n, streak, physicalTasks, quickTasks, habitDays);

      case 'helioforja':
        return _getHelioforjaMessage(
            blessingId, n, streak, physicalTasks, quickTasks, habitDays);

      case 'chispa-azul':
        return _getChispaAzulMessage(
            blessingId, n, streak, physicalTasks, quickTasks, habitDays);

      default:
        return null;
    }
  }

  /// Mensajes de Aethel - Fuego y energia.
  String? _getAethelMessage(
    String blessingId,
    int n,
    int streak,
    int physicalTasks,
    int quickTasks,
    int habitDays,
  ) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        if (n == 1) return 'Primer rayo del dia! El fuego despierta.';
        if (n == 2) return 'Dos llamas arden. Tu impulso crece.';
        if (n == 3) return 'Tres soles! Aethel siente tu poder.';
        return null;

      case 'manto_constancia':
        if (streak >= 30) return '$streak dias ardiendo! Eres fuego eterno!';
        if (streak >= 14) return '$streak dias de llama constante!';
        if (streak >= 7) return 'Una semana de fuego! La brasa es fuerte!';
        if (streak >= 3) return '$streak dias encendido! El calor permanece!';
        return null;

      case 'gracia_primer_golpe':
        if (physicalTasks == 1) return 'Primera chispa fisica! Tu cuerpo arde!';
        if (physicalTasks == 2) return 'Segunda llama! El fuego crece en ti!';
        return null;

      case 'gracia_mensajero':
        if (quickTasks == 5) return '5 relampagos de fuego! Velocidad ardiente!';
        if (quickTasks >= 3) return 'Chispa $quickTasks/5 - El fuego acelera!';
        return 'Chispa $quickTasks/5';

      case 'gracia_brote':
        if (habitDays == 3) return 'Tu habito prende! 3 dias de llama!';
        if (habitDays >= 7) return 'Tu habito es fuego! $habitDays dias ardiendo!';
        return null;

      case 'gracia_corona':
        return 'Corona de fuego! Tarea prioritaria conquistada!';

      case 'aliento_plata':
        return 'Brasas nocturnas cuidan tu descanso';

      case 'gracia_nexo':
        return 'Red de fuego conectada! Organizacion ardiente!';

      default:
        return null;
    }
  }

  /// Mensajes de Crono-Velo - Hilos y patrones.
  String? _getCronoVeloMessage(
    String blessingId,
    int n,
    int streak,
    int physicalTasks,
    int quickTasks,
    int habitDays,
  ) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        if (n == 1) return 'Primer hilo tejido. El patron comienza.';
        if (n == 2) return 'Dos hilos entrelazados. Constancia.';
        if (n == 3) return 'Tres puntos en el tapiz. Crono-Velo asiente.';
        return null;

      case 'manto_constancia':
        if (streak >= 30) return '$streak hilos tejidos! Tapiz legendario!';
        if (streak >= 14) return '$streak dias de tejido constante!';
        if (streak >= 7) return 'Una semana de hilos! El patron emerge!';
        if (streak >= 3) return '$streak hilos en secuencia! Ritmo perfecto!';
        return null;

      case 'gracia_primer_golpe':
        if (physicalTasks == 1) return 'Primer nudo fisico tejido!';
        if (physicalTasks == 2) return 'Segundo nudo! La trama se fortalece!';
        return null;

      case 'gracia_mensajero':
        if (quickTasks == 5) return '5 hilos rapidos! Tejido veloz completado!';
        if (quickTasks >= 3) return 'Hilo $quickTasks/5 - El telar avanza!';
        return 'Hilo $quickTasks/5';

      case 'gracia_brote':
        if (habitDays == 3) return 'Tu habito se teje! 3 dias de patron!';
        if (habitDays >= 7) return 'Tapiz de habito! $habitDays dias tejidos!';
        return null;

      case 'gracia_corona':
        return 'Hilo dorado tejido! Prioridad en el tapiz!';

      case 'aliento_plata':
        return 'Velo nocturno te envuelve en paz';

      case 'gracia_nexo':
        return 'Hilos conectados! Trama organizada!';

      default:
        return null;
    }
  }

  /// Mensajes de Luna-Vacia - Paz y serenidad.
  String? _getLunaVaciaMessage(
    String blessingId,
    int n,
    int streak,
    int physicalTasks,
    int quickTasks,
    int habitDays,
  ) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        if (n == 1) return 'Primera tarea en paz. Bien.';
        if (n == 2) return 'Dos pasos serenos. Fluyes.';
        if (n == 3) return 'Tres logros en silencio. Luna-Vacia te protege.';
        return null;

      case 'manto_constancia':
        if (streak >= 30) return '$streak lunas de serenidad. Paz profunda.';
        if (streak >= 14) return '$streak noches de constancia serena.';
        if (streak >= 7) return 'Una semana de calma. El silencio fortalece.';
        if (streak >= 3) return '$streak dias en paz. La calma permanece.';
        return null;

      case 'gracia_primer_golpe':
        if (physicalTasks == 1) return 'Movimiento sereno. Tu cuerpo fluye.';
        if (physicalTasks == 2) return 'Segundo flujo. Armonia fisica.';
        return null;

      case 'gracia_mensajero':
        if (quickTasks == 5) return '5 acciones fluidas. Serenidad en movimiento.';
        if (quickTasks >= 3) return 'Paso $quickTasks/5 - Flujo constante.';
        return 'Paso $quickTasks/5';

      case 'gracia_brote':
        if (habitDays == 3) return 'Tu habito germina en silencio. 3 dias.';
        if (habitDays >= 7) return 'Habito sereno. $habitDays dias de calma.';
        return null;

      case 'gracia_corona':
        return 'Prioridad resuelta en paz. Luna-Vacia sonrie.';

      case 'aliento_plata':
        return 'La luna te abraza en la noche';

      case 'gracia_nexo':
        return 'Armonia en la organizacion. Todo fluye.';

      default:
        return null;
    }
  }

  /// Mensajes de Helioforja - Forja y acero.
  String? _getHelioforjaMessage(
    String blessingId,
    int n,
    int streak,
    int physicalTasks,
    int quickTasks,
    int habitDays,
  ) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        if (n == 1) return 'Primer golpe en la forja!';
        if (n == 2) return 'Dos martillazos. El acero cede.';
        if (n == 3) return 'Tres golpes certeros. Helioforja aplaude.';
        return null;

      case 'manto_constancia':
        if (streak >= 30) return '$streak dias forjando! Acero legendario!';
        if (streak >= 14) return '$streak dias de martillo constante!';
        if (streak >= 7) return 'Una semana en la forja! El metal brilla!';
        if (streak >= 3) return '$streak golpes seguidos! La forja calienta!';
        return null;

      case 'gracia_primer_golpe':
        if (physicalTasks == 1) return 'Primer golpe del cuerpo! El yunque resuena!';
        if (physicalTasks == 2) return 'Segundo martillazo! Tu fuerza crece!';
        return null;

      case 'gracia_mensajero':
        if (quickTasks == 5) return '5 golpes rapidos! Forja veloz completada!';
        if (quickTasks >= 3) return 'Golpe $quickTasks/5 - El ritmo acelera!';
        return 'Golpe $quickTasks/5';

      case 'gracia_brote':
        if (habitDays == 3) return 'Tu habito se templa! 3 dias de forja!';
        if (habitDays >= 7) return 'Habito de acero! $habitDays dias templando!';
        return null;

      case 'gracia_corona':
        return 'Obra maestra forjada! Prioridad en acero!';

      case 'aliento_plata':
        return 'La forja descansa. Mañana seguiras forjando.';

      case 'gracia_nexo':
        return 'Cadena de acero conectada! Organizacion solida!';

      default:
        return null;
    }
  }

  /// Mensajes de Chispa-Azul - Velocidad y relampagos.
  String? _getChispaAzulMessage(
    String blessingId,
    int n,
    int streak,
    int physicalTasks,
    int quickTasks,
    int habitDays,
  ) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        if (n == 1) return 'Primera chispa! Rapido.';
        if (n == 2) return 'Dos destellos! Velocidad.';
        if (n == 3) return 'Tres relampagos! Chispa-Azul brilla contigo.';
        return null;

      case 'manto_constancia':
        if (streak >= 30) return '$streak dias de relampagos! Tormenta eterna!';
        if (streak >= 14) return '$streak destellos consecutivos!';
        if (streak >= 7) return 'Una semana de chispas! La tormenta crece!';
        if (streak >= 3) return '$streak dias de velocidad! El rayo persiste!';
        return null;

      case 'gracia_primer_golpe':
        if (physicalTasks == 1) return 'Primer rayo fisico! Energia pura!';
        if (physicalTasks == 2) return 'Segundo destello! Tu cuerpo electrifica!';
        return null;

      case 'gracia_mensajero':
        if (quickTasks == 5) return '5 relampagos! Velocidad maxima alcanzada!';
        if (quickTasks >= 3) return 'Rayo $quickTasks/5 - La tormenta avanza!';
        return 'Rayo $quickTasks/5';

      case 'gracia_brote':
        if (habitDays == 3) return 'Tu habito electrifica! 3 dias de chispa!';
        if (habitDays >= 7) return 'Habito relampago! $habitDays dias de energia!';
        return null;

      case 'gracia_corona':
        return 'Relampago maestro! Prioridad fulminada!';

      case 'aliento_plata':
        return 'Las chispas descansan bajo las estrellas';

      case 'gracia_nexo':
        return 'Red electrica conectada! Organizacion veloz!';

      default:
        return null;
    }
  }

  /// Genera mensajes genericos (fallback cuando no hay guia o mensaje especifico).
  String? _getGenericMessage(String blessingId, BlessingTriggerContext context) {
    switch (blessingId) {
      case 'gracia_accion_inmediata':
        final n = context.tasksCompletedToday;
        if (n == 1) return 'Primera tarea del dia completada!';
        if (n == 2) return 'Dos tareas listas! Sigue asi!';
        if (n == 3) return 'Tres tareas completadas! Excelente inicio!';
        return null;

      case 'manto_constancia':
        final streak = context.currentStreak;
        if (streak >= 30) return '$streak dias de racha! Eres imparable!';
        if (streak >= 14) {
          return '$streak dias seguidos! Dos semanas de constancia!';
        }
        if (streak >= 7) return 'Una semana de racha! El habito se fortalece!';
        if (streak >= 3) {
          return '$streak dias seguidos! La constancia rinde frutos!';
        }
        return null;

      case 'gracia_primer_golpe':
        if (context.physicalEffortTasksToday == 1) {
          return 'Primer golpe del dia! Tu cuerpo te lo agradece!';
        }
        if (context.physicalEffortTasksToday == 2) {
          return 'Segundo golpe! La forja arde con fuerza!';
        }
        return null;

      case 'gracia_mensajero':
        final n = context.quickTasksToday;
        if (n == 5) return '5 tareas rapidas completadas! Velocidad total!';
        if (n >= 3) return 'Chispa $n/5 - Sigue el ritmo!';
        return 'Chispa $n/5';

      case 'gracia_brote':
        final days = context.habitStreakDays;
        if (days == 3) return 'Tu habito ha brotado! 3 dias consecutivos!';
        if (days >= 7) return 'Tu habito florece! $days dias de crecimiento!';
        return null;

      case 'gracia_corona':
        return 'Tarea prioritaria completada! Corona merecida!';

      case 'aliento_plata':
        return 'Paz nocturna para tu bienestar';

      case 'gracia_nexo':
        return 'Nexo conectado! Organizacion ejemplar!';

      default:
        return null;
    }
  }
}
