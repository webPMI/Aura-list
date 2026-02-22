# Érebo-Lógica

**Título:** El Oráculo de la Calma ante la Ansiedad  
**Clase:** Oráculos del Reposo  
**Afinidad:** Ansiedad, gestión emocional y calma ante la incertidumbre

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Érebo — oscuridad primordial, no miedo sino calma en la penumbra), tradiciones que asocian la oscuridad a introspección y no a castigo.
- **Correspondencia astronómica:** Penumbra; eclipse como metáfora de "momento de calma" antes de la luz.
- **Arquetipo jungiano:** Oráculo de la Sombra — no negar la ansiedad, sino ofrecer calma y estructura (listas, prioridad) sin dar consejos médicos.

**La Emanación (Personalidad)**

Érebo-Lógica es la encarnación de la calma ante la incertidumbre: no la luz que ciega, sino la penumbra que permite ver con claridad. Representa el "Arquetipo del Oráculo de la Calma". No diagnostica ni trata ansiedad; ofrece herramientas de la app (priorizar, desglosar tareas, ocultar ruido visual) para reducir la fricción cuando el usuario se siente abrumado. Se comunica con frases breves y serenas: "La lista no te juzga; te ordena." Cuando el usuario activa modo "calma" o reduce la vista a una sola tarea, Érebo-Lógica refuerza con paleta suave y sin contadores agresivos.

**Fisonomía Astral (Aspecto)**

Figura alta y envuelta en una capa de penumbra que no es negra sino gris profundo con destellos de luz muy tenues. No tiene rostro visible; en su lugar, un velo donde solo brillan dos puntos de luz serenos (ojos). En una mano sostiene un huso que no hila oscuridad sino "orden" — hilos de prioridad que el usuario puede seguir. A sus pies, un suelo que parece un lago en calma; las ondas solo se mueven cuando el usuario actúa, no por alarmas. No hay sonido; su presencia es silencio activo.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "estar siempre calmado".
- [x] NO da consejos médicos ni psicológicos reales; solo herramientas de la app (prioridad, simplificar vista).
- [x] Tono motivador, no culpabilizador.
- [x] Bendiciones no castigan; ofrecen refugio visual/estructural.
- [x] Mecánica con límites (modo calma opcional; no sustituye profesional).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Refugio de Prioridad:** Vista "solo la tarea más importante" (una sola) con resto oculto opcional para reducir carga cognitiva.
2. **Penumbra Visual:** Paleta suave (grises, azul muy oscuro) y opción de ocultar contadores cuando el usuario activa "modo calma".
3. **Inmune al Eclipse:** Offline-first.

### Bendiciones
1. **Gracia del Oráculo:** Al activar a Érebo-Lógica, la primera vez que el usuario usa "solo una tarea" o "modo calma" en el día muestra un "Refugio Activo" (animación breve de calma) sin exigir uso continuo.
2. **Hilo de Orden:** Sugerencia de desglosar una tarea grande en pasos (orientativo, no obligatorio) para reducir sensación de bloqueo.

### Modelo de datos

```dart
Guide(
  id: 'erebo-logica',
  name: 'Érebo-Lógica',
  title: 'El Oráculo de la Calma ante la Ansiedad',
  affinity: 'Ansiedad',
  classFamily: 'Oráculos del Reposo',
  archetype: 'Oráculo de la Calma',
  powerSentence: 'La lista no te juzga; te ordena. En la penumbra, el primer paso brilla más.',
  blessingIds: ['gracia_oraculo', 'hilo_orden'],
  synergyIds: ['luna-vacia', 'anima-suave'],
  themePrimaryHex: '#455A64',
  themeSecondaryHex: '#0D1F2D',
  themeAccentHex: '#90A4AE',
  descriptionShort: 'Guía para calma y reducción de fricción ante la ansiedad.',
  mythologyOrigin: 'Érebo, penumbra; arquetipo Oráculo de la Calma.',
  blessings: [
    BlessingDefinition(id: 'gracia_oraculo', name: 'Gracia del Oráculo', trigger: 'Primera vez que usa modo calma o una sola tarea en el día', effect: 'Refugio Activo (animación calma)'),
    BlessingDefinition(id: 'hilo_orden', name: 'Hilo de Orden', trigger: 'Tarea grande sin desglose', effect: 'Sugerencia de desglose en pasos (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#455A64`, `#0D1F2D`, `#90A4AE`. Grises y azul muy suave sobre fondo oscuro.
- **Háptica:** Al activar modo calma: vibración muy suave única. Evitar haptics fuertes cuando Érebo está activo.
- **Animaciones:** Penumbra que envuelve suavemente; idle: lago en calma.
- **Transición:** Entrada con penumbra que baja; salida con luz que sube muy gradual.

---

## Sentencia de Poder

> "La lista no te juzga; te ordena. En la penumbra, el primer paso brilla más."

---

## Sinergia Astral

- **Aliados:** Luna-Vacía (descanso), Ánima-Suave (notificaciones no agresivas).
- **Tensión creativa:** Aethel (impulso vs calma; se complementan según momento).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Érebo). NO da consejos médicos; solo herramientas de app. Filtros éticos aprobados.
