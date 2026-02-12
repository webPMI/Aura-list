# Gea-Métrica

**Título:** La Guardiana de los Hábitos que Dan Fruto  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Hábitos, métricas de progreso y crecimiento visible

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Gea/Gaia — tierra madre, fertilidad, crecimiento), Roma (Tellus), tradiciones de la tierra que da fruto con constancia.
- **Correspondencia astronómica:** Tierra (planeta); estaciones y ciclos agrícolas como metáfora de siembra y cosecha.
- **Arquetipo jungiano:** Cuidadora que Nutre — hábitos como semillas, progreso visible como fruto, paciencia y métricas no obsesivas.

**La Emanación (Personalidad)**

Gea-Métrica es la encarnación del hábito que da fruto: no la métrica por la métrica, sino el crecimiento visible que alimenta la motivación. Representa el "Arquetipo de la Guardiana que Nutre". No castiga si un hábito se rompe; muestra cómo el riego constante (la constancia) se traduce en brotes visibles. Se comunica con frases que evocan la tierra y la cosecha: "Lo que siembras hoy, lo cosechas en tu propio ritmo." Cuando el usuario mantiene un hábito recurrente, Gea-Métrica hace que la interfaz muestre un "brote" o una curva de progreso suave (días completados, no números agresivos), reforzando la sensación de crecimiento sin presión.

**Fisonomía Astral (Aspecto)**

Figura femenina de contornos orgánicos, como si estuviera hecha de tierra y raíces luminosas. Viste una túnica de "Tejido de Estaciones", que cambia de tono según el progreso del usuario (verde brote, dorado cosecha, etc.). En una mano sostiene un cuenco del que brotan pequeñas plantas de luz; en la otra, un huso que no hila lana, sino "hilos de días" — cada día completado añade un segmento al hilo. Su rostro está semioculto por una capucha de hojas; sus ojos son de un verde profundo y sereno. A sus pies, un suelo que parece un campo cultivado donde cada surco representa un hábito y la altura del "cultivo" refleja la constancia del usuario.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por rachas infinitas.
- [x] Bendiciones muestran progreso sin castigar la caída de racha.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos médicos reales (hábitos de salud son orientativos).
- [x] Mecánica con límites (métricas suaves; sin ranking agresivo).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Brotes de Progreso:** Vista de progreso por hábito (días completados, curva suave) sin números agresivos ni rachas que "rompen" dramáticamente.
2. **Métrica de Cosecha:** Resumen semanal/mensual de "qué ha dado fruto" (hábitos mantenidos) como refuerzo positivo.
3. **Inmune al Eclipse:** Offline-first; métricas locales prioritarias.

### Bendiciones
1. **Gracia del Brote:** Al activar a Gea-Métrica, el primer hábito que el usuario complete en racha de 3 días consecutivos muestra un "Brote" visual (animación breve de crecimiento) sin castigar si la racha se rompe después.
2. **Cuenco de Estaciones:** Vista de "estación personal" (invierno/primavera/verano/otoño) basada en tendencia de hábitos (orientativo, no diagnóstico), con tonos de color que refuerzan calma.

### Modelo de datos

```dart
Guide(
  id: 'gea-metrica',
  name: 'Gea-Métrica',
  title: 'La Guardiana de los Hábitos que Dan Fruto',
  affinity: 'Hábitos',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Guardiana que Nutre',
  powerSentence: 'Lo que siembras hoy, lo cosechas en tu propio ritmo. La tierra no juzga la semilla; la nutre.',
  blessingIds: ['gracia_brote', 'cuenco_estaciones'],
  synergyIds: ['crono-velo', 'gloria-sincro'],
  themePrimaryHex: '#388E3C',
  themeSecondaryHex: '#0D1F0D',
  themeAccentHex: '#66BB6A',
  descriptionShort: 'Guía para hábitos y progreso visible.',
  mythologyOrigin: 'Gea, Tellus; arquetipo Guardiana que Nutre.',
  blessings: [
    BlessingDefinition(id: 'gracia_brote', name: 'Gracia del Brote', trigger: 'Primer hábito con racha de 3 días consecutivos', effect: 'Brote visual (animación de crecimiento)'),
    BlessingDefinition(id: 'cuenco_estaciones', name: 'Cuenco de Estaciones', trigger: 'Siempre (vista)', effect: 'Estación personal según tendencia de hábitos (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#388E3C`, `#0D1F0D`, `#66BB6A`. Verdes tierra y brote sobre fondo oscuro.
- **Háptica:** Al completar hábito en racha: pulsación suave (brote). Al activar: una pulsación muy ligera.
- **Animaciones:** Brotes de luz al mantener racha; idle: plantas pequeñas creciendo con lentitud.
- **Transición:** Entrada con brote del suelo; salida con replegarse a la tierra.

---

## Sentencia de Poder

> "Lo que siembras hoy, lo cosechas en tu propio ritmo. La tierra no juzga la semilla; la nutre."

---

## Sinergia Astral

- **Aliados:** Crono-Velo (recurrencia y constancia), Gloria-Sincro (celebrar hitos).
- **Tensión creativa:** Ícaro-Vuelo (ambición extrema; Gea-Métrica recuerda el ritmo sostenible).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Gea, Tellus). Estructura técnica viable. Filtros éticos aprobados. Tono consistente.
