# Plan de Refactorizacion: DatabaseService

## Resumen Ejecutivo

El archivo `database_service.dart` tiene **3708 lineas** con **12 responsabilidades distintas** y mas de **80 metodos**. El analisis de 6 agentes identifico:

- ~1185 lineas de codigo duplicado (32%)
- 78 bloques try-catch, solo 47 con stack trace
- 15+ casos de error swallowing
- Race conditions en sync debouncing
- Backoff inconsistente (lineal vs exponencial)
- 8 cajas Hive con patrones de acceso inconsistentes

---

## Fase 1: Infraestructura Base (Interfaces)

### 1.1 Crear directorio de contratos
```
lib/services/contracts/
  ├── i_local_storage.dart      # Interface para almacenamiento local
  ├── i_cloud_storage.dart      # Interface para almacenamiento en nube
  ├── i_sync_service.dart       # Interface para sincronizacion
  └── i_repository.dart         # Interface base para repositorios
```

### 1.2 Archivos a crear

**`lib/services/contracts/i_local_storage.dart`**
```dart
abstract class ILocalStorage<T> {
  Future<void> init();
  Future<T?> get(dynamic key);
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> delete(dynamic key);
  Stream<List<T>> watch();
  Future<void> clear();
}
```

**`lib/services/contracts/i_cloud_storage.dart`**
```dart
abstract class ICloudStorage<T> {
  Future<String> create(T item, String userId);
  Future<void> update(String id, T item, String userId);
  Future<void> delete(String id, String userId);
  Future<T?> get(String id, String userId);
  Future<List<T>> getAll(String userId, {DateTime? since});
}
```

**`lib/services/contracts/i_sync_service.dart`**
```dart
abstract class ISyncService<T> {
  Future<void> syncToCloud(T item, String userId);
  Future<void> syncFromCloud(String userId, {DateTime? since});
  Future<void> addToQueue(T item, String userId);
  Future<void> processQueue();
  Future<int> getPendingCount();
}
```

---

## Fase 2: Capa de Almacenamiento

### 2.1 Estructura de directorios
```
lib/services/storage/
  ├── local/
  │   ├── hive_task_storage.dart
  │   ├── hive_note_storage.dart
  │   ├── hive_notebook_storage.dart
  │   └── hive_preferences_storage.dart
  └── cloud/
      ├── firestore_task_storage.dart
      ├── firestore_note_storage.dart
      └── firestore_notebook_storage.dart
```

### 2.2 Implementacion ejemplo: HiveTaskStorage

```dart
// lib/services/storage/local/hive_task_storage.dart
class HiveTaskStorage implements ILocalStorage<Task> {
  final ErrorHandler _errorHandler;
  Box<Task>? _box;
  static const String _boxName = 'tasks';

  HiveTaskStorage(this._errorHandler);

  @override
  Future<void> init() async {
    _box = Hive.isBoxOpen(_boxName)
        ? Hive.box<Task>(_boxName)
        : await Hive.openBox<Task>(_boxName);
  }

  @override
  Future<List<Task>> getAll() async {
    return _box!.values.where((t) => !t.deleted).toList();
  }

  @override
  Stream<List<Task>> watch() async* {
    yield await getAll();
    await for (final _ in _box!.watch()) {
      yield await getAll();
    }
  }

  // ... resto de metodos
}
```

---

## Fase 3: Capa de Sincronizacion

### 3.1 Estructura
```
lib/services/sync/
  ├── sync_queue.dart           # Cola unificada con dead-letter
  ├── task_sync_service.dart    # Sync de tareas
  ├── note_sync_service.dart    # Sync de notas
  ├── notebook_sync_service.dart# Sync de notebooks
  └── sync_utils.dart           # Utilidades compartidas
```

### 3.2 Metodos genericos para reducir duplicacion

**Patron actual (repetido 3 veces):**
```dart
Future<void> _processSyncQueue() async { ... 120 lineas }
Future<void> _processNotesSyncQueue() async { ... 120 lineas }
Future<void> _processNotebooksSyncQueue() async { ... 120 lineas }
```

**Propuesta (1 metodo generico):**
```dart
// lib/services/sync/sync_queue.dart
class SyncQueue<T> {
  final Box<Map> _queueBox;
  final Future<void> Function(T, String) _syncFn;
  final T? Function(dynamic) _findLocalFn;

  Future<void> processQueue({
    int maxRetries = 3,
    Duration initialBackoff = const Duration(seconds: 2),
    int maxAgeDays = 7,
  }) async {
    // Implementacion unificada ~120 lineas
    // Reemplaza 360 lineas duplicadas
  }
}
```

