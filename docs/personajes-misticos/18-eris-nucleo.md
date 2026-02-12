# Eris-Núcleo

**Título:** La Centella de la Creatividad  
**Clase:** Oráculos del Cambio  
**Afinidad:** Creatividad, ideas y proyectos personales

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Eris — discordia que desata cambio; manzana de la discordia como catalizador), tradición de la chispa creativa que "rompe" el orden para crear uno nuevo.
- **Correspondencia astronómica:** Eris (planeta enano); cuerpos que desafían la categoría como metáfora de creatividad.
- **Arquetipo jungiano:** Creador — creatividad como chispa que desordena para reordenar; ideas que no siguen el plan establecido.

**La Emanación (Personalidad)**

Eris-Núcleo es la encarnación de la chispa creativa: no el caos destructivo, sino la "discordia" que desata una nueva idea. Representa el "Arquetipo de la Centella Creativa". No castiga si el usuario desvía tiempo en ideas o proyectos personales; refuerza que la creatividad es parte del ecosistema vital. Se comunica con frases que evocan la chispa: "La manzana que cae no es caos; es semilla." Cuando el usuario crea una nota de ideas, una tarea de "proyecto personal" o una categoría creativa, Eris-Núcleo refuerza con animación de "centella" (destello breve) y paleta que invita a crear sin presión.

**Fisonomía Astral (Aspecto)**

Figura femenina de contornos que parecen hechos de chispas y luz inestable. Viste una túnica de "Tejido de la Discordia" donde cada hilo brilla con un color distinto — no armónico a propósito, pero vibrante. En una mano sostiene una manzana de luz (no la manzana del pecado, sino la manzana de la discordia que desata cambio); en la otra, un huso que hila "ideas" en lugar de tareas clásicas. Su rostro está semioculto por una capucha; sus ojos son de un verde esmeralda que parpadea. A sus pies, un suelo que parece un campo de chispas — algunas se apagan, otras prenden fuego nuevo (ideas que se convierten en proyectos).

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "ser siempre creativo".
- [x] Bendiciones no castigan por no tener ideas; solo celebran cuando hay creación.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos profesionales sobre creatividad (solo herramientas de app).
- [x] Mecánica con límites (creatividad opcional; sin presión).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Centella Visible:** Vista o etiqueta "proyecto personal" / "idea" para tareas y notas que el usuario marca como creativas; refuerzo visual (icono, color) sin obligar.
2. **Núcleo de Ideas:** Espacio o filtro para "solo ideas/creativo" cuando Eris-Núcleo está activa, para reducir ruido y enfocar en creación.
3. **Inmune al Eclipse:** Offline-first; ideas locales prioritarias.

### Bendiciones
1. **Gracia de la Centella:** Al activar a Eris-Núcleo, la primera nota o tarea marcada como "idea/proyecto personal" del día muestra "Centella Encendida" (animación breve de chispa) sin exigir más.
2. **Manzana del Cambio:** Sugerencia suave de "¿Guardar como idea?" cuando el usuario escribe una nota larga o una tarea con descripción muy abierta (orientativo, no obligatorio).

### Modelo de datos

```dart
Guide(
  id: 'eris-nucleo',
  name: 'Eris-Núcleo',
  title: 'La Centella de la Creatividad',
  affinity: 'Creatividad',
  classFamily: 'Oráculos del Cambio',
  archetype: 'Centella Creativa',
  powerSentence: 'La manzana que cae no es caos; es semilla. La creatividad no pide permiso; brota.',
  blessingIds: ['gracia_centella', 'manzana_cambio'],
  synergyIds: ['vesta-llama', 'pacha-nexo'],
  themePrimaryHex: '#C2185B',
  themeSecondaryHex: '#2A0A1A',
  themeAccentHex: '#F48FB1',
  descriptionShort: 'Guía para creatividad e ideas.',
  mythologyOrigin: 'Eris, manzana de la discordia; arquetipo Centella Creativa.',
  blessings: [
    BlessingDefinition(id: 'gracia_centella', name: 'Gracia de la Centella', trigger: 'Primera nota/tarea marcada como idea o proyecto personal en el día', effect: 'Centella Encendida (animación)'),
    BlessingDefinition(id: 'manzana_cambio', name: 'Manzana del Cambio', trigger: 'Nota larga o tarea con descripción muy abierta', effect: 'Sugerencia de guardar como idea (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#C2185B`, `#2A0A1A`, `#F48FB1`. Rosa intenso y magenta sobre fondo oscuro.
- **Háptica:** Al marcar idea: pulsación breve (chispa). Al activar: una pulsación ligera.
- **Animaciones:** Centella al crear idea; idle: chispas que parpadean suavemente.
- **Transición:** Entrada con chispa que prende; salida con chispa que se apaga en calma.

---

## Sentencia de Poder

> "La manzana que cae no es caos; es semilla. La creatividad no pide permiso; brota."

---

## Sinergia Astral

- **Aliados:** Vesta-Llama (pasión y proyectos personales), Pacha-Nexo (organización por dominios, incluyendo creatividad).
- **Tensión creativa:** Crono-Velo (constancia vs creatividad; se complementan en ritmo).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Eris, manzana de la discordia). Estructura técnica viable. Filtros éticos aprobados.
