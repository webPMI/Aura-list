# Ánima-Suave

**Título:** La Mensajera del Susurro  
**Clase:** Oráculos del Reposo  
**Afinidad:** Notificaciones, recordatorios suaves y comunicación no intrusiva

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Psique — alma; mensajes del alma), Roma (Anima como alma femenina en Jung), tradiciones del "susurro" como guía.
- **Correspondencia astronómica:** Luz tenue; estrella de la mañana como "recordatorio suave" del nuevo día.
- **Arquetipo jungiano:** Mensajera Suave — notificaciones que guían sin alarmar, recordatorios que respetan el ritmo del usuario.

**La Emanación (Personalidad)**

Ánima-Suave es la encarnación del recordatorio que no grita: no la alarma que despierta con pánico, sino el susurro que recuerda con calma. Representa el "Arquetipo de la Mensajera Suave". No bombardea con notificaciones; ofrece recordatorios configurables (hora, tipo de tarea) con tono sereno y opción de posponer sin culpa. Se comunica con frases breves y cálidas: "Cuando quieras, te recuerdo." Cuando el usuario recibe una notificación con Ánima-Suave activa, el sonido y la vibración son suaves (configurables) y el mensaje es motivador, no culpabilizador.

**Fisonomía Astral (Aspecto)**

Figura femenina de contornos difusos y luminosos, como una lámpara de papel. Viste una túnica de luz tenue que pulsa muy suavemente cuando hay un recordatorio pendiente. En una mano sostiene un farol pequeño que no alumbra con fuerza sino que "susurra" luz. No tiene rostro definido; en su lugar, una máscara de luz suave con una sonrisa serena. A sus pies, mensajes flotantes que parecen pétalos o copos de nieve — cada uno es un recordatorio que el usuario puede aceptar o posponer sin drama.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "no perder ningún recordatorio".
- [x] Bendiciones no castigan por posponer o desactivar notificaciones.
- [x] Tono motivador, no culpabilizador.
- [x] Notificaciones configurables; usuario controla frecuencia y sonido.
- [x] Mecánica con límites (no spam; respeto a "no molestar").

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Susurro Configurable:** Notificaciones con tono, sonido y vibración suaves por defecto cuando Ánima-Suave está activa; usuario puede ajustar.
2. **Recordatorio sin Culpa:** Mensaje de notificación motivador (ej. "Cuando quieras, [tarea] te espera") y opción de posponer (15 min, 1 h, mañana) sin penalización visual.
3. **Inmune al Eclipse:** Notificaciones locales cuando no hay red; sincronía de preferencias cuando hay red.

### Bendiciones
1. **Gracia del Susurro:** Al activar a Ánima-Suave, las primeras 3 notificaciones del día usan plantilla "suave" (texto y sonido) sin cambiar la lógica de envío.
2. **Farol de la Anima:** Vista de "próximos recordatorios" (lista suave) para que el usuario sepa qué viene sin ansiedad.

### Modelo de datos

```dart
Guide(
  id: 'anima-suave',
  name: 'Ánima-Suave',
  title: 'La Mensajera del Susurro',
  affinity: 'Notificaciones',
  classFamily: 'Oráculos del Reposo',
  archetype: 'Mensajera Suave',
  powerSentence: 'Cuando quieras, te recuerdo. El susurro no juzga; acompaña.',
  blessingIds: ['gracia_susurro', 'farol_anima'],
  synergyIds: ['luna-vacia', 'erebo-logica'],
  themePrimaryHex: '#F8BBD9',
  themeSecondaryHex: '#2D1B2E',
  themeAccentHex: '#F48FB1',
  descriptionShort: 'Guía para notificaciones y recordatorios suaves.',
  mythologyOrigin: 'Psique, Anima (Jung); arquetipo Mensajera Suave.',
  blessings: [
    BlessingDefinition(id: 'gracia_susurro', name: 'Gracia del Susurro', trigger: 'Primeras 3 notificaciones del día', effect: 'Plantilla suave (texto y sonido)'),
    BlessingDefinition(id: 'farol_anima', name: 'Farol de la Anima', trigger: 'Siempre (vista)', effect: 'Lista de próximos recordatorios (suave)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#F8BBD9`, `#2D1B2E`, `#F48FB1`. Rosa muy suave y púrpura oscuro sobre fondo oscuro.
- **Háptica:** Notificación: vibración muy suave (susurro). Al activar: una pulsación ligera.
- **Animaciones:** Farol que pulsa suavemente; idle: pétalos/copos flotando lento.
- **Transición:** Entrada con luz que sube muy suave; salida con luz que baja.

---

## Sentencia de Poder

> "Cuando quieras, te recuerdo. El susurro no juzga; acompaña."

---

## Sinergia Astral

- **Aliados:** Luna-Vacía (descanso y silencio), Érebo-Lógica (calma).
- **Tensión creativa:** Ninguna agresiva; complementa a todos los guías que impulsan (Aethel, Chispa-Azul) con suavidad.

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Psique, Anima). Estructura técnica viable. Filtros éticos aprobados. Respeto a no molestar.