---

## Fase 4: Capa de Repositorios

### 4.1 Estructura
```
lib/services/repositories/
  ├── task_repository.dart
  ├── note_repository.dart
  ├── notebook_repository.dart
  └── preferences_repository.dart
```

### 4.2 Implementacion ejemplo: TaskRepository

```dart
// lib/services/repositories/task_repository.dart
class TaskRepository {
  final ILocalStorage<Task> _localStorage;
  final ICloudStorage<Task> _cloudStorage;
  final ISyncService<Task> _syncService;
  final ErrorHandler _errorHandler;

  TaskRepository({
    required ILocalStorage<Task> localStorage,
    required ICloudStorage<Task> cloudStorage,
    required ISyncService<Task> syncService,
    required ErrorHandler errorHandler,
  }) : _localStorage = localStorage,
       _cloudStorage = cloudStorage,
       _syncService = syncService,
       _errorHandler = errorHandler;

  /// Guardar tarea (local + sync)
  Future<void> save(Task task, String userId) async {
    await _localStorage.save(task);
    await _syncService.syncToCloud(task, userId);
  }

  /// Obtener tareas por tipo
  Future<List<Task>> getByType(String type) async {
    final tasks = await _localStorage.getAll();
    return tasks.where((t) => t.type == type).toList();
  }

  /// Stream de tareas
  Stream<List<Task>> watchByType(String type) {
    return _localStorage.watch().map(
      (tasks) => tasks.where((t) => t.type == type).toList()
    );
  }
}
```

---

## Fase 5: Correccion de Bugs Criticos

### 5.1 Race condition en debounce sync

**Problema actual:**
```dart
_pendingSyncUserId = userId;  // Puede cambiar durante debounce
_syncDebounceTimer = Timer(_syncDebounceDelay, () {
  _flushPendingSyncs();  // Usa _pendingSyncUserId global
});
```

**Solucion:**
```dart
// Capturar userId por item
class PendingSyncItem {
  final dynamic key;
  final String userId;
  final DateTime timestamp;
}

final Set<PendingSyncItem> _pendingSyncs = {};

Future<void> syncTaskToCloudDebounced(Task task, String userId) async {
  _pendingSyncs.add(PendingSyncItem(
    key: task.key,
    userId: userId,  // Capturado al momento de agregar
    timestamp: DateTime.now(),
  ));
  // ...
}
```

### 5.2 Backoff inconsistente

**Problema:** Lineal en algunos lugares, exponencial en otros.

**Solucion unificada:**
```dart
// lib/services/sync/sync_utils.dart
Duration calculateBackoff(int retryCount, {
  Duration initial = const Duration(seconds: 2),
  double multiplier = 2.0,
  Duration maximum = const Duration(minutes: 5),
}) {
  final delay = initial * pow(multiplier, retryCount);
  return delay > maximum ? maximum : delay;
}
```

### 5.3 Dead-letter queue para items fallidos

**Problema:** Items que fallan 3 veces se eliminan silenciosamente.

**Solucion:**
```dart
// Agregar box para dead-letter
static const String _deadLetterBoxName = 'dead_letter_queue';
Box<Map>? _deadLetterBox;

// Mover a dead-letter en lugar de eliminar
if (retryCount >= maxRetries) {
  await _moveToDeadLetter(entry);
  keysToRemove.add(entry.key);
}
```

### 5.4 Error handling consistente

**Patron actual (inconsistente):**
```dart
// Algunos con stack trace
_errorHandler.handle(e, stackTrace: stack);

// Otros sin stack trace
_errorHandler.handle(e);

// Otros ignorados silenciosamente
catch (e) { /* nada */ }
```

**Solucion - wrapper unificado:**
```dart
// lib/services/sync/sync_utils.dart
Future<T> withErrorHandling<T>(
  Future<T> Function() operation, {
  required ErrorHandler errorHandler,
  required ErrorType type,
  required String operation,
  T? fallbackValue,
}) async {
  try {
    return await operation();
  } catch (e, stack) {
    errorHandler.handle(
      e,
      type: type,
      severity: ErrorSeverity.error,
      message: 'Error en $operation',
      stackTrace: stack,
    );
    if (fallbackValue != null) return fallbackValue;
    rethrow;
  }
}
```

---

## Fase 6: Migracion Gradual

### 6.1 Estrategia de facade

Mantener `DatabaseService` como facade durante la transicion:

