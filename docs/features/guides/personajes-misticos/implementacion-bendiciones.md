# Implementación de Bendiciones (Arquitecto)

Cómo las Bendiciones del lore se traducen en funciones lógicas de código en AuraList.

---

## Flujo general

1. **Usuario elige un guía activo** → se persiste `activeGuideId` (SharedPreferences / documento usuario en Firestore).
2. **Provider `activeGuideProvider`** → expone el `Guide` activo (desde Firestore o catálogo local).
3. **Registry de bendiciones** → por cada `blessingId` del guía, el código aplica el comportamiento (tema, haptics, animaciones, lógica de negocio).
4. **Streams reactivos** → el tema de la app, las vibraciones y las animaciones reaccionan al guía activo y a eventos (completar tarea, racha, etc.).

---

## Mapeo Bendición → Código

| Concepto | En lore | En código |
|----------|---------|-----------|
| Guía activo | "El usuario tiene a Helioforja como guía" | `activeGuideProvider` → `Guide?` |
| Tema según guía | "Paleta de Helioforja: rojo forja" | `themeProvider` escucha `activeGuideProvider`; si hay guía, aplica `themePrimaryHex` / `themeSecondaryHex` / `themeAccentHex`. |
| Bendición al completar tarea | "Gracia del Primer Golpe: las 2 primeras tareas de esfuerzo del día generan Ecos de Aura" | Servicio o provider que cuenta tareas de esfuerzo completadas hoy; si `activeGuideId == 'helioforja'` y count <= 2, dispara animación + haptic y aplica "Ecos de Aura" (reducción visual de carga). |
| Bendición al activar guía | "Escudo Térmico: suaviza contrastes si el usuario lleva mucho tiempo sin actuar" | Al cambiar a Helioforja, registrar timestamp; si el usuario no completa tarea en X minutos, reducir contraste (por ejemplo vía overlay o tema suavizado). |

---

## Estructura sugerida en Flutter

- **`lib/models/guide_model.dart`** — Ya existe: `Guide`, `BlessingDefinition`.
- **`lib/providers/active_guide_provider.dart`** — Lee `activeGuideId` de preferencias/Firestore; devuelve `Guide?` del catálogo.
- **`lib/services/guide_blessing_registry.dart`** (o lógica dentro del provider) — Map `blessingId` → callback o configuración (ej. `gracia_primer_golpe` → { trigger: onTaskCompleted, condition: taskCategory == 'esfuerzo_fisico' && countToday <= 2, effect: showEcosDeAura + haptic }).
- **Tema:** `themeProvider` puede tener una rama: si `activeGuide != null` y tiene `themePrimaryHex`, usarla; si no, tema por defecto.
- **Haptics:** Al completar tarea, el código que ya maneja la celebración puede consultar `activeGuide` y aplicar el patrón de vibración definido en la ficha del personaje (Experiencia).

---

## Límites (Guardian)

- Las bendiciones **nunca** castigan (no quitar puntos, no bloquear funcionalidad por "fallar").
- Los triggers deben estar **acotados** (ej. "primeras 3 tareas del día", "una vez por racha") para evitar loops infinitos de engagement.
- La IA de la app **no** dará consejos médicos, financieros o legales reales; el tono es ficción motivadora.

Este documento se amplía cuando se implementen las pantallas de selección de guía y la lógica de bendiciones en código.
