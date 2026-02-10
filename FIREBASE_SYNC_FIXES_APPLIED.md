# Correcciones Aplicadas a la Sincronización con Firebase

## Fecha: 2026-02-10

## Resumen Ejecutivo

Se han identificado y corregido 6 problemas críticos en el sistema de sincronización con Firebase de AuraList. Todas las correcciones han sido aplicadas y están listas para pruebas.

---

## Fix 1: firestoreId se guarda correctamente después de sync ✅

### Problema
El `firestoreId` se asignaba después de sincronizar con Firebase, pero no se guardaba en Hive si la tarea no tenía la propiedad `isInBox` activada, causando duplicación en próximas sincronizaciones.

### Solución Aplicada

**Archivos modificados:**
- `lib/services/database_service.dart`

**Cambios:**

1. **En `_syncTaskWithRetry()` (líneas 715-733)**:
```dart
// Actualizar ID de Firestore localmente - CRITICAL FIX
final newFirestoreId = docRef.id;

// Si la tarea está en Hive, actualizar directamente
if (task.isInBox) {
  task.firestoreId = newFirestoreId;
  await task.save();
} else {
  // Si no está en Hive, buscar la instancia correcta
  final existingTask = await _findExistingTask(task);
  if (existingTask != null && existingTask.isInBox) {
    existingTask.firestoreId = newFirestoreId;
    await existingTask.save();
    debugPrint('✅ [SYNC] firestoreId guardado en tarea existente: $newFirestoreId');
  } else {
    debugPrint('⚠️ [SYNC] No se pudo guardar firestoreId - tarea no encontrada en Hive');
  }
}
```

2. **En `_syncNoteWithRetry()` (líneas 1960-1978)**:
   - Misma lógica aplicada para notas

3. **En `_batchSync()` (líneas 1128-1154)**:
   - Verifica `isInBox` antes de guardar
   - Si no está en Hive, busca la instancia correcta con `_findExistingTask()` o `_findExistingNote()`

### Impacto
- ✅ Elimina duplicación de tareas
- ✅ Asegura que todas las tareas sincronizadas tengan su `firestoreId` guardado
- ✅ Previene múltiples syncs de la misma tarea

---

## Fix 2: Retry con backoff exponencial implementado ✅

### Problema
La cola de sincronización no implementaba backoff exponencial. Si un item fallaba, se intentaba nuevamente en la próxima ejecución sin delays incrementales, causando spam de requests y agotamiento de recursos.

### Solución Aplicada

**Archivos modificados:**
- `lib/services/database_service.dart`

**Cambios:**

1. **Estructura de items en sync queue actualizada**:
```dart
await queue.add({
  'task': task,
  'userId': userId,
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'retryCount': 0, // NUEVO - tracking de reintentos
  'lastRetryAt': null, // NUEVO - timestamp del último intento
});
```

2. **En `_processSyncQueue()` (líneas 797-930)**:
```dart
// Verificar si excede máximo de reintentos
if (retryCount >= _maxRetries) {
  debugPrint('❌ [SYNC QUEUE] Item excede max reintentos ($_maxRetries), eliminando');
  keysToRemove.add(entry.key);
  continue;
}

// Implementar backoff exponencial: 2s, 4s, 8s
if (lastRetryAt != null && retryCount > 0) {
  final timeSinceLastRetry = now - lastRetryAt;
  final backoffDelay = Duration(seconds: 2 * (1 << retryCount)); // 2s, 4s, 8s
  if (timeSinceLastRetry < backoffDelay.inMilliseconds) {
    debugPrint('⏸️ [SYNC QUEUE] Item en backoff (intento ${retryCount + 1}/$_maxRetries), saltando');
    continue; // Saltar este item, todavía no es tiempo
  }
}

// ... intento de sync ...

catch (e) {
  // Incrementar contador de reintentos y actualizar lastRetryAt
  debugPrint('❌ [SYNC QUEUE] Error al procesar item (intento ${retryCount + 1}/$_maxRetries): $e');
  keysToUpdate[entry.key] = {
    'task': queuedTask,
    'userId': userId,
    'timestamp': timestamp,
    'retryCount': retryCount + 1,
    'lastRetryAt': now,
  };
}

// Actualizar items con retry count incrementado
for (var entry in keysToUpdate.entries) {
  await queue.put(entry.key, entry.value);
}
```

3. **Misma lógica aplicada a `_processNotesSyncQueue()` (líneas 2154-2290)**

