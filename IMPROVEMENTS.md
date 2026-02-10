# AuraList - Roadmap de Mejoras

> Generado por analisis de 5 agentes especializados
> Fecha: 2026-02-10 (Actualizado)

## Vision

Una app de tareas tranquila y enfocada que ayuda a las personas a lograr lo que importa sin agregar estres a sus vidas.

---

## Quick Wins (1-3 horas cada uno)

### QW-1. [Code] Corregir Errores Silenciosos en Sync Queue - CRITICO
**Problema:** Errores en sync queue se ignoran sin logging ni reintentos.
**Archivos:** `database_service.dart` (lineas 576-609)
**Impacto:** Previene perdida de datos, habilita debugging.
**Fix:** Agregar clasificacion de errores, logging y tracking de reintentos.

### QW-2. [Code] Flush Syncs Pendientes al Cerrar App
**Problema:** `dispose()` cancela timer pero no llama `flushPendingSyncs()`.
**Archivos:** `database_service.dart` (metodo dispose)
**Impacto:** Previene perdida de datos al cerrar app durante edicion.
**Fix:** Hacer `dispose()` async, await `flushPendingSyncs()`.

### QW-3. [UX] Undo de Completar/Eliminar con Toast Persistente
**Problema:** Eliminar tareas solo muestra snackbar breve sin opcion de deshacer confiable.
**Archivos:** `task_tile.dart`, nuevo `undo_provider.dart`, `home_screen.dart`
**Impacto:** Elimina ansiedad por borrado accidental.
**Fix:** Snackbar extendido (4-5 seg) con boton "Deshacer", stack de undo por 30 seg.

### QW-4. [A11y] Corregir Touch Targets Pequenos
**Problema:** Weekly dots son 8x8dp, muy pequenos para usuarios con discapacidad motora.
**Archivos:** `task_stats.dart`
**Impacto:** Usuarios con motor impairments pueden interactuar.
**Fix:** Envolver en touch targets de 48x48dp.

### QW-5. [A11y] Agregar Labels Semanticos
**Problema:** Botones interactivos sin etiquetas para screen readers.
**Archivos:** `speed_dial_fab.dart`, `task_stats.dart`, `calendar_view.dart`
**Impacto:** Screen readers pueden identificar botones.
**Fix:** Agregar `Semantics` widgets con labels descriptivos.

---

## Fase 1: UX + Productividad (3-6 horas cada uno)

### ME-1. [UX+Prod] Busqueda Rapida de Tareas
**User Story:** Como usuario con muchas tareas, quiero buscar rapidamente sin scroll.
**Archivos:** `tasks_screen.dart`, `dashboard_screen.dart`, nuevo `search_bar.dart`, `task_provider.dart`
**Impacto:** 30s → 3s para encontrar cualquier tarea.
**Solucion:** Search bar con filtrado en tiempo real por titulo, categoria, prioridad.

### ME-2. [UX+Prod] Quick Add Speed Dial Menu
**User Story:** Como usuario, quiero agregar tareas simples en <5 segundos.
**Archivos:** `main_scaffold.dart`, nuevo `task_speed_dial.dart`, `task_form_dialog.dart`
**Impacto:** 80% mas rapido para tareas simples.
**Solucion:** FAB con opciones: Quick Add (solo titulo), Formulario Completo, Entrada de Voz.

### ME-3. [Prod] Templates de Tareas
**User Story:** Como usuario, quiero reusar patrones de tareas recurrentes.
**Archivos:** Nuevo modelo `task_template.dart`, nuevo `task_template_provider.dart`, `task_form_dialog.dart`
**Impacto:** 30s → 2s para crear tareas recurrentes.
**Solucion:** Guardar templates con titulo, categoria, prioridad, hora sugerida.

### ME-4. [Wellbeing] Rachas Compasivas con Dias de Recuperacion
**User Story:** Como usuario, no quiero que un dia malo rompa toda mi racha.
**Archivos:** `stats_provider.dart`, `task_stats.dart`
**Impacto:** Reduce ansiedad de rachas, promueve progreso sobre perfeccion.
**Solucion:**
- 2 "dias de recuperacion" por mes que pausan (no rompen) rachas
- Mostrar "score de consistencia" en vez de racha cruda
- Mensajes: "progreso sobre perfeccion"

