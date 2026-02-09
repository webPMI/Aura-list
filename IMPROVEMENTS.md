# AuraList - Roadmap de Mejoras

> Generado por análisis de 5 agentes especializados
> Fecha: 2026-02-09

## Visión
Una app de tareas tranquila y enfocada que ayuda a las personas a lograr lo que importa sin agregar estrés a sus vidas.

---

## Quick Wins (Implementar Esta Semana)

### QW1. [A11y] Agregar Labels Semánticos - CRÍTICO
**Problema:** Botones e iconos sin etiquetas para lectores de pantalla.
**Archivos:** `task_tile.dart`, `calendar_view.dart`
**Impacto:** Usuarios con discapacidad visual no pueden usar la app.
```dart
// Agregar Semantics wrapper a iconos interactivos
Semantics(
  label: 'Marcar tarea como completada',
  child: Checkbox(...)
)
```

### QW2. [A11y] Mejorar Contraste de Color
**Problema:** Texto con alpha 0.3-0.4 no cumple WCAG AA (4.5:1).
**Archivos:** `task_list.dart`, `calendar_view.dart`, `date_header.dart`
**Fix:** Cambiar `alpha: 0.3` → `alpha: 0.65` mínimo.

### QW3. [Code] Inyección de Dependencias para ErrorHandler
**Problema:** ErrorHandler instanciado globalmente en múltiples archivos.
**Archivos:** `error_handler.dart`, `database_service.dart`, `auth_service.dart`
**Fix:** Crear `errorHandlerProvider` con Riverpod.

### QW4. [UX] Swipe-to-Complete con Animación
**Problema:** Completar tareas requiere precisión en checkbox pequeño.
**Archivos:** `task_tile.dart`
**Impacto:** 40-60% menos taps por tarea completada.

---

## Fase 1: Mejoras de UX (2-3 features)

### P1.1 [UX] Quick Add - Captura Rápida de Tareas
**User Story:** Como usuario, quiero agregar tareas rápidamente sin abrir el diálogo completo.
**Solución:** Bottom sheet con solo título + enter, auto-asigna al tab actual.
**Archivos:** `home_screen.dart` (nuevo método `_showQuickAddSheet`)
**Impacto:** 70% más rápido para tareas simples.

### P1.2 [UX] Long-Press para Edición Rápida de Prioridad
**Problema:** Cambiar prioridad requiere abrir diálogo completo.
**Solución:** Menú contextual en long-press con: Prioridad, Categoría, Fecha.
**Archivos:** `task_tile.dart`
**Impacto:** 50-70% menos diálogos abiertos.

### P1.3 [Wellbeing] Recuperación Compasiva de Tareas Vencidas
**Problema:** Marcadores rojos "¡Vencida!" crean ansiedad y culpa.
**Solución:**
- Cambiar rojo → ámbar suave
- Texto: "Aún puedes hacerlo" en vez de "¡Vencida!"
- Botón "Reprogramar" directo en el tile
**Archivos:** `task_tile.dart`
**Impacto:** Usuarios regresan a la app en vez de evitarla.

---

## Fase 2: Productividad (3-4 features)

### P2.1 [Feature] Smart Views - Hoy/Próximos/Vencidos
**User Story:** Como usuario, quiero ver todas mis tareas urgentes en una vista, sin importar el tipo.
**Cambios Modelo:** Agregar getters `isToday`, `isUpcoming`, `daysTillDue`
**UI:** Nueva pantalla con tabs: Hoy | Próximos 7 días | Vencidos | Por Prioridad
**Archivos:** `task_model.dart`, nuevo `smart_views_screen.dart`
**Complejidad:** Media

### P2.2 [Feature] Búsqueda Full-Text
**User Story:** Como usuario con muchas tareas, quiero buscar por título o categoría.
**Solución:** SearchDelegate en AppBar, filtrado en memoria.
**Archivos:** `home_screen.dart`, nuevo `task_search_delegate.dart`
**Complejidad:** Baja