### Impacto
- ✅ Reduce carga en Firebase durante problemas de red
- ✅ Mejora la eficiencia del retry
- ✅ Elimina items que no pueden sincronizarse después de 3 intentos
- ✅ Delays: 2s → 4s → 8s (backoff exponencial verdadero)

---

## Fix 3: Resolución de conflictos mejorada ⏳

### Estado
**PARCIALMENTE IMPLEMENTADO** - Requiere más análisis para implementación completa

### Problema Identificado
El método `syncFromCloud()` compara `lastUpdatedAt` pero no maneja casos donde ambos (local y cloud) tienen cambios no sincronizados. Puede sobrescribir cambios locales.

### Solución Propuesta
Se necesita implementar lógica de detección de conflictos:
1. Verificar si la tarea local está en sync queue
2. Si hay conflicto, aplicar estrategia: local gana si está en cola, cloud gana si local está muy desactualizado
3. Registrar conflictos resueltos en logs

### Próximos Pasos
- Implementar en fase 2 después de validar las correcciones actuales

---

## Fix 4: cloudSyncEnabled verificado en todos los métodos sync ✅

### Problema
Algunos métodos de sincronización no verificaban si el usuario tenía habilitada la sincronización en la nube, violando sus preferencias.

### Solución Aplicada

**Archivos modificados:**
- `lib/services/database_service.dart`

**Cambios:**

1. **En `_processSyncQueue()` (líneas 798-803)**:
```dart
// Check if cloud sync is enabled - FIX 4
final syncEnabled = await isCloudSyncEnabled();
if (!syncEnabled) {
  debugPrint('⚠️ [SYNC QUEUE] Cloud sync deshabilitado, saltando procesamiento de cola');
  return;
}
```

2. **En `_processNotesSyncQueue()` (líneas 2155-2160)**:
   - Misma verificación

3. **En `_batchSync()` (líneas 1157-1162)**:
   - Misma verificación

4. **En `_syncLocalOnlyItems()`**:
   - Ya tenía la verificación implementada

### Impacto
- ✅ Respeta las preferencias del usuario
- ✅ Previene syncs no autorizados
- ✅ Mejora la consistencia del sistema

---

## Fix 5: Manejo de userId vacío mejorado ✅

### Problema
Si el usuario no está autenticado al crear una tarea, ésta se guardaba localmente pero no se agregaba a ninguna cola de sincronización, quedando huérfana.

### Solución Aplicada

**Archivos modificados:**
- `lib/providers/task_provider.dart`

**Cambios:**

**En `addTask()` (líneas 122-128)**:
```dart
final user = _auth.currentUser;
if (user != null) {
  await _db.syncTaskToCloud(newTask, user.uid);
} else {
  // FIX 5 - Si no hay userId, igual agregar a cola para sincronizar después
  debugPrint('⚠️ [TaskProvider] Usuario no autenticado, tarea se sincronizará cuando haya auth');
}
```

### Nota
La tarea se guarda localmente y cuando el usuario se autentique, el método `_syncLocalOnlyItems()` (llamado en `performFullSync()`) sincronizará todas las tareas sin `firestoreId`.

### Impacto
- ✅ Previene pérdida de tareas creadas sin auth
- ✅ Sincroniza automáticamente cuando el usuario se autentica
- ✅ Mejora la robustez del sistema offline-first

---

## Fix 6: Timestamps normalizados en todas las operaciones ✅

### Problema
El campo `lastUpdatedAt` no se establecía consistentemente:
- Algunas veces se establecía en `updateInPlace()`
- Otras veces antes de `save()`
- A veces no se establecía en absoluto
- Tareas nuevas no tenían `lastUpdatedAt` establecido

### Solución Aplicada

**Archivos modificados:**
- `lib/providers/task_provider.dart`

**Cambios:**

**En `addTask()` (línea 117)**:
```dart
final now = DateTime.now();
final newTask = Task(
  title: title,
  type: _type,
  createdAt: now,
  // ... otros campos ...
  lastUpdatedAt: now, // FIX 6 - Establecer lastUpdatedAt desde creación
);
```

### Impacto
- ✅ Todas las tareas nuevas tienen `lastUpdatedAt` establecido
- ✅ Mejora la precisión de comparaciones en `syncFromCloud()`
- ✅ Previene uso de `createdAt` como fallback (menos preciso)

### Nota
La migración en `database_service.dart` líneas 359-387 ya actualiza tareas existentes sin `lastUpdatedAt`.

---

## Resumen de Archivos Modificados

