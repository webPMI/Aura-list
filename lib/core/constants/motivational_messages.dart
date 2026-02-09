import 'dart:math';

/// A comprehensive collection of motivational messages in Spanish
/// for various occasions throughout the AuraList app experience.
///
/// Messages are designed to be warm, supportive, and genuinely motivating
/// without causing guilt or anxiety. They focus on progress over perfection.
class MotivationalMessages {
  static final Random _random = Random();

  // ============================================================
  // TASK COMPLETED - Celebratory and encouraging messages
  // ============================================================
  static final List<String> taskCompleted = [
    '¡Excelente trabajo! Cada tarea completada es un paso hacia tus metas.',
    '¡Lo lograste! Tu esfuerzo está dando frutos.',
    '¡Brillante! Estás construyendo el futuro que mereces.',
    '¡Tarea completada! Tu dedicación es inspiradora.',
    '¡Muy bien hecho! El progreso se nota.',
    '¡Fantástico! Sigue así, vas por buen camino.',
    '¡Increíble! Tu constancia es admirable.',
    '¡Genial! Cada logro cuenta, por pequeño que parezca.',
    '¡Felicidades! Estás haciendo un trabajo maravilloso.',
    '¡Perfecto! Tu compromiso contigo mismo es evidente.',
    '¡Asombroso! La disciplina que muestras es ejemplar.',
    '¡Eso es! El éxito se construye paso a paso.',
    '¡Maravilloso! Tu perseverancia está rindiendo frutos.',
    '¡Espectacular! Celebra este logro, te lo mereces.',
    '¡Qué bien! Estás superando tus propias expectativas.',
    '¡Impresionante! Tu energía positiva es contagiosa.',
    '¡Extraordinario! Cada tarea completada fortalece tu confianza.',
    '¡Sobresaliente! El camino al éxito está hecho de pequeños triunfos.',
    '¡Formidable! Tu actitud hacia el trabajo es admirable.',
    '¡Estupendo! La constancia siempre trae recompensas.',
    '🎉 ¡Lo hiciste! Otro paso más hacia tu mejor versión.',
    '⭐ ¡Brillante trabajo! Tu esfuerzo no pasa desapercibido.',
    '🌟 ¡Excepcional! Estás demostrando de lo que eres capaz.',
    '💪 ¡Fuerza! Cada tarea completada te hace más fuerte.',
    '🏆 ¡Victoria! Pequeños triunfos construyen grandes logros.',
    '✨ ¡Magnífico! Tu luz interior brilla con cada logro.',
    '🎯 ¡En el blanco! Tu enfoque está dando resultados.',
    '🚀 ¡Imparable! Estás elevando tu productividad.',
    '💫 ¡Espléndido! Tu dedicación es realmente inspiradora.',
    '🌈 ¡Colorido día! Este logro le da brillo a tu jornada.',
  ];

  // ============================================================
  // MORNING MOTIVATION - Starting a new day messages
  // ============================================================
  static final List<String> morningMotivation = [
    'Buenos días. Hoy es una nueva oportunidad para brillar.',
    'Un nuevo día comienza. ¿Qué pequeño paso darás hoy hacia tus sueños?',
    'Amanece con posibilidades infinitas. Elige una y hazla realidad.',
    'Cada mañana es un regalo. Ábrelo con gratitud y determinación.',
    'Hoy tienes 24 horas para crear algo hermoso. ¡Adelante!',
    'El sol sale de nuevo, y con él, nuevas oportunidades te esperan.',
    'Buenos días. Tu potencial es ilimitado, confía en ti.',
    'Empieza el día con calma. Las grandes cosas comienzan con pasos pequeños.',
    'Hoy es el día perfecto para avanzar hacia tus metas.',
    'Que este día te traiga claridad, energía y satisfacción.',
    'Un nuevo amanecer, una nueva página en tu historia. Escríbela bien.',
    'Buenos días. Recuerda: eres capaz de más de lo que imaginas.',
    'El día de hoy es único. Aprovéchalo a tu manera y ritmo.',
    'Que la tranquilidad te acompañe mientras conquistas el día.',
    'Despierta tu mejor versión. El mundo necesita lo que tú ofreces.',
    'Buenos días. Hoy puedes ser un poco mejor que ayer, y eso es suficiente.',
    'La mañana trae energía renovada. Úsala sabiamente.',
    'Cada día es una nueva aventura. ¿Qué descubrirás hoy?',
    'Comienza con intención. Terminarás con satisfacción.',
    'Buenos días. Tu bienestar es la prioridad de hoy.',
    '☀️ ¡Buenos días! El sol brilla para ti hoy.',
    '🌅 Un nuevo amanecer lleno de promesas te saluda.',
    '🌻 Que tu día florezca como un girasol al sol.',
    '☕ Buenos días. Toma un momento para ti antes de comenzar.',
    '🌤️ El día está lleno de luz. Déjala entrar en tu vida.',
    '🌸 Que este día sea tan especial como tú mereces.',
    '🎵 Buenos días. Que tu jornada tenga su propia melodía feliz.',
    '🦋 Hoy puedes transformarte. Cada día trae cambios positivos.',
    '🌞 El nuevo día te abraza con calidez y esperanza.',
    '🍀 Que la suerte te acompañe en todo lo que emprendas hoy.',
  ];

