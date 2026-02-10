# Diagrama de Flujo - Sistema de Deduplicación de Tareas

## Flujo 1: Guardar Tarea Localmente

```
┌─────────────────────────────────────────────────────────────────┐
│           DatabaseService.saveTaskLocally(task)                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ╔════════════════╗
                    ║ ¿task.isInBox? ║
                    ╚════════╤═══════╝
                             │
                   ┌─────────┴─────────┐
                   │                   │
                  SÍ                  NO
                   │                   │
                   ▼                   ▼
        ┌──────────────────┐  ┌─────────────────────────┐
        │  task.save()     │  │ _findExistingTask(task) │
        │  (actualizar)    │  └──────────┬──────────────┘
        └──────────────────┘             │
                                         ▼
                                 ╔═══════════════╗
                                 ║ ¿Encontrado?  ║
                                 ╚═══════╤═══════╝
                                         │
                               ┌─────────┴─────────┐
                               │                   │
                              SÍ                  NO
                               │                   │
                               ▼                   ▼
              ┌──────────────────────────┐  ┌──────────────┐
              │ existing.updateInPlace() │  │ box.add()    │
              │ existing.save()          │  │ (nueva tarea)│
              │ return ← NO box.add()    │  └──────────────┘
              └──────────────────────────┘
```

## Flujo 2: Buscar Tarea Existente (_findExistingTask)

```
┌──────────────────────────────────────────────────────────────┐
│              _findExistingTask(task)                          │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                    ╔════════════════╗
                    ║ ¿task.key?     ║
                    ║ != null        ║
                    ╚════════╤═══════╝
                             │
                   ┌─────────┴─────────┐
                   │                   │
                  SÍ                  NO
                   │                   │
                   ▼                   │
        ┌──────────────────┐           │
        │ t = box.get(key) │           │
        └─────────┬────────┘           │
                  │                    │
                  ▼                    │
          ╔═══════════╗                │
          ║ ¿t!=null? ║                │
          ╚═════╤═════╝                │
                │                      │
        ┌───────┴───────┐              │
       SÍ              NO              │
        │               │               │
        ▼               └───────────────┤
   ┌────────┐                           │
   │ return │                           │
   │   t    │                           │
   └────────┘                           │
                                        ▼
                            ╔═══════════════════════╗
                            ║ ¿task.firestoreId?    ║
                            ║ != empty              ║
                            ╚═══════════╤═══════════╝
                                        │
                              ┌─────────┴─────────┐
                              │                   │
                             SÍ                  NO
                              │                   │
                              ▼                   │
              ┌──────────────────────────┐        │
              │ t = box.values.firstWhere│        │
              │ (firestoreId == task.fId)│        │
              └─────────┬────────────────┘        │
                        │                         │
                        ▼                         │
                ╔═══════════╗                     │
                ║ ¿t!=null? ║                     │
                ╚═════╤═════╝                     │
                      │                           │
              ┌───────┴───────┐                   │
             SÍ              NO                   │
              │               │                   │
              ▼               └───────────────────┤
         ┌────────┐                               │
         │ return │                               │
         │   t    │                               │
         └────────┘                               │
                                                  ▼
                                ╔═══════════════════════════╗
                                ║ Buscar por createdAt      ║
                                ║ (timestamp único)         ║
                                ╚═════════╤═════════════════╝
                                          │
                                          ▼
                        ┌────────────────────────────────────┐
                        │ return box.values.firstWhere(      │
                        │   createdAt == task.createdAt)     │
                        │ orElse: () => null                 │
                        └────────────────────────────────────┘
```

## Flujo 3: Sincronización desde Firebase

