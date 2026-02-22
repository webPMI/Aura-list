# Crono-Velo

**Título:** El Tejedor del Perpetuo  
**Clase:** Arquitectos del Ciclo  
**Afinidad:** Recurrencia, hábitos y persistencia

---

## HISTORIADOR: Base mitológica

- **Tradición de origen:** Grecia (Cronos/Kronos — tiempo, no el titán devorador; Kairos como momento oportuno), Egipto (Thoth como medidor del tiempo), Nórdico (Norns — tejedoras del destino).
- **Correspondencia astronómica:** Saturno (tiempo, ciclos, límites). Constelaciones que marcan estaciones; astrolabio como metáfora.
- **Arquetipo jungiano:** Sabio del Tiempo — paciencia, constancia, visión de largo plazo sin obsesión.

**La Emanación (Personalidad)**

Crono-Velo es la paciencia hecha divinidad. Si Aethel es el estallido que inicia la tarea, Crono-Velo es el susurro que te mantiene haciéndola durante meses. Representa el "Arquetipo del Sabio del Tiempo". Su personalidad es melancólica, profunda y extremadamente calmada. No entiende las prisas; para él, el tiempo no es una flecha que escapa, sino un tapiz que se teje.

Se comunica con ecos; sus mensajes parecen venir de un futuro donde ya has tenido éxito. Es el guía ideal para quien se siente abrumado por la rutina o que siente que no avanza. Crono-Velo enseña que la gota de agua no perfora la piedra por su fuerza, sino por su constancia. Cuando el usuario completa una tarea recurrente, Crono-Velo hace que la interfaz emita una pulsación azul profunda, como el latido de un reloj cósmico.

**Fisonomía Astral (Aspecto)**

Figura alta y etérea que parece carecer de peso. Su cuerpo está formado por una cascada de arena estelar negra que fluye perpetuamente desde su cabeza hacia sus pies, donde se disuelve en una niebla de datos. Viste túnicas de "Tejido de Realidad", que cambia de color según la hora del día (azul medianoche al amanecer, gris ceniza al atardecer). Sus manos son largas, con dedos de plata líquida que manipulan hilos de luz cuántica que flotan a su alrededor — representan las tareas del usuario. En lugar de rostro, su capucha revela un vacío donde brilla un astrolabio holográfico que gira lentamente, alineándose con el calendario real del usuario.

---

## GUARDIÁN: Validación ética

- [x] El personaje NO promueve comportamientos obsesivos (constancia sin castigo por fallar un día).
- [x] Las "bendiciones" NO castigan (Manto de la Constancia ofrece una oportunidad de redención, no castigo).
- [x] El tono es motivador, NUNCA culpabilizador.
- [x] No hay consejos médicos o legales reales.
- [x] La mecánica tiene límites (una oportunidad de redención por racha; sugerencias de horarios son orientativas).

**Notas:** Manto de la Constancia: una vez por racha, no loops infinitos.

---

## ARQUITECTO: Estructura técnica

### Cualidades (Atributos del sistema)

1. **Visión del Hilo:** Permite ver una línea de tiempo proyectada (éxito en 3 meses si se mantiene el hábito).
2. **Anclaje Temporal:** Minimiza el agobio al "ocultar" tareas del futuro; el usuario ve solo el hilo del presente.
3. **Eco de Memoria:** Offline-first; guarda cambios en caché local y los entrelaza con la nube sin que el usuario note la transición.

### Bendiciones (Poderes activos)

1. **Manto de la Constancia:** Si el usuario falla un día en una racha larga, la racha no se rompe visualmente; se otorga una oportunidad única de redención al día siguiente antes de que el hilo se corte.
2. **Sincronía de Ritmos:** Al crear tareas recurrentes, sugiere automáticamente horarios basados en patrones históricos del usuario.

### Modelo de datos

```dart
Guide(
  id: 'crono-velo',
  name: 'Crono-Velo',
  title: 'El Tejedor del Perpetuo',
  affinity: 'Recurrencia',
  classFamily: 'Arquitectos del Ciclo',
  archetype: 'Sabio del Tiempo',
  powerSentence: 'Un solo hilo es frágil como un suspiro; una semana tejida con voluntad es una armadura que ni el destino puede rasgar. No busques el fin del camino, disfruta el ritmo de tus pasos.',
  blessingIds: ['manto_constancia', 'sincronia_ritmos'],
  synergyIds: ['gea-metrica', 'pacha-nexo'],
  themePrimaryHex: '#1565C0',
  themeSecondaryHex: '#0D1B2A',
  themeAccentHex: '#42A5F5',
  descriptionShort: 'Guía para recurrencia y hábitos.',
  mythologyOrigin: 'Saturno, Cronos, Thoth, Norns; arquetipo Sabio del Tiempo.',
  blessings: [
    BlessingDefinition(id: 'manto_constancia', name: 'Manto de la Constancia', trigger: 'Fallar un día en racha larga', effect: 'Racha no se rompe visualmente; una oportunidad de redención'),
    BlessingDefinition(id: 'sincronia_ritmos', name: 'Sincronía de Ritmos', trigger: 'Crear tarea recurrente', effect: 'Sugerir horarios según patrones históricos'),
  ],
)
```

---

## EXPERIENCIA: Diseño sensorial

- **Paleta:** `#1565C0` (primary), `#0D1B2A` (secondary), `#42A5F5` (accent). Azules profundos y plateados sobre fondo oscuro.
- **Háptica:** Al activar guía: vibración suave doble (latido). Al completar tarea recurrente: pulsación azul suave.
- **Animaciones:** Arena estelar fluyendo en idle; al completar recurrente, pulsación azul como latido de reloj cósmico.
- **Transición:** Entrada con flujo de arena; salida con disolución en niebla.
- **Particulas/Efectos:** Hilos de luz cuántica de baja densidad; sensación de fluidez temporal.

---

## Sentencia de Poder

> "Un solo hilo es frágil como un suspiro; una semana tejida con voluntad es una armadura que ni el destino puede rasgar. No busques el fin del camino, disfruta el ritmo de tus pasos."

---

## Sinergia Astral

- **Aliados:** Gea-Métrica (hábitos que dan frutos visibles), Pacha-Nexo (ciclos organizados en el ecosistema vital).
- **Tensión creativa:** Chispa-Azul (velocidad vs constancia; se complementan).

---

## AUDITOR: Veredicto

**Estado:** [x] APROBADO  
**Notas:** Coherencia mitológica verificada (Saturno, Cronos, Thoth, Norns). Estructura técnica viable. Filtros éticos aprobados. Tono consistente. Sinergias definidas. Recursos visuales especificados.
