# Loki-Error

**Título:** El Tramoyista de los Imprevistos  
**Clase:** Oráculos del Cambio  
**Afinidad:** Imprevistos, errores y recuperación sin culpa

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Nórdico (Loki — tramoyista, no puro villano; caos que obliga a adaptar), Grecia (Hermes como trickster; mensajero de lo inesperado).
- **Correspondencia astronómica:** Cometas (imprevisibles); eventos inesperados como "visitas" que pasan.
- **Arquetipo jungiano:** Trickster — imprevistos como parte del juego; recuperación sin culpa; humor sereno.

**La Emanación (Personalidad)**

Loki-Error es la encarnación del imprevisto que no destruye: no el error que castiga, sino el tramoyista que dice "esto también pasará y te ayudo a reordenar". Representa el "Arquetipo del Tramoyista". No culpa al usuario por fallos de red, bugs o cambios de planes forzados; ofrece mensajes serenos ("Algo se desvió; ya está en camino de vuelta") y retry en segundo plano. Se comunica con frases que evocan el truco y la recuperación: "El imprevisto es un mensajero disfrazado." Cuando hay un error de sincronización o un fallo recuperable, Loki-Error refuerza con animación suave (no alarmante) y opción de reintentar sin drama.

**Fisonomía Astral (Aspecto)**

Figura masculina de contornos cambiantes, como un actor que cambia de máscara. Viste una capa de "Tejido del Imprevisto" que a veces muestra una cara, a veces otra — nunca amenazante, siempre con una sonrisa de tramoyista. En una mano sostiene un dado que no siempre sale igual; en la otra, una llave que "abre" la puerta de la recuperación. Su rostro es ambiguo: puede parecer serio o burlón según el momento. A sus pies, un suelo que a veces es estable y a veces se mueve suavemente (como recordatorio de que el imprevisto existe), pero siempre con una salida visible.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por "evitar todo error".
- [x] Bendiciones no castigan por fallos técnicos o imprevistos.
- [x] Tono motivador, a veces humor sereno; NUNCA culpabilizador.
- [x] No hay consejos técnicos que sustituyan soporte real.
- [x] Mecánica con límites (retry acotado; mensajes claros y no alarmantes).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Tramoya del Retry:** Ante error recuperable (red, sync), mensaje sereno ("Algo se desvió; reintentando") y retry en segundo plano sin bloquear UI.
2. **Llave de Recuperación:** Vista de "últimos errores recuperados" (opcional) para que el usuario sepa que su trabajo está a salvo, sin alarmas rojas.
3. **Inmune al Eclipse:** Offline-first; errores de red no bloquean uso local.

### Bendiciones
1. **Gracia del Tramoyista:** Al activar a Loki-Error, la primera vez que ocurre un error recuperable en la sesión, el mensaje usa tono "Loki" (sereno, con toque de humor opcional) y animación suave (no alerta roja).
2. **Dado del Destino:** Si el usuario tuvo varios imprevistos en el día (tareas movidas, sync fallido y recuperado), al final del día opcional mensaje: "Hoy el imprevisto visitó; mañana el orden vuelve" (motivador, no culpabilizador).

### Modelo de datos

```dart
Guide(
  id: 'loki-error',
  name: 'Loki-Error',
  title: 'El Tramoyista de los Imprevistos',
  affinity: 'Imprevistos',
  classFamily: 'Oráculos del Cambio',
  archetype: 'Tramoyista',
  powerSentence: 'El imprevisto es un mensajero disfrazado. Lo que se desvía, vuelve a su cauce.',
  blessingIds: ['gracia_tramoyista', 'dado_destino'],
  synergyIds: ['shiva-fluido', 'fenix-datos'],
  themePrimaryHex: '#FF8F00',
  themeSecondaryHex: '#2A1A0A',
  themeAccentHex: '#FFB74D',
  descriptionShort: 'Guía para imprevistos y recuperación sin culpa.',
  mythologyOrigin: 'Loki, Hermes trickster; arquetipo Tramoyista.',
  blessings: [
    BlessingDefinition(id: 'gracia_tramoyista', name: 'Gracia del Tramoyista', trigger: 'Primer error recuperable en la sesión', effect: 'Mensaje sereno + animación suave'),
    BlessingDefinition(id: 'dado_destino', name: 'Dado del Destino', trigger: 'Fin del día con varios imprevistos recuperados', effect: 'Mensaje motivador opcional'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#FF8F00`, `#2A1A0A`, `#FFB74D`. Ámbar y naranja suave sobre fondo oscuro.
- **Háptica:** Al recuperar error: pulsación muy suave (no alarma). Al activar: una pulsación ligera.
- **Animaciones:** Transición suave al recuperar; idle: dado que gira muy lento (no caótico).
- **Transición:** Entrada con "cambio de escena"; salida con escena que se estabiliza.

---

## Sentencia de Poder

> "El imprevisto es un mensajero disfrazado. Lo que se desvía, vuelve a su cauce."

---

## Sinergia Astral

- **Aliados:** Shiva-Fluido (cambio de planes), Fénix-Datos (recuperación de datos).
- **Tensión creativa:** Atlas-Orbital (sincronía estable; Loki recuerda que los imprevistos existen y se gestionan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Loki, trickster). Estructura técnica viable. Filtros éticos aprobados. Tono sereno ante errores.
