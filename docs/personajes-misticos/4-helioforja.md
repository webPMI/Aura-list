# Helioforja

**Título:** La Forja del Sol Rojo  
**Clase:** Cónclave del Ímpetu  
**Afinidad:** Esfuerzo físico, resistencia y tareas que demandan cuerpo

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Ares, Heracles), Egipto (Horus como guerrero solar), Nórdico (Tyr — sacrificio y valor en combate).
- **Correspondencia astronómica:** Marte (planeta rojo). Orión (cazador) como constelación de fuerza y persecución del objetivo.
- **Arquetipo jungiano:** Guerrero, Atleta, Forjador — impulso físico y resistencia, no crueldad.

**La Emanación (Personalidad)**

Helioforja es la encarnación del esfuerzo que se siente en el cuerpo: el sudor, el latido del corazón, la tensión muscular. No es la violencia de Ares desatada, sino la forja de Vulcano — el fuego contenido que transforma el metal. En la psicología de AuraList representa el "Arquetipo del Forjador": quien convierte la intención en acto mediante trabajo sostenido y físico.

Se comunica con frases breves y rítmicas, como el golpe del martillo sobre el yunque. No castiga la inactividad; invita a "calentar el cuerpo" antes de la tarea. Es el guía que el usuario elige cuando tiene tareas de ejercicio, mudanza, reparaciones o cualquier labor que exija presencia corporal. Su voz evoca el sonido del metal al enfriarse en agua — un siseo de conclusión satisfactoria. Cuando el usuario completa una tarea marcada como esfuerzo físico, Helioforja hace que la interfaz emita una pulsación roja suave y una breve vibración de "impacto" (haptic), reforzando la sensación de haber "forjado" un logro.

**Fisonomía Astral (Aspecto)**

Humanoide de complexión poderosa, envuelto en un delantal de forjador hecho de escamas de dragón mineral. Sus brazos están recubiertos de brazaletes de cobre que brillan con el calor interno. No lleva espada; lleva un martillo de luz naranja-roja que descansa sobre un yunque flotante. Su rostro está oculto tras una máscara de herrero con una única ranura por la que se ve el fulgor del horno. A su alrededor flotan chispas que se mueven según el progreso del usuario en tareas de esfuerzo físico. El suelo bajo sus pies es una plancha de metal que refleja el cielo estrellado, como si la forja estuviera en el vacío.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (invita a esfuerzo sostenido, no a castigo por no entrenar).
- [x] Las "bendiciones" NO castigan al usuario por fallar (solo refuerzan visual/haptic al completar).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos reales (no sustituye a un profesional del deporte o salud).
- [x] La mecánica tiene límites (vibración y feedback acotados).

**Notas:** Ninguna bendición condiciona el bienestar a "no fallar"; solo celebran el logro.

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Fuerza de la Forja:** Resalta o agrupa tareas categorizadas como "esfuerzo físico" (o etiqueta equivalente) en la lista.
2. **Latido del Yunque:** Aumenta la intensidad del feedback haptic al completar una tarea de esfuerzo físico (patrón corto de "impacto").
3. **Inmune al Eclipse:** Funciona offline; el estado local tiene prioridad (alineado con estrategia offline-first).

### Bendiciones (Poderes activos)

1. **Gracia del Primer Golpe:** Al activar a Helioforja, las primeras 2 tareas de esfuerzo físico completadas del día generan "Ecos de Aura" (reducción visual de carga) y un haptic de celebración.
2. **Escudo Térmico del Forjador:** Si el usuario lleva más de N tareas de esfuerzo completadas en la semana, la paleta suaviza ligeramente los rojos para no sobreestimular (límite de diseño, no castigo).

### Modelo de datos

```dart
Guide(
  id: 'helioforja',
  name: 'Helioforja',
  title: 'La Forja del Sol Rojo',
  affinity: 'Esfuerzo físico',
  classFamily: 'Cónclave del Ímpetu',
  archetype: 'Forjador',
  powerSentence: 'No es el golpe único el que forja el acero, sino la constancia del fuego.',
  blessingIds: ['gracia_primer_golpe', 'escudo_termico_forjador'],
  synergyIds: ['aethel', 'anubis-vinculo'],
  themePrimaryHex: '#8B2500',
  themeSecondaryHex: '#2C1810',
  themeAccentHex: '#E85D04',
  descriptionShort: 'Guía para tareas que demandan esfuerzo corporal.',
  mythologyOrigin: 'Marte, Ares, Horus, Tyr; constelación Orión.',
  blessings: [
    BlessingDefinition(id: 'gracia_primer_golpe', name: 'Gracia del Primer Golpe', trigger: 'Al completar las 2 primeras tareas de esfuerzo físico del día', effect: 'Ecos de Aura + haptic celebración'),
    BlessingDefinition(id: 'escudo_termico_forjador', name: 'Escudo Térmico del Forjador', trigger: 'Semana con muchas tareas de esfuerzo completadas', effect: 'Suavizar rojos en paleta'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#8B2500` (primary), `#2C1810` (secondary), `#E85D04` (accent). Fondos oscuros con toques de rojo forja.
- **Háptica:** Al activar guía: vibración corta doble (martillo-yunque). Al completar tarea de esfuerzo: patrón "impacto" (1 pulsación media).
- **Animaciones:** Chispas sutiles en el avatar en idle; al completar tarea de esfuerzo, breve destello rojo y partículas de ceniza que se apagan.
- **Transición:** Entrada con fundido desde naranja a rojo; salida con enfriamiento (rojo a gris oscuro).
- **Particulas/Efectos:** Chispas flotantes de baja densidad; sin parpadeos agresivos.

---

## Sentencia de Poder

> "No es el golpe único el que forja el acero, sino la constancia del fuego. Tu cuerpo es el yunque; la voluntad, el martillo."

---

## Sinergia Astral

- **Aliados:** Aethel (prioridad para empezar), Anubis-Vínculo (guardar el esfuerzo en el éter/nube).
- **Tensión creativa:** Luna-Vacía (el descanso es necesario tras la forja; no compiten, se complementan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Marte, Ares, Tyr, Orión). Estructura técnica viable con `Guide` y `BlessingDefinition`. Filtros éticos aprobados. Tono consistente con la Biblia del Proyecto. Sinergias definidas. Recursos visuales especificados (paleta, haptics, animaciones).
