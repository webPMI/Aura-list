# Firebase Firestore Synchronization - Fix Report

## Fecha: 2026-02-10

## Problema Identificado

La sincronización con Firebase Firestore no funcionaba debido a que **no se estaba inicializando la autenticación anónima al inicio de la aplicación**.

### Causa raíz:

1. **Autenticación no inicializada automáticamente**:
   - La autenticación anónima solo se inicializaba en `HomeScreen` (línea 38)
   - La aplicación inicia con `MainScaffold`, no con `HomeScreen`
   - Por lo tanto, cuando se creaban tareas, `currentUser` era `null`

2. **Sincronización silenciosa sin avisos**:
   - Los métodos de sincronización validaban `userId.isEmpty`
   - Cuando no había usuario, simplemente retornaban sin sincronizar
   - No había logs claros para diagnosticar el problema

## Solución Implementada

### 1. Inicialización automática de autenticación en `main.dart`

**Cambios realizados:**

```dart
// ANTES:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  await Hive.initFlutter();
  await initializeDateFormatting('es', null);
  runApp(const ProviderScope(child: ChecklistApp()));
}

class ChecklistApp extends ConsumerWidget {
  // No inicializaba autenticación
}

// DESPUÉS:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verificar si Firebase se inicializó correctamente
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(...);
    firebaseInitialized = true;
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
  }

  await Hive.initFlutter();
  await initializeDateFormatting('es', null);

  runApp(ProviderScope(
    child: ChecklistApp(firebaseInitialized: firebaseInitialized),
  ));
}

class ChecklistApp extends ConsumerStatefulWidget {
  final bool firebaseInitialized;

  const ChecklistApp({super.key, required this.firebaseInitialized});

  @override
  ConsumerState<ChecklistApp> createState() => _ChecklistAppState();
}

class _ChecklistAppState extends ConsumerState<ChecklistApp> {
  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeAuth();
      });
    }
  }

  Future<void> _initializeAuth() async {
    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        debugPrint('No hay usuario autenticado, iniciando sesión anónima...');
        await authService.signInAnonymously();
        debugPrint('Usuario anónimo creado correctamente');
      } else {
        debugPrint('Usuario ya autenticado: ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('Error al inicializar autenticación: $e');
    }
  }

  // ... resto del código
}
```

### 2. Mejoras en logging de sincronización en `database_service.dart`

Agregado logging detallado para diagnosticar problemas:

```dart
Future<void> syncTaskToCloud(Task task, String userId) async {
  if (!_firebaseAvailable || firestore == null) {
    debugPrint('⚠️ [SYNC] Firebase no disponible, tarea guardada solo localmente');
    return;
  }

  if (userId.isEmpty) {
    debugPrint('⚠️ [SYNC] Usuario no autenticado (userId vacío), tarea guardada solo localmente');
    return;
  }

  debugPrint('🔄 [SYNC] Iniciando sincronización de tarea "${task.title}" para usuario $userId');

  try {
    await _syncTaskWithRetry(task, userId);
  } catch (e, stack) {
    debugPrint('❌ [SYNC] Error al sincronizar tarea: $e');
    await _addToSyncQueue(task, userId);
  }
}
```

Similar logging agregado a:
- `syncTaskToCloudDebounced()`
- `_flushPendingSyncs()`

### 3. Logging en `task_provider.dart`

```dart
Future<void> addTask(...) async {
  try {
    final newTask = Task(...);

    debugPrint('➕ [TASK] Guardando tarea localmente: "$title"');
    await _db.saveTaskLocally(newTask);

    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('👤 [TASK] Usuario autenticado: ${user.uid}, sincronizando...');
      await _db.syncTaskToCloud(newTask, user.uid);
    } else {
      debugPrint('⚠️ [TASK] No hay usuario autenticado, tarea guardada solo localmente');
    }
  } catch (e, stack) {
    debugPrint('❌ [TASK] Error al agregar tarea: $e');
    rethrow;
  }
}
```

