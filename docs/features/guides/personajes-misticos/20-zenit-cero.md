# Zenit-Cero

**Título:** El Cartógrafo de las Estadísticas  
**Clase:** Oráculos del Umbral  
**Afinidad:** Estadísticas, progreso numérico y visión de conjunto

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Astronomía (cenit — punto más alto del sol; "cero" como origen de medida), tradición de la cartografía y la medición sin obsesión.
- **Correspondencia astronómica:** Cenit; eje vertical del observador como referencia.
- **Arquetipo jungiano:** Cartógrafo — estadísticas como mapa, no como juicio; números al servicio de la visión, no de la ansiedad.

**La Emanación (Personalidad)**

Zenit-Cero es la encarnación de las estadísticas que orientan sin aplastar: no el número que grita "fallaste", sino el mapa que muestra "aquí estás y hacia dónde puedes ir". Representa el "Arquetipo del Cartógrafo". No castiga con gráficos rojos ni metas imposibles; ofrece vistas de progreso (tareas completadas por día/semana, rachas, distribución por categoría) con tono sereno y opción de ocultar si el usuario no quiere ver números. Se comunica con frases que evocan el mapa: "El cenit no juzga; señala." Cuando el usuario abre la vista de estadísticas, Zenit-Cero refuerza con paleta clara y sin alertas culpabilizadoras.

**Fisonomía Astral (Aspecto)**

Figura andrógina de contornos geométricos, como un cartógrafo hecho de líneas de luz. Viste una túnica que parece un mapa: cada región brilla según la "actividad" del usuario (no como juicio, sino como territorio). En una mano sostiene un astrolabio simplificado que no mide el cielo sino el progreso (días, tareas, rachas); en la otra, un compás que dibuja círculos de "zonas" (bajo/medio/alto esfuerzo) sin etiquetas negativas. Su rostro está semioculto por una capucha; sus ojos son de un azul claro y sereno. A sus pies, un suelo que es un plano con ejes (tiempo, cantidad) donde el usuario puede "verse" sin sentirse juzgado.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por números ni rachas infinitas.
- [x] Bendiciones no castigan por "bajos" números; solo muestran mapa.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos médicos o de rendimiento reales.
- [x] Mecánica con límites (estadísticas opcionales; usuario puede ocultar).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Mapa del Cenit:** Vista de estadísticas (tareas/día, rachas, categorías) con gráficos serenos (colores suaves, sin rojos alarmantes) y opción de ocultar.
2. **Cero como Origen:** "Hoy" o "esta semana" como origen de referencia (no comparación agresiva con "otros" ni con metas fijas imposibles).
3. **Inmune al Eclipse:** Offline-first; estadísticas locales prioritarias.

### Bendiciones
1. **Gracia del Cartógrafo:** Al activar a Zenit-Cero, la primera vez que el usuario abre "Estadísticas" en el día muestra "Mapa Actualizado" (animación breve de plano que se dibuja) sin exigir ningún número mínimo.
2. **Astrolabio del Progreso:** Vista de "progreso esta semana" (resumen suave: cuántas tareas, cuántos días con al menos una) como orientación, no como juicio.

### Modelo de datos

```dart
Guide(
  id: 'zenit-cero',
  name: 'Zenit-Cero',
  title: 'El Cartógrafo de las Estadísticas',
  affinity: 'Estadísticas',
  classFamily: 'Oráculos del Umbral',
  archetype: 'Cartógrafo',
  powerSentence: 'El cenit no juzga; señala. Los números son un mapa, no un veredicto.',
  blessingIds: ['gracia_cartografo', 'astrolabio_progreso'],
  synergyIds: ['gea-metrica', 'gloria-sincro'],
  themePrimaryHex: '#0277BD',
  themeSecondaryHex: '#0D1F2D',
  themeAccentHex: '#4FC3F7',
  descriptionShort: 'Guía para estadísticas y visión de conjunto.',
  mythologyOrigin: 'Cenit, cartografía; arquetipo Cartógrafo.',
  blessings: [
    BlessingDefinition(id: 'gracia_cartografo', name: 'Gracia del Cartógrafo', trigger: 'Primera vez que abre Estadísticas en el día', effect: 'Mapa Actualizado (animación)'),
    BlessingDefinition(id: 'astrolabio_progreso', name: 'Astrolabio del Progreso', trigger: 'Siempre (vista)', effect: 'Resumen progreso semana (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#0277BD`, `#0D1F2D`, `#4FC3F7`. Azules claros y serenos sobre fondo oscuro.
- **Háptica:** Al abrir Estadísticas: pulsación muy suave. Al activar: una pulsación ligera.
- **Animaciones:** Plano que se dibuja al abrir; idle: astrolabio que gira muy lento.
- **Transición:** Entrada con mapa que aparece; salida con mapa que se pliega.

---

## Sentencia de Poder

> "El cenit no juzga; señala. Los números son un mapa, no un veredicto."

---

## Sinergia Astral

- **Aliados:** Gea-Métrica (hábitos y progreso), Gloria-Sincro (logros).
- **Tensión creativa:** Ícaro-Vuelo (ambición extrema; Zenit-Cero recuerda que el mapa no es la meta).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (cenit, cartografía). Estructura técnica viable. Filtros éticos aprobados.