### ME-5. [Wellbeing] Notificaciones Mindful y Horas Tranquilas
**Archivos:** Nueva seccion en `settings_screen.dart`, extender `UserPreferences`
**Impacto:** Reduce fatiga de notificaciones.
**Solucion:** Horas tranquilas, limite diario de notificaciones, modo focus.

### ME-6. [UX] Detalles de Tarea Colapsables
**Problema:** Task tiles muestran mucha metadata (prioridad, categoria, fecha, motivacion, stats).
**Archivos:** `task_tile.dart`
**Impacto:** 40% mejor rendimiento scroll, UI mas limpia.
**Solucion:** Mostrar solo titulo + prioridad + fecha por defecto. Tap para expandir.

### ME-7. [A11y] Soporte de Escalado de Texto
**Problema:** Tamanos de fuente fijos ignoran preferencias del usuario.
**Archivos:** `dashboard_screen.dart`, `task_tile.dart`, `task_stats.dart`
**Impacto:** Usuarios con discapacidad visual pueden usar la app.
**Fix:** Multiplicar tamanos por `MediaQuery.textScaleFactorOf(context)`.

### ME-8. [Wellbeing] Limites Diarios de Tareas
**Problema:** Usuarios pueden crear tareas ilimitadas, llevando a overwhelm.
**Archivos:** Nuevo `daily_capacity_provider.dart`, `home_screen.dart`
**Impacto:** Previene sobrecarga y fallo de completar.
**Solucion:** Analizar historial de completadas, mostrar cap recomendado, advertir al exceder.

### ME-9. [Wellbeing] Racha de Bienestar (Separada de Tareas)
**Problema:** Actividades de wellness enterradas en sugerencias, sin reconocimiento.
**Archivos:** `wellness_provider.dart`, `stats_provider.dart`, `dashboard_screen.dart`
**Impacto:** Valida descanso como productivo.
**Solucion:** Tracking separado de wellness con su propia racha. "Descansar es productivo".

### ME-10. [Code] Arreglar Manejo de Errores en Stream Subscriptions
**Problema:** Errores en streams terminan silenciosamente, UI muestra datos stale.
**Archivos:** `task_provider.dart`, `notes_provider.dart`
**Impacto:** Previene UI desactualizada.
**Fix:** Agregar recuperacion de errores, logica de retry, notificacion al usuario.

---

## Fase 2: Features Mayores (1-2 dias cada uno)

### MF-1. [Prod] Focus Mode / Vista "Hoy"
**User Story:** Como usuario, quiero ver solo lo accionable hoy sin paralisis de decision.
**Archivos:** Nuevo `today_screen.dart`, nuevo `today_tasks_provider.dart`, `navigation_provider.dart`
**Impacto:** Elimina paralisis de decision.
**Solucion:** Vista unica mostrando:
- Vencidas (rojo)
- Vencen hoy (naranja)
- Alta prioridad urgente (amarillo)
- Nada mas. Meta: max 10 items.

### MF-2. [Prod] Notificaciones Inteligentes con Snooze/Postergar
**Problema:** App tiene `notificationsEnabled` pero no sistema de notificaciones.
**Archivos:** Nuevo `notification_service.dart`, nuevo `notification_config.dart`, `task_tile.dart`
**Impacto:** Nunca olvidar deadlines.
**Solucion:** Programar alertas basadas en dueTime/deadline, opciones snooze: 1h, 4h, 1d.

### MF-3. [Wellbeing] Reflexion Semanal e Insights de Patrones
**User Story:** Como usuario, quiero entender que realmente funciona para mi.
**Archivos:** Nuevo `weekly_review_screen.dart`, nuevo `weekly_insight.dart`, `stats_provider.dart`
**Impacto:** Auto-conciencia y balance.
**Solucion:**
- Seleccion de mood semanal
- Reconocimiento de patrones ("100% Lunes, 40% Viernes")
- Sugerencias accionables
- Victorias en una oracion (framing positivo)