### 4. Actualización de test en `widget_test.dart`

```dart
// ANTES:
await tester.pumpWidget(const ProviderScope(child: ChecklistApp()));

// DESPUÉS:
await tester.pumpWidget(const ProviderScope(
  child: ChecklistApp(firebaseInitialized: false),
));
```

## Flujo de Sincronización Actualizado

### Al iniciar la app:

1. ✅ `main()` inicializa Firebase
2. ✅ `ChecklistApp` detecta Firebase inicializado
3. ✅ `_initializeAuth()` se ejecuta después del primer frame
4. ✅ Se crea usuario anónimo automáticamente si no existe
5. ✅ `authStateChanges` stream notifica a los providers

### Al crear una tarea:

1. ✅ Usuario escribe título y presiona "Agregar"
2. ✅ `TaskNotifier.addTask()` guarda localmente en Hive
3. ✅ `TaskNotifier.addTask()` verifica `currentUser` (ahora existe ✅)
4. ✅ `syncTaskToCloud()` envía a Firestore con `userId`
5. ✅ Tarea se guarda en `users/{userId}/tasks/{taskId}`

### Si falla la sincronización:

1. ❌ Error de red / timeout
2. ✅ Tarea se agrega a `sync_queue` en Hive
3. ✅ Se reintenta automáticamente al iniciar la app
4. ✅ Usuario puede forzar sincronización manualmente

## Verificación de la Solución

### Pasos para verificar:

1. Ejecutar la app: `flutter run`
2. Observar logs en consola:
   ```
   Firebase inicializado correctamente
   No hay usuario autenticado, iniciando sesión anónima...
   Usuario anónimo creado correctamente
   ```
3. Crear una tarea nueva
4. Observar logs de sincronización:
   ```
   ➕ [TASK] Guardando tarea localmente: "Mi tarea"
   👤 [TASK] Usuario autenticado: AbC123xyz, sincronizando...
   🔄 [SYNC] Iniciando sincronización de tarea "Mi tarea" para usuario AbC123xyz
   ✅ Tarea sincronizada con Firebase (nueva)
   ```
5. Verificar en Firebase Console:
   - Ir a Firestore
   - Buscar colección `users/{userId}/tasks`
   - Verificar que la tarea está presente

### Comandos útiles:

```bash
# Ver logs en tiempo real
flutter run --verbose

# Verificar análisis estático
flutter analyze

# Ejecutar tests
flutter test
```

## Archivos Modificados

1. ✅ `lib/main.dart` - Inicialización de autenticación automática
2. ✅ `lib/services/database_service.dart` - Logging mejorado
3. ✅ `lib/providers/task_provider.dart` - Logging de operaciones
4. ✅ `test/widget_test.dart` - Actualización de parámetro

## Problemas Solucionados

- ✅ Tareas no se sincronizaban a Firestore
- ✅ Usuario anónimo no se creaba automáticamente
- ✅ Sin logs de diagnóstico para debugging
- ✅ Sincronización silenciosa sin avisos

## Reglas de Firestore

Las reglas ya estaban correctas:

```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
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

## Notas Importantes

- La app sigue funcionando **offline-first**
- Si Firebase no está disponible, todo funciona localmente
- La sincronización es **asíncrona y transparente**
- Los errores se manejan con **reintentos automáticos**
- El usuario puede **forzar sincronización** desde el AppBar

## Próximos Pasos (Opcional)

1. Agregar indicador visual de estado de sincronización
2. Mostrar snackbar cuando se sincroniza exitosamente
3. Agregar página de configuración para ver estado de Firebase
4. Implementar sincronización bidireccional (pull de Firestore)

## Conclusión

La sincronización ahora funciona correctamente. El problema era simplemente que la autenticación anónima no se inicializaba al inicio, por lo que `currentUser` era `null` cuando se creaban tareas. Con la inicialización automática en `main.dart`, el usuario anónimo se crea inmediatamente al abrir la app, permitiendo que la sincronización funcione como se espera.
