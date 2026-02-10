# Guía Rápida - Prevención de Duplicados en AuraList

## Para Desarrolladores

Esta guía de referencia rápida te ayuda a evitar crear duplicados al trabajar con tareas y notas en AuraList.

---

## Regla de Oro

### ✅ HACER: Usar `updateInPlace()` para objetos en Hive

```dart
// ✅ CORRECTO
if (task.isInBox) {
  task.updateInPlace(title: 'Nuevo título');
  await task.save();
}
```

### ❌ NO HACER: Usar `copyWith()` y guardar directamente

```dart
// ❌ INCORRECTO - Puede crear duplicados
final updatedTask = task.copyWith(title: 'Nuevo título');
await box.add(updatedTask); // ¡Crea duplicado!
```

---

## Casos Comunes

### 1. Crear Nueva Tarea

```dart
// ✅ CORRECTO
final newTask = Task(
  title: 'Nueva tarea',
  type: 'daily',
  createdAt: DateTime.now(),
);
await _db.saveTaskLocally(newTask); // Verifica duplicados internamente
```

### 2. Actualizar Tarea Existente

```dart
// ✅ CORRECTO - Si tienes la referencia original
if (task.isInBox) {
  task.updateInPlace(
    title: 'Título actualizado',
    isCompleted: true,
    lastUpdatedAt: DateTime.now(),
  );
  await task.save();
}

// ✅ CORRECTO - Si usaste copyWith (en provider)
await taskProvider.updateTask(task); // Busca el original internamente
```

### 3. Cambiar Estado de Tarea

```dart
// ✅ CORRECTO
if (task.isInBox) {
  task.updateInPlace(isCompleted: !task.isCompleted);
  await task.save();
} else {
  await taskProvider.toggleTask(task); // Busca el original
}
```

### 4. Guardar Después de Editar

```dart
// ✅ CORRECTO
await _db.saveTaskLocally(task); // Verifica si existe antes de agregar
```

---

## Identificadores de Tareas

Cada tarea tiene 3 identificadores:

```dart
1. task.key          // Hive key (null si no está en Hive)
2. task.firestoreId  // ID de Firebase ('' si no está sincronizada)
3. task.createdAt    // Timestamp de creación (siempre existe)
```

### Verificar si una Tarea Está en Hive

```dart
if (task.isInBox) {
  // La tarea está guardada en Hive
  // Puedes usar task.save() directamente
} else {
  // La tarea no está en Hive (objeto nuevo o desconectado)
  // Debes usar saveTaskLocally() que verifica duplicados
}
```

---

## Métodos Seguros

### En DatabaseService

```dart
// ✅ SIEMPRE USAR ESTOS
await _db.saveTaskLocally(task);        // Verifica duplicados
await _db.saveNoteLocally(note);        // Verifica duplicados
await _db.softDeleteTask(task, userId); // Elimina sin perder identidad

// ❌ NUNCA USAR DIRECTAMENTE
await box.add(task);  // ¡Puede crear duplicados!
```

### En TaskProvider

```dart
// ✅ SIEMPRE USAR ESTOS
await taskProvider.addTask(title);      // Crea nueva tarea
await taskProvider.updateTask(task);    // Actualiza existente
await taskProvider.toggleTask(task);    // Cambia estado
await taskProvider.deleteTask(task);    // Elimina tarea

// ❌ NUNCA HACER
final box = Hive.box<Task>('tasks');
await box.add(task); // ¡Saltea las protecciones!
```

---

## Checklist de Verificación

Antes de hacer commit, verifica:

- [ ] ¿Usaste `updateInPlace()` para actualizar objetos en Hive?
- [ ] ¿Usaste `saveTaskLocally()` en vez de `box.add()` directamente?
- [ ] ¿Verificaste `task.isInBox` antes de guardar?
- [ ] ¿Usaste los métodos del provider en vez de acceder a Hive directamente?
- [ ] ¿Preservaste el `createdAt` original al copiar tareas?

---

## Patrones Anti-Duplicación

### Patrón 1: Actualizar Objeto en Hive

```dart
// ✅ CORRECTO
void _updateTask(Task task, String newTitle) {
  if (task.isInBox) {
    task.updateInPlace(
      title: newTitle,
      lastUpdatedAt: DateTime.now(),
    );
    task.save();
  }
}
```

### Patrón 2: Guardar con Verificación

