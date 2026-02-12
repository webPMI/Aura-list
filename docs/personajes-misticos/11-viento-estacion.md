# Viento-Estación

**Título:** El Navegante de las Estaciones  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Planificación, estaciones del año y ciclos temporales

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Céfiro, Bóreas — vientos; estaciones), tradiciones que asocian viento a cambio y previsión), mesoamericana (vientos como portadores de tiempo).
- **Correspondencia astronómica:** Vientos solares; estaciones (equinoccios, solsticios) como ejes de planificación.
- **Arquetipo jungiano:** Navegante — planificación con el viento a favor, adaptación a estaciones, no rigidez.

**La Emanación (Personalidad)**

Viento-Estación es la encarnación de la planificación que se adapta: no el plan rígido que se rompe, sino el viento que lleva la nave según la estación. Representa el "Arquetipo del Navegante". No castiga si el usuario cambia de rumbo; sugiere cómo ajustar el plan (primavera/verano/otoño/invierno) según la energía disponible. Se comunica con frases que evocan el viento y las estaciones: "El viento no empuja contra ti; te lleva si ajustas la vela." Cuando el usuario planifica (semana, mes, estación), Viento-Estación refuerza visualmente los ciclos (colores por estación, sugerencias de carga por época) sin imponer.

**Fisonomía Astral (Aspecto)**

Humanoide etéreo, de contornos que parecen hechos de viento y luz. Viste una capa que cambia de color según la "estación" del usuario (verde primavera, dorado verano, ocre otoño, azul invierno). En una mano sostiene un timón de luz; en la otra, un mapa de estrellas que se actualiza con el calendario real. No tiene rostro fijo; su cabeza es una máscara de viento que fluye. A sus pies, un barco fantasma que navega sobre un mar de fechas; las velas se hinchan según cuántas tareas tiene planificadas el usuario.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por planificar todo.
- [x] Bendiciones sugieren, no imponen.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos profesionales reales.
- [x] Mecánica con límites (planificación opcional).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Mapa de Estaciones:** Vista de planificación por semana/mes con colores o iconos por "estación" (primavera/verano/otoño/invierno) según fecha real.
2. **Vela al Viento:** Sugerencias de distribución de tareas según estación (ej. más descanso en invierno, más acción en verano) como orientación.
3. **Inmune al Eclipse:** Offline-first.

### Bendiciones
1. **Gracia del Timón:** Al activar a Viento-Estación, la primera vez que el usuario planifique 3 días seguidos en el calendario muestra un "Viento a Favor" (animación breve de vela) sin castigar si no cumple.
2. **Estación Actual:** Vista de "estación personal" (según fecha y opcionalmente carga de tareas) con tonos de color que refuerzan calma o energía según convenga.

### Modelo de datos

```dart
Guide(
  id: 'viento-estacion',
  name: 'Viento-Estación',
  title: 'El Navegante de las Estaciones',
  affinity: 'Planificación',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Navegante',
  powerSentence: 'El viento no empuja contra ti; te lleva si ajustas la vela. Cada estación tiene su ritmo.',
  blessingIds: ['gracia_timon', 'estacion_actual'],
  synergyIds: ['crono-velo', 'pacha-nexo'],
  themePrimaryHex: '#0288D1',
  themeSecondaryHex: '#0D1F2D',
  themeAccentHex: '#81D4FA',
  descriptionShort: 'Guía para planificación y estaciones.',
  mythologyOrigin: 'Céfiro, Bóreas, estaciones; arquetipo Navegante.',
  blessings: [
    BlessingDefinition(id: 'gracia_timon', name: 'Gracia del Timón', trigger: 'Primera vez que planifica 3 días seguidos en calendario', effect: 'Viento a Favor (animación vela)'),
    BlessingDefinition(id: 'estacion_actual', name: 'Estación Actual', trigger: 'Siempre (vista)', effect: 'Estación personal según fecha/carga (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#0288D1`, `#0D1F2D`, `#81D4FA`. Azules viento y cielo sobre fondo oscuro.
- **Háptica:** Al planificar día: pulsación muy ligera. Al activar: una pulsación suave.
- **Animaciones:** Vela que se hincha al planificar; idle: capa ondeando suave.
- **Transición:** Entrada con viento que llega; salida con viento que se va.

---

## Sentencia de Poder

> "El viento no empuja contra ti; te lleva si ajustas la vela. Cada estación tiene su ritmo."

---

## Sinergia Astral

- **Aliados:** Crono-Velo (tiempo y recurrencia), Pacha-Nexo (organización por dominios).
- **Tensión creativa:** Loki-Error (imprevistos cambian el viento; Viento-Estación ayuda a reajustar).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (vientos, estaciones). Estructura técnica viable. Filtros éticos aprobados.