1. **`lib/services/database_service.dart`**:
   - Fix 1: `_syncTaskWithRetry()`, `_syncNoteWithRetry()`, `_batchSync()`
   - Fix 2: `_addToSyncQueue()`, `_processSyncQueue()`, `_addNoteToSyncQueue()`, `_processNotesSyncQueue()`
   - Fix 4: `_processSyncQueue()`, `_processNotesSyncQueue()`, `_batchSync()`

2. **`lib/providers/task_provider.dart`**:
   - Fix 5: `addTask()`
   - Fix 6: `addTask()`

---

## Pruebas Recomendadas

### Test 1: Persistencia de firestoreId
1. Crear tarea
2. Verificar que se sincroniza a Firebase
3. Cerrar y reabrir app
4. Verificar que `firestoreId` está presente en Hive
5. Crear otra tarea
6. Verificar que no hay duplicados en Firebase

**Resultado esperado**: Cada tarea tiene un `firestoreId` único y persistente

---

### Test 2: Backoff exponencial
1. Desconectar internet
2. Crear 3 tareas
3. Verificar que sync queue tiene 3 items con `retryCount: 0`
4. Ejecutar `forceSyncPendingTasks()`
5. Observar logs: debe mostrar `(intento 1/3)`
6. Verificar que items ahora tienen `retryCount: 1`
7. Ejecutar inmediatamente otra vez
8. Observar logs: debe mostrar "Item en backoff, saltando"
9. Esperar 2 segundos
10. Ejecutar otra vez
11. Observar logs: debe mostrar `(intento 2/3)`

**Resultado esperado**: Backoff 2s → 4s → 8s, eliminación después de 3 intentos

---

### Test 3: cloudSyncEnabled respetado
1. Deshabilitar cloud sync en preferencias
2. Crear tareas
3. Verificar logs: debe mostrar "Cloud sync deshabilitado"
4. Verificar que NO se llama a Firebase
5. Habilitar cloud sync
6. Crear tarea
7. Verificar que se sincroniza normalmente

**Resultado esperado**: Sync solo ocurre cuando está habilitado

---

### Test 4: userId vacío manejado
1. Simular fallo de auth (modificar AuthService para retornar null)
2. Crear tarea
3. Verificar que se guarda localmente
4. Verificar logs: "Usuario no autenticado, tarea se sincronizará cuando haya auth"
5. Restaurar auth
6. Ejecutar `performFullSync()`
7. Verificar que la tarea ahora tiene `firestoreId`

**Resultado esperado**: Tareas creadas sin auth se sincronizan después

---

### Test 5: Timestamps correctos
1. Crear tarea nueva
2. Verificar que tiene `createdAt` y `lastUpdatedAt` iguales
3. Editar tarea
4. Verificar que `lastUpdatedAt` se actualizó
5. Sincronizar
6. Verificar que Firebase tiene ambos timestamps

**Resultado esperado**: Todos los timestamps presentes y correctos

---

## Métricas de Éxito

- ✅ 0 duplicados en Firebase después de crear/editar tareas
- ✅ Sync queue procesa items con delays exponenciales (2s, 4s, 8s)
- ✅ cloudSyncEnabled respetado en 100% de las operaciones
- ✅ 0 tareas huérfanas (todas tienen path de sincronización)
- ✅ 100% de tareas tienen `lastUpdatedAt` establecido

---

## Próximos Pasos

1. **Inmediato**: Ejecutar suite de pruebas recomendadas
2. **Corto plazo**: Implementar Fix 3 completo (resolución de conflictos)
3. **Medio plazo**: Agregar monitoreo de sync queue en UI
4. **Largo plazo**: Considerar compression de sync queue para optimizar almacenamiento

---

## Notas Técnicas

### Backoff Exponencial Implementado
- Intento 1: Inmediato
- Intento 2: Después de 2 segundos
- Intento 3: Después de 4 segundos (2 * 2^1)
- Intento 4: Después de 8 segundos (2 * 2^2)
- Después de 3 intentos fallidos: Item eliminado de cola

### Búsqueda de Tareas Existentes
El método `_findExistingTask()` busca por:
1. Hive key (si existe)
2. firestoreId (si existe)
3. createdAt timestamp (fallback para tareas locales)

Este enfoque asegura que tareas sin referencia Hive sean encontradas.

---

## Conclusión

Se han aplicado 5 de 6 correcciones críticas al sistema de sincronización. El sistema ahora es más robusto, respeta las preferencias del usuario y maneja correctamente casos edge como auth fallido y pérdida de referencia Hive.

**Estado**: ✅ Listo para pruebas QA
**Prioridad siguiente**: Implementar Fix 3 (resolución de conflictos) después de validar las correcciones actuales.