```dart
// ✅ CORRECTO
Future<void> _saveTask(Task task) async {
  await _db.saveTaskLocally(task); // Verifica duplicados
  await _db.syncTaskToCloud(task, userId); // Sincroniza
}
```

### Patrón 3: Buscar Antes de Crear

```dart
// ✅ CORRECTO
Future<void> _createOrUpdate(Task task) async {
  final existing = await _db._findExistingTask(task);

  if (existing != null) {
    existing.updateInPlace(...);
    await existing.save();
  } else {
    await box.add(task);
  }
}
```

### Patrón 4: Early Return para Prevenir Duplicados

```dart
// ✅ CORRECTO
Future<void> _saveTaskLocally(Task task) async {
  // Verificar si ya existe
  final existing = await _findExistingTask(task);

  if (existing != null) {
    existing.updateInPlace(...);
    await existing.save();
    return; // IMPORTANTE: Previene el box.add() de abajo
  }

  // Solo llega aquí si no existe
  await box.add(task);
}
```

---

## Errores Comunes

### ❌ Error 1: Usar copyWith y Agregar

```dart
// ❌ MAL
final updated = task.copyWith(title: 'Nuevo');
await box.add(updated); // ¡Crea duplicado!

// ✅ BIEN
if (task.isInBox) {
  task.updateInPlace(title: 'Nuevo');
  await task.save();
} else {
  await _db.saveTaskLocally(task);
}
```

### ❌ Error 2: No Verificar isInBox

```dart
// ❌ MAL
await box.add(task); // Asume que es nueva

// ✅ BIEN
if (task.isInBox) {
  await task.save();
} else {
  await _db.saveTaskLocally(task);
}
```

### ❌ Error 3: Ignorar el Objeto Original

```dart
// ❌ MAL
final newTask = task.copyWith(isCompleted: true);
await _db.saveTaskLocally(newTask); // Pierde Hive key

// ✅ BIEN
task.updateInPlace(isCompleted: true);
await task.save();
```

### ❌ Error 4: No Preservar createdAt

```dart
// ❌ MAL
final copy = Task(
  title: task.title,
  type: task.type,
  createdAt: DateTime.now(), // ¡Nuevo timestamp!
);

// ✅ BIEN
final copy = Task(
  title: task.title,
  type: task.type,
  createdAt: task.createdAt, // Preserva timestamp original
  firestoreId: task.firestoreId, // Preserva ID
);
```

---

## Debugging

### Verificar si Hay Duplicados

```dart
// En debug mode
import 'package:checklist_app/services/deduplication_verifier.dart';

void checkDuplicates() async {
  final taskBox = Hive.box<Task>('tasks');
  final noteBox = Hive.box<Note>('notes');

  await DeduplicationVerifier.verifyAllBoxes(taskBox, noteBox);
  // Ver logs en consola
}
```

### Logs Útiles

```dart
// Agregar logs para debugging
debugPrint('Task identity:');
debugPrint('  - key: ${task.key}');
debugPrint('  - firestoreId: ${task.firestoreId}');
debugPrint('  - createdAt: ${task.createdAt}');
debugPrint('  - isInBox: ${task.isInBox}');
```

### Obtener Info Detallada de una Tarea

```dart
final info = DeduplicationVerifier.getTaskIdentityInfo(task);
debugPrint(info);
```

---

## Referencia Rápida de Métodos

### Task Model

| Método | Uso | ¿Crea Duplicados? |
|--------|-----|-------------------|
| `updateInPlace()` | Actualizar objeto en Hive | ✅ NO |
| `copyWith()` | Crear nueva instancia | ⚠️ SÍ (si no se maneja bien) |
| `save()` | Guardar cambios en Hive | ✅ NO |

### DatabaseService

| Método | Uso | ¿Verifica Duplicados? |
|--------|-----|------------------------|
| `saveTaskLocally()` | Guardar tarea | ✅ SÍ |
| `saveNoteLocally()` | Guardar nota | ✅ SÍ |
| `syncFromCloud()` | Sincronizar desde Firebase | ✅ SÍ |
| `_findExistingTask()` | Buscar tarea existente | ✅ SÍ |

### TaskProvider

| Método | Uso | ¿Verifica Duplicados? |
|--------|-----|------------------------|
| `addTask()` | Crear nueva tarea | ✅ SÍ |
| `updateTask()` | Actualizar existente | ✅ SÍ |
| `toggleTask()` | Cambiar estado | ✅ SÍ |
| `deleteTask()` | Eliminar tarea | ✅ SÍ |

---