  // ============================================================
  // TASK OVERDUE - Gentle, understanding messages (not guilt-inducing)
  // ============================================================
  static final List<String> taskOverdue = [
    'Esta tarea sigue esperándote. Cuando estés listo, ahí estará.',
    'No pasa nada. A veces los planes cambian, y eso está bien.',
    'La vida tiene su propio ritmo. Puedes retomar esto cuando sea el momento.',
    'Esta tarea puede esperar. Tu bienestar no puede.',
    'Hay días más difíciles que otros. Sé amable contigo.',
    'Si no pudiste hacerlo antes, quizás había una buena razón.',
    'Recuerda: el progreso no siempre es lineal, y está bien.',
    'Esta tarea no define tu valor. Hazla cuando puedas.',
    'A veces posponer es escuchar lo que tu cuerpo necesita.',
    'No hay prisa perfecta. Avanza a tu propio paso.',
    'El tiempo pasado no regresa, pero el presente es tuyo.',
    'Quizás hoy sea el día. O quizás mañana. Ambos están bien.',
    'Las tareas pendientes no son fracasos, son oportunidades.',
    'Tu valor no se mide en tareas completadas a tiempo.',
    'Respira. Prioriza. Haz lo que puedas, cuando puedas.',
    'El pasado ya fue. Enfócate en lo que puedes hacer ahora.',
    'Cada momento es una nueva oportunidad para empezar.',
    'Sé compasivo contigo. Mañana es otro día.',
    'Esta tarea te espera pacientemente, sin juicios.',
    'Lo importante no es cuándo, sino que eventualmente lo logres.',
    '🌱 Las cosas crecen a su propio ritmo. Tú también.',
    '💙 Sé gentil contigo. El progreso tiene muchas formas.',
    '🕊️ Déjate llevar. Lo que debe hacerse, se hará.',
    '🌊 Como las olas, hay flujo y reflujo. Todo está bien.',
    '🍃 Deja ir la presión. Hazlo cuando sea el momento correcto.',
    '💆 Tu paz mental vale más que cualquier fecha límite.',
    '🌙 A veces necesitamos más tiempo. Eso es humano.',
    '🤗 Un abrazo virtual. Haz lo mejor que puedas, es suficiente.',
    '🧘 Respira profundo. Las tareas pueden esperar, tú no.',
    '💫 Todo llega a su tiempo. Confía en tu proceso.',
  ];

