# Análisis de Problemas de Sincronización con Firebase

## Fecha: 2026-02-10

## Problemas Identificados

### 1. **firestoreId no se guarda después de sync inicial**

**Ubicación**: `database_service.dart` líneas 706-718 y 1076-1084

**Problema**:
- Cuando se crea una nueva tarea sin `firestoreId`, se asigna el ID del documento después de la operación `set()` o `batch.set()`
- Sin embargo, hay un error crítico: el ID se asigna ANTES de llamar a `task.save()`, pero si la tarea no está en Hive (`!task.isInBox`), el guardado falla silenciosamente
- En el sync por lotes, se asigna el `firestoreId` pero si la tarea fue creada con `copyWith()` o sin estar en Hive, pierde su referencia

**Evidencia en código**:
```dart
// Línea 706-718 - Sync individual
task.firestoreId = docRef.id;
await task.save(); // ⚠️ Falla si !task.isInBox
```

```dart
// Línea 1076-1084 - Batch sync
if (task.firestoreId.isEmpty) {
  task.firestoreId = docRef.id; // ⚠️ Asigna pero no verifica isInBox
}
```

**Impacto**: Las tareas se sincronizan a Firebase pero localmente quedan sin `firestoreId`, causando duplicación en próximos syncs.

---

### 2. **Sync queue no procesa items con retry exponencial correcto**

**Ubicación**: `database_service.dart` líneas 780-868

**Problema**:
- El método `_processSyncQueue()` NO implementa el backoff exponencial prometido
- Solo intenta sincronizar una vez por llamada
- Si falla, mantiene el item en cola pero no hay lógica de retry con delays incrementales
- No hay tracking de intentos de retry ni timestamps de último intento

**Código actual**:
```dart
await _syncTaskWithRetry(currentTask, userId); // Solo 1 intento en este punto
```

**Falta**:
- Campo `retryCount` en items de cola
- Campo `lastRetryAt` para calcular backoff
- Lógica para saltar items que no deben reintentarse todavía
- Eliminación de items que exceden `_maxRetries`

---

### 3. **Conflictos entre datos locales y remotos no se resuelven correctamente**

**Ubicación**: `database_service.dart` líneas 2115-2339

**Problema**:
- `syncFromCloud()` compara `lastUpdatedAt` pero NO maneja el caso donde ambos (local y cloud) tienen cambios
- Cuando cloud es más nuevo, sobrescribe local SIN verificar si hay cambios locales pendientes de subir
- No hay estrategia de resolución de conflictos (last-write-wins está mal implementado)

**Código problemático**:
```dart
if (cloudUpdated.isAfter(localUpdated)) {
  // Sobrescribe local SIN verificar sync queue
  existingTask.updateInPlace(...);
}
// else: local es más nuevo - se asume que se sincronizará después
// ⚠️ Pero si la tarea local NO está en sync queue, se pierde
```

**Escenario de falla**:
1. Usuario edita tarea offline → queda en Hive con `lastUpdatedAt` nuevo
2. Antes de sincronizar, se ejecuta `syncFromCloud()`
3. Firebase tiene versión más vieja pero NO se sincroniza la versión local
4. Cambios locales se PIERDEN

---

### 4. **cloudSyncEnabled no se respeta consistentemente**

**Ubicación**: Múltiples métodos en `database_service.dart`

**Problema**:
- Algunos métodos verifican `cloudSyncEnabled` al inicio
- Otros métodos NO verifican y dependen del caller
- `_processSyncQueue()` línea 780 NO verifica `cloudSyncEnabled`
- `_processNotesSyncQueue()` línea 2014 NO verifica `cloudSyncEnabled`

**Inconsistencias encontradas**:
```dart
// ✅ Verifica
syncTaskToCloud() - línea 641
syncTaskToCloudDebounced() - línea 918
syncNoteToCloud() - línea 1863

// ❌ NO verifica
_processSyncQueue() - línea 780
_processNotesSyncQueue() - línea 2014
_batchSync() - línea 1061
```

---

### 5. **UserId vacío en algunos flujos**

**Ubicación**: `task_provider.dart` y `database_service.dart`

**Problema**:
- `task_provider.dart` obtiene `userId` de `_auth.currentUser?.uid`
- Si Firebase no está inicializado o auth falla, `currentUser` es `null`
- En `addTask()` línea 121, si `user == null` se guarda localmente pero NO se agrega a sync queue
- La tarea queda huérfana sin forma de sincronizarse después

**Código problemático**:
```dart
// task_provider.dart línea 118-123
await _db.saveTaskLocally(newTask);

final user = _auth.currentUser;
if (user != null) { // ⚠️ Si es null, la tarea NUNCA se sincronizará
  await _db.syncTaskToCloud(newTask, user.uid);
}
```

---

### 6. **Timestamps no se manejan consistentemente**

