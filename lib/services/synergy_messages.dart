/// Mensajes poéticos de sinergia entre pares específicos de Guías Celestiales.
///
/// Cada mensaje celebra la complementariedad entre dos guías,
/// usando metáforas que honran sus mitologías y afinidades.
///
/// Filosofía:
/// - Los mensajes son motivacionales, nunca críticos
/// - Celebran la elección del usuario, no la imponen
/// - Usan lenguaje poético coherente con el tono de AuraList
library;

/// Mapa de sinergias específicas entre guías.
/// La clave es '{guideId1}_{guideId2}' (orden alfabético de IDs).
final Map<String, String> kSynergyMessages = {
  // Aethel + Helioforja
  'aethel_helioforja':
      'El fuego de la prioridad alimenta la forja del esfuerzo. '
      'Juntos, Aethel y Helioforja transforman la urgencia en acción tempered by discipline.',

  // Aethel + Anubis-Vínculo
  'aethel_anubis-vinculo':
      'El sol que ilumina y el guardián que protege. '
      'Aethel marca las prioridades mientras Anubis custodia cada paso en el umbral.',

  // Crono-Velo + Gea-Métrica
  'crono-velo_gea-metrica':
      'El tejedor del tiempo y la guardiana de los frutos. '
      'Crono-Velo teje los días mientras Gea-Métrica nutre cada semilla de hábito.',

  // Crono-Velo + Pacha-Nexo
  'crono-velo_pacha-nexo':
      'El perpetuo y el ecosistema se entrelazan. '
      'Crono-Velo mantiene el ritmo mientras Pacha-Nexo organiza los dominios de tu vida.',

  // Luna-Vacía + Morfeo-Astral
  'luna-vacia_morfeo-astral':
      'El silencio protege los sueños; las ideas flotan en calma. '
      'Luna-Vacía crea el espacio donde Morfeo-Astral teje las notas del alma.',

  // Luna-Vacía + Loki-Error
  'loki-error_luna-vacia':
      'El descanso acepta el imprevisto sin juicio. '
      'Luna-Vacía ofrece refugio mientras Loki-Error transforma el caos en aprendizaje.',

  // Helioforja + Anubis-Vínculo
  'anubis-vinculo_helioforja':
      'La forja que crea y el guardián que preserva. '
      'Helioforja construye con esfuerzo, Anubis-Vínculo protege cada logro.',

  // Leona-Nova + Crono-Velo
  'crono-velo_leona-nova':
      'La corona del sol y el telar del perpetuo. '
      'Leona-Nova reina sobre la disciplina, Crono-Velo sostiene cada ciclo.',

  // Leona-Nova + Gea-Métrica
  'gea-metrica_leona-nova':
      'El ritmo solar nutre los hábitos que dan fruto. '
      'Leona-Nova marca el compás, Gea-Métrica celebra cada cosecha.',

  // Chispa-Azul + Aethel
  'aethel_chispa-azul':
      'El relámpago que ejecuta y el sol que prioriza. '
      'Chispa-Azul actúa con velocidad, Aethel ilumina qué merece el primer golpe.',

  // Chispa-Azul + Loki-Error
  'chispa-azul_loki-error':
      'La rapidez acepta el desvío sin perder momentum. '
      'Chispa-Azul avanza ligero, Loki-Error ajusta el rumbo con gracia.',

  // Gloria-Sincro + Aethel
  'aethel_gloria-sincro':
      'La llama del amanecer teje coronas de logro. '
      'Aethel impulsa la acción, Gloria-Sincro honra cada conquista.',

  // Gloria-Sincro + Gea-Métrica
  'gea-metrica_gloria-sincro':
      'Los frutos cosechados se convierten en símbolos de victoria. '
      'Gea-Métrica siembra con paciencia, Gloria-Sincro celebra la abundancia.',

  // Pacha-Nexo + Gea-Métrica
  'gea-metrica_pacha-nexo':
      'El ecosistema organizado nutre hábitos interconectados. '
      'Pacha-Nexo teje los dominios, Gea-Métrica hace florecer cada territorio.',

  // Selene-Fase + Luna-Vacía
  'luna-vacia_selene-fase':
      'La luna vacía acoge las fases sin prisa. '
      'Luna-Vacía protege el descanso, Selene-Fase honra el crecimiento gradual.',

  // Selene-Fase + Crono-Velo
  'crono-velo_selene-fase':
      'El ciclo perpetuo y las fases lunares bailan juntos. '
      'Crono-Velo sostiene el ritmo, Selene-Fase celebra cada etapa del camino.',

  // Viento-Estación + Crono-Velo
  'crono-velo_viento-estacion':
      'El tejedor del tiempo ajusta las velas según la estación. '
      'Crono-Velo mantiene el compás, Viento-Estación navega cada cambio.',

  // Viento-Estación + Pacha-Nexo
  'pacha-nexo_viento-estacion':
      'Las estaciones del año organizan el ecosistema vital. '
      'Pacha-Nexo distribuye energía, Viento-Estación guía la transición.',

  // Atlas-Orbital + Anubis-Vínculo
  'anubis-vinculo_atlas-orbital':
      'El sustentador y el guardián protegen lo construido. '
      'Atlas-Orbital mantiene la órbita, Anubis-Vínculo custodia el vínculo.',

  // Atlas-Orbital + Fenix-Datos (futura implementación)
  'atlas-orbital_fenix-datos':
      'La órbita estable y el renacimiento de los datos. '
      'Atlas-Orbital sostiene, Fénix-Datos restaura cuando es necesario.',

  // Érebo-Lógica + Luna-Vacía
  'erebo-logica_luna-vacia':
      'La penumbra calma la ansiedad; el vacío acoge sin juicio. '
      'Érebo-Lógica ordena el caos interno, Luna-Vacía ofrece refugio.',

  // Érebo-Lógica + Ánima-Suave
  'anima-suave_erebo-logica':
      'El susurro suave ilumina la penumbra con gentileza. '
      'Érebo-Lógica reduce la fricción, Ánima-Suave acompaña sin presionar.',

  // Ánima-Suave + Luna-Vacía
  'anima-suave_luna-vacia':
      'El susurro respeta el silencio; ambos protegen tu paz. '
      'Ánima-Suave te recuerda con dulzura, Luna-Vacía te da permiso para pausar.',

  // Morfeo-Astral + Érebo-Lógica
  'erebo-logica_morfeo-astral':
      'Los sueños flotan en la calma de la penumbra. '
      'Morfeo-Astral teje ideas, Érebo-Lógica las ordena sin ansiedad.',

  // Shiva-Fluido + Loki-Error
  'loki-error_shiva-fluido':
      'El danzante del cambio y el tramoyista del imprevisto celebran la flexibilidad. '
      'Shiva-Fluido ajusta planes, Loki-Error transforma obstáculos en oportunidades.',

  // Shiva-Fluido + Érebo-Lógica
  'erebo-logica_shiva-fluido':
      'El cambio fluye sin resistencia en la calma de la penumbra. '
      'Shiva-Fluido danza con lo nuevo, Érebo-Lógica lo recibe sin ansiedad.',

  // Loki-Error + Fenix-Datos (futura implementación)
  'fenix-datos_loki-error':
      'El imprevisto encuentra redención en el renacimiento. '
      'Loki-Error acepta el error, Fénix-Datos restaura lo perdido.',

  // Eris-Núcleo + Vesta-Llama (futura implementación)
  'eris-nucleo_vesta-llama':
      'La centella de creatividad enciende la llama sagrada del hogar interno. '
      'Eris-Núcleo despierta ideas, Vesta-Llama las protege y nutre.',

  // Eris-Núcleo + Pacha-Nexo
  'eris-nucleo_pacha-nexo':
      'La creatividad florece cuando el ecosistema está organizado. '
      'Eris-Núcleo libera la chispa, Pacha-Nexo le da espacio para crecer.',

  // Anubis-Vínculo + Aethel
  // (ya definido arriba como 'aethel_anubis-vinculo')

  // Zenit-Cero + Gea-Métrica
  'gea-metrica_zenit-cero':
      'El cartógrafo mapea los frutos que la tierra ha dado. '
      'Gea-Métrica cultiva hábitos, Zenit-Cero revela el panorama completo.',

  // Zenit-Cero + Gloria-Sincro
  'gloria-sincro_zenit-cero':
      'Las estadísticas tejen el mapa de tus victorias. '
      'Gloria-Sincro celebra logros, Zenit-Cero muestra el camino recorrido.',

  // Océano-Bit + Aethel
  'aethel_oceano-bit':
      'El sol del amanecer impulsa la corriente del flujo mental. '
      'Aethel enciende la voluntad, Océano-Bit la sostiene en estado de gracia.',

  // Océano-Bit + Chispa-Azul
  'chispa-azul_oceano-bit':
      'El relámpago veloz fluye como río sin resistencia. '
      'Chispa-Azul ejecuta con rapidez, Océano-Bit mantiene el momentum.',
};

/// Obtiene el mensaje de sinergia específico entre dos guías.
///
/// Retorna null si no existe un mensaje específico para ese par.
/// El orden de los IDs no importa (se normaliza internamente).
String? getSynergyMessage(String guideId1, String guideId2) {
  // Normalizar el orden (alfabético) para buscar en el mapa
  final ids = [guideId1, guideId2]..sort();
  final key = ids.join('_');
  return kSynergyMessages[key];
}

/// Obtiene todos los pares de guías que tienen mensajes de sinergia específicos.
List<({String guide1, String guide2, String message})> getAllSynergyPairs() {
  final pairs = <({String guide1, String guide2, String message})>[];

  for (final entry in kSynergyMessages.entries) {
    final ids = entry.key.split('_');
    if (ids.length == 2) {
      pairs.add((
        guide1: ids[0],
        guide2: ids[1],
        message: entry.value,
      ));
    }
  }

  return pairs;
}

/// Verifica si existe un mensaje de sinergia específico entre dos guías.
bool hasSynergyMessage(String guideId1, String guideId2) {
  return getSynergyMessage(guideId1, guideId2) != null;
}
