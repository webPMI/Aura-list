# Selene-Fase

**Título:** La Tejedora del Progreso Lunar  
**Clase:** Oráculos del Reposo  
**Afinidad:** Progreso visible, fases y ciclos de avance

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Selene — diosa de la luna; fases lunares), Egipto (Thoth asociado a ciclos lunares), tradición de la luna como medidora del tiempo.
- **Correspondencia astronómica:** Luna (fases: nueva, creciente, llena, menguante); ciclo lunar como metáfora de progreso por etapas.
- **Arquetipo jungiano:** Guía de las Fases — progreso por etapas visibles, no todo-o-nada; aceptación del ciclo.

**La Emanación (Personalidad)**

Selene-Fase es la encarnación del progreso que se ve por fases: no el "todo listo" de golpe, sino la luna que crece día a día. Representa el "Arquetipo de la Tejedora de Fases". No castiga si el usuario no completa todo; muestra cómo cada paso (creciente, llena) es una fase más en el ciclo. Se comunica con frases que evocan la luna: "Hoy no necesitas estar llena; solo crecer un poco." Cuando el usuario avanza en un proyecto o hábito, Selene-Fase hace que la interfaz muestre una "fase" (creciente, llena) según el progreso, reforzando la sensación de avance sin presión por completar todo.

**Fisonomía Astral (Aspecto)**

Figura femenina de contornos plateados y translúcidos, como la luna misma. Viste una túnica que cambia de forma según la "fase" del usuario: creciente (una franja de luz), llena (círculo completo de luz suave), menguante (franja que se apaga). En una mano sostiene un espejo que no refleja el rostro, sino el progreso del usuario (porcentaje o etapas). No tiene pies sólidos; flota como la luna sobre un mar de datos. A su alrededor orbitan pequeñas lunas que representan proyectos o hábitos; cada una en una fase distinta.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por completar todo.
- [x] Bendiciones muestran fases sin castigar la fase "menguante".
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos médicos reales.
- [x] Mecánica con límites (fases orientativas).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Fase Visible:** Muestra progreso por proyecto/hábito como "fase lunar" (creciente/llena/menguante) según % o etapas completadas.
2. **Ciclo de Progreso:** Vista de ciclos (semana/mes) donde el usuario ve su "fase" global sin números agresivos.
3. **Inmune al Eclipse:** Offline-first.

### Bendiciones
1. **Gracia de la Creciente:** Al activar a Selene-Fase, el primer avance visible en un proyecto (ej. 25% o primera etapa) muestra animación "luna creciente" sin castigar si después se estanca.
2. **Espejo de Fases:** Vista de "fase actual" del usuario (creciente/llena/menguante) según tendencia reciente (orientativo).

### Modelo de datos

```dart
Guide(
  id: 'selene-fase',
  name: 'Selene-Fase',
  title: 'La Tejedora del Progreso Lunar',
  affinity: 'Progreso',
  classFamily: 'Oráculos del Reposo',
  archetype: 'Tejedora de Fases',
  powerSentence: 'Hoy no necesitas estar llena; solo crecer un poco. Cada fase es parte del ciclo.',
  blessingIds: ['gracia_creciente', 'espejo_fases'],
  synergyIds: ['luna-vacia', 'crono-velo'],
  themePrimaryHex: '#B0BEC5',
  themeSecondaryHex: '#1A1A2E',
  themeAccentHex: '#E1F5FE',
  descriptionShort: 'Guía para progreso por fases.',
  mythologyOrigin: 'Selene, fases lunares; arquetipo Tejedora de Fases.',
  blessings: [
    BlessingDefinition(id: 'gracia_creciente', name: 'Gracia de la Creciente', trigger: 'Primer avance visible en un proyecto (25% o etapa)', effect: 'Animación luna creciente'),
    BlessingDefinition(id: 'espejo_fases', name: 'Espejo de Fases', trigger: 'Siempre (vista)', effect: 'Fase actual según tendencia (orientativo)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#B0BEC5`, `#1A1A2E`, `#E1F5FE`. Plateados y azul muy suave sobre fondo oscuro.
- **Háptica:** Al avanzar fase: pulsación muy suave. Al activar: una pulsación ligera.
- **Animaciones:** Luna creciente/llena según progreso; idle: orbitas de lunas pequeñas.
- **Transición:** Entrada con aparición de luna; salida con menguante.

---

## Sentencia de Poder

> "Hoy no necesitas estar llena; solo crecer un poco. Cada fase es parte del ciclo."

---

## Sinergia Astral

- **Aliados:** Luna-Vacía (descanso como parte del ciclo), Crono-Velo (constancia en el tiempo).
- **Tensión creativa:** Aethel (impulso vs fases; se complementan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Selene, fases lunares). Estructura técnica viable. Filtros éticos aprobados.