## Casos de Uso por Escenario

### Escenario 1: Usuario Crea Tarea

```dart
// En TaskProvider
Future<void> addTask(String title) async {
  final newTask = Task(
    title: title,
    type: _type,
    createdAt: DateTime.now(), // Timestamp único
  );

  await _db.saveTaskLocally(newTask); // Verifica duplicados

  final user = _auth.currentUser;
  if (user != null) {
    await _db.syncTaskToCloud(newTask, user.uid); // Asigna firestoreId
  }
}
```

### Escenario 2: Usuario Edita Tarea

```dart
// En UI
onPressed: () {
  // Obtener tarea del state
  final task = tasks[index];

  // Actualizar in-place
  task.updateInPlace(
    title: newTitle,
    lastUpdatedAt: DateTime.now(),
  );
  await task.save();

  // Sincronizar
  if (user != null) {
    await _db.syncTaskToCloudDebounced(task, user.uid);
  }
}
```

### Escenario 3: Sincronización desde Firebase

```dart
// En DatabaseService.syncFromCloud()
for (final doc in tasksSnapshot.docs) {
  final cloudTask = Task.fromFirestore(doc.id, doc.data());

  // Buscar existente
  final existingTask = box.values.firstWhere(
    (t) => t?.firestoreId == doc.id,
    orElse: () => null,
  );

  if (existingTask != null) {
    // Comparar timestamps
    if (cloudUpdated.isAfter(localUpdated)) {
      existingTask.updateInPlace(...); // Actualizar
      await existingTask.save();
    }
  } else {
    await box.add(cloudTask); // Solo si no existe
  }
}
```

### Escenario 4: Cambiar Estado con Toggle

```dart
// En TaskProvider
Future<void> toggleTask(Task task) async {
  if (task.isInBox) {
    task.updateInPlace(
      isCompleted: !task.isCompleted,
      lastUpdatedAt: DateTime.now(),
    );
    await task.save();
  } else {
    // Buscar original si se perdió la referencia
    final original = state.firstWhere(
      (t) => t.createdAt == task.createdAt,
    );
    original.updateInPlace(isCompleted: !original.isCompleted);
    await original.save();
  }

  // Sincronizar
  if (user != null) {
    await _db.syncTaskToCloudDebounced(task, user.uid);
  }
}
```

---

## Preguntas Frecuentes

### ¿Cuándo usar `updateInPlace()` vs `copyWith()`?

- **`updateInPlace()`**: Cuando quieres modificar un objeto que ya está en Hive
- **`copyWith()`**: Cuando necesitas un nuevo objeto para estado inmutable (providers)

### ¿Qué pasa si uso `copyWith()` y luego `saveTaskLocally()`?

No hay problema. `saveTaskLocally()` busca el objeto original por `createdAt` y lo actualiza en vez de crear duplicado.

### ¿Cómo sé si una tarea está en Hive?

```dart
if (task.isInBox) {
  // Está en Hive
} else {
  // No está en Hive o perdió la referencia
}
```

### ¿Qué hacer si sospecho que hay duplicados?

```dart
import 'package:checklist_app/services/deduplication_verifier.dart';

await DeduplicationVerifier.verifyAllBoxes(taskBox, noteBox);
```

### ¿Se eliminan automáticamente los duplicados?

Sí, al iniciar la app se ejecuta `_cleanupDuplicates()` que elimina cualquier duplicado existente.

---

## Resumen

### ✅ Siempre Hacer

1. Usar `updateInPlace()` para actualizar objetos en Hive
2. Usar `saveTaskLocally()` en vez de `box.add()` directamente
3. Verificar `task.isInBox` antes de guardar
4. Preservar `createdAt` al copiar tareas
5. Usar métodos del provider en vez de acceder a Hive directamente

### ❌ Nunca Hacer

1. Usar `box.add()` directamente sin verificar duplicados
2. Usar `copyWith()` + `box.add()` para actualizar
3. Cambiar el `createdAt` de una tarea existente
4. Saltear los métodos del provider
5. Ignorar el valor de `isInBox`

---

**Documentos Relacionados**:
- `DEDUPLICATION_ANALYSIS.md` - Análisis técnico completo
- `DEDUPLICATION_FLOWCHART.md` - Diagramas de flujo
- `INFORME_FINAL_DEDUPLICACION.md` - Informe ejecutivo
- `lib/services/deduplication_verifier.dart` - Herramienta de diagnóstico

**Última actualización**: 2026-02-10