### MF-4. [UX] Vista de Agrupacion Inteligente
**Problema:** Todas las tareas en listas lineales por tipo.
**Archivos:** `home_screen.dart`, nuevo `smart_task_view.dart`, `task_provider.dart`
**Impacto:** 25% mas rapido descubrir tareas urgentes.
**Solucion:** Toggle de vista: "Vencidas | Urgentes | Proximas | Completadas Hoy".

### MF-5. [Prod] Estimacion de Esfuerzo y Time-Boxing
**User Story:** Como usuario, quiero planear realisticamente mi carga de trabajo.
**Archivos:** `task_model.dart` (agregar estimatedMinutes), `task_history.dart`, nuevo `effort_tracking_provider.dart`
**Impacto:** Planificacion realista de carga.
**Solucion:** Estimar tiempo por tarea, mostrar "carga de hoy", trackear actual vs estimado.

### MF-6. [A11y] Navegacion Completa por Teclado
**Problema:** App depende principalmente de touch/mouse.
**Archivos:** `speed_dial_fab.dart`, `adaptive_navigation.dart`, `task_form_dialog.dart`
**Impacto:** Usuarios solo-teclado incluidos.
**Solucion:** Manejo de orden de focus, shortcuts de teclado, indicadores de focus.

### MF-7. [A11y] Modo Alto Contraste y Paleta Colorblind-Safe
**Problema:** Contraste de modo oscuro no verificado, rojo/verde no amigable para daltonicos.
**Archivos:** `main.dart`, `theme_provider.dart`, `task_tile.dart`
**Impacto:** Cumplimiento WCAG AA, soporte daltonismo.
**Solucion:** Verificar ratios 4.5:1, agregar opcion alto contraste, usar iconos + color.

---

## Deuda Tecnica

### TD-1. [Code] Type Casting Inseguro en Deteccion de Duplicados
**Severidad:** Alta
**Archivos:** `database_service.dart` (lineas 396-420)
**Fix:** Reemplazar `cast<Task?>()` con type checking explicito. Usar `copyWith()` inmutable.

### TD-2. [Code] Entradas de Sync Queue Type-Safe
**Severidad:** Media
**Archivos:** `database_service.dart` (lineas 560, 1527)
**Fix:** Crear clases wrapper tipadas en vez de Maps sin tipo. Agregar factory methods de validacion.

### TD-3. [Code] Suite de Tests Comprensiva
**Severidad:** Media
**Archivos:** Carpeta `test/`
**Actual:** Solo un smoke test.
**Necesario:** Tests de logica de retry de sync queue, recuperacion de errores en streams, comportamiento offline-first, integridad de base de datos.

---

## Matriz de Prioridad

| ID | Mejora | Esfuerzo | Impacto | Prioridad |
|----|--------|----------|---------|-----------|
| QW-1 | Corregir errores silenciosos sync | Bajo | Critico | 1 |
| QW-2 | Flush syncs al cerrar | Bajo | Alto | 2 |
| ME-1 | Busqueda rapida | Medio | Alto | 3 |
| ME-2 | Quick add speed dial | Medio | Alto | 4 |
| ME-4 | Rachas compasivas | Medio | Alto | 5 |
| QW-4 | Touch target sizes | Bajo | Medio | 6 |
| QW-5 | Labels semanticos | Bajo | Medio | 7 |
| MF-1 | Vista Hoy | Alto | Muy Alto | 8 |
| ME-8 | Limites diarios tareas | Medio | Alto | 9 |
| ME-7 | Escalado de texto | Medio | Medio | 10 |

---

## Completados

*(Ninguno aun)*

---

## Como Usar Este Roadmap

```bash
# Ver el roadmap
/roadmap

# Implementar una mejora especifica
/implement QW-1

# Re-analizar con todos los agentes
/init
```

## Principios de Diseno

1. **Offline-first**: Siempre funciona sin conexion
2. **Compasion > Culpa**: Ambar en vez de rojo, "aun puedes" en vez de "fallaste"
3. **Progresion gentil**: Celebrar logros, no castigar fallos
4. **Accesible para todos**: WCAG AA minimo
5. **Simple por defecto**: Features avanzados opt-in
