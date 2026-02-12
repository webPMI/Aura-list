# Morfeo-Astral

**Título:** El Tejedor de las Notas y los Sueños  
**Clase:** Oráculos del Reposo  
**Afinidad:** Notas, ideas y transición al descanso

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Morfeo — dios de los sueños; forma y transformación en el sueño), tradición de las notas como "semillas de sueños" e ideas.
- **Correspondencia astronómica:** Fase de sueño; noche como espacio de ideas y notas.
- **Arquetipo jungiano:** Tejedor de Sueños — notas como puente entre vigilia y descanso; ideas que se guardan sin presión.

**La Emanación (Personalidad)**

Morfeo-Astral es la encarnación de las notas que no pesan: no la lista de tareas que no duermen, sino el espacio donde las ideas se guardan para soñar con ellas después. Representa el "Arquetipo del Tejedor de Sueños". No exige que el usuario escriba; ofrece un refugio para notas, listas de ideas y recordatorios suaves que pueden convertirse en tareas más tarde. Se comunica con frases que evocan el sueño: "Guarda la idea; el sueño la tejerá." Cuando el usuario abre la sección de notas o escribe una nota antes de dormir, Morfeo-Astral refuerza con paleta nocturna y transición suave hacia modo descanso (complementando a Luna-Vacía).

**Fisonomía Astral (Aspecto)**

Figura masculina de contornos cambiantes, como si estuviera hecho de sueños. Viste una túnica de "Tejido de Sueños" donde cada hilo brilla con una nota o idea guardada. En una mano sostiene un huso que no hila lana sino "hilos de ideas" — cada nota es un hilo que puede convertirse en tarea o quedarse como sueño. Su rostro está semioculto por una capucha; sus ojos son de un violeta profundo y sereno. A sus pies, un suelo que parece un mar de notas flotantes — algunas se convierten en estrellas (tareas), otras permanecen como luz tenue (solo notas).

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "anotar todo".
- [x] Bendiciones no castigan por no convertir notas en tareas.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos médicos sobre sueño (solo transición visual/sonora).
- [x] Mecánica con límites (notas opcionales; integración con descanso respetuosa).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Tejido de Notas:** Vista de notas (y opcionalmente checklist dentro de notas) con opción de "convertir en tarea" sin obligar.
2. **Transición al Sueño:** Cuando el usuario abre notas en horario nocturno (configurable), sugerir transición a paleta nocturna y opción de "modo descanso" (complementa Luna-Vacía).
3. **Inmune al Eclipse:** Offline-first; notas locales prioritarias.

### Bendiciones
1. **Gracia del Tejedor:** Al activar a Morfeo-Astral, la primera nota guardada del día (o de la noche) muestra un "Hilo de Sueño" (animación breve de hilo que se guarda) sin exigir más.
2. **Huso de Ideas:** Sugerencia suave de "¿Convertir esta nota en tarea?" cuando la nota tiene formato de acción (orientativo, no obligatorio).

### Modelo de datos

```dart
Guide(
  id: 'morfeo-astral',
  name: 'Morfeo-Astral',
  title: 'El Tejedor de las Notas y los Sueños',
  affinity: 'Notas',
  classFamily: 'Oráculos del Reposo',
  archetype: 'Tejedor de Sueños',
  powerSentence: 'Guarda la idea; el sueño la tejerá. Las notas no pesan; flotan.',
  blessingIds: ['gracia_tejedor', 'huso_ideas'],
  synergyIds: ['luna-vacia', 'erebo-logica'],
  themePrimaryHex: '#7E57C2',
  themeSecondaryHex: '#1A0A2E',
  themeAccentHex: '#B39DDB',
  descriptionShort: 'Guía para notas e ideas.',
  mythologyOrigin: 'Morfeo, sueños; arquetipo Tejedor de Sueños.',
  blessings: [
    BlessingDefinition(id: 'gracia_tejedor', name: 'Gracia del Tejedor', trigger: 'Primera nota guardada del día o noche', effect: 'Hilo de Sueño (animación)'),
    BlessingDefinition(id: 'huso_ideas', name: 'Huso de Ideas', trigger: 'Nota con formato de acción', effect: 'Sugerencia de convertir en tarea (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#7E57C2`, `#1A0A2E`, `#B39DDB`. Violetas y púrpuras nocturnos sobre fondo oscuro.
- **Háptica:** Al guardar nota: pulsación muy suave. Al activar: una pulsación ligera.
- **Animaciones:** Hilos que se tejen al guardar nota; idle: notas flotando como estrellas tenues.
- **Transición:** Entrada con sueño que envuelve; salida con despertar suave.

---

## Sentencia de Poder

> "Guarda la idea; el sueño la tejerá. Las notas no pesan; flotan."

---

## Sinergia Astral

- **Aliados:** Luna-Vacía (transición al descanso), Érebo-Lógica (calma y orden de ideas).
- **Tensión creativa:** Aethel (impulso vs sueño; se complementan en ritmo día/noche).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Morfeo). Estructura técnica viable. Filtros éticos aprobados.