**Problema**:
- `lastUpdatedAt` se establece inconsistentemente:
  - A veces en `updateInPlace()`
  - A veces antes de llamar a `save()`
  - A veces no se establece
- En `syncFromCloud()`, si `lastUpdatedAt` es `null`, se usa `createdAt` como fallback
- Esto causa comparaciones incorrectas (tarea recién editada parece vieja)

**Casos sin `lastUpdatedAt`**:
- `addTask()` en `task_provider.dart` - NO establece `lastUpdatedAt`
- `toggleTask()` en algunos paths - NO siempre lo establece
- Tareas antiguas migradas sin `lastUpdatedAt`

---

## Soluciones Propuestas

### Fix 1: Asegurar que firestoreId se guarda correctamente

**Cambios en `_syncTaskWithRetry()` y `_batchSync()`**:
1. Después de asignar `firestoreId`, verificar si la tarea está en Hive
2. Si no está, buscar la instancia correcta con `_findExistingTask()`
3. Actualizar la instancia en Hive con el nuevo `firestoreId`
4. Validar que el guardado fue exitoso

### Fix 2: Implementar retry con backoff exponencial verdadero

**Estructura de item en sync queue**:
```dart
{
  'task': Task,
  'userId': String,
  'timestamp': int,
  'retryCount': int,      // NUEVO
  'lastRetryAt': int?,    // NUEVO
}
```

**Lógica de backoff**:
```dart
final timeSinceLastRetry = now - lastRetryAt;
final backoffDelay = Duration(seconds: 2 * pow(2, retryCount)); // 2s, 4s, 8s, 16s
if (timeSinceLastRetry < backoffDelay) {
  continue; // Saltar este item, todavía no es tiempo
}
```

### Fix 3: Mejorar resolución de conflictos

**Estrategia**:
1. Antes de `syncFromCloud()`, detectar tareas locales con cambios pendientes
2. Si hay conflicto (cloud más nuevo pero hay cambios locales), usar heurística:
   - Si tarea local está en sync queue → local gana
   - Si cloud.deleted == true → cloud gana
   - Si diferencia de tiempo < 5 minutos → local gana (usuario activo)
   - Caso contrario → cloud gana (last-write-wins)
3. Registrar conflictos resueltos en logs

### Fix 4: Verificar cloudSyncEnabled en TODOS los métodos sync

**Métodos a actualizar**:
- `_processSyncQueue()`
- `_processNotesSyncQueue()`
- `_batchSync()`
- `_syncLocalOnlyItems()`

### Fix 5: Manejar userId vacío correctamente

**Estrategia**:
1. Si `userId` es vacío al crear tarea, agregar a cola local especial
2. En próximo auth exitoso, procesar cola local y asignar userId
3. En `main.dart` después de auth, llamar a método que sincroniza items huérfanos

### Fix 6: Normalizar timestamps

**Cambios**:
1. SIEMPRE establecer `lastUpdatedAt = DateTime.now()` antes de guardar
2. En constructor de `Task`, si `lastUpdatedAt` es null, usar `createdAt`
3. En migración, asegurar que todas las tareas tienen `lastUpdatedAt`

---

## Verificación Post-Fix

### Tests a ejecutar:

1. **Test de firestoreId persistencia**:
   - Crear tarea → verificar que `firestoreId` se guarda en Hive
   - Cerrar app → reabrir → verificar que `firestoreId` sigue presente

2. **Test de retry con backoff**:
   - Desconectar internet
   - Crear 5 tareas
   - Verificar que sync queue tiene 5 items
   - Reconectar internet
   - Observar logs de retry con delays incrementales

3. **Test de resolución de conflictos**:
   - Dispositivo A: editar tarea, no sincronizar
   - Dispositivo B: editar misma tarea, sincronizar
   - Dispositivo A: sincronizar
   - Verificar que gana la versión más reciente

4. **Test de cloudSyncEnabled**:
   - Deshabilitar cloud sync
   - Crear tareas
   - Verificar que NO se llama a Firebase
   - Verificar que sync queue NO se procesa

5. **Test de userId vacío**:
   - Simular fallo de auth
   - Crear tareas
   - Verificar que se guardan localmente
   - Auth exitoso
   - Verificar que tareas se sincronizan

6. **Test de timestamps**:
   - Crear tarea → verificar `lastUpdatedAt`
   - Editar tarea → verificar que `lastUpdatedAt` se actualiza
   - Sync → verificar que Firebase tiene timestamp correcto

---

## Prioridad de Fixes

1. **Alta**: Fix 1 (firestoreId) - causa duplicación de datos
2. **Alta**: Fix 3 (conflictos) - causa pérdida de datos
3. **Media**: Fix 2 (retry backoff) - afecta performance pero no causa pérdida
4. **Media**: Fix 4 (cloudSyncEnabled) - viola preferencia del usuario
5. **Baja**: Fix 5 (userId vacío) - caso raro, hay workaround
6. **Baja**: Fix 6 (timestamps) - mejora precisión pero no crítico
