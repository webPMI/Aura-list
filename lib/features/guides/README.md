# Feature: Guías Celestiales (Personajes místicos)

Todo lo relacionado con los personajes místicos de AuraList está centralizado en este feature para uso controlado y reutilizable en cualquier parte de la app.

## Uso en la app

Un solo import para acceder al feature completo:

```dart
import 'package:checklist_app/features/guides/guides.dart';
```

A partir de ahí tienes:

- **Modelo:** `Guide`, `BlessingDefinition`
- **Catálogo:** `kGuideCatalog`, `getGuideById(id)`, `availableGuideIds`
- **Rutas de assets:** `GuideAssetPaths.avatar(id)`, `GuideAssetPaths.animationIdle(id)`, etc.
- **Providers:** `activeGuideIdProvider`, `activeGuideProvider`, `availableGuidesProvider`, `guidePrimaryColorProvider`, `guideSecondaryColorProvider`, `guideAccentColorProvider`
- **Bendiciones:** `kGuideBlessingRegistry`, `getBlessingById(id)`
- **Widgets:** `GuideAvatar`, `showGuideSelectorSheet(context)`

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

- **data/** — Catálogo de guías y rutas de assets (imágenes, animaciones).
- **providers/** — Guía activo y colores de tema.
- **widgets/** — `GuideAvatar`, `GuideSelectorSheet`.
- **guides.dart** — Barrel que re-exporta modelo, datos, providers, servicios y widgets.

El modelo `Guide` vive en `lib/models/guide_model.dart` (compartido). El registro de bendiciones vive en `lib/services/guide_blessing_registry.dart` y se re-exporta desde el barrel.

## Assets

- **Avatares:** `assets/guides/avatars/{guideId}.png` (y opcionalmente `{guideId}_vertical.png`).
- **Animaciones:** `assets/guides/animations/{guideId}_idle.json`, `{guideId}_celebration.json`, `{guideId}_motivation.json` (opcional; si no hay archivo, se usan placeholders o animaciones por defecto).

Ver `assets/guides/avatars/README.md` y `assets/guides/animations/README.md` para nomenclatura y detalles.

## Documentación de lore

- `docs/personajes-misticos/` — Fichas de personajes, correspondencias mitológicas, arquitectura y consejo de los pilares.
