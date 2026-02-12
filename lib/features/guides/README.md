# Feature: Guías Celestiales (Personajes místicos)

Todo lo relacionado con los personajes místicos de AuraList está centralizado en este feature para uso controlado y reutilizable en cualquier parte de la app.

## Estado del Feature (Actualizado 2026-02-12)

- **21 guías implementados** de 40 planificados
- **Fase 1 (Fundamentos):** COMPLETADA ✓
- **Fase 2 (Personalización):** COMPLETADA ✓
- **Fase 3 (Conexión Profunda):** PENDIENTE
- **Fase 4 (Onboarding):** PENDIENTE (Alta prioridad)

## Uso en la app

Un solo import para acceder al feature completo:

```dart
import 'package:checklist_app/features/guides/guides.dart';
```

A partir de ahí tienes:

- **Modelo:** `Guide`, `BlessingDefinition`
- **Catálogo:** `kGuideCatalog`, `getGuideById(id)`, `availableGuideIds`
- **Rutas de assets:** `GuideAssetPaths.avatar(id)`, `GuideAssetPaths.animationIdle(id)`, etc.
- **Providers:** `activeGuideIdProvider`, `activeGuideProvider`, `availableGuidesProvider`, `guidePrimaryColorProvider`, `guideSecondaryColorProvider`, `guideAccentColorProvider`, `guideVoiceProvider`
- **Bendiciones:** `kGuideBlessingRegistry`, `getBlessingById(id)`
- **Servicios:** `GuideVoiceService.instance`, `BlessingTriggerService` (via providers)
- **Widgets:** `GuideAvatar`, `showGuideSelectorSheet(context)`, `GuideGreetingWidget`, `GuideFarewellWidget`
- **Sistema de rachas:** `streakProvider`, `currentStreakProvider`, `checkStreakProvider`
- **Ciclo del día:** `dayCycleProvider`, `currentPeriodProvider`

## Ejemplos

### Mostrar avatar del guía activo

```dart
GuideAvatar(size: 48)
```

### Selector de guía (bottom sheet)

```dart
onTap: () => showGuideSelectorSheet(context),
```

### Tema con color del guía activo

```dart
final primaryColor = ref.watch(guidePrimaryColorProvider);
// Si primaryColor != null, aplicar en ThemeData o en una pantalla concreta
```

### Celebración con color del guía

```dart
final guide = ref.watch(activeGuideProvider);
final color = guide?.themeAccentHex != null
    ? _parseHex(guide!.themeAccentHex)
    : null;
CelebrationOverlay.show(context, color: color);
```

## Estructura del feature

- **data/** — Catálogo de guías (21 guías) y rutas de assets (imágenes, animaciones).
- **providers/** — Guía activo, colores de tema, voces, triggers de bendiciones.
- **widgets/** — `GuideAvatar`, `GuideSelectorSheet`, `GuideGreetingWidget`, `GuideFarewellWidget`.
- **guides.dart** — Barrel que re-exporta modelo, datos, providers, servicios y widgets.

### Archivos externos al feature (compartidos)

- **Modelo:** `lib/models/guide_model.dart` - Definiciones de `Guide` y `BlessingDefinition`
- **Registro de bendiciones:** `lib/services/guide_blessing_registry.dart` - Catálogo de bendiciones
- **Servicio de voces:** `lib/services/guide_voice_service.dart` - Mensajes personalizados (692 líneas)
- **Servicio de triggers:** `lib/services/blessing_trigger_service.dart` - Lógica de activación de bendiciones
- **Providers de racha:** `lib/providers/streak_provider.dart` - Sistema de rachas diarias
- **Servicio de ciclo del día:** `lib/services/day_cycle_service.dart` - Detección de períodos del día
- **Widgets globales:** `lib/widgets/guide_greeting_widget.dart`, `guide_farewell_widget.dart`, `streak_celebration_widget.dart`

## Assets

- **Avatares:** `assets/guides/avatars/{guideId}.png` (y opcionalmente `{guideId}_vertical.png`).
- **Animaciones:** `assets/guides/animations/{guideId}_idle.json`, `{guideId}_celebration.json`, `{guideId}_motivation.json` (opcional; si no hay archivo, se usan placeholders o animaciones por defecto).

Ver `assets/guides/avatars/README.md` y `assets/guides/animations/README.md` para nomenclatura y detalles.

## Arquitectura del sistema

### Flujo de datos

```
Usuario selecciona guía
    ↓
activeGuideIdProvider guarda en SharedPreferences
    ↓
activeGuideProvider obtiene Guide del catálogo
    ↓
UI lee guía activo para:
  - Mostrar avatar (GuideAvatar)
  - Aplicar tema (guidePrimaryColorProvider)
  - Mostrar mensajes (GuideVoiceService)
  - Activar bendiciones (BlessingTriggerService)
```

### Momentos rituales implementados

El sistema de personalización incluye 6 momentos donde el guía "habla":

1. **appOpening** - Saludo al abrir la app (1 vez por día)
2. **firstTaskOfDay** - Primera tarea completada del día
3. **streakAchieved** - Hito de racha alcanzado (3, 7, 14, 21, 30+ días)
4. **endOfDay** - Despedida al anochecer (transición a período nocturno)
5. **encouragement** - Motivación general
6. **taskCompleted** - Celebración al completar tarea

### Providers disponibles

```dart
// Guía activo
final guide = ref.watch(activeGuideProvider); // Guide?
final guideId = ref.watch(activeGuideIdProvider); // String?

// Colores del tema
final primaryColor = ref.watch(guidePrimaryColorProvider); // Color?
final accentColor = ref.watch(guideAccentColorProvider); // Color?

// Voces del guía
final voiceProvider = ref.watch(guideVoiceProvider);
final message = voiceProvider.getMessage(guide, GuideVoiceMoment.appOpening);

// Sistema de rachas
final streak = ref.watch(currentStreakProvider); // int
final checkStreak = ref.read(checkStreakProvider); // Future<int?> Function()

// Ciclo del día
final period = ref.watch(currentPeriodProvider); // TimePeriod
```

### Integración con UI

```dart
// Mostrar saludo del guía (en main_scaffold.dart)
GuideGreetingWidget()

// Mostrar despedida (listener en main_scaffold.dart)
GuideFarewellListener()

// Celebrar racha (en task_tile.dart al completar)
if (isStreakMilestone(newStreak)) {
  StreakCelebrationWidget.show(context, newStreak);
}

// Selector de guía
showGuideSelectorSheet(context)

// Avatar del guía
GuideAvatar(size: 48)
```

## Documentación de lore

- `docs/personajes-misticos/` — Fichas de personajes, correspondencias mitológicas, arquitectura y consejo de los pilares.
- `docs/personajes-misticos/GUIA_IMPLEMENTACION.md` — Guía paso a paso para agregar guías, bendiciones y voces.
- `docs/personajes-misticos/ANALISIS_UX_PILARES.md` — Análisis de UX y plan de mejora por fases.
