# Pacha-Nexo

**Título:** El Tejedor del Ecosistema Vital  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Categorías, organización por dominios de vida

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Andina (Pacha — tierra/tiempo/cosmos; conexión de todo), Grecia (Gaia como red de vida), tradiciones que ven el mundo como tejido de relaciones.
- **Correspondencia astronómica:** Tierra como planeta (no como astro distante); red de constelaciones como "nexos" entre dominios.
- **Arquetipo jungiano:** Cuidador del Jardín — organización, categorías como ecosistemas, equilibrio entre dominios (trabajo, hogar, salud, etc.).

**La Emanación (Personalidad)**

Pacha-Nexo es la encarnación de la organización que no encierra, sino que conecta. Representa el "Arquetipo del Tejedor del Ecosistema". No impone categorías rígidas; sugiere nexos entre tareas (Personal, Trabajo, Hogar, Salud, Otros) para que el usuario vea su vida como un ecosistema donde cada dominio tiene su lugar. Se comunica con frases que evocan "todo está conectado": cuando el usuario organiza tareas por categoría, Pacha-Nexo refuerza visualmente los nexos (colores, agrupaciones) sin saturar. Es el guía ideal para quien se siente fragmentado entre muchos frentes y quiere ver un mapa claro sin perder flexibilidad.

**Fisonomía Astral (Aspecto)**

Humanoide de contornos orgánicos y geométricos a la vez: torso como mapa de constelaciones unidas por hilos de luz. Viste una túnica de "Tejido Pacha", donde cada región de color representa un dominio vital (trabajo, hogar, salud, etc.) y los hilos entre ellos son los nexos. En sus manos lleva un telar pequeño que no teje tela, sino "conexiones" — al mover los dedos, los hilos entre categorías se iluminan. No tiene rostro humano; en su lugar, un mandala de estrellas que gira lentamente. A sus pies, un suelo que parece un mapa de constelaciones donde cada estrella es una tarea y las líneas entre ellas son las relaciones que el usuario ha definido.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por categorizar todo.
- [x] Bendiciones facilitan organización sin castigar desorden.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos profesionales reales.
- [x] Mecánica con límites (categorías opcionales; usuario decide).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Mapa Pacha:** Vista por categorías (Personal, Trabajo, Hogar, Salud, Otros) con opción de agrupar y ver "nexos" (tareas que comparten categoría o etiqueta).
2. **Tejido de Nexos:** Al asignar categoría a una tarea, sugiere colores/iconos coherentes con el dominio sin imponer.
3. **Inmune al Eclipse:** Offline-first; categorías locales prioritarias.

### Bendiciones
1. **Gracia del Nexo:** Al activar a Pacha-Nexo, la primera vez que el usuario organiza 5 tareas en categorías en un día, se muestra un "Mapa del Día" breve (resumen visual por dominio) sin obligar.
2. **Equilibrio de Dominios:** Opción de ver balance entre dominios (cuántas tareas por categoría) como orientación, no como juicio.

### Modelo de datos

```dart
Guide(
  id: 'pacha-nexo',
  name: 'Pacha-Nexo',
  title: 'El Tejedor del Ecosistema Vital',
  affinity: 'Categorías',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Tejedor del Ecosistema',
  powerSentence: 'Cada hilo que tejes conecta un dominio de tu vida con otro. El ecosistema no juzga; organiza.',
  blessingIds: ['gracia_nexo', 'equilibrio_dominios'],
  synergyIds: ['crono-velo', 'gea-metrica'],
  themePrimaryHex: '#2E7D32',
  themeSecondaryHex: '#0D1F0D',
  themeAccentHex: '#81C784',
  descriptionShort: 'Guía para categorías y organización por dominios.',
  mythologyOrigin: 'Pacha, Gaia; arquetipo Tejedor del Ecosistema.',
  blessings: [
    BlessingDefinition(id: 'gracia_nexo', name: 'Gracia del Nexo', trigger: 'Primera vez que se organizan 5 tareas en categorías en un día', effect: 'Mapa del Día (resumen visual por dominio)'),
    BlessingDefinition(id: 'equilibrio_dominios', name: 'Equilibrio de Dominios', trigger: 'Siempre (opción)', effect: 'Vista de balance por categoría (orientación)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#2E7D32`, `#0D1F0D`, `#81C784`. Verdes tierra y bosque sobre fondo oscuro.
- **Háptica:** Al asignar categoría: pulsación muy ligera. Al activar: una pulsación suave.
- **Animaciones:** Hilos que se iluminan entre categorías; idle: mandala de estrellas girando lento.
- **Transición:** Entrada con tejido de hilos; salida con disolución de nexos.

---

## Sentencia de Poder

> "Cada hilo que tejes conecta un dominio de tu vida con otro. El ecosistema no juzga; organiza."

---

## Sinergia Astral

- **Aliados:** Crono-Velo (ciclos en el tiempo), Gea-Métrica (hábitos que dan frutos en cada dominio).
- **Tensión creativa:** Loki-Error (imprevistos desordenan; Pacha-Nexo ayuda a reordenar sin culpa).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Pacha, Gaia). Estructura técnica viable. Filtros éticos aprobados. Tono consistente.