  // ============================================================
  // WEEKLY PROGRESS - Reflective and proud messages
  // ============================================================
  static final List<String> weeklyProgress = [
    'Mira todo lo que has logrado esta semana. Es más de lo que crees.',
    'Cada semana es un capítulo de tu historia. Este ha sido grandioso.',
    'Tu progreso semanal demuestra tu compromiso. Siéntete orgulloso.',
    'Una semana más de crecimiento. Celebra cada paso dado.',
    'Has trabajado duro. Tómate un momento para reconocerlo.',
    'La semana termina, pero tu impulso continúa. ¡Bravo!',
    'Reflexiona sobre tus logros. Son más valiosos de lo que parecen.',
    'Semana completada. Tu dedicación ha dejado huella.',
    'Mira atrás con orgullo. Has avanzado más de lo que imaginas.',
    'Cada semana sumamos experiencias. Esta ha sido enriquecedora.',
    'Tu esfuerzo semanal es la base de grandes logros futuros.',
    'Una semana de progreso real. Date el crédito que mereces.',
    'Los pequeños avances diarios crean grandes cambios semanales.',
    'Tu consistencia esta semana ha sido admirable. ¡Felicidades!',
    'Cerramos una semana productiva. Abre la siguiente con confianza.',
    'El tiempo invertido esta semana es una inversión en tu futuro.',
    'Cada tarea completada esta semana te acercó a tus sueños.',
    'Semana tras semana, estás construyendo algo hermoso.',
    'Tu progreso puede parecer lento, pero es constante y real.',
    'Mira tu semana con gratitud. Has hecho lo mejor que pudiste.',
    '📊 ¡Qué semana! Tu progreso es evidente y medible.',
    '🏅 Mereces reconocimiento por todo lo logrado estos días.',
    '📈 Tu curva de crecimiento esta semana es inspiradora.',
    '🎊 ¡Celebra! Una semana más de avances significativos.',
    '💪 Tu fuerza y determinación brillaron esta semana.',
    '🌟 Semana estelar. Tus esfuerzos han valido la pena.',
    '🎯 Objetivos cumplidos, metas alcanzadas. ¡Excelente semana!',
    '📅 Siete días de progreso constante. Eso es disciplina.',
    '🏆 Campeón de la semana. Tu dedicación es ejemplar.',
    '✨ Una semana que brilla por tus logros. ¡Felicidades!',
  ];

  // ============================================================
  // EMPTY TASK LIST - Encouraging to add tasks or celebrate
  // ============================================================
  static final List<String> emptyTaskList = [
    '¡Lista vacía! Momento perfecto para planificar algo especial.',
    'Sin tareas pendientes. ¿Hora de descansar o de soñar nuevo?',
    'Tu lista está libre. ¿Qué nueva aventura quieres emprender?',
    'Espacio en blanco, posibilidades infinitas. ¿Qué agregarás?',
    'Lista despejada. Disfruta el momento o crea nuevas metas.',
    '¡Todo completado! Mereces un momento de celebración.',
    'Sin pendientes. Perfecto para reflexionar sobre lo logrado.',
    'Tu lista está en cero. ¿Qué sueño quieres convertir en tarea?',
    'Lienzo en blanco. Pinta tu día con las tareas que te inspiren.',
    'Nada pendiente. Es un buen momento para cuidar de ti.',
    'Lista vacía significa logros alcanzados. ¡Bien hecho!',
    '¿Qué te gustaría lograr hoy? Tu lista espera tus ideas.',
    'Sin tareas. Perfecto para disfrutar o planificar con calma.',
    'El vacío también es logro. Disfrútalo o llénalo con propósito.',
    'Tu lista brilla por su vacío. ¿Qué le agregarás?',
    'Momento de pausa o de acción. Tú decides qué sigue.',
    'Lista despejada. El mundo está lleno de posibilidades.',
    'Sin pendientes. ¿Qué te haría feliz agregar hoy?',
    'Espacio libre para nuevos sueños y objetivos.',
    'Tu productividad dejó la lista vacía. ¡Impresionante!',
    '🎈 ¡Lista vacía! Tiempo de celebrar o crear nuevos planes.',
    '🌅 Horizonte despejado. ¿Qué aventura te espera?',
    '📝 Página en blanco. Escribe tu próxima historia de éxito.',
    '🎨 Tu lista es un lienzo. Píntala con tus aspiraciones.',
    '🌻 Sin tareas pendientes. El jardín está listo para nuevas semillas.',
    '🎯 Nueva oportunidad para definir tus próximas metas.',
    '💭 Momento perfecto para soñar y planificar.',
    '🌈 Lista limpia. ¿Qué colores quieres agregar hoy?',
    '🚀 Plataforma de lanzamiento lista. ¿Hacia dónde vamos?',
    '✨ Tu lista brilla por su claridad. ¿Qué nuevo brillo le darás?',
  ];

