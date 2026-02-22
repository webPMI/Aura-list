# Guía de Implementación: Guías Celestiales

Esta guía proporciona instrucciones paso a paso para extender el sistema de Guías Celestiales de AuraList.

---

## Tabla de Contenidos

1. [Agregar un nuevo guía al catálogo](#1-agregar-un-nuevo-guía-al-catálogo)
2. [Agregar nuevas bendiciones](#2-agregar-nuevas-bendiciones)
3. [Agregar voces personalizadas al guía](#3-agregar-voces-personalizadas-al-guía)
4. [Modificar mensajes existentes](#4-modificar-mensajes-existentes)
5. [Integrar triggers de bendiciones](#5-integrar-triggers-de-bendiciones)
6. [Agregar assets visuales](#6-agregar-assets-visuales)
7. [Testing y validación](#7-testing-y-validación)

---

## 1. Agregar un nuevo guía al catálogo

### Paso 1.1: Diseñar la ficha del guía

Primero crea la ficha conceptual en `docs/personajes-misticos/` usando la plantilla:

```markdown
# [Número]-[nombre-slug].md

## [Nombre del Guía]

**Título:** [Título completo]
**Afinidad:** [Dominio principal]
**Familia de Clase:** [Conclave/Arquitectos/Oráculos del...]
**Arquetipo:** [Rol arquetípico]

### Sentencia de Poder
> [Frase inspiradora que define al guía]

### Origen Mitológico
[Referencias a mitología/astronomía]

### Bendiciones
1. **[Nombre de Bendición 1]** (ID: `blessing_id_1`)
   - Trigger: [Cuándo se activa]
   - Efecto: [Qué hace]

2. **[Nombre de Bendición 2]** (ID: `blessing_id_2`)
   - Trigger: [Cuándo se activa]
   - Efecto: [Qué hace]

### Sinergias
- **[Guía aliado 1]** (ID: `guide-id-1`): [Por qué son compatibles]
- **[Guía aliado 2]** (ID: `guide-id-2`): [Por qué son compatibles]

### Paleta de Colores
- Primary: `#RRGGBB`
- Secondary: `#RRGGBB`
- Accent: `#RRGGBB`
```

### Paso 1.2: Agregar al catálogo técnico

Edita `lib/features/guides/data/guide_catalog.dart`:

```dart
Guide(
  id: 'nombre-guia',  // Slug en kebab-case
  name: 'Nombre-Guía', // Nombre con guiones (ej: Raiz-Eterea)
  title: 'El/La [Título Completo]',
  affinity: 'Dominio principal', // Ej: 'Conexión familiar'
  classFamily: 'Familia de Clase', // Ej: 'Oráculos del Vínculo'
  archetype: 'Arquetipo', // Ej: 'Tejedora de Raíces'
  powerSentence: 'Tu sentencia de poder aquí. Debe ser inspiradora y reflejar la filosofía del guía.',
  blessingIds: ['blessing_id_1', 'blessing_id_2'],
  synergyIds: ['guia-aliado-1', 'guia-aliado-2'],
  themePrimaryHex: '#RRGGBB',
  themeSecondaryHex: '#RRGGBB',
  themeAccentHex: '#RRGGBB',
  descriptionShort: 'Descripción breve de 1-2 líneas para el selector.',
  mythologyOrigin: 'Referencias mitológicas/astronómicas.',
),
```

**Importante:**
- El `id` debe ser único, en minúsculas y usar guiones (kebab-case)
- Los `blessingIds` deben existir en el registro de bendiciones (ver sección 2)
- Los `synergyIds` deben ser IDs de otros guías ya existentes
- Los colores hex deben incluir el `#` y ser válidos

### Paso 1.3: Actualizar documentación

Marca el guía como completado en `docs/personajes-misticos/00-todo.md`:

```markdown
- [x] **[Nombre-Guía]** - [Título] ([Afinidad])
```

---

## 2. Agregar nuevas bendiciones

### Paso 2.1: Definir la bendición

Edita `lib/services/guide_blessing_registry.dart`:

```dart
'blessing_id': const BlessingDefinition(
  id: 'blessing_id',
  name: 'Nombre de la Bendición',
  trigger: 'Descripción clara de cuándo se activa',
  effect: 'Descripción del efecto visible/feedback',
),
```

**Principio del Guardián:** Las bendiciones NUNCA castigan. Solo refuerzan positivamente (animación, haptic, mensaje motivador, sugerencia orientativa).

### Paso 2.2: Tipos de triggers comunes

```dart
// Triggers basados en eventos
trigger: 'Primeras N tareas completadas del día'
trigger: 'Racha de X días consecutivos'
trigger: 'Primera vez que [acción] en la sesión'
trigger: 'Al completar tarea de categoría [X]'

// Triggers de vista (siempre activos)
trigger: 'Siempre (vista)'
trigger: 'Siempre (opción)'

// Triggers de estado
trigger: 'Mucho tiempo en lista sin actuar'
trigger: 'Muchas tareas pendientes + rato en lista'
trigger: 'Fin del día con [condición] completada'
```

### Paso 2.3: Tipos de efectos comunes

```dart
// Efectos visuales
effect: 'Animación [tipo] + haptic celebración'
effect: 'Ecos de Aura (reducción visual de carga)'
effect: 'Sello [nombre] visual'

// Efectos de feedback
effect: 'Mensaje motivador personalizado'
effect: 'Celebración con voz del guía'

// Efectos de sugerencia (no forzados)
effect: 'Sugerir [acción] (orientativo)'
effect: 'Vista de [información] (orientativo)'
```

---

## 3. Agregar voces personalizadas al guía

### Paso 3.1: Definir personalidad del guía

Antes de escribir mensajes, define la personalidad:

**Ejemplos de personalidades:**
- **Aethel:** Épico, urgente, fuego, acción inmediata
- **Crono-Velo:** Paciente, metódico, tejido, ritmo
- **Luna-Vacía:** Sereno, protector, silencio, equilibrio
- **Loki-Error:** Juguetón, resiliente, aceptación del caos

### Paso 3.2: Agregar mensajes al servicio de voces

Edita `lib/services/guide_voice_service.dart`:

```dart
'nombre-guia': {
  GuideVoiceMoment.appOpening: [
    'Mensaje 1 al abrir la app.',
    'Mensaje 2 al abrir la app.',
    'Mensaje 3 al abrir la app.',
  ],
  GuideVoiceMoment.firstTaskOfDay: [
    'Mensaje al completar primera tarea!',
    'Otro mensaje motivador para inicio.',
  ],
  GuideVoiceMoment.streakAchieved: [
    '{days} dias de [metáfora del guía]. [Celebración]!',
    'Tu [atributo] suma {days} dias.',
  ],
  GuideVoiceMoment.endOfDay: [
    'Mensaje de despedida del día.',
    'Otro mensaje al final del día.',
  ],
  GuideVoiceMoment.encouragement: [
    'Frase motivadora general.',
    'Otra frase de ánimo.',
  ],
  GuideVoiceMoment.taskCompleted: [
    'Mensaje corto 1!',
    'Mensaje corto 2.',
    'Mensaje corto 3.',
  ],
},
```

**Importante:**
- Usa la variable `{days}` en `streakAchieved` para mostrar el número de días
- Provee al menos 2-3 variantes por momento para variedad
- Mantén consistencia con la personalidad del guía
- Los mensajes de `taskCompleted` deben ser breves (1-3 palabras o frase corta)

### Paso 3.3: Verificar cobertura completa

Asegúrate de cubrir los 6 momentos rituales:
- ✓ `appOpening` - Saludo al abrir la app
- ✓ `firstTaskOfDay` - Primera tarea completada
- ✓ `streakAchieved` - Hito de racha alcanzado
- ✓ `endOfDay` - Fin del día exitoso
- ✓ `encouragement` - Motivación general
- ✓ `taskCompleted` - Tarea completada (general)

---

## 4. Modificar mensajes existentes

### Paso 4.1: Localizar el guía

Los mensajes están organizados por familia de clase en `guide_voice_service.dart`:

```dart
// ========== CONCLAVE DEL IMPETU ==========
'aethel': { ... },
'helioforja': { ... },
...

// ========== ARQUITECTOS DEL CICLO ==========
'crono-velo': { ... },
...

// ========== ORACULOS DEL REPOSO ==========
'luna-vacia': { ... },
...
```

### Paso 4.2: Editar mensajes

Simplemente reemplaza o agrega mensajes en la lista correspondiente:

```dart
GuideVoiceMoment.appOpening: [
  'Mensaje original.',
  'Mensaje nuevo que agregas.',  // ← NUEVO
],
```

### Paso 4.3: Probar variedad

El servicio selecciona mensajes de forma semi-aleatoria. Para probar:

```dart
// En un widget de prueba
final message = GuideVoiceService.instance.getMessage(
  guide,
  GuideVoiceMoment.appOpening,
);
print(message); // Debería variar entre los mensajes disponibles
```

---

## 5. Integrar triggers de bendiciones

### Paso 5.1: Identificar el momento del trigger

Los triggers se pueden activar en:
- Completar tarea (`task_tile.dart`, método `_onTaskCompleted`)
- Crear tarea (`task_form.dart`)
- Abrir la app (`main_scaffold.dart`, `initState`)
- Alcanzar racha (`streak_provider.dart`)
- Cambios de estado (observers/listeners)

### Paso 5.2: Implementar lógica del trigger

Edita `lib/services/blessing_trigger_service.dart`:

```dart
/// Evalúa si se debe activar la bendición [blessingId]
bool shouldTriggerBlessing(String blessingId, Map<String, dynamic> context) {
  switch (blessingId) {
    case 'mi_nueva_bendicion':
      // Lógica de evaluación
      final tasksToday = context['tasksCompletedToday'] as int? ?? 0;
      return tasksToday == 1; // Primera tarea del día

    case 'otra_bendicion':
      final category = context['taskCategory'] as String?;
      return category == 'Salud'; // Tarea de salud

    default:
      return false;
  }
}
```

### Paso 5.3: Conectar trigger a evento

Ejemplo en `task_tile.dart`:

```dart
Future<void> _onTaskCompleted() async {
  // ... guardar tarea ...

  // Verificar bendiciones del guía activo
  final guide = ref.read(activeGuideProvider);
  if (guide != null) {
    final context = {
      'tasksCompletedToday': tasksCompletedToday,
      'taskCategory': widget.task.category,
      'taskPriority': widget.task.priority,
    };

    for (final blessingId in guide.blessingIds) {
      if (shouldTriggerBlessing(blessingId, context)) {
        await _showBlessingFeedback(blessingId);
      }
    }
  }
}
```

### Paso 5.4: Implementar feedback visual

```dart
Future<void> _showBlessingFeedback(String blessingId) async {
  final blessing = getBlessingById(blessingId);
  if (blessing == null) return;

  // Animación
  await BlessingFeedback.show(
    context,
    blessing: blessing,
    guide: ref.read(activeGuideProvider),
  );

  // Haptic opcional
  if (Platform.isIOS || Platform.isAndroid) {
    HapticFeedback.mediumImpact();
  }
}
```

---

## 6. Agregar assets visuales

### Paso 6.1: Preparar imagen del avatar

Especificaciones:
- **Formato:** PNG con transparencia
- **Tamaño:** 512x512 px (se escalará automáticamente)
- **Estilo:** Coherente con los demás guías
- **Nombre:** `[guide-id].png` (ej: `aethel.png`)

### Paso 6.2: Agregar a assets

1. Coloca la imagen en `assets/guides/avatars/[guide-id].png`
2. Verifica que `pubspec.yaml` incluya la ruta:

```yaml
flutter:
  assets:
    - assets/guides/avatars/
```

### Paso 6.3: (Opcional) Agregar imagen vertical

Para pantallas de bienvenida:
- **Nombre:** `[guide-id]_vertical.png`
- **Tamaño:** 512x1024 px (ratio 1:2)

### Paso 6.4: (Opcional) Agregar animaciones Lottie

Para animaciones avanzadas:
1. Coloca los JSON en `assets/guides/animations/`
2. Nomenclatura:
   - `[guide-id]_idle.json` - Estado neutral
   - `[guide-id]_celebration.json` - Celebración
   - `[guide-id]_motivation.json` - Motivación

3. Actualiza `GuideAssetPaths` si es necesario:

```dart
static String animationIdle(String guideId) =>
    'assets/guides/animations/${guideId}_idle.json';
```

---

## 7. Testing y validación

### Paso 7.1: Verificar compilación

```bash
flutter analyze
dart run build_runner build --delete-conflicting-outputs
```

### Paso 7.2: Validar consistencia

Ejecuta estas verificaciones:

**1. Verificar synergyIds:**
```dart
// Todos los IDs en synergyIds deben existir en el catálogo
for (final guide in kGuideCatalog) {
  for (final synergyId in guide.synergyIds) {
    assert(getGuideById(synergyId) != null,
      'Synergy ID inválido: $synergyId en ${guide.id}');
  }
}
```

**2. Verificar blessingIds:**
```dart
// Todos los IDs en blessingIds deben existir en el registro
for (final guide in kGuideCatalog) {
  for (final blessingId in guide.blessingIds) {
    assert(getBlessingById(blessingId) != null,
      'Blessing ID inválido: $blessingId en ${guide.id}');
  }
}
```

**3. Verificar voces:**
```dart
// Todos los guías deben tener voces definidas
for (final guide in kGuideCatalog) {
  final hasVoices = GuideVoiceService.instance._messagesByGuide
    .containsKey(guide.id);
  assert(hasVoices, 'Guía sin voces: ${guide.id}');
}
```

### Paso 7.3: Prueba manual

1. **Selector de guías:**
   - Abre el selector (`showGuideSelectorSheet`)
   - Verifica que el nuevo guía aparezca en su classFamily
   - Selecciona el guía y verifica que se active correctamente

2. **Avatar y tema:**
   - Verifica que el avatar se muestre correctamente
   - Comprueba que los colores del tema se apliquen

3. **Voces:**
   - Abre la app → debe mostrar saludo del guía
   - Completa una tarea → debe mostrar mensaje de celebración
   - Alcanza un hito de racha → debe celebrar con voz personalizada

4. **Bendiciones:**
   - Activa los triggers definidos
   - Verifica que el feedback sea correcto
   - Comprueba que no haya errores en consola

### Paso 7.4: Actualizar documentación

Después de validar:
1. Marca el guía como implementado en `00-todo.md`
2. Actualiza `lib/features/guides/README.md` si es necesario
3. Agrega notas de sesión en `00-todo.md`

---

## Checklist de implementación completa

Al agregar un nuevo guía, verifica que hayas completado:

- [ ] Ficha conceptual creada en `docs/personajes-misticos/`
- [ ] Guía agregado a `guide_catalog.dart`
- [ ] Bendiciones registradas en `guide_blessing_registry.dart`
- [ ] Voces completas en `guide_voice_service.dart` (6 momentos)
- [ ] Avatar agregado a `assets/guides/avatars/`
- [ ] SynergyIds válidos (todos existen en catálogo)
- [ ] BlessingIds válidos (todos existen en registro)
- [ ] `flutter analyze` sin errores
- [ ] Prueba manual exitosa
- [ ] Documentación actualizada (`00-todo.md`, `README.md`)

---

## Recursos adicionales

- **Plantilla de ficha:** `docs/personajes-misticos/1-aethel.md` (referencia completa)
- **Ejemplo de implementación:** Ver cualquier guía del Cónclave del Ímpetu
- **Documentación de arquitectura:** `docs/personajes-misticos/ARQUITECTURA_GUIAS_EN_APP.md`
- **Análisis UX:** `docs/personajes-misticos/ANALISIS_UX_PILARES.md`

---

**Última actualización:** 2026-02-12
**Estado del sistema:** 21 guías implementados, 19 pendientes
