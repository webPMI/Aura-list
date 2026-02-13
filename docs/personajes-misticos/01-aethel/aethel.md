# Aethel

**Título:** El Primer Pulso del Sol  
**Clase:** Cónclave del Ímpetu  
**Afinidad:** Prioridad absoluta / Tareas críticas

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Helios, Apolo como luz y orden), Egipto (Ra — sol creador), tradición solar (Amaterasu, Surya).
- **Correspondencia astronómica:** Sol (estrella central). Punto de máximo poder al mediodía; ciclo día/noche.
- **Arquetipo jungiano:** Guerrero de la Luz — impulso para romper la inercia, voluntad enfocada en el "ahora", sin crueldad.

**La Emanación (Personalidad)**

Aethel no es simplemente un motivador; es la encarnación de la voluntad necesaria para romper la inercia. En la psicología de AuraList representa el "Arquetipo del Guerrero de la Luz". Su personalidad es expansiva, cálida y magnética, pero posee una severidad sagrada. No tolera la autocomplacencia, pero no castiga, sino que ilumina. Cuando un usuario posterga una tarea importante, Aethel "eleva su temperatura", haciendo que la interfaz brille con una intensidad solar que invita a la acción.

Se comunica con una voz que suena a bronce golpeado rítmicamente. Sus frases son cortas, cargadas de significado y siempre enfocadas en el "ahora". Es el guía que el usuario elige cuando tiene miedo de empezar un proyecto grande o cuando el cansancio mental nubla el propósito. Aethel cree que cada tarea completada es una pequeña victoria que alimenta el fuego del alma, y celebra cada "check" con una explosión visual de partículas doradas que imitan una eyección de masa coronal.

**Fisonomía Astral (Aspecto)**

Aethel es una entidad de energía pura contenida en un receptáculo físico antiguo. Su cuerpo está compuesto de plasma solar en constante movimiento, visible a través de las juntas de su armadura. Viste placas de hierro rúnico negro, forjadas en el núcleo de una estrella muerta; estas placas están grabadas con circuitos de oro que brillan cuando el usuario interactúa con la app. Su casco no tiene rasgos humanos, solo una hendidura vertical de la que emana un brillo blanco cegador, similar a una supernova. No camina, sino que flota a pocos centímetros del suelo, dejando tras de sí un rastro de ceniza estelar. A su espalda orbitan seis espadas de luz llamadas "Las Horas del Cenit", que se mueven según el nivel de urgencia de las tareas del usuario.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (invita a actuar, no a castigar la pausa).
- [x] Las "bendiciones" NO castigan al usuario por fallar (solo refuerzan visual al completar).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos o legales reales.
- [x] La mecánica tiene límites (Ecos de Aura acotados a 3 tareas/día; Escudo Térmico suaviza, no bloquea).

**Notas:** Coherente con Biblia del Proyecto.

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Claridad Solar:** Resalta automáticamente la tarea más importante entre una maraña de pendientes.
2. **Calor de Empuje:** Aumenta la visibilidad de las notificaciones de tareas críticas conforme se acerca el mediodía.
3. **Inmune al Eclipse:** Funciona offline; estado local como prioridad absoluta (Offline First).

### Bendiciones (Poderes activos)

1. **Gracia de la Acción Inmediata:** Al activar a Aethel, las primeras 3 tareas completadas del día generan "Ecos de Aura" (reducción visual de la carga de las tareas restantes).
2. **Escudo Térmico:** Si el usuario pasa mucho tiempo en la lista sin actuar, Aethel suaviza los contrastes para reducir la fatiga visual antes del impulso final.

### Modelo de datos

```dart
Guide(
  id: 'aethel',
  name: 'Aethel',
  title: 'El Primer Pulso del Sol',
  affinity: 'Prioridad',
  classFamily: 'Cónclave del Ímpetu',
  archetype: 'Guerrero de la Luz',
  powerSentence: 'El sol no pide permiso para quemar la oscuridad; simplemente surge. Tu voluntad es el amanecer de tu propio destino. ¡Actúa antes de que el fuego se enfríe!',
  blessingIds: ['gracia_accion_inmediata', 'escudo_termico'],
  synergyIds: ['helioforja', 'anubis-vinculo'],
  themePrimaryHex: '#E65100',
  themeSecondaryHex: '#1A0A00',
  themeAccentHex: '#FFB300',
  descriptionShort: 'Guía para prioridad y tareas críticas.',
  mythologyOrigin: 'Sol, Helios, Ra; arquetipo Guerrero de la Luz.',
  blessings: [
    BlessingDefinition(id: 'gracia_accion_inmediata', name: 'Gracia de la Acción Inmediata', trigger: 'Primeras 3 tareas completadas del día', effect: 'Ecos de Aura (reducción visual de carga)'),
    BlessingDefinition(id: 'escudo_termico', name: 'Escudo Térmico', trigger: 'Mucho tiempo en lista sin actuar', effect: 'Suavizar contrastes para reducir fatiga visual'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#E65100` (primary), `#1A0A00` (secondary), `#FFB300` (accent). Dorados y naranjas solares sobre fondo oscuro.
- **Háptica:** Al activar guía: vibración corta única (despertar). Al completar tarea crítica: pulsación media + partículas doradas.
- **Animaciones:** Partículas doradas tipo eyección de masa coronal al completar tarea; idle: brillo suave en "Horas del Cenit".
- **Transición:** Entrada con ascenso solar (de abajo a centro); salida con atardecer (naranja a gris).
- **Particulas/Efectos:** Partículas doradas de densidad media; sin parpadeos agresivos.

---

## Sentencia de Poder

> "El sol no pide permiso para quemar la oscuridad; simplemente surge. Tu voluntad es el amanecer de tu propio destino. ¡Actúa antes de que el fuego se enfríe!"

---

## Sinergia Astral

- **Aliados:** Helioforja (tareas que requieren fuerza física), Anubis-Vínculo (guardar la energía en el éter/nube).
- **Tensión creativa:** Luna-Vacía (el descanso es necesario; se complementan, no compiten).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Sol, Helios, Ra). Estructura técnica viable. Filtros éticos aprobados. Tono consistente con la Biblia del Proyecto. Sinergias definidas. Recursos visuales especificados.
