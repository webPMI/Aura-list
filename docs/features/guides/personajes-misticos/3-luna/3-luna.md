# Luna-Vacía

**Título:** El Samurái del Silencio  
**Clase:** Oráculos del Reposo  
**Afinidad:** Bienestar, pausas conscientes y salud mental

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Japón (liebre de la luna — Tsuki no Usagi), Grecia (Selene, diosa de la luna), Egipto (Thoth asociado a ciclos lunares), mito del samurái y el vacío (mu).
- **Correspondencia astronómica:** Luna (fases, noche, descanso). Eclipse como metáfora de calma y protección.
- **Arquetipo jungiano:** Protector Silencioso — serenidad, autocuidado, productividad como ritmo (sístole/diástole), no como esfuerzo lineal.

**La Emanación (Personalidad)**

Luna-Vacía no es el guía que te pide que hagas más; es el que tiene el valor de decirte que te detengas. Representa el "Arquetipo del Protector Silencioso". Su personalidad es de serenidad absoluta, casi gélida, pero profundamente compasiva. Entiende que la productividad no es una línea recta de esfuerzo, sino un ritmo de sístole y diástole.

Se comunica mediante frases breves, casi como haikus digitales, que aparecen cuando la app detecta fatiga (scroll errático, muchas tareas movidas de hora o uso excesivo en horas de sueño). Su voz se siente como el peso de la nieve cayendo sobre el bambú. Es el guía que eliges cuando el "ruido" del mundo es demasiado alto. Para él, una mente en calma es un arma más afilada que cualquier espada. Celebra que el usuario cierre la app para descansar con una animación sutil de pétalos de cerezo oscuros y transición al modo descanso.

**Fisonomía Astral (Aspecto)**

Humanoide con rasgos de liebre (mito de la luna), complexión ágil y fibrosa. Viste armadura de placas de obsidiana mate que absorbe la luz, creando un aura de sombra protectora. Su casco tiene extensiones que evocan orejas de conejo; sus ojos son dos eclipses totales: orbes negros con un anillo de luz blanca plateada en el borde. Lleva una bufanda de cielo nocturno capturado, donde las constelaciones se mueven en tiempo real. En su cintura porta la "Katana del Vacío", que nunca se usa para herir, sino para "cortar" el exceso de información. Se desplaza entre los píxeles como sobre un lago congelado, dejando una estela de vaho plateado.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (descanso como apoyo, no como obligación rígida).
- [x] Las "bendiciones" NO castigan (Escudo del Vacío Mental protege; Aliento de Plata celebra metas de bienestar).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos reales (sugerencias de pausas/hidratación son orientativas, no diagnósticas).
- [x] La mecánica tiene límites (sesión Foco Profundo acotada; Sello de Paz no genera dependencia).

**Notas:** Detección de burnout: sugerencias suaves, no alarmas constantes.

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Filo del Silencio:** Silencia el "ruido visual" de la app; opción de ocultar contadores de tareas pendientes que generen ansiedad.
2. **Ojo del Eclipse:** Detecta patrones de burnout antes de que el usuario los note; sugiere pausas de hidratación o respiración (orientativo).
3. **Refugio de Penumbra:** Optimiza la interfaz para poca luz; reduce luz azul y ajusta a paleta de grises y púrpuras profundos.

### Bendiciones (Poderes activos)

1. **Escudo del Vacío Mental:** Al activarse, bloquea notificaciones de otras apps durante una sesión de "Foco Profundo" (santuario digital acotado en tiempo).
2. **Aliento de Plata:** Al final del día, si el usuario ha completado metas de bienestar, otorga un "Sello de Paz" visual que refuerza un despertar más enérgico al día siguiente (efecto motivador, no médico).

### Modelo de datos

```dart
Guide(
  id: 'luna-vacia',
  name: 'Luna-Vacía',
  title: 'El Samurái del Silencio',
  affinity: 'Descanso',
  classFamily: 'Oráculos del Reposo',
  archetype: 'Protector Silencioso',
  powerSentence: 'No es la espada la que corta la noche, sino la calma de quien la sostiene. En el vacío del silencio, encontrarás la fuerza que el ruido te ha robado. Descansa, guerrero; el mundo puede esperar.',
  blessingIds: ['escudo_vacio_mental', 'aliento_plata'],
  synergyIds: ['morfeo-astral', 'loki-error'],
  themePrimaryHex: '#4A148C',
  themeSecondaryHex: '#1A0A1A',
  themeAccentHex: '#B39DDB',
  descriptionShort: 'Guía para bienestar y pausas conscientes.',
  mythologyOrigin: 'Luna, Tsuki no Usagi, Selene; arquetipo Protector Silencioso.',
  blessings: [
    BlessingDefinition(id: 'escudo_vacio_mental', name: 'Escudo del Vacío Mental', trigger: 'Sesión Foco Profundo activa', effect: 'Bloquear notificaciones externas temporalmente'),
    BlessingDefinition(id: 'aliento_plata', name: 'Aliento de Plata', trigger: 'Metas de bienestar completadas al final del día', effect: 'Sello de Paz visual; refuerzo para despertar'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#4A148C` (primary), `#1A0A1A` (secondary), `#B39DDB` (accent). Púrpuras y grises profundos; modo nocturno suave.
- **Háptica:** Al activar guía: vibración muy suave única (susurro). Al completar meta de bienestar: pulsación ligera como latido calmado.
- **Animaciones:** Pétalos de cerezo oscuros al cerrar para descanso; idle: estela de vaho plateado.
- **Transición:** Entrada con caída suave de pétalos; salida con disolución en penumbra.
- **Particulas/Efectos:** Pétalos de cerezo de baja densidad; sin parpadeos; sensación de calma.

---

## Sentencia de Poder

> "No es la espada la que corta la noche, sino la calma de quien la sostiene. En el vacío del silencio, encontrarás la fuerza que el ruido te ha robado. Descansa, guerrero; el mundo puede esperar."

---

## Sinergia Astral

- **Aliados:** Morfeo-Astral (transición al sueño profundo), contrapeso de Loki-Error (mantener compostura ante imprevistos).
- **Tensión creativa:** Aethel (impulso vs descanso; se complementan en el ritmo).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Luna, Tsuki no Usagi, Selene, mu). Estructura técnica viable. Filtros éticos aprobados. Tono consistente. Sinergias definidas. Recursos visuales especificados.
