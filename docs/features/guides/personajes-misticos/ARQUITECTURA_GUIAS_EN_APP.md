# Arquitectura: Guías Celestiales en AuraList

Diseño de implementación para integrar el Panteón de Guías (Herederos) en la aplicación Flutter.

---

## Feature centralizado

Todo lo relacionado con personajes místicos está en el **feature Guías Celestiales** (`lib/features/guides/`), de uso controlado y reutilizable:

- **Punto de entrada único:** `import 'package:checklist_app/features/guides/guides.dart';`
- **Incluye:** data (catálogo, rutas de assets), providers (guía activo, tema), widgets (GuideAvatar, GuideSelectorSheet), re-exports del modelo y del registro de bendiciones.
- **Assets:** `assets/guides/avatars/` (imágenes por guía), `assets/guides/animations/` (Lottie opcional). Ver README en cada carpeta.
- **Documentación del feature:** `lib/features/guides/README.md`

## Resumen

- **Personajes:** 21 guías con ficha completa (pausa en creación de más; 19 pendientes).
- **Modelo:** `Guide` y `BlessingDefinition` en `lib/models/guide_model.dart` (re-exportado desde el feature).
- **Estado:** Guía activa por usuario → `activeGuideId` en preferencias (y opcionalmente en Firestore en documento usuario).
- **Tema:** Cuando hay guía activa, la app puede aplicar colores del guía (`guidePrimaryColorProvider`, etc.) además del tema claro/oscuro.
- **Bendiciones:** Cada guía tiene `blessingIds`; la lógica se resuelve por ID en `guide_blessing_registry.dart`.
- **Widgets:** `GuideAvatar`, `showGuideSelectorSheet(context)`; celebraciones con color del guía usando `CelebrationOverlay.show(context, color: ref.watch(guideAccentColorProvider))`.

---

## Flujo de datos

```
Usuario elige guía → activeGuideProvider guarda activeGuideId (SharedPreferences)
                          ↓
UI / tema / bendiciones leen activeGuideProvider → obtienen Guide? del catálogo
                          ↓
Si Guide != null: aplicar paleta opcional, registrar bendiciones activas para triggers
```

---

## Componentes

### 1. Catálogo de guías (`lib/features/guides/data/guide_catalog.dart`)

- Lista fija de los 21 `Guide` (por ahora en código; luego puede venir de Firestore `guides`).
- Función `Guide? getGuideById(String id)` para obtener un guía por ID.
- Lista de IDs disponibles para el selector: `List<String> get availableGuideIds`.

### 2. Provider del guía activo (`lib/features/guides/providers/active_guide_provider.dart`)

- **Estado:** `String? activeGuideId` (null = sin guía; usa tema por defecto).
- **Lectura:** `activeGuideProvider` → `Guide?` (busca en catálogo por `activeGuideId`).
- **Escritura:** `setActiveGuide(String? id)` → guarda en SharedPreferences (clave `active_guide_id`) y notifica.
- **Persistencia:** SharedPreferences; opcionalmente sincronizar con Firestore en documento de usuario (`activeGuideId`).

### 3. Integración con el tema

- **Opción A (recomendada al inicio):** El `ThemeNotifier` actual no se toca; se añade un provider derivado `guideThemeDataProvider` que, si `activeGuide != null` y tiene `themePrimaryHex`, devuelve `ThemeData` con esos colores (para una pantalla o modo "con guía"). El `MaterialApp` puede seguir usando `themeProvider` y en pantallas concretas (ej. selector de guía, pantalla de tareas con guía) usar el tema del guía.
- **Opción B:** Extender `ThemeNotifier` para que acepte un "override" de colores cuando hay guía activa (más invasivo).
- Por ahora: documentar Opción A y dejar un provider que expone `Color? primaryColorOverride` (y opcionalmente secondary/accent) cuando hay guía activa, para que quien quiera aplicarlo en una pantalla lo use.

### 4. Registro de bendiciones (stub)

- **Archivo:** `lib/services/guide_blessing_registry.dart` (o `lib/core/constants/guide_blessing_registry.dart`).
- **Contenido:** Map `blessingId` → descripción o configuración (ej. `BlessingConfig` con trigger type, efecto sugerido). No ejecuta lógica aún; solo permite "saber qué bendiciones tiene el guía activo" y, más adelante, conectar triggers (al completar tarea, al activar guía, etc.).
- **Uso:** Al completar una tarea, el código que ya hace celebración puede consultar `activeGuideProvider` y `blessingRegistry.get(blessingId)` para decidir si aplicar animación/haptic extra según la ficha del personaje.

### 5. Firebase (opcional, fase posterior)

- **Colección `guides`:** Documentos por `id` de guía con los campos de `Guide` (para poder actualizar fichas sin release).
- **Documento usuario:** Campo `activeGuideId` (string o null) para sincronizar la selección entre dispositivos.
- **Prioridad:** Primero implementación local (catálogo + SharedPreferences); Firestore cuando la cuenta de usuario y la sincronización de preferencias estén listas.

---

## Orden de implementación sugerido

1. **Catálogo:** Definir los 21 `Guide` en `guide_catalog.dart` (datos mínimos: id, name, title, affinity, themePrimaryHex, themeSecondaryHex, themeAccentHex, blessingIds, synergyIds, powerSentence).
2. **activeGuideProvider:** Leer/escribir `activeGuideId` en SharedPreferences; exponer `Guide?` desde el catálogo.
3. **Tema guía (opcional):** Provider que expone colores override cuando hay guía activa; usarlos en una pantalla de prueba o en el selector de guía.
4. **Registro de bendiciones (stub):** Map de `blessingId` a descripción/config; sin lógica de triggers aún.
5. **UI (fase siguiente):** Pantalla de selección de guía, avatar del guía activo en drawer o home, y conexión de triggers (completar tarea → bendición) cuando se definan las reglas por bendición.

---

## Notas

- **Guardian:** Las bendiciones no castigan; solo refuerzan (animación, haptic, mensaje). El registro debe usarse para efectos positivos o neutros, nunca para restar o bloquear por "fallo".
- **Offline-first:** La selección de guía funciona sin red; la sincronización con Firestore es opcional y en segundo plano.