  // ============================================================
  // STREAK ACHIEVED - Consecutive days of completing tasks
  // ============================================================
  static final List<String> streakAchieved = [
    '¡Racha increíble! Tu constancia está creando hábitos poderosos.',
    '¡Días consecutivos de logros! Tu disciplina es admirable.',
    '¡Sigue así! Cada día que mantienes tu racha, creces más.',
    '¡Racha en fuego! Tu compromiso contigo mismo es inspirador.',
    '¡Impresionante consistencia! Los hábitos se forjan así.',
    '¡Tu racha crece! Estás demostrando de qué estás hecho.',
    '¡Días consecutivos de éxito! Tu futuro te lo agradecerá.',
    '¡Mantén la racha! Cada día cuenta en tu transformación.',
    '¡Qué constancia! Estás construyendo una versión increíble de ti.',
    '¡Racha imparable! Tu determinación no conoce límites.',
    '¡Otro día más! Tu perseverancia es tu superpoder.',
    '¡La racha continúa! Estás creando tu propia historia de éxito.',
    '¡Día tras día! Tu esfuerzo constante está dando frutos.',
    '¡Racha legendaria! Pocos tienen tu nivel de compromiso.',
    '¡Sigue adelante! Tu racha es prueba de tu fortaleza interior.',
    '¡Consistencia pura! Los grandes logros nacen de días como este.',
    '¡Tu racha brilla! Estás iluminando tu camino hacia el éxito.',
    '¡Días de gloria! Tu dedicación diaria es extraordinaria.',
    '¡Racha épica! Cada día sumado es una victoria.',
    '¡Imparable! Tu constancia está transformando tu vida.',
    '🔥 ¡Racha en llamas! Tu energía es contagiosa.',
    '⚡ ¡Electricidad pura! Tu racha está cargada de poder.',
    '🌟 ¡Estrella constante! Brillando día tras día.',
    '💎 ¡Racha de diamante! Tan valiosa como resistente.',
    '🏃 ¡Corredor incansable! Tu maratón de logros continúa.',
    '🎖️ ¡Medalla de constancia! Tu esfuerzo merece reconocimiento.',
    '🌊 ¡Ola imparable! Tu momentum es impresionante.',
    '⭐ ¡Superestrella! Tu racha ilumina tu camino.',
    '🦁 ¡Valentía diaria! Tu racha ruge con fuerza.',
    '🎯 ¡Puntería perfecta! Día tras día, dando en el blanco.',
  ];

  // ============================================================
  // RANDOM GETTERS - Easy access to random messages
  // ============================================================

  /// Returns a random celebratory message for task completion.
  static String get randomTaskCompleted =>
      taskCompleted[_random.nextInt(taskCompleted.length)];

  /// Returns a random morning motivation message.
  static String get randomMorningMotivation =>
      morningMotivation[_random.nextInt(morningMotivation.length)];

  /// Returns a random gentle message for overdue tasks.
  static String get randomTaskOverdue =>
      taskOverdue[_random.nextInt(taskOverdue.length)];

  /// Returns a random weekly progress review message.
  static String get randomWeeklyProgress =>
      weeklyProgress[_random.nextInt(weeklyProgress.length)];

  /// Returns a random message for empty task lists.
  static String get randomEmptyTaskList =>
      emptyTaskList[_random.nextInt(emptyTaskList.length)];

  /// Returns a random streak achievement message.
  static String get randomStreakAchieved =>
      streakAchieved[_random.nextInt(streakAchieved.length)];

  // ============================================================
  // FILTERED GETTERS - Messages with or without emojis
  // ============================================================

  /// Returns a random task completed message without emojis.
  static String get randomTaskCompletedNoEmoji =>
      _getRandomWithoutEmoji(taskCompleted);

  /// Returns a random morning motivation message without emojis.
  static String get randomMorningMotivationNoEmoji =>
      _getRandomWithoutEmoji(morningMotivation);

  /// Returns a random overdue task message without emojis.
  static String get randomTaskOverdueNoEmoji =>
      _getRandomWithoutEmoji(taskOverdue);

  /// Returns a random weekly progress message without emojis.
  static String get randomWeeklyProgressNoEmoji =>
      _getRandomWithoutEmoji(weeklyProgress);

  /// Returns a random empty task list message without emojis.
  static String get randomEmptyTaskListNoEmoji =>
      _getRandomWithoutEmoji(emptyTaskList);

  /// Returns a random streak achieved message without emojis.
  static String get randomStreakAchievedNoEmoji =>
      _getRandomWithoutEmoji(streakAchieved);

  /// Returns a random task completed message with emojis.
  static String get randomTaskCompletedWithEmoji =>
      _getRandomWithEmoji(taskCompleted);

  /// Returns a random morning motivation message with emojis.
  static String get randomMorningMotivationWithEmoji =>
      _getRandomWithEmoji(morningMotivation);

  /// Returns a random overdue task message with emojis.
  static String get randomTaskOverdueWithEmoji =>
      _getRandomWithEmoji(taskOverdue);