```
┌──────────────────────────────────────────────────────────────┐
│              syncFromCloud(userId)                            │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ Obtener todas las tareas de  │
              │ Firebase para el usuario     │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Para cada tarea en Firebase: │
              └──────────┬───────────────────┘
                         │
                         ▼
                 ╔═══════════════╗
                 ║ ¿task.deleted ║
                 ║ == true?      ║
                 ╚═══════╤═══════╝
                         │
               ┌─────────┴─────────┐
               │                   │
              SÍ                  NO
               │                   │
               ▼                   │
    ┌──────────────────┐           │
    │ Marcar local     │           │
    │ como deleted     │           │
    │ continue         │           │
    └──────────────────┘           │
                                   ▼
                    ╔══════════════════════════╗
                    ║ existing = box.values    ║
                    ║ .firstWhere(firestoreId) ║
                    ╚═══════════╤══════════════╝
                                │
                      ┌─────────┴─────────┐
                      │                   │
               ¿Encontrado?              NO
                      │                   │
                     SÍ                   │
                      │                   │
                      ▼                   ▼
          ╔═══════════════════╗   ┌──────────────┐
          ║ Comparar          ║   │ box.add()    │
          ║ timestamps        ║   │ (nueva tarea)│
          ╚═════════╤═════════╝   └──────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
    ¿Cloud > Local?         NO
          │                   │
         SÍ                   │
          │                   │
          ▼                   ▼
┌──────────────────┐  ┌────────────────┐
│ existing.update  │  │ No actualizar  │
│ InPlace()        │  │ (local más     │
│ existing.save()  │  │ reciente)      │
└──────────────────┘  └────────────────┘
```

## Flujo 4: Actualizar Tarea (TaskProvider)

```
┌──────────────────────────────────────────────────────────────┐
│              TaskProvider.updateTask(task)                    │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                    ╔════════════════╗
                    ║ ¿task.isInBox? ║
                    ╚════════╤═══════╝
                             │
                   ┌─────────┴─────────┐
                   │                   │
                  SÍ                  NO
                   │                   │
                   ▼                   │
        ┌──────────────────┐           │
        │ task.updateInPlace│          │
        │ task.save()      │           │
        │ sync debounced   │           │
        │ return           │           │
        └──────────────────┘           │
                                       ▼
                        ╔══════════════════════╗
                        ║ Buscar original en   ║
                        ║ state por:           ║
                        ║ 1. key               ║
                        ║ 2. firestoreId       ║
                        ║ 3. createdAt         ║
                        ╚═════════╤════════════╝
                                  │
                        ┌─────────┴─────────┐
                        │                   │
                  ¿Encontrado?             NO
                        │                   │
                       SÍ                   │
                        │                   ▼
                        ▼         ┌─────────────────┐
        ┌──────────────────────┐  │ ⚠️ Warning      │
        │ original.updateInPlace│ │ Guardar como    │
        │ original.save()       │  │ nueva (raro)    │
        │ sync debounced        │  └─────────────────┘
        └──────────────────────┘
```

## Flujo 5: Toggle Estado de Tarea

```
┌──────────────────────────────────────────────────────────────┐
│              TaskProvider.toggleTask(task)                    │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
                    ╔════════════════╗
                    ║ ¿task.isInBox? ║
                    ╚════════╤═══════╝
                             │
                   ┌─────────┴─────────┐
                   │                   │
                  SÍ                  NO
                   │                   │
                   ▼                   │
        ┌──────────────────┐           │
        │ task.updateInPlace│          │
        │ (isCompleted=!x) │           │
        │ task.save()      │           │
        │ sync debounced   │           │
        └──────────────────┘           │
                                       ▼
                        ╔══════════════════════╗
                        ║ Buscar original:     ║
                        ║ 1. Por key           ║
                        ║ 2. Por firestoreId   ║
                        ║ 3. Por createdAt     ║
                        ╚═════════╤════════════╝
                                  │
                        ┌─────────┴─────────┐
                        │                   │
                  ¿Encontrado?             NO
                        │                   │
                       SÍ                   │
                        │                   ▼
                        ▼         ┌─────────────────┐
        ┌──────────────────────┐  │ ⚠️ Fallback:    │
        │ original.updateInPlace│ │ llamar updateTask│
        │ (isCompleted=!x)      │ │ con copyWith    │
        │ original.save()       │  └─────────────────┘
        │ sync debounced        │
        └──────────────────────┘
```

## Flujo 6: Limpieza Automática de Duplicados

