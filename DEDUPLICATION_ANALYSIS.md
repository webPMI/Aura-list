# Análisis de Deduplicación de Tareas y Notas - AuraList

## Fecha: 2026-02-10

## Resumen Ejecutivo

Después de una investigación exhaustiva del código, **el sistema de deduplicación está correctamente implementado** en todos los puntos críticos. El código actual previene duplicaciones mediante:

1. **Deduplicación por firestoreId** antes de guardar
2. **Deduplicación por Hive key** para objetos persistidos
3. **Deduplicación por timestamp createdAt** para tareas locales
4. **Lógica de upsert** en vez de insert ciego
5. **Limpieza automática de duplicados** en migraciones

## Escenarios de Duplicación Analizados

### ✅ 1. Al sincronizar desde la nube, se duplican tareas existentes

**Ubicación**: `lib/services/database_service.dart` líneas 2183-2226

**Solución implementada**:
```dart
// Check if task exists locally by firestoreId
final existingTask = box.values.cast<Task?>().firstWhere(
  (t) => t?.firestoreId == doc.id,
  orElse: () => null,
);

if (existingTask != null) {
  // Task exists locally - check which is newer
  final localUpdated = existingTask.lastUpdatedAt ?? existingTask.createdAt;
  final cloudUpdated = cloudTask.lastUpdatedAt ?? cloudTask.createdAt;

  if (cloudUpdated.isAfter(localUpdated)) {
    // Cloud is newer - update local IN-PLACE (no new entry)
    existingTask.updateInPlace(...);
    await existingTask.save();
  }
  // else: local is newer - no action needed
} else {
  // Only add if it doesn't exist locally
  await box.add(cloudTask);
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Busca por `firestoreId` antes de agregar
- Actualiza in-place si existe (no crea duplicado)
- Solo agrega si es realmente nueva

### ✅ 2. Al crear tarea, se guarda múltiples veces

**Ubicación**: `lib/services/database_service.dart` líneas 574-620

**Solución implementada**:
```dart
Future<void> saveTaskLocally(Task task) async {
  await _executeWithRetry(() async {
    final box = await _box;
    if (task.isInBox) {
      // Ya está en Hive - solo actualizar
      await task.save();
    } else {
      // IMPORTANT: Avoid duplicating local tasks.
      // AI agents often create new Task instances (via copyWith) which lose their Hive reference.
      // We must check if a task with the same identity already exists.
      final existing = await _findExistingTask(task);

      if (existing != null) {
        // Update existing instead of adding duplicate
        existing.updateInPlace(...);
        await existing.save();
        // IMPORTANT: Exit to avoid box.add() creating a duplicate
        return;
      }
      await box.add(task);
    }
  }, operationName: 'guardar tarea');
}
```

**Método auxiliar** `_findExistingTask` (líneas 1167-1191):
```dart
Future<Task?> _findExistingTask(Task task) async {
  final box = await _box;
  // 1. By Hive key (most reliable)
  if (task.key != null) {
    final t = box.get(task.key);
    if (t != null) return t;
  }
  // 2. By firestoreId (for synced tasks)
  if (task.firestoreId.isNotEmpty) {
    final t = box.values.cast<Task?>().firstWhere(
      (t) => t?.firestoreId == task.firestoreId,
      orElse: () => null,
    );
    if (t != null) return t;
  }
  // 3. By createdAt timestamp (for local tasks)
  return box.values.cast<Task?>().firstWhere(
    (t) =>
        t != null &&
        t.createdAt.millisecondsSinceEpoch ==
            task.createdAt.millisecondsSinceEpoch,
    orElse: () => null,
  );
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Triple verificación: Hive key → firestoreId → createdAt
- Actualiza existente en vez de crear duplicado
- Early return previene ejecución de `box.add()`

### ✅ 3. Al editar tarea, se crea una nueva en vez de actualizar

**Ubicación**: `lib/providers/task_provider.dart` líneas 137-230

**Solución implementada**:
```dart
Future<void> updateTask(Task task) async {
  try {
    // Si la tarea ya está en Hive, guardar directamente
    if (task.isInBox) {
      task.lastUpdatedAt = DateTime.now();
      await task.save();
      // Sync to cloud
      return;
    }

    // Buscar la tarea original en el estado actual
    Task? original;

    // 1. Buscar por Hive key (más confiable para tareas locales)
    if (task.key != null) {
      original = state.cast<Task?>().firstWhere(
        (t) => t?.key == task.key,
        orElse: () => null,
      );
    }

    // 2. Si no se encuentra por key, buscar por firestoreId
    if (original == null && task.firestoreId.isNotEmpty) {
      original = state.cast<Task?>().firstWhere(
        (t) => t?.firestoreId == task.firestoreId,
        orElse: () => null,
      );
    }

    // 3. Si aún no se encuentra, buscar por createdAt
    if (original == null) {
      original = state.cast<Task?>().firstWhere(
        (t) =>
            t != null &&
            t.createdAt.millisecondsSinceEpoch ==
                task.createdAt.millisecondsSinceEpoch,
        orElse: () => null,
      );
    }

    if (original != null && original.isInBox) {
      // Actualizar la tarea original in-place
      original.updateInPlace(...);
      await original.save();
      // Sync to cloud
    } else {
      // Solo crear nueva si realmente no existe (caso raro)
      debugPrint('⚠️ [TaskProvider] updateTask llamado con tarea no encontrada');
      await _db.saveTaskLocally(task);
    }
  }
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Busca tarea original por 3 métodos
- Actualiza in-place si existe
- Solo crea nueva en caso excepcional (con warning)

### ✅ 4. Al cambiar de usuario, tareas se mezclan

**Ubicación**: `lib/services/database_service.dart` + Firebase Rules

**Solución implementada**:

**Firebase Security Rules**:
```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Solo el usuario puede acceder a sus propios datos
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /tasks/{taskId} {
        allow read: if request.auth.uid == userId;
        allow create: if request.auth.uid == userId && isValidTask();
        allow update: if request.auth.uid == userId && isValidTask();
        allow delete: if request.auth.uid == userId;
      }
    }
  }
}
```

**Separación por usuario**:
- Cada usuario tiene su propia colección: `users/{userId}/tasks/{taskId}`
- Firebase Rules previenen acceso cruzado
- Hive local no mezcla usuarios (se borra al cambiar cuenta)

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Aislamiento total por usuario en Firestore
- Security rules validan userId == auth.uid
- No hay mezcla de datos entre usuarios

### ✅ 5. Conflictos de merge entre local y remoto

**Ubicación**: `lib/services/database_service.dart` líneas 2189-2218

**Solución implementada**:
```dart
if (existingTask != null) {
  // Task exists locally - check which is newer
  final localUpdated = existingTask.lastUpdatedAt ?? existingTask.createdAt;
  final cloudUpdated = cloudTask.lastUpdatedAt ?? cloudTask.createdAt;

  if (cloudUpdated.isAfter(localUpdated)) {
    // Cloud is newer - update local
    existingTask.updateInPlace(...);
    await existingTask.save();
    tasksDownloaded++;
  } else {
    // Local is newer or same - will be synced to cloud later
    // No action needed - avoid overwriting local changes
  }
}
```

**Estrategia de resolución de conflictos**:
1. **Last Write Wins (LWW)** basado en `lastUpdatedAt`
2. Si cloud es más nuevo → actualiza local
3. Si local es más nuevo → mantiene local (se sincronizará después)
4. Previene pérdida de datos locales no sincronizados

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Comparación de timestamps antes de sobrescribir
- Protege cambios locales más recientes
- Sincronización bidireccional inteligente

## Soluciones Adicionales Implementadas

### ✅ 6. Limpieza automática de duplicados existentes

**Ubicación**: `lib/services/database_service.dart` líneas 389-469

**Ejecución**: En `_runMigrations()` al inicializar la app

```dart
Future<void> _cleanupDuplicates() async {
  try {
    // Clean up duplicate tasks
    final seenTaskIds = <String>{};
    final seenTimestamps = <int>{};
    final tasksToDelete = <dynamic>[];

    for (final task in _taskBox!.values) {
      bool isDuplicate = false;

      // Check by firestoreId
      if (task.firestoreId.isNotEmpty) {
        if (seenTaskIds.contains(task.firestoreId)) {
          isDuplicate = true;
        } else {
          seenTaskIds.add(task.firestoreId);
        }
      }

      // Also check by timestamp for local-only duplicates
      final ts = task.createdAt.millisecondsSinceEpoch;
      if (!isDuplicate && ts > 0) {
        if (seenTimestamps.contains(ts)) {
          isDuplicate = true;
        } else {
          seenTimestamps.add(ts);
        }
      }

      if (isDuplicate) {
        tasksToDelete.add(task.key);
      }
    }

    for (final key in tasksToDelete) {
      await _taskBox!.delete(key);
    }

    if (tasksToDelete.isNotEmpty) {
      debugPrint('Eliminados ${tasksToDelete.length} tareas duplicadas');
    }

    // Same logic for notes...
  } catch (e) {
    debugPrint('Error limpiando duplicados: $e');
  }
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Se ejecuta automáticamente al iniciar la app
- Elimina duplicados por firestoreId
- Elimina duplicados por timestamp (para tareas locales)
- Logging detallado de limpieza

### ✅ 7. Deduplicación en UI (TaskProvider)

**Ubicación**: `lib/providers/task_provider.dart` líneas 30-84

```dart
void _init() {
  _subscription = _db
      .watchLocalTasks(_type)
      .listen(
        (tasks) => state = _deduplicateTasks(tasks),
        onError: (e) => debugPrint('Error watching tasks: $e'),
      );
}

List<Task> _deduplicateTasks(List<Task> tasks) {
  final seenFirestoreIds = <String>{};
  final seenHiveKeys = <dynamic>{};
  final seenTimestamps = <int>{};
  final unique = <Task>[];

  for (final task in tasks) {
    bool isDuplicate = false;

    // 1. Check by firestoreId
    if (task.firestoreId.isNotEmpty) {
      if (seenFirestoreIds.contains(task.firestoreId)) {
        isDuplicate = true;
      } else {
        seenFirestoreIds.add(task.firestoreId);
      }
    }

    // 2. Check by Hive key
    if (!isDuplicate && task.key != null) {
      if (seenHiveKeys.contains(task.key)) {
        isDuplicate = true;
      } else {
        seenHiveKeys.add(task.key);
      }
    }

    // 3. Check by createdAt (crucial for local tasks with lost keys)
    if (!isDuplicate) {
      final ts = task.createdAt.millisecondsSinceEpoch;
      if (seenTimestamps.contains(ts)) {
        isDuplicate = true;
      } else {
        seenTimestamps.add(ts);
      }
    }

    if (!isDuplicate) {
      unique.add(task);
    }
  }

  return unique;
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Capa final de protección antes de mostrar en UI
- Triple verificación de identidad
- Garantiza que nunca se muestren duplicados al usuario

### ✅ 8. Soft Delete previene re-creación

**Ubicación**: `lib/services/database_service.dart` líneas 1137-1165

```dart
Future<void> softDeleteTask(Task task, String userId) async {
  task.deleted = true;
  task.deletedAt = DateTime.now();
  task.lastUpdatedAt = DateTime.now();

  if (task.isInBox) {
    await task.save();
  } else {
    // IMPORTANT: Find the local instance to mark as deleted.
    final existing = await _findExistingTask(task);
    if (existing != null) {
      existing.updateInPlace(
        deleted: true,
        deletedAt: task.deletedAt,
        lastUpdatedAt: task.lastUpdatedAt,
      );
      await existing.save();
      task.firestoreId = existing.firestoreId;
    }
  }

  // Sync deletion to cloud
  if (userId.isNotEmpty) {
    await syncTaskToCloudDebounced(task, userId);
  }
}
```

**Estado**: ✅ **CORRECTAMENTE IMPLEMENTADO**
- Marca como eliminada en vez de borrar físicamente
- Sincroniza el estado de eliminación a la nube
- Previene re-descarga de tareas eliminadas

## Task Model - Métodos de Actualización

### ✅ `updateInPlace()` - Método clave

**Ubicación**: `lib/models/task_model.dart` líneas 225-287

```dart
void updateInPlace({
  String? firestoreId,
  String? title,
  String? type,
  bool? isCompleted,
  DateTime? dueDate,
  bool clearDueDate = false,
  String? category,
  int? priority,
  int? dueTimeMinutes,
  bool clearDueTime = false,
  String? motivation,
  bool clearMotivation = false,
  String? reward,
  bool clearReward = false,
  int? recurrenceDay,
  bool clearRecurrenceDay = false,
  DateTime? deadline,
  bool clearDeadline = false,
  bool? deleted,
  DateTime? deletedAt,
  DateTime? lastUpdatedAt,
}) {
  if (firestoreId != null) this.firestoreId = firestoreId;
  if (title != null) this.title = title;
  if (type != null) this.type = type;
  if (isCompleted != null) this.isCompleted = isCompleted;
  // ... actualiza campos sin crear nuevo objeto
}
```

**Ventajas**:
- Modifica el objeto existente en Hive
- Preserva el Hive key (identidad en la base de datos)
- Evita crear instancias nuevas que pierden referencia
- Opciones `clear*` para limpiar campos opcionales

**Contraste con `copyWith()`**:
- `copyWith()` crea una **nueva instancia** (pierde Hive key)
- `updateInPlace()` modifica **el mismo objeto** (mantiene Hive key)
- `updateInPlace()` es esencial para prevenir duplicaciones

## Arquitectura de Identificación de Tareas

### Triple Sistema de Identidad

```
┌─────────────────────────────────────────────────────────────┐
│                   Identificación de Tareas                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Hive key (dynamic)                                        │
│    - Asignado automáticamente por Hive al guardar           │
│    - Único dentro de la box local                           │
│    - Se pierde si se usa copyWith() o task.copyWith()       │
│    - Más confiable para tareas locales                      │
├─────────────────────────────────────────────────────────────┤
│ 2. firestoreId (String)                                      │
│    - Asignado por Firebase al crear en Firestore            │
│    - Único globalmente entre todos los usuarios             │
│    - Vacío ('') para tareas solo locales (no sincronizadas) │
│    - Más confiable para tareas sincronizadas                │
├─────────────────────────────────────────────────────────────┤
│ 3. createdAt (DateTime)                                      │
│    - Timestamp de creación                                   │
│    - Único con alta probabilidad (milisegundos)             │
│    - Fallback para tareas que perdieron key/firestoreId     │
│    - Crucial para AI agents que usan copyWith()             │
└─────────────────────────────────────────────────────────────┘
```

### Orden de Verificación

```dart
// Orden preferido para buscar tareas existentes:
1. task.key (si existe y está en Hive)
2. task.firestoreId (si no está vacío)
3. task.createdAt (timestamp único como último recurso)
```

## Flujos de Datos Sin Duplicación

### Flujo 1: Crear Nueva Tarea

```
Usuario presiona "Agregar tarea"
         ↓
TaskNotifier.addTask()
         ↓
DatabaseService.saveTaskLocally(task)
         ↓
¿task.isInBox? → SÍ → task.save() (actualizar)
         ↓ NO
_findExistingTask(task)
         ↓
¿Existe? → SÍ → existing.updateInPlace() + existing.save()
         ↓ NO
box.add(task) ← ÚNICA vez que se agrega
         ↓
Sincronizar a Firebase (async)
```

### Flujo 2: Sincronizar desde Firebase

```
Usuario abre la app
         ↓
performFullSync(userId)
         ↓
syncFromCloud(userId)
         ↓
Obtener todas las tareas de Firebase
         ↓
Para cada tarea cloud:
    ↓
    ¿existingTask = box.values.firstWhere(firestoreId == cloudTask.id)?
    ↓
    ¿Existe? → SÍ → Comparar timestamps
                    ↓
                    ¿Cloud más nuevo? → SÍ → existingTask.updateInPlace()
                                      ↓ NO → No hacer nada (local prevalece)
    ↓ NO
    box.add(cloudTask) ← ÚNICA vez que se agrega (nueva tarea de otro dispositivo)
```

### Flujo 3: Editar Tarea

```
Usuario edita tarea
         ↓
TaskNotifier.updateTask(task)
         ↓
¿task.isInBox? → SÍ → task.updateInPlace() + task.save()
         ↓ NO (objeto desconectado por copyWith)
Buscar original en state:
    1. Por task.key
    2. Por task.firestoreId
    3. Por task.createdAt
         ↓
original.updateInPlace() + original.save()
         ↓
Sincronizar a Firebase (debounced)
```

## Casos Especiales Manejados

### ✅ AI Agents que usan `copyWith()`

**Problema**: Algunos agentes AI/asistentes pueden usar:
```dart
final updatedTask = task.copyWith(title: 'Nuevo título');
```

Esto crea una **nueva instancia** que pierde su `key` de Hive.

**Solución implementada**:
1. `_findExistingTask()` busca por `createdAt` como fallback
2. Se actualiza el objeto original con `updateInPlace()`
3. Se previene la creación de duplicado

**Código relevante**:
```dart
// En DatabaseService.saveTaskLocally()
final existing = await _findExistingTask(task);
if (existing != null) {
  // Update existing instead of adding duplicate
  existing.updateInPlace(...);
  await existing.save();
  return; // IMPORTANT: Exit para prevenir box.add()
}
```

### ✅ Reconexión después de modo offline

**Escenario**:
1. Usuario crea tarea en modo offline
2. Tarea se guarda localmente (sin firestoreId)
3. Usuario vuelve online
4. Se sincroniza a Firebase (obtiene firestoreId)
5. La próxima sincronización no debe duplicar

**Solución implementada**:
```dart
// En syncFromCloud, se busca por firestoreId
final existingTask = box.values.firstWhere(
  (t) => t?.firestoreId == doc.id,
  orElse: () => null,
);
// Si existe, actualiza. Si no, agrega.
```

**Además**, en `_syncLocalOnlyItems()`:
```dart
// Encuentra tareas sin firestoreId y las sincroniza
final localOnlyTasks = box.values
    .where((t) => t.firestoreId.isEmpty && !t.deleted)
    .toList();

for (final task in localOnlyTasks) {
  await syncTaskToCloud(task, userId);
  // Esto asigna el firestoreId y previene duplicación futura
}
```

### ✅ Múltiples dispositivos del mismo usuario

**Escenario**:
1. Usuario tiene app en teléfono y tablet
2. Crea tarea en teléfono → se sincroniza a Firebase
3. Abre app en tablet → descarga desde Firebase
4. Edita en tablet → se sincroniza
5. Vuelve al teléfono → debe actualizar, no duplicar

**Solución implementada**:
- Cada tarea tiene `firestoreId` único
- `syncFromCloud()` busca por `firestoreId` antes de agregar
- Last Write Wins previene conflictos
- Soft delete sincroniza eliminaciones entre dispositivos

## Verificación de Implementación

### Métodos clave verificados:

| Método | Ubicación | Previene Duplicación | Estado |
|--------|-----------|----------------------|--------|
| `saveTaskLocally()` | database_service.dart:574 | ✅ Busca existing antes de add | ✅ OK |
| `_findExistingTask()` | database_service.dart:1168 | ✅ Triple verificación | ✅ OK |
| `syncFromCloud()` | database_service.dart:2118 | ✅ Busca por firestoreId | ✅ OK |
| `updateTask()` | task_provider.dart:137 | ✅ Busca original antes de crear | ✅ OK |
| `toggleTask()` | task_provider.dart:232 | ✅ Usa updateInPlace | ✅ OK |
| `_cleanupDuplicates()` | database_service.dart:390 | ✅ Limpia existentes | ✅ OK |
| `_deduplicateTasks()` | task_provider.dart:41 | ✅ Filtro final en UI | ✅ OK |
| `softDeleteTask()` | database_service.dart:1138 | ✅ Encuentra existing | ✅ OK |
| `saveNoteLocally()` | database_service.dart:1720 | ✅ Busca existing antes de add | ✅ OK |
| `_findExistingNote()` | database_service.dart:1221 | ✅ Triple verificación | ✅ OK |

### Notas (Notes) - Misma Protección

La misma arquitectura de deduplicación está implementada para **Notes**:
- `saveNoteLocally()` → busca existing antes de agregar
- `_findExistingNote()` → triple verificación (key, firestoreId, createdAt)
- `syncFromCloud()` → busca por firestoreId antes de agregar
- `_cleanupDuplicates()` → limpia duplicados de notas también

## Logging y Diagnóstico

### Mensajes de debug implementados:

```dart
// En saveTaskLocally
debugPrint('⚠️ [TaskProvider] updateTask llamado con tarea no encontrada en state');

// En _cleanupDuplicates
debugPrint('Eliminados ${tasksToDelete.length} tareas duplicadas');
debugPrint('Eliminadas ${notesToDelete.length} notas duplicadas');

// En syncFromCloud
debugPrint('📥 [SYNC] Tarea actualizada: "${cloudTask.title}"');
debugPrint('📥 [SYNC] Tarea nueva descargada: "${cloudTask.title}"');
```

Estos logs ayudan a identificar si hay duplicaciones no esperadas.

## Conclusiones

### ✅ Estado Actual: EXCELENTE

El sistema de deduplicación está **completamente implementado** y cubre todos los escenarios críticos:

1. ✅ **Sincronización desde nube**: Busca por firestoreId antes de agregar
2. ✅ **Creación de tareas**: Triple verificación antes de agregar
3. ✅ **Edición de tareas**: Actualiza in-place, no crea nuevas
4. ✅ **Cambio de usuario**: Aislamiento total por userId
5. ✅ **Conflictos de merge**: Last Write Wins inteligente
6. ✅ **Limpieza automática**: Elimina duplicados al inicio
7. ✅ **Protección en UI**: Filtrado final antes de mostrar
8. ✅ **Soft delete**: Previene re-creación de eliminadas

### Arquitectura Robusta

- **Triple sistema de identidad**: key, firestoreId, createdAt
- **Método updateInPlace()**: Preserva identidad Hive
- **Búsqueda exhaustiva**: Nunca asume, siempre verifica
- **Early returns**: Previene ejecución de código de adición
- **Logging detallado**: Facilita diagnóstico

### Sin Acción Requerida

No se encontraron problemas de duplicación en el código actual. Todas las soluciones necesarias ya están implementadas.

### Recomendaciones Adicionales (Opcionales)

Si en el futuro se detectan duplicaciones, considerar:

1. **Agregar constraint único** en Hive (no soportado nativamente, requeriría índice custom)
2. **Test de integración** que simule todos los escenarios de duplicación
3. **Telemetría** para rastrear llamadas a `box.add()` vs `updateInPlace()`
4. **Validación más estricta** de que `box.add()` solo se llama cuando realmente no existe

### Verificación Práctica

Para verificar que no hay duplicados en una instalación:

```dart
// Agregar este método a DatabaseService para diagnóstico
Future<void> checkForDuplicates() async {
  final box = await _box;
  final firestoreIds = <String>[];
  final timestamps = <int>[];

  for (final task in box.values) {
    if (task.firestoreId.isNotEmpty) {
      if (firestoreIds.contains(task.firestoreId)) {
        debugPrint('⚠️ DUPLICADO por firestoreId: ${task.firestoreId}');
      }
      firestoreIds.add(task.firestoreId);
    }

    final ts = task.createdAt.millisecondsSinceEpoch;
    if (timestamps.contains(ts)) {
      debugPrint('⚠️ DUPLICADO por timestamp: $ts');
    }
    timestamps.add(ts);
  }

  debugPrint('✅ Verificación completa. Tareas totales: ${box.length}');
}
```

---

**Análisis realizado por**: Claude Code (Sonnet 4.5)
**Fecha**: 2026-02-10
**Conclusión**: Sistema de deduplicación completamente funcional y robusto.