  /// Returns a random weekly progress message with emojis.
  static String get randomWeeklyProgressWithEmoji =>
      _getRandomWithEmoji(weeklyProgress);

  /// Returns a random empty task list message with emojis.
  static String get randomEmptyTaskListWithEmoji =>
      _getRandomWithEmoji(emptyTaskList);

  /// Returns a random streak achieved message with emojis.
  static String get randomStreakAchievedWithEmoji =>
      _getRandomWithEmoji(streakAchieved);

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Checks if a string contains common emoji Unicode ranges.
  static bool _containsEmoji(String text) {
    // Common emoji ranges
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
      unicode: true,
    );
    return emojiRegex.hasMatch(text);
  }

  /// Returns a random message from the list that doesn't contain emojis.
  static String _getRandomWithoutEmoji(List<String> messages) {
    final filtered = messages.where((m) => !_containsEmoji(m)).toList();
    if (filtered.isEmpty) return messages[_random.nextInt(messages.length)];
    return filtered[_random.nextInt(filtered.length)];
  }

  /// Returns a random message from the list that contains emojis.
  static String _getRandomWithEmoji(List<String> messages) {
    final filtered = messages.where((m) => _containsEmoji(m)).toList();
    if (filtered.isEmpty) return messages[_random.nextInt(messages.length)];
    return filtered[_random.nextInt(filtered.length)];
  }

  /// Returns a message appropriate for the given streak count.
  /// Higher streaks get more enthusiastic messages.
  static String getStreakMessage(int streakDays) {
    if (streakDays >= 30) {
      return '🏆 ¡$streakDays días de racha! Eres una leyenda de la constancia.';
    } else if (streakDays >= 14) {
      return '🔥 ¡$streakDays días consecutivos! Tu dedicación es extraordinaria.';
    } else if (streakDays >= 7) {
      return '⭐ ¡Una semana completa! $streakDays días de puro compromiso.';
    } else if (streakDays >= 3) {
      return '💪 ¡$streakDays días seguidos! El hábito se está formando.';
    } else {
      return randomStreakAchieved;
    }
  }

  /// Returns a contextual weekly progress message based on completion rate.
  static String getWeeklyProgressMessage(int completed, int total) {
    if (total == 0) {
      return 'Una semana de descanso también es válida. ¿Qué te gustaría lograr la próxima?';
    }

    final percentage = (completed / total * 100).round();

    if (percentage >= 90) {
      return '🌟 ¡$completed de $total tareas completadas! Semana excepcional.';
    } else if (percentage >= 70) {
      return '💪 $completed de $total tareas. ¡Gran progreso esta semana!';
    } else if (percentage >= 50) {
      return '👍 $completed de $total tareas. Buen avance, sigue adelante.';
    } else if (percentage >= 30) {
      return '🌱 $completed de $total tareas. Cada paso cuenta en tu camino.';
    } else {
      return '💙 $completed de $total tareas. Algunas semanas son más difíciles, y está bien.';
    }
  }

  /// Returns a time-appropriate greeting based on the hour of day.
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return randomMorningMotivation;
    } else if (hour >= 12 && hour < 18) {
      final afternoonMessages = [
        'Buenas tardes. El día aún tiene mucho por ofrecer.',
        'La tarde es perfecta para avanzar con calma.',
        'Mitad del día completada. ¿Cómo va todo?',
        '☀️ Buenas tardes. Tu energía sigue brillando.',
        'Tarde productiva por delante. ¡Tú puedes!',
      ];
      return afternoonMessages[_random.nextInt(afternoonMessages.length)];
    } else if (hour >= 18 && hour < 22) {
      final eveningMessages = [
        'Buenas noches. Momento de reflexionar sobre el día.',
        'La noche llega. Celebra lo que lograste hoy.',
        'Atardecer de logros. Descansa con satisfacción.',
        '🌙 Buenas noches. Has hecho suficiente por hoy.',
        'El día termina. Mañana hay nuevas oportunidades.',
      ];
      return eveningMessages[_random.nextInt(eveningMessages.length)];
    } else {
      final nightMessages = [
        'Noche tranquila. El descanso también es productivo.',
        'Si aún estás despierto, recuerda cuidarte.',
        '🌟 Las estrellas brillan. Tú también lo hiciste hoy.',
        'Hora de descansar. Mañana será otro gran día.',
        'Buenas noches. Tu bienestar es lo primero.',
      ];
      return nightMessages[_random.nextInt(nightMessages.length)];
    }
  }
}
