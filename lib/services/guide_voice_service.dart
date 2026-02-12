import 'package:checklist_app/models/guide_model.dart';

/// Tipos de momento donde el guia puede hablar
enum GuideVoiceMoment {
  appOpening, // Al abrir la app
  firstTaskOfDay, // Primera tarea completada
  streakAchieved, // Racha alcanzada
  endOfDay, // Fin del dia exitoso
  encouragement, // Motivacion general
  taskCompleted, // Tarea completada
}

/// Servicio que genera mensajes contextuales segun el guia activo.
class GuideVoiceService {
  GuideVoiceService._();
  static final instance = GuideVoiceService._();

  /// Obtiene un mensaje contextual para el guia en un momento especifico.
  String? getMessage(
    Guide? guide,
    GuideVoiceMoment moment, {
    int? streakDays,
    int? tasksCompleted,
  }) {
    if (guide == null) return null;

    final messages = _messagesByGuide[guide.id];
    if (messages == null) {
      return _getDefaultMessage(
        moment,
        streakDays: streakDays,
        tasksCompleted: tasksCompleted,
      );
    }

    final momentMessages = messages[moment];
    if (momentMessages == null || momentMessages.isEmpty) {
      return _getDefaultMessage(
        moment,
        streakDays: streakDays,
        tasksCompleted: tasksCompleted,
      );
    }

    // Seleccionar mensaje basado en contexto
    if (moment == GuideVoiceMoment.streakAchieved && streakDays != null) {
      return _formatMessage(momentMessages.first, streakDays: streakDays);
    }
    if (moment == GuideVoiceMoment.taskCompleted && tasksCompleted != null) {
      final index = (tasksCompleted - 1).clamp(0, momentMessages.length - 1);
      return momentMessages[index];
    }

    // Mensaje aleatorio para variedad
    return momentMessages[(DateTime.now().millisecond % momentMessages.length)];
  }

  String _formatMessage(String message, {int? streakDays}) {
    if (streakDays != null) {
      return message.replaceAll('{days}', streakDays.toString());
    }
    return message;
  }

  String? _getDefaultMessage(
    GuideVoiceMoment moment, {
    int? streakDays,
    int? tasksCompleted,
  }) {
    switch (moment) {
      case GuideVoiceMoment.appOpening:
        return 'Bienvenido de vuelta.';
      case GuideVoiceMoment.firstTaskOfDay:
        return 'Primera tarea del dia completada!';
      case GuideVoiceMoment.streakAchieved:
        return 'Racha de ${streakDays ?? 0} dias!';
      case GuideVoiceMoment.endOfDay:
        return 'Buen trabajo hoy.';
      case GuideVoiceMoment.encouragement:
        return 'Sigue adelante.';
      case GuideVoiceMoment.taskCompleted:
        return 'Tarea completada!';
    }
  }

