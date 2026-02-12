# Shiva-Fluido

**Título:** El Danzante del Cambio de Planes  
**Clase:** Oráculos del Cambio  
**Afinidad:** Cambio de planes, flexibilidad y adaptación

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Hinduismo (Shiva — destructor/transformador; danza cósmica que disuelve y renueva), Grecia (Urano — cambio brusco; innovación).
- **Correspondencia astronómica:** Urano (planeta del cambio); transformación como metáfora.
- **Arquetipo jungiano:** Transformador — cambio de planes sin culpa; disolver lo viejo para abrir espacio a lo nuevo.

**La Emanación (Personalidad)**

Shiva-Fluido es la encarnación del cambio de planes sin drama: no el plan rígido que se rompe, sino la danza que adapta el paso. Representa el "Arquetipo del Danzante del Cambio". No castiga si el usuario pospone, reorganiza o elimina tareas; refuerza que "cambiar de planes es parte del plan". Se comunica con frases que evocan la danza: "El que no cambia, no baila." Cuando el usuario mueve una tarea de día, la pospone o la elimina, Shiva-Fluido refuerza con animación suave (transición fluida) y sin mensajes de culpa.

**Fisonomía Astral (Aspecto)**

Figura andrógina de contornos en movimiento perpetuo, como una danza congelada en un instante. Viste una túnica de "Tejido del Cambio" que se disuelve y recompone según el movimiento del usuario en la app. En sus cuatro brazos (evocando Shiva Nataraja) no lleva armas destructivas sino herramientas de flujo: un reloj de arena, un mapa que se redibuja, un hilo que se desata y un hilo que se anuda. Su rostro está en calma; sus ojos son de un azul profundo y sereno. A sus pies, un círculo de fuego que no quema sino que transforma — las tareas que se mueven "danzan" dentro del círculo.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "cambiar todo".
- [x] Bendiciones no castigan por mantener planes; solo facilitan el cambio sin culpa.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos profesionales reales.
- [x] Mecánica con límites (cambios libres; sin penalización visual).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Danza del Cambio:** Al mover/posponer/eliminar tarea, animación fluida (transición) sin mensaje de "fallo" o "pérdida".
2. **Redibujar Mapa:** Vista de "historial de cambios" opcional (qué se movió/pospuso) como orientación, no como juicio.
3. **Inmune al Eclipse:** Offline-first; cambios locales se sincronizan después.

### Bendiciones
1. **Gracia del Danzante:** Al activar a Shiva-Fluido, la primera vez que el usuario mueve una tarea de día o la pospone en la sesión muestra "Danza Aceptada" (animación breve de fluidez) sin castigar.
2. **Círculo de Transformación:** Opción de "deshacer" último cambio (mover/posponer) dentro de la misma sesión (una vez) para reducir miedo a equivocarse.

### Modelo de datos

```dart
Guide(
  id: 'shiva-fluido',
  name: 'Shiva-Fluido',
  title: 'El Danzante del Cambio de Planes',
  affinity: 'Cambio de planes',
  classFamily: 'Oráculos del Cambio',
  archetype: 'Danzante del Cambio',
  powerSentence: 'El que no cambia, no baila. Cambiar de planes es parte del plan.',
  blessingIds: ['gracia_danzante', 'circulo_transformacion'],
  synergyIds: ['loki-error', 'erebo-logica'],
  themePrimaryHex: '#5E35B1',
  themeSecondaryHex: '#1A0A2E',
  themeAccentHex: '#9575CD',
  descriptionShort: 'Guía para flexibilidad y cambio de planes.',
  mythologyOrigin: 'Shiva, Urano; arquetipo Danzante del Cambio.',
  blessings: [
    BlessingDefinition(id: 'gracia_danzante', name: 'Gracia del Danzante', trigger: 'Primera vez que mueve/pospone tarea en la sesión', effect: 'Danza Aceptada (animación fluida)'),
    BlessingDefinition(id: 'circulo_transformacion', name: 'Círculo de Transformación', trigger: 'Después de mover/posponer', effect: 'Opción deshacer último cambio (una vez por sesión)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#5E35B1`, `#1A0A2E`, `#9575CD`. Violetas y púrpuras sobre fondo oscuro.
- **Háptica:** Al mover tarea: pulsación muy suave (fluida). Al activar: una pulsación ligera.
- **Animaciones:** Transición fluida al mover/posponer; idle: danza lenta de contornos.
- **Transición:** Entrada con danza que comienza; salida con danza que se detiene en calma.

---

## Sentencia de Poder

> "El que no cambia, no baila. Cambiar de planes es parte del plan."

---

## Sinergia Astral

- **Aliados:** Loki-Error (imprevistos; Shiva-Fluido ayuda a adaptar), Érebo-Lógica (calma ante el cambio).
- **Tensión creativa:** Crono-Velo (constancia vs cambio; se complementan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Shiva, Urano). Estructura técnica viable. Filtros éticos aprobados.