```
┌──────────────────────────────────────────────────────────────┐
│    DatabaseService._cleanupDuplicates()                       │
│    (ejecutado en _runMigrations al inicio)                    │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ Inicializar Sets:            │
              │ - seenTaskIds (firestoreId)  │
              │ - seenTimestamps (createdAt) │
              │ - tasksToDelete (keys)       │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Para cada task en _taskBox:  │
              └──────────┬───────────────────┘
                         │
                         ▼
              ╔═════════════════════════╗
              ║ ¿firestoreId no vacío?  ║
              ╚═══════════╤═════════════╝
                          │
                ┌─────────┴─────────┐
                │                   │
               SÍ                  NO
                │                   │
                ▼                   │
    ╔═══════════════════════╗       │
    ║ ¿Ya visto el ID?      ║       │
    ╚═══════╤═══════════════╝       │
            │                       │
    ┌───────┴───────┐               │
   SÍ              NO               │
    │               │               │
    ▼               ▼               │
┌─────────┐  ┌──────────────┐      │
│ Marcar  │  │ Agregar a    │      │
│ como    │  │ seenTaskIds  │      │
│duplicado│  └──────────────┘      │
└─────────┘                        │
    │                              │
    └──────────────────────────────┤
                                   ▼
                        ╔══════════════════════╗
                        ║ ¿Ya visto timestamp? ║
                        ╚═════════╤════════════╝
                                  │
                        ┌─────────┴─────────┐
                        │                   │
                       SÍ                  NO
                        │                   │
                        ▼                   ▼
                 ┌─────────┐      ┌──────────────────┐
                 │ Marcar  │      │ Agregar a        │
                 │ como    │      │ seenTimestamps   │
                 │duplicado│      └──────────────────┘
                 └─────────┘
                      │
                      ▼
            ╔════════════════╗
            ║ ¿Es duplicado? ║
            ╚═════╤══════════╝
                  │
          ┌───────┴───────┐
         SÍ              NO
          │               │
          ▼               ▼
┌───────────────────┐  ┌─────────┐
│ tasksToDelete.add │  │Continue │
│ (task.key)        │  │next task│
└───────────────────┘  └─────────┘
          │
          ▼
┌───────────────────────────┐
│ Eliminar todos los keys   │
│ en tasksToDelete          │
└───────────────┬───────────┘
                │
                ▼
    ┌────────────────────────────┐
    │ Mismo proceso para Notes   │
    └────────────────────────────┘
```

## Flujo 7: Deduplicación en UI (Filtro Final)

```
┌──────────────────────────────────────────────────────────────┐
│    TaskProvider._deduplicateTasks(tasks)                      │
│    (llamado al recibir stream de Hive)                        │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ Inicializar Sets:            │
              │ - seenFirestoreIds           │
              │ - seenHiveKeys               │
              │ - seenTimestamps             │
              │ - unique (resultado)         │
              └──────────┬───────────────────┘
                         │
                         ▼
              ┌──────────────────────────────┐
              │ Para cada task en tasks:     │
              └──────────┬───────────────────┘
                         │
                         ▼
              ╔═════════════════════════╗
              ║ ¿firestoreId no vacío?  ║
              ╚═══════════╤═════════════╝
                          │
                ┌─────────┴─────────┐
                │                   │
               SÍ                  NO
                │                   │
                ▼                   │
    ╔═══════════════════════╗       │
    ║ ¿Ya visto?            ║       │
    ╚═══════╤═══════════════╝       │
            │                       │
    ┌───────┴───────┐               │
   SÍ              NO               │
    │               │               │
    ▼               ▼               │
┌─────────┐  ┌──────────────┐      │
│isDupli- │  │ Agregar a    │      │
│cate=true│  │ seenIds      │      │
└─────────┘  └──────────────┘      │
    │                              │
    └──────────────────────────────┤
                                   ▼
                        ╔══════════════════╗
                        ║ ¿key != null?    ║
                        ╚═════════╤════════╝
                                  │
                        ┌─────────┴─────────┐
                        │                   │
                       SÍ                  NO
                        │                   │
                        ▼                   │
            ╔═══════════════════╗           │
            ║ ¿Ya visto key?    ║           │
            ╚═════════╤═════════╝           │
                      │                     │
            ┌─────────┴─────────┐           │
           SÍ                  NO           │
            │                   │           │
            ▼                   ▼           │
    ┌──────────┐     ┌──────────────┐      │
    │isDupli-  │     │ Agregar a    │      │
    │cate=true │     │ seenKeys     │      │
    └──────────┘     └──────────────┘      │
         │                                  │
         └──────────────────────────────────┤
                                            ▼
                                 ╔══════════════════╗
                                 ║ ¿Ya visto        ║
                                 ║ timestamp?       ║
                                 ╚═════════╤════════╝
                                           │
                                 ┌─────────┴─────────┐
                                 │                   │
                                SÍ                  NO
                                 │                   │
                                 ▼                   ▼
                         ┌──────────┐      ┌──────────────┐
                         │isDupli-  │      │ Agregar a    │
                         │cate=true │      │ seenTimes    │
                         └──────────┘      └──────────────┘
                              │
                              ▼
                    ╔═════════════════╗
                    ║ ¿isDuplicate?   ║
                    ╚═════════╤═══════╝
                              │
                    ┌─────────┴─────────┐
                   NO                  SÍ
                    │                   │
                    ▼                   ▼
          ┌─────────────────┐    ┌──────────┐
          │ unique.add(task)│    │ Descartar│
          └─────────────────┘    └──────────┘
                    │
                    ▼
          ┌─────────────────┐
          │ return unique   │
          └─────────────────┘
```