```dart
// lib/services/database_service.dart (reducido)
class DatabaseService {
  final TaskRepository _taskRepo;
  final NoteRepository _noteRepo;
  final NotebookRepository _notebookRepo;
  final PreferencesRepository _prefsRepo;

  // Delegacion a repositorios
  Future<List<Task>> getLocalTasks(String type) =>
      _taskRepo.getByType(type);

  Future<void> saveTaskLocally(Task task) =>
      _taskRepo.saveLocal(task);

  // ... resto de metodos delegando
}
```

### 6.2 Orden de migracion recomendado

1. **Semana 1**: Crear interfaces y estructura de directorios
2. **Semana 2**: Implementar HiveTaskStorage + FirestoreTaskStorage
3. **Semana 3**: Implementar TaskSyncService con cola generica
4. **Semana 4**: Crear TaskRepository, migrar metodos de tareas
5. **Semana 5**: Repetir para Notes
6. **Semana 6**: Repetir para Notebooks
7. **Semana 7**: Migrar Preferences + History
8. **Semana 8**: Eliminar codigo deprecado de DatabaseService

---

## Fase 7: Actualizacion de Providers

### 7.1 Nuevos providers

```dart
// lib/providers/storage_providers.dart
final hiveTaskStorageProvider = Provider<HiveTaskStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return HiveTaskStorage(errorHandler);
});

final firestoreTaskStorageProvider = Provider<FirestoreTaskStorage>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return FirestoreTaskStorage(errorHandler);
});

// lib/providers/repository_providers.dart
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    localStorage: ref.watch(hiveTaskStorageProvider),
    cloudStorage: ref.watch(firestoreTaskStorageProvider),
    syncService: ref.watch(taskSyncServiceProvider),
    errorHandler: ref.watch(errorHandlerProvider),
  );
});
```

---

## Metricas de Exito

| Metrica | Actual | Objetivo |
|---------|--------|----------|
| Lineas en database_service.dart | 3708 | <500 (facade) |
| Codigo duplicado | ~1185 lineas | <100 lineas |
| try-catch sin stack trace | 31 | 0 |
| Casos de error swallowing | 15+ | 0 |
| Archivos de servicio | 1 | ~15 |
| Test coverage | ? | >80% |

---

## Archivos Finales Propuestos

```
lib/services/
├── contracts/
│   ├── i_local_storage.dart
│   ├── i_cloud_storage.dart
│   ├── i_sync_service.dart
│   └── i_repository.dart
├── storage/
│   ├── local/
│   │   ├── hive_task_storage.dart
│   │   ├── hive_note_storage.dart
│   │   ├── hive_notebook_storage.dart
│   │   ├── hive_history_storage.dart
│   │   └── hive_preferences_storage.dart
│   └── cloud/
│       ├── firestore_task_storage.dart
│       ├── firestore_note_storage.dart
│       ├── firestore_notebook_storage.dart
│       └── firestore_preferences_storage.dart
├── sync/
│   ├── sync_queue.dart
│   ├── dead_letter_queue.dart
│   ├── task_sync_service.dart
│   ├── note_sync_service.dart
│   ├── notebook_sync_service.dart
│   └── sync_utils.dart
├── repositories/
│   ├── task_repository.dart
│   ├── note_repository.dart
│   ├── notebook_repository.dart
│   ├── history_repository.dart
│   └── preferences_repository.dart
├── database_service.dart          # Facade simplificado (~500 lineas)
├── sync_orchestrator.dart         # Ya existe
├── sync_watcher_service.dart      # Ya existe
└── app_bootstrap.dart             # Ya existe
```

---

## Notas de Implementacion

1. **No romper funcionalidad existente**: La facade mantiene la API actual
2. **Tests primero**: Escribir tests para cada modulo nuevo antes de migrar
3. **Feature flags**: Usar flags para alternar entre implementacion vieja y nueva
4. **Rollback plan**: Mantener codigo viejo comentado hasta validar produccion
5. **Documentacion**: Actualizar CLAUDE.md con nueva arquitectura

---

## Proximos Pasos Inmediatos

1. [ ] Crear directorio `lib/services/contracts/`
2. [ ] Implementar interfaces base
3. [ ] Crear `HiveTaskStorage` como primer modulo
4. [ ] Crear tests unitarios para `HiveTaskStorage`
5. [ ] Implementar `SyncQueue` generico
6. [ ] Migrar `_processSyncQueue()` a usar `SyncQueue`

---

*Plan creado: 2026-02-12*
*Basado en analisis de 6 agentes Sonnet*
