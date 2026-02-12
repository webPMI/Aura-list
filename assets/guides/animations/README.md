# Animaciones de Guías Celestiales

Opcional: animaciones Lottie (.json) por guía para estados idle, celebración y motivación.

## Nomenclatura

- **Idle (estado neutro):** `{guideId}_idle.json`
- **Celebración (al completar tarea):** `{guideId}_celebration.json`
- **Motivación (tareas pendientes):** `{guideId}_motivation.json`

Ejemplos: `aethel_idle.json`, `aethel_celebration.json`, `aethel_motivation.json`.

## Uso en código

Rutas construidas con `GuideAssetPaths`:

- `GuideAssetPaths.animationIdle(guideId)`
- `GuideAssetPaths.animationCelebration(guideId)`
- `GuideAssetPaths.animationMotivation(guideId)`

Si no hay archivo, la app usa animaciones por defecto (por ejemplo `CelebrationOverlay` con color del guía).

## Formato

Lottie JSON exportado desde After Effects o creado en lottiefiles.com. Tamaño recomendado: moderado (< 500 KB por archivo) para rendimiento en móvil.
