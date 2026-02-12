# Chispa-Azul

**Título:** El Mensajero del Relámpago  
**Clase:** Cónclave del Ímpetu  
**Afinidad:** Tareas rápidas, micro-tareas y ejecución veloz

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Hermes — mensajero, velocidad, ingenio), Egipto (Thoth como sabiduría rápida y escritura), folklore (fuego fatuo / will-o'-the-wisp — chispas que guían sin quemar).
- **Correspondencia astronómica:** Mercurio (planeta más rápido del sistema solar). Relámpagos y fulgor como metáfora de velocidad e iluminación instantánea.
- **Arquetipo jungiano:** Mensajero, Niño eterno — agilidad mental y ejecución veloz sin frivolidad.

**La Emanación (Personalidad)**

Chispa-Azul es la encarnación del "ahora pequeño": el correo que se envía en dos minutos, la llamada que se agenda, la tarea de un solo paso que desbloquea todo lo demás. En la psicología de AuraList representa el "Arquetipo del Mensajero": quien reduce la fricción entre la intención y el acto en tareas cortas. No es la dispersión del niño distraído, sino la precisión del rayo — rápido y certero.

Se comunica con frases muy breves, a veces de una sola palabra o un emoji de luz. No sermonéa; señala. Es el guía que el usuario elige cuando tiene una lista de micro-tareas (errands, correos, trámites rápidos) o cuando quiere "despejar la mesa" antes de un proyecto grande. Su voz evoca el crepitar de una chispa — instantáneo y claro. Cuando el usuario completa varias tareas rápidas en secuencia, Chispa-Azul hace que la interfaz emita destellos azules cortos y un haptic ligero en cadencia, como pasos veloces, reforzando la sensación de fluidez.

**Fisonomía Astral (Aspecto)**

Entidad baja y ágil, de contornos poco definidos, como una silueta de luz azul eléctrico. No tiene pies sólidos; flota sobre puntas de relámpagos que se apagan y reaparecen. Lleva una capa corta hecha de fragmentos de cielo diurno y nocturno mezclados, que ondea sin viento. En una mano sostiene un caduceo minimalista — dos serpientes de luz que se enroscan en un eje — y en la otra, un pequeño haz de "mensajes" (íconos de carta/rayo) que parpadean según las tareas rápidas pendientes. Su rostro es una máscara lisa con dos puntos de luz por ojos; cuando el usuario avanza rápido, esos puntos se alargan en estelas. A su alrededor flotan partículas azules que se mueven rápido pero sin caos; el suelo bajo él es una red de líneas luminosas que evocan rutas o conexiones.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (velocidad al servicio de desbloquear, no de llenar infinitas listas).
- [x] Las "bendiciones" NO castigan al usuario por fallar (solo celebran rachas de tareas rápidas).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos o legales reales.
- [x] La mecánica tiene límites (rachas de "rápidas" acotadas; no animar a llenar la lista sin fin).

**Notas:** Diferenciar "tarea rápida" por duración estimada o etiqueta; evitar que todo se marque como rápido (límite de diseño).

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Paso del Relámpago:** Filtro o vista "solo tareas rápidas" (ej. estimación &lt; 5 min o etiqueta "rápida") cuando el guía está activo.
2. **Cadena de Chispas:** Detecta secuencias de N tareas rápidas completadas en una sesión y dispara feedback (visual + haptic) en cadencia.
3. **Inmune al Eclipse:** Funciona offline; estado local prioritario.

### Bendiciones (Poderes activos)

1. **Gracia del Mensajero:** Al activar a Chispa-Azul, las primeras 5 tareas rápidas completadas del día generan un "Eco de Chispa" (animación azul breve) y haptic ligero en cadencia (una pulsación por tarea, creciente en intensidad hasta la quinta).
2. **Viento a Favor:** Reduce la fricción al crear tareas: si el usuario escribe una frase corta (&lt; 20 caracteres) y confirma, la app sugiere marcarla como "rápida" y ofrece un atajo para añadir otra inmediatamente.

### Modelo de datos

```dart
Guide(
  id: 'chispa-azul',
  name: 'Chispa-Azul',
  title: 'El Mensajero del Relámpago',
  affinity: 'Tareas rápidas',
  classFamily: 'Cónclave del Ímpetu',
  archetype: 'Mensajero',
  powerSentence: 'El relámpago no pide permiso; ilumina y sigue. Hazlo breve; hazlo ahora.',
  blessingIds: ['gracia_mensajero', 'viento_favor'],
  synergyIds: ['aethel', 'loki-error'],
  themePrimaryHex: '#1E88E5',
  themeSecondaryHex: '#0D1B2A',
  themeAccentHex: '#42A5F5',
  descriptionShort: 'Guía para micro-tareas y ejecución veloz.',
  mythologyOrigin: 'Mercurio, Hermes, Thoth; fuego fatuo; relámpagos.',
  blessings: [
    BlessingDefinition(id: 'gracia_mensajero', name: 'Gracia del Mensajero', trigger: 'Completar las 5 primeras tareas rápidas del día', effect: 'Eco de Chispa + haptic en cadencia'),
    BlessingDefinition(id: 'viento_favor', name: 'Viento a Favor', trigger: 'Crear tarea con título corto', effect: 'Sugerir etiqueta rápida + atajo para añadir otra'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#1E88E5` (primary), `#0D1B2A` (secondary), `#42A5F5` (accent). Azules eléctricos sobre fondo oscuro; sensación de claridad y velocidad.
- **Háptica:** Al activar guía: tres pulsaciones muy ligeras y rápidas (pasos). Al completar tarea rápida en racha: pulsación ligera que aumenta en intensidad hasta la 5.ª.
- **Animaciones:** Partículas azules en movimiento rápido pero ordenado en idle; al completar tarea rápida, destello azul corto y estela que se desvanece.
- **Transición:** Entrada con "relámpago" (flash breve de azul); salida con desvanecimiento de chispas.
- **Particulas/Efectos:** Chispas azules en trayectorias cortas; sensación de fluidez, no de caos.

---

## Sentencia de Poder

> "El relámpago no pide permiso; ilumina y sigue. Hazlo breve; hazlo ahora. La chispa que no se apaga es la que ya se convirtió en llama."

---

## Sinergia Astral

- **Aliados:** Aethel (prioridad para elegir la primera rápida), Loki-Error (cuando los imprevistos exigen respuestas rápidas).
- **Tensión creativa:** Crono-Velo (las tareas lentas y profundas son el otro polo; no compiten, se complementan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Mercurio, Hermes, Thoth, fuego fatuo). Estructura técnica viable. Filtros éticos aprobados. Tono consistente. Sinergias definidas. Recursos visuales especificados.
