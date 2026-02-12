# Atlas-Orbital

**Título:** El Sustentador de la Sincronía  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Seguridad, sincronización y respaldo de datos

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Atlas — titán que sostiene el cielo; no como castigo eterno sino como sostén del orden), tradición del mundo que se mantiene en equilibrio.
- **Correspondencia astronómica:** Órbitas (planetas que giran en sincronía); red de satélites como metáfora de sincronización.
- **Arquetipo jungiano:** Sustentador — seguridad, respaldo, sincronía entre dispositivos/nube sin angustia por "perder datos".

**La Emanación (Personalidad)**

Atlas-Orbital es la encarnación de la tranquilidad que da saber que lo importante está sostenido: no el cielo sobre los hombros como castigo, sino la órbita estable donde los datos del usuario están respaldados y en sincronía. Representa el "Arquetipo del Sustentador". No asusta con mensajes de "pérdida de datos"; comunica con calma el estado de sincronización (sincronizado, pendiente, offline) y ofrece respaldo sin dramatizar. Se comunica con frases que evocan solidez: "Tu trabajo orbita contigo; no cae." Cuando la app sincroniza o hace respaldo, Atlas-Orbital refuerza visualmente con un indicador sereno (órbita completa, no alertas rojas agresivas).

**Fisonomía Astral (Aspecto)**

Humanoide de complexión poderosa pero serena, como un titán que no sufre sino que sostiene. Viste una armadura de placas que evocan capas de órbita (círculos concéntricos de luz suave). En sus hombros no carga el cielo literal, sino una esfera translúcida donde se ven los "datos" del usuario como estrellas en órbita — cuando todo está en orden, las estrellas giran en calma; cuando hay pendiente de sincronía, una órbita parpadea suavemente. Su rostro está semioculto por una capucha; sus ojos son de un azul profundo y estable. A sus pies, un suelo que parece un mapa de órbitas entrelazadas (dispositivo, nube, respaldo).

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por estar "siempre sincronizado".
- [x] Bendiciones informan, no alarman.
- [x] Tono motivador, no culpabilizador (no "has perdido datos").
- [x] No hay consejos técnicos que sustituyan soporte real.
- [x] Mecánica con límites (indicadores claros; retry en segundo plano).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Órbita Visible:** Indicador de estado de sincronización (sincronizado / pendiente / offline) con icono y color serenos (verde/ámbar/gris), no rojo alarmante.
2. **Respaldo en Sombra:** Respaldo local y/o nube en segundo plano sin interrumpir al usuario; notificación solo si hay conflicto que requiera decisión.
3. **Inmune al Eclipse:** Offline-first; sincronía cuando hay red sin bloquear uso local.

### Bendiciones
1. **Gracia del Sustentador:** Al activar a Atlas-Orbital, la primera sincronización exitosa del día (si hay red) muestra un "Orbita Completa" (animación breve de órbita cerrada) sin castigar si después hay fallo de red.
2. **Manto de Respaldo:** Vista de "última sincronización" y "estado de respaldo" (orientativo) para que el usuario sepa que su trabajo está sostenido, sin alarmas innecesarias.

### Modelo de datos

```dart
Guide(
  id: 'atlas-orbital',
  name: 'Atlas-Orbital',
  title: 'El Sustentador de la Sincronía',
  affinity: 'Sincronización',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Sustentador',
  powerSentence: 'Tu trabajo orbita contigo; no cae. Lo que construyes está sostenido.',
  blessingIds: ['gracia_sustentador', 'manto_respaldo'],
  synergyIds: ['anubis-vinculo', 'fenix-datos'],
  themePrimaryHex: '#37474F',
  themeSecondaryHex: '#0D1F2D',
  themeAccentHex: '#78909C',
  descriptionShort: 'Guía para sincronización y respaldo.',
  mythologyOrigin: 'Atlas, órbitas; arquetipo Sustentador.',
  blessings: [
    BlessingDefinition(id: 'gracia_sustentador', name: 'Gracia del Sustentador', trigger: 'Primera sincronización exitosa del día', effect: 'Órbita Completa (animación)'),
    BlessingDefinition(id: 'manto_respaldo', name: 'Manto de Respaldo', trigger: 'Siempre (vista)', effect: 'Estado de sincronización y respaldo (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#37474F`, `#0D1F2D`, `#78909C`. Grises azulados y estables sobre fondo oscuro.
- **Háptica:** Al sincronizar correctamente: pulsación suave única. Al activar: una pulsación muy ligera.
- **Animaciones:** Órbitas que se cierran al sincronizar; idle: esfera con estrellas girando en calma.
- **Transición:** Entrada con órbita que se forma; salida con órbita que se mantiene en segundo plano.

---

## Sentencia de Poder

> "Tu trabajo orbita contigo; no cae. Lo que construyes está sostenido."

---

## Sinergia Astral

- **Aliados:** Anubis-Vínculo (privacidad y guardado), Fénix-Datos (recuperación si algo falla).
- **Tensión creativa:** Loki-Error (imprevistos técnicos; Atlas-Orbital da calma y retry).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Atlas, órbitas). Estructura técnica viable. Filtros éticos aprobados.
