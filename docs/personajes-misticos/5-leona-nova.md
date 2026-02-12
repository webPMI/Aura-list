# Leona-Nova

**Título:** La Soberana del Ritmo Solar  
**Clase:** Cónclave del Ímpetu  
**Afinidad:** Disciplina, orden y constancia

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Egipto (Sekhmet — leona solar, poder controlado), Grecia/Roma (Leo como constelación regia), tradición solar (Amaterasu, diosas solares).
- **Correspondencia astronómica:** Sol en Leo; estrella Regulus (corazón del león). Leo como constelación de realeza y fuego contenido.
- **Arquetipo jungiano:** Soberano, Disciplinado — orden y constancia sin crueldad; la leona que caza con estrategia, no con caos.

**La Emanación (Personalidad)**

Leona-Nova es la encarnación de la disciplina que no grita: la que se levanta a la misma hora, cumple el ritual y avanza sin necesidad de aplausos. En la psicología de AuraList representa el "Arquetipo de la Soberana": quien gobierna su propio tiempo y espacio con calma y firmeza. No es la furia de Sekhmet desatada, sino la Sekhmet que protege el orden cósmico — poder al servicio de la ley interior.

Se comunica con frases serenas y afirmativas, como decretos suaves. No amenaza; recuerda. Es el guía que el usuario elige cuando quiere construir rutinas, bloques de trabajo o hábitos de orden (limpieza, horarios, repasos). Su voz evoca el rumor del viento en la sabana al amanecer — presencia tranquila y segura. Cuando el usuario cumple una racha de días con tareas completadas en horario, Leona-Nova hace que la interfaz muestre un destello dorado discreto y una transición de color hacia tonos cálidos pero contenidos, reforzando la sensación de "reinado interior".

**Fisonomía Astral (Aspecto)**

Figura femenina de rasgos nobles, con melena de llamas doradas contenidas que no queman, sino que irradian luz estable. Viste una armadura ligera de escamas doradas y óxido suave, evocando el atuendo de una soberana guerrera. Su cabeza está coronada por un diadema que incorpora el símbolo de Leo; sus ojos son de un ámbar sereno. No lleva armas visibles; en una mano sostiene un cetro de luz que termina en una esfera solar pequeña. A sus pies, un mosaico de baldosas que representan los días de la semana se ilumina según el progreso del usuario. Flota sobre un suelo de mármol astral; a su espalda, la silueta de un león acostado, en calma.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (disciplina como apoyo, no como obligación rígida).
- [x] Las "bendiciones" NO castigan al usuario por fallar (refuerzan rachas sin romper la experiencia si se pierde un día).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos o legales reales.
- [x] La mecánica tiene límites (rachas y recordatorios acotados; no loops infinitos).

**Notas:** "Manto de la Constancia" (o equivalente) puede ofrecer una oportunidad de redención visual sin castigar; coherente con Crono-Velo.

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Ojo del Ritmo:** Muestra una vista simplificada de "rachas" o consistencia semanal (días con al menos una tarea completada) sin exagerar números.
2. **Corona del Orden:** Permite agrupar o filtrar tareas por "bloque horario" o etiqueta de rutina cuando el guía está activo.
3. **Inmune al Eclipse:** Funciona offline; preferencias y rachas locales tienen prioridad.

### Bendiciones (Poderes activos)

1. **Gracia de la Corona:** Al activar a Leona-Nova, el primer día que el usuario complete al menos una tarea en cada bloque horario configurado (mañana/tarde/noche) recibe un "Sello Solar" visual discreto (badge o animación suave).
2. **Manto de la Constancia:** Si el usuario pierde un día en una racha larga, Leona-Nova ofrece una única "segunda oportunidad" al día siguiente: la racha no se rompe visualmente si se completan las tareas críticas del día de redención (límite: una vez por racha).

### Modelo de datos

```dart
Guide(
  id: 'leona-nova',
  name: 'Leona-Nova',
  title: 'La Soberana del Ritmo Solar',
  affinity: 'Disciplina',
  classFamily: 'Cónclave del Ímpetu',
  archetype: 'Soberana',
  powerSentence: 'La corona no se lleva en la cabeza; se teje con cada amanecer en el que eliges volver a empezar.',
  blessingIds: ['gracia_corona', 'manto_constancia'],
  synergyIds: ['crono-velo', 'gea-metrica'],
  themePrimaryHex: '#B8860B',
  themeSecondaryHex: '#2A1810',
  themeAccentHex: '#FFD700',
  descriptionShort: 'Guía para disciplina y ritmos constantes.',
  mythologyOrigin: 'Sol en Leo, Sekhmet, Regulus; constelación Leo.',
  blessings: [
    BlessingDefinition(id: 'gracia_corona', name: 'Gracia de la Corona', trigger: 'Primer día con al menos una tarea completada en cada bloque horario', effect: 'Sello Solar visual'),
    BlessingDefinition(id: 'manto_constancia', name: 'Manto de la Constancia', trigger: 'Día siguiente a fallar una racha; usuario completa tareas críticas', effect: 'Racha no se rompe visualmente (una vez por racha)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#B8860B` (primary), `#2A1810` (secondary), `#FFD700` (accent). Dorados cálidos sobre fondo oscuro; sin brillos agresivos.
- **Háptica:** Al activar guía: vibración suave única (presencia). Al completar tarea que mantiene racha: pulsación muy ligera.
- **Animaciones:** Melena de llamas con movimiento lento en idle; al recibir Sello Solar, breve destello dorado y partículas discretas.
- **Transición:** Entrada con ascenso suave (de abajo a centro); salida con atardecer (dorado a gris).
- **Particulas/Efectos:** Partículas doradas de baja densidad; sensación de estabilidad, no de explosión.

---

## Sentencia de Poder

> "La corona no se lleva en la cabeza; se teje con cada amanecer en el que eliges volver a empezar. Tu ritmo es tu reino."

---

## Sinergia Astral

- **Aliados:** Crono-Velo (recurrencia y hábitos), Gea-Métrica (los hábitos dan frutos visibles).
- **Tensión creativa:** Loki-Error (los imprevistos desafían el orden; Leona-Nova ayuda a reordenar sin culpa).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Leo, Sekhmet, Regulus). Estructura técnica viable. Filtros éticos aprobados. Tono consistente. Sinergias definidas. Recursos visuales especificados.