### P2.3 [Feature] Subtareas con Progreso
**User Story:** Como usuario, quiero dividir tareas complejas en pasos y ver mi progreso.
**Cambios Modelo:**
```dart
@HiveType(typeId: 2)
class Subtask extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) bool isCompleted;
}
// En Task:
@HiveField(17) List<Subtask> subtasks = [];
```
**UI:** Lista expandible en TaskTile, barra de progreso.
**Complejidad:** Media-Alta

### P2.4 [Wellbeing] Reporte Semanal de Reflexión
**User Story:** Como usuario, quiero ver mi progreso semanal y celebrar logros.
**UI:** Nueva pestaña "Insights" con:
- Gráfico de completadas Mon-Sun
- Contador de racha
- "Score de consistencia"
- Badges de logros
**Archivos:** nuevo `insights_screen.dart`, `date_header.dart`
**Complejidad:** Media

---

## Fase 3: Accesibilidad Completa

### P3.1 [A11y] Navegación por Teclado
**WCAG:** 2.1.1 Keyboard (Level A)
**Problema:** Calendar usa solo GestureDetector, no es navegable con teclado.
**Archivos:** `calendar_view.dart`, `home_screen.dart`

### P3.2 [A11y] Touch Targets de 48x48dp
**WCAG:** 2.5.5 Target Size
**Problema:** Botones de cerrar en date pickers son 18dp.
**Archivos:** `home_screen.dart`

### P3.3 [A11y] Escalado de Texto Responsivo
**WCAG:** 1.4.4 Resize Text
**Problema:** Tamaños de fuente fijos ignoran preferencias del usuario.
**Solución:** Usar `MediaQuery.textScaleFactor` o crear `AccessibleTextStyles` helper.

---

## Fase 4: Mejoras Técnicas

### P4.1 [Code] Extraer Lógica de Diálogos
**Problema:** `_showAddTaskDialog` y `_showEditTaskDialog` duplican ~400 líneas.
**Solución:** Crear `TaskDialogController` y `TaskDialog` widget reutilizable.
**Archivos:** `home_screen.dart` → `task_dialog.dart`, `task_dialog_controller.dart`
**Beneficio:** Mantenibilidad, testabilidad.

### P4.2 [Code] Rebuilds Selectivos con select()
**Problema:** TaskList rebuilds completo cuando cambia cualquier tarea.
**Solución:** Usar `ref.watch().select()` para optimizar rebuilds.
**Archivos:** `task_list.dart`, `task_provider.dart`
**Beneficio:** 30-50% menos rebuilds en listas grandes.

### P4.3 [Code] Tracking de Errores de Sync
**Problema:** Errores de sync se pierden silenciosamente.
**Solución:** Crear `SyncProvider` para trackear items fallidos con timestamps.
**Archivos:** `database_service.dart`, nuevo `sync_provider.dart`

---

## Backlog (Futuro)

| ID | Categoría | Feature | Complejidad |
|----|-----------|---------|-------------|
| BL1 | Feature | Time Tracking con timer | Alta |
| BL2 | Feature | Recordatorios con notificaciones locales | Alta |
| BL3 | Feature | Recurrencia avanzada (días específicos) | Alta |
| BL4 | Wellbeing | Modo "Energía" - tareas por nivel de esfuerzo | Media |
| BL5 | Wellbeing | Check-in de estado de ánimo | Media |
| BL6 | Wellbeing | Reset diario gentil | Media |
| BL7 | UX | Drag-to-reorder tareas | Media |
| BL8 | UX | Bulk actions (seleccionar múltiples) | Alta |

---

## Completados

*(Ninguno aún - ¡empecemos!)*

---

## Cómo Usar Este Roadmap

```bash
# Ver el roadmap
/roadmap

# Implementar una mejora específica
/implement QW1

# Agregar nueva idea
/roadmap add "Descripción de la mejora"

# Re-analizar con todos los agentes
/init
```

## Principios de Diseño

1. **Offline-first**: Siempre funciona sin conexión
2. **Compasión > Culpa**: Ámbar en vez de rojo, "aún puedes" en vez de "fallaste"
3. **Progresión gentil**: Celebrar logros, no castigar fallos
4. **Accesible para todos**: WCAG AA mínimo
5. **Simple por defecto**: Features avanzados opt-in