## Resumen de Protecciones por Capa

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PROTECCIÓN                        │
├─────────────────────────────────────────────────────────────┤
│ 1. MIGRACIÓN (al inicio)                                     │
│    _cleanupDuplicates() → Elimina duplicados existentes     │
├─────────────────────────────────────────────────────────────┤
│ 2. DATABASE SERVICE (al guardar)                             │
│    saveTaskLocally() → Busca existing antes de add           │
│    _findExistingTask() → Triple verificación                 │
├─────────────────────────────────────────────────────────────┤
│ 3. SINCRONIZACIÓN (al descargar)                             │
│    syncFromCloud() → Busca por firestoreId antes de add      │
│    Compara timestamps para conflictos                        │
├─────────────────────────────────────────────────────────────┤
│ 4. PROVIDER (al actualizar)                                  │
│    updateTask() → Busca original antes de crear              │
│    toggleTask() → Usa updateInPlace                          │
├─────────────────────────────────────────────────────────────┤
│ 5. UI STREAM (antes de mostrar)                              │
│    _deduplicateTasks() → Filtro final por 3 identidades     │
└─────────────────────────────────────────────────────────────┘
```

## Casos de Uso con Resolución

### Caso 1: Usuario Crea Tarea Offline
```
[Usuario] → [addTask] → [saveTaskLocally]
                             ↓
                    _findExistingTask
                             ↓
                    No encontrado → box.add() ✅
                             ↓
                    firestoreId = ''
                             ↓
              [Cuando vuelva online]
                             ↓
              syncToCloud → asigna firestoreId
```

### Caso 2: Sincronización Después de Offline
```
[App Online] → [syncFromCloud]
                      ↓
    Para cada tarea en Firebase:
                      ↓
    ¿existingTask con ese firestoreId?
                      ↓
        SÍ → updateInPlace ✅ (no duplica)
        NO → box.add() ✅ (nueva de otro dispositivo)
```

### Caso 3: Edición con copyWith (AI Agent)
```
[AI Agent] → task.copyWith(title: 'New')
                      ↓
           (pierde Hive key)
                      ↓
         [updateTask(copiedTask)]
                      ↓
      _findExistingTask por createdAt
                      ↓
        original.updateInPlace() ✅
                      ↓
              No duplica
```

### Caso 4: Dos Dispositivos del Mismo Usuario
```
[Dispositivo A] → Crea tarea → Firebase
                                   ↓
                          firestoreId: 'abc123'
                                   ↓
[Dispositivo B] → syncFromCloud
                       ↓
    ¿Existe local con firestoreId='abc123'?
                       ↓
        NO → box.add() ✅ (primera vez)
                       ↓
    [B edita tarea] → Firebase actualiza
                       ↓
[Dispositivo A] → syncFromCloud
                       ↓
    ¿Existe local con firestoreId='abc123'?
                       ↓
        SÍ → ¿Cloud más nuevo?
                       ↓
              SÍ → updateInPlace() ✅
                       ↓
                  No duplica
```

---

**Nota**: Todos los flujos están verificados en el código actual y funcionan correctamente.
