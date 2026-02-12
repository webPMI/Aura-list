# Océano-Bit

**Título:** El Flujo de la Fluidez Mental  
**Clase:** Oráculos del Umbral  
**Afinidad:** Fluidez mental, flujo de trabajo y estado flow

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Océano — titán del río que rodea el mundo; flujo perpetuo), tradición del "flow" como estado de fluidez (Csikszentmihalyi).
- **Correspondencia astronómica:** Océano como metáfora; corrientes que fluyen sin romper.
- **Arquetipo jungiano:** Flujo — fluidez mental, reducción de fricción, estado flow sin forzar.

**La Emanación (Personalidad)**

Océano-Bit es la encarnación del flujo que no se fuerza: no la productividad a gritos, sino la corriente que lleva cuando la fricción se reduce. Representa el "Arquetipo del Flujo". No exige "entrar en flow"; ofrece herramientas (modo foco, ocultar ruido, bloques de tiempo sugeridos) para que el usuario pueda encontrar su corriente. Se comunica con frases que evocan el agua: "El río no empuja; lleva." Cuando el usuario activa modo foco o completa varias tareas en secuencia sin distraerse, Océano-Bit refuerza con animación de "corriente" (fluidez visual) y tono sereno.

**Fisonomía Astral (Aspecto)**

Figura de contornos fluidos, como hecha de agua y luz. Viste una túnica que parece un río en movimiento — no violento, sino constante. En una mano sostiene un cántaro del que sale un flujo continuo de "bits" (pequeñas partículas de luz) que representan tareas o ideas en movimiento. En la otra, un remo que no rema contra la corriente sino que "guía" suavemente. Su rostro está semioculto por una capucha de agua; sus ojos son de un azul verdoso sereno. A sus pies, un suelo que es un río lento — las tareas completadas "fluyen" hacia adelante sin retroceso dramático.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "estar siempre en flow".
- [x] Bendiciones no castigan por distraerse; solo facilitan la fluidez cuando el usuario la busca.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos médicos o de rendimiento reales.
- [x] Mecánica con límites (modo foco opcional; sin presión).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Corriente Visible:** Modo "flujo" o "foco" que reduce ruido (notificaciones suaves, vista simplificada) cuando el usuario lo activa.
2. **Río de Tareas:** Vista de "tareas en secuencia" (lista ordenada sin saltos agresivos) para reducir fricción al completar varias seguidas.
3. **Inmune al Eclipse:** Offline-first; flujo local prioritario.

### Bendiciones
1. **Gracia del Flujo:** Al activar a Océano-Bit, la primera vez que el usuario completa 3 tareas seguidas sin salir de la app en la sesión muestra "Corriente Activa" (animación breve de flujo) sin exigir más.
2. **Cántaro del Bit:** Sugerencia suave de "¿Activar modo foco?" cuando el usuario tiene muchas tareas pendientes y lleva un rato en la lista (orientativo, no obligatorio).

### Modelo de datos

```dart
Guide(
  id: 'oceano-bit',
  name: 'Océano-Bit',
  title: 'El Flujo de la Fluidez Mental',
  affinity: 'Fluidez mental',
  classFamily: 'Oráculos del Umbral',
  archetype: 'Flujo',
  powerSentence: 'El río no empuja; lleva. La fluidez no se fuerza; se encuentra.',
  blessingIds: ['gracia_flujo', 'cantaro_bit'],
  synergyIds: ['aethel', 'chispa-azul'],
  themePrimaryHex: '#00838F',
  themeSecondaryHex: '#0D1F2D',
  themeAccentHex: '#4DD0E1',
  descriptionShort: 'Guía para fluidez mental y estado flow.',
  mythologyOrigin: 'Océano, flow; arquetipo Flujo.',
  blessings: [
    BlessingDefinition(id: 'gracia_flujo', name: 'Gracia del Flujo', trigger: 'Primera vez que completa 3 tareas seguidas sin salir de la app', effect: 'Corriente Activa (animación)'),
    BlessingDefinition(id: 'cantaro_bit', name: 'Cántaro del Bit', trigger: 'Muchas tareas pendientes + rato en lista', effect: 'Sugerencia de modo foco (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#00838F`, `#0D1F2D`, `#4DD0E1`. Azul verdoso y cyan sobre fondo oscuro.
- **Háptica:** Al completar secuencia: pulsación muy suave (ola). Al activar: una pulsación ligera.
- **Animaciones:** Corriente al completar tareas en secuencia; idle: río lento.
- **Transición:** Entrada con corriente que llega; salida con corriente que se aleja en calma.

---

## Sentencia de Poder

> "El río no empuja; lleva. La fluidez no se fuerza; se encuentra."

---

## Sinergia Astral

- **Aliados:** Aethel (impulso inicial), Chispa-Azul (tareas rápidas en secuencia).
- **Tensión creativa:** Luna-Vacía (descanso; el flujo no sustituye la pausa).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Océano, flow). Estructura técnica viable. Filtros éticos aprobados.