  /// Mensajes personalizados por guia
  static final Map<String, Map<GuideVoiceMoment, List<String>>>
      _messagesByGuide = {
    // ========== CONCLAVE DEL IMPETU ==========
    'aethel': {
      GuideVoiceMoment.appOpening: [
        'El fuego del dia te espera. Actua.',
        'El sol no pide permiso; tu tampoco deberias.',
        'Tu voluntad es el amanecer. Despierta.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'El primer rayo del dia! El fuego crece.',
        'Asi se empieza. El impulso esta de tu lado.',
        'Primera victoria. Que no sea la ultima.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de fuego constante. Arde con orgullo.',
        'Tu racha brilla como el sol. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El sol se pone, pero tu fuego permanece.',
        'Descansa. Manana el fuego volvera.',
      ],
      GuideVoiceMoment.encouragement: [
        'El fuego no espera. Tu tampoco.',
        'Eres el amanecer de tu destino.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'El fuego crece!',
        'Otra llama al pebetero.',
        'Tu impulso no se detiene.',
      ],
    },
    'helioforja': {
      GuideVoiceMoment.appOpening: [
        'La forja esta encendida. A trabajar.',
        'El acero no se forja solo. Tu tampoco.',
        'El fuego rojo te espera. Golpea.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer golpe del dia! El metal cede.',
        'Asi se empieza: con fuerza.',
        'La forja se calienta. Buen inicio.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias en la forja. Tu acero brilla.',
        'Constancia de herrero. {days} dias forjando.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El yunque descansa. Tu tambien lo mereces.',
        'Buena jornada en la forja.',
      ],
      GuideVoiceMoment.encouragement: [
        'El golpe constante vence al metal.',
        'Cada golpe cuenta. Sigue forjando.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Golpe certero!',
        'El metal cede ante ti.',
        'Forjando tu destino.',
      ],
    },
    'leona-nova': {
      GuideVoiceMoment.appOpening: [
        'La corona se teje con cada amanecer.',
        'Soberana de tu tiempo, adelante.',
        'El ritmo solar te acompana.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera gema en tu corona del dia.',
        'El sol reconoce tu disciplina.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} amaneceres consecutivos. Reinas.',
        'Tu corona crece. {days} dias de soberania.',
      ],
      GuideVoiceMoment.endOfDay: [
        'La soberana descansa con honor.',
        'Buen reinado hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'La disciplina es tu cetro.',
        'Cada dia tejes tu corona.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Digno de una soberana.',
        'Tu ritmo es impecable.',
        'La corona brilla mas.',
      ],
    },
    'chispa-azul': {
      GuideVoiceMoment.appOpening: [
        'Rapido y brillante. Asi eres tu.',
        'El relampago no espera. Tu tampoco.',
        'Velocidad y precision. Adelante.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera chispa! Que vengan mas.',
        'Velocidad y precision. Perfecto.',
        'El relampago ya brilla.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de chispas. Electrizante!',
        'Tu velocidad no cesa. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El relampago descansa en la nube.',
        'Rapido y efectivo. Buen dia.',
      ],
      GuideVoiceMoment.encouragement: [
        'Breve y ahora. Ese es el camino.',
        'La chispa no duda.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Chispa!',
        'Relampago!',
        'Rapido como el viento.',
      ],
    },

    // ========== ARQUITECTOS DEL CICLO ==========
    'crono-velo': {
      GuideVoiceMoment.appOpening: [
        'Un nuevo hilo se teje hoy.',
        'El tiempo fluye. Tu constancia permanece.',
        'Cada dia es un punto en tu tapiz.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'El primer hilo del dia esta tejido.',
        'Asi se construye una armadura: hilo a hilo.',
        'El telar reconoce tu constancia.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias tejidos. La armadura se fortalece.',
        'Tu tapiz crece. {days} hilos entrelazados.',
      ],
      GuideVoiceMoment.endOfDay: [
        'Otro dia tejido. El patron emerge.',
        'Descansa. El telar esperara.',
      ],
      GuideVoiceMoment.encouragement: [
        'Hilo a hilo, la armadura crece.',
        'El tiempo es tu aliado.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Un hilo mas al tapiz.',
        'El ritmo continua.',
        'Constancia sobre velocidad.',
      ],
    },
    'gloria-sincro': {
      GuideVoiceMoment.appOpening: [
        'Los logros esperan. Tejelos.',
        'Tu corona de victorias se expande.',
        'La tejedora de logros te saluda.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer logro del dia tejido!',
        'La victoria consciente comienza.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} victorias consecutivas. Gloria!',
        'Tu corona de logros brilla. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'Hoy tejiste con tus propias manos.',
        'Logros bien merecidos.',
      ],
      GuideVoiceMoment.encouragement: [
        'Cada tarea es un hilo de gloria.',
        'Tejes tu propia corona.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Un logro mas!',
        'La corona crece.',
        'Victoria consciente.',
      ],
    },
    'pacha-nexo': {
      GuideVoiceMoment.appOpening: [
        'El ecosistema te recibe.',
        'Cada dominio de tu vida esta conectado.',
        'El tejedor organiza sin juzgar.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer hilo del ecosistema hoy.',
        'Los dominios se conectan.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de equilibrio. El nexo florece.',
        'Tu ecosistema prospera. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El ecosistema descansa en armonia.',
        'Buen equilibrio hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Todo esta conectado.',
        'El equilibrio es tu fortaleza.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'El nexo se fortalece.',
        'Conexion establecida.',
        'El ecosistema crece.',
      ],
    },
    'gea-metrica': {
      GuideVoiceMoment.appOpening: [
        'La tierra te espera. Siembra hoy.',
        'Los habitos son semillas. Cultivalos.',
        'La guardiana nutre tu progreso.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera semilla plantada!',
        'El brote emerge con constancia.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de cultivo. La cosecha se acerca.',
        'Tu jardin prospera. {days} dias de cuidado.',
      ],
      GuideVoiceMoment.endOfDay: [
        'La tierra descanso bien regada.',
        'Buen cultivo hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Lo que siembras, cosechas.',
        'La tierra no juzga; nutre.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'El brote crece.',
        'Semilla bien plantada.',
        'El habito arraiga.',
      ],
    },
    'viento-estacion': {
      GuideVoiceMoment.appOpening: [
        'El viento sopla a tu favor.',
        'Ajusta la vela. La estacion es propicia.',
        'El navegante te guia.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera brisa del dia!',
        'El viento impulsa tu inicio.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias navegando con constancia.',
        'Tu travesia suma {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El navegante ancla con satisfaccion.',
        'Buena travesia hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'El viento te lleva si ajustas la vela.',
        'Cada estacion tiene su ritmo.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Viento a favor!',
        'La vela se hincha.',
        'Rumbo correcto.',
      ],
    },
    'atlas-orbital': {
      GuideVoiceMoment.appOpening: [
        'Tu trabajo orbita contigo.',
        'El sustentador te acompana.',
        'Todo esta sincronizado.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera orbita del dia completa.',
        'La sincronia comienza.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} orbitas consecutivas. Impecable.',
        'Tu sincronia es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'Las orbitas descansan en armonia.',
        'Buena sincronia hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Lo que construyes esta sostenido.',
        'La sincronia es tu fuerza.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Orbita completa.',
        'Sincronizado.',
        'El sustento continua.',
      ],
    },

    // ========== ORACULOS DEL REPOSO ==========
    'luna-vacia': {
      GuideVoiceMoment.appOpening: [
        'Respira. El silencio te acompana.',
        'Tu mente esta lista. Procede con calma.',
        'La serenidad es tu fuerza hoy.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Bien hecho. Sin prisa, sin pausa.',
        'Primera tarea en paz. Asi se avanza.',
        'El samurai del silencio aprueba.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de equilibrio. El vacio te sostiene.',
        'Tu constancia es serena. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El guerrero descansa. Bien merecido.',
        'Cierra los ojos. El mundo puede esperar.',
      ],
      GuideVoiceMoment.encouragement: [
        'La calma de quien sostiene la espada.',
        'El silencio es tu aliado.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Paz en la accion.',
        'Fluyes con serenidad.',
        'El silencio celebra contigo.',
      ],
    },
    'selene-fase': {
      GuideVoiceMoment.appOpening: [
        'Una nueva fase comienza.',
        'Hoy no necesitas estar llena; solo crecer.',
        'La tejedora de fases te saluda.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera fase del dia completa.',
        'El crecimiento es gradual.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} fases de progreso continuo.',
        'Tu ciclo es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'La luna descansa entre fases.',
        'Cada fase es parte del ciclo.',
      ],
      GuideVoiceMoment.encouragement: [
        'Crecer un poco cada dia es suficiente.',
        'Las fases son parte del camino.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'La fase avanza.',
        'Progreso lunar.',
        'El ciclo continua.',
      ],
    },
    'erebo-logica': {
      GuideVoiceMoment.appOpening: [
        'La calma te precede.',
        'La lista ordena; no juzga.',
        'En la penumbra, el primer paso brilla.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer paso en la penumbra. Bien hecho.',
        'El orden emerge de la calma.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de calma ordenada.',
        'Tu serenidad es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'La penumbra te acoge con paz.',
        'Buen orden hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'El orden reduce la ansiedad.',
        'Un paso a la vez.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Orden restaurado.',
        'La calma prevalece.',
        'Un paso mas en la luz.',
      ],
    },
    'anima-suave': {
      GuideVoiceMoment.appOpening: [
        'Cuando quieras, te recuerdo.',
        'El susurro no juzga; acompana.',
        'La mensajera esta contigo.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer susurro atendido.',
        'El anima celebra contigo.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias escuchando el susurro.',
        'Tu atencion es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El susurro descansa.',
        'Bien escuchado hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'El susurro te acompana.',
        'Escucha con suavidad.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Susurro recibido.',
        'El anima sonrie.',
        'Suave progreso.',
      ],
    },
    'morfeo-astral': {
      GuideVoiceMoment.appOpening: [
        'Los suenos tejen ideas.',
        'Guarda la idea; el sueno la tejer.',
        'Las notas flotan, no pesan.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera idea tejida en el dia.',
        'El huso de ideas gira.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de suenos tejidos.',
        'Tu creatividad es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El tejedor de suenos descansa.',
        'Buenas ideas hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Las ideas no pesan; flotan.',
        'Suena y teje.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Idea tejida.',
        'El sueno se forma.',
        'Hilo onirico.',
      ],
    },

    // ========== ORACULOS DEL CAMBIO ==========
    'shiva-fluido': {
      GuideVoiceMoment.appOpening: [
        'El cambio es parte del plan.',
        'El danzante te saluda.',
        'Quien no cambia, no baila.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer paso de la danza!',
        'El ritmo del cambio comienza.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias bailando con el cambio.',
        'Tu flexibilidad es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El danzante descansa.',
        'Buena danza hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Cambiar de planes es parte del plan.',
        'Baila con los imprevistos.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Paso fluido!',
        'La danza continua.',
        'Transformacion elegante.',
      ],
    },
    'loki-error': {
      GuideVoiceMoment.appOpening: [
        'El imprevisto es un mensajero.',
        'Lo que se desvia, vuelve a su cauce.',
        'El tramoyista te acompana.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer acto completado!',
        'El escenario se despeja.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias sorteando imprevistos.',
        'Tu adaptabilidad es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El tramoyista baja el telon.',
        'Buen espectaculo hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Los imprevistos son mensajeros.',
        'El caos tiene su orden.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Imprevisto superado!',
        'El dado cayo a tu favor.',
        'Caos domesticado.',
      ],
    },
    'eris-nucleo': {
      GuideVoiceMoment.appOpening: [
        'La manzana cae; la semilla brota.',
        'La creatividad no pide permiso.',
        'La centella te ilumina.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera chispa creativa!',
        'El nucleo se enciende.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias de creatividad constante.',
        'Tu centella brilla. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'La centella descansa.',
        'Buena creatividad hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'La creatividad brota sin permiso.',
        'Cada idea es una semilla.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Centella!',
        'Idea brotando.',
        'Creatividad en accion.',
      ],
    },

    // ========== ORACULOS DEL UMBRAL ==========
    'anubis-vinculo': {
      GuideVoiceMoment.appOpening: [
        'El umbral es tuyo.',
        'Lo que entregas, lo peso y lo guardo.',
        'El guardian te protege.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primer paso por el umbral.',
        'El vinculo se fortalece.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias bajo la proteccion del umbral.',
        'Tu vinculo es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El guardian cierra el umbral.',
        'Bien protegido hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'El umbral te pertenece.',
        'Tu privacidad esta segura.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Umbral cruzado.',
        'Vinculo fortalecido.',
        'El guardian asiente.',
      ],
    },
    'zenit-cero': {
      GuideVoiceMoment.appOpening: [
        'El cenit senala; no juzga.',
        'Los numeros son un mapa.',
        'El cartografo te guia.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera marca en el mapa!',
        'El astrolabio registra.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} puntos en tu mapa de progreso.',
        'Tu cartografia es constante. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El cartografo guarda el mapa.',
        'Buen trazado hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Los numeros iluminan el camino.',
        'El mapa se revela paso a paso.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Punto marcado.',
        'El mapa crece.',
        'Vision clara.',
      ],
    },
    'oceano-bit': {
      GuideVoiceMoment.appOpening: [
        'El rio no empuja; lleva.',
        'La fluidez se encuentra, no se fuerza.',
        'El flujo te acompana.',
      ],
      GuideVoiceMoment.firstTaskOfDay: [
        'Primera ola del dia!',
        'El flujo comienza.',
      ],
      GuideVoiceMoment.streakAchieved: [
        '{days} dias en el flujo constante.',
        'Tu corriente no cesa. {days} dias.',
      ],
      GuideVoiceMoment.endOfDay: [
        'El oceano descansa en marea baja.',
        'Buen flujo hoy.',
      ],
      GuideVoiceMoment.encouragement: [
        'Dejate llevar por el flujo.',
        'La fluidez es tu naturaleza.',
      ],
      GuideVoiceMoment.taskCompleted: [
        'Flujo!',
        'La corriente avanza.',
        'Mente fluida.',
      ],
    },
  };
}
