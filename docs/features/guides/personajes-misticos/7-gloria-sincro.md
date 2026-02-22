# Gloria-Sincro

**Título:** La Tejedora de Logros  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Logros, hitos y celebración del progreso

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Nike — victoria alada; Gloria como fama y honor), Roma (Fama, Gloria), tradición de los juegos y la corona.
- **Correspondencia astronómica:** Estrella polar / Norte (orientación hacia el objetivo); constelación Corona Borealis (corona del norte).
- **Arquetipo jungiano:** Héroe que celebra — reconocimiento del esfuerzo, hitos visibles, motivación por logros sin obsesión por el ranking.

**La Emanación (Personalidad)**

Gloria-Sincro es la encarnación del momento en que una meta se cumple: la corona que no aplasta, sino que reconoce. Representa el "Arquetipo de la Victoria Consciente". No premia la competencia con otros, sino la sincronía entre el esfuerzo del usuario y su propio destino. Se comunica con fanfarrias sutiles — no ruidosas — y con frases que refuerzan que el logro es del usuario, no de la app. Cuando el usuario alcanza un hito (N tareas completadas, racha de X días), Gloria-Sincro hace que la interfaz muestre una corona o un destello de luz que "sincroniza" visualmente el progreso, sin castigar si no se llega.

**Fisonomía Astral (Aspecto)**

Figura femenina alada, de contornos dorados y plateados, con una corona de luz que no es rígida sino fluida (como llamas bajas). Viste una túnica de "Tejido de Hitos", donde cada hilo brilla cuando el usuario alcanza un logro. Sus alas son de luz cristalina; no vuelan hacia arriba en arrogancia, sino que se pliegan en calma cuando no hay nada que celebrar. En una mano sostiene un cetro que termina en un engranaje y una estrella entrelazados — símbolo de sincronía entre esfuerzo y resultado. A sus pies, un mosaico de baldosas que se iluminan con cada hito alcanzado.

---

## GUARDIÁN: Validación ética

- [x] No promueve obsesión por puntos o ranking.
- [x] Bendiciones celebran logros sin castigar el no-logro.
- [x] Tono motivador, no culpabilizador.
- [x] No hay consejos financieros o legales reales.
- [x] Mecánica con límites (hitos definidos, no loops infinitos).

---

## ARQUITECTO: Estructura técnica

### Cualidades
1. **Corona de Hitos:** Muestra hitos configurables (N tareas/día, racha de X días) y los resalta al alcanzarlos.
2. **Sincronía Visual:** Al alcanzar un hito, animación de "sincronía" (corona o destello) y opcional haptic suave.
3. **Inmune al Eclipse:** Offline-first; hitos locales prioritarios.

### Bendiciones
1. **Gracia de la Corona:** Al activar a Gloria-Sincro, el primer hito alcanzado del día genera un "Eco de Gloria" (animación breve de reconocimiento) sin penalizar si no se alcanza más.
2. **Tejido de Fama:** Historial de hitos alcanzados (últimos 7 días) visible en una vista resumida, sin ranking con otros usuarios.

### Modelo de datos

```dart
Guide(
  id: 'gloria-sincro',
  name: 'Gloria-Sincro',
  title: 'La Tejedora de Logros',
  affinity: 'Logros',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Victoria Consciente',
  powerSentence: 'La corona no pesa sobre quien la ha tejido con sus propias manos. Cada hito es un latido más en sincronía con tu destino.',
  blessingIds: ['gracia_corona', 'tejido_fama'],
  synergyIds: ['aethel', 'gea-metrica'],
  themePrimaryHex: '#FFD700',
  themeSecondaryHex: '#2A1810',
  themeAccentHex: '#FFA000',
  descriptionShort: 'Guía para logros e hitos.',
  mythologyOrigin: 'Nike, Corona Borealis; arquetipo Victoria Consciente.',
  blessings: [
    BlessingDefinition(id: 'gracia_corona', name: 'Gracia de la Corona', trigger: 'Primer hito alcanzado del día', effect: 'Eco de Gloria (animación de reconocimiento)'),
    BlessingDefinition(id: 'tejido_fama', name: 'Tejido de Fama', trigger: 'Siempre', effect: 'Vista resumida de hitos últimos 7 días (sin ranking)'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#FFD700`, `#2A1810`, `#FFA000`. Dorados y ámbar sobre fondo oscuro.
- **Háptica:** Al alcanzar hito: pulsación suave doble (corona). Al activar: una pulsación ligera.
- **Animaciones:** Corona de luz fluida al alcanzar hito; idle: alas plegadas con brillo suave.
- **Transición:** Entrada con despliegue de alas suave; salida con pliegue.

---

## Sentencia de Poder

> "La corona no pesa sobre quien la ha tejido con sus propias manos. Cada hito es un latido más en sincronía con tu destino."

---

## Sinergia Astral

- **Aliados:** Aethel (prioridad para empezar), Gea-Métrica (hábitos que dan frutos visibles).
- **Tensión creativa:** Ícaro-Vuelo (ambición extrema; Gloria-Sincro modera con celebración sana).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica (Nike, Corona Borealis). Estructura técnica viable. Filtros éticos aprobados. Tono consistente.
