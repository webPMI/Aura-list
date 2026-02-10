# Guía Rápida del Sistema de Autenticación

## Uso Básico

### 1. Login Anónimo Automático

```dart
// En cualquier screen o widget
final authService = ref.read(authServiceProvider);
if (authService.currentUser == null) {
  await authService.signInAnonymously();
}
```

### 2. Verificar Estado de Autenticación

```dart
// Escuchar cambios en tiempo real
final authState = ref.watch(authStateProvider);

authState.when(
  data: (user) {
    if (user == null) {
      // No hay usuario
    } else if (user.isAnonymous) {
      // Usuario anónimo
    } else {
      // Usuario con cuenta vinculada
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 3. Verificar si la Cuenta está Vinculada

```dart
final isLinked = ref.watch(isLinkedAccountProvider);

if (isLinked) {
  // Usuario tiene cuenta permanente
  final email = authService.linkedEmail;
  final provider = authService.linkedProvider; // 'email' o 'google'
} else {
  // Usuario anónimo
}
```

### 4. Vincular Cuenta Anónima con Email

```dart
final authService = ref.read(authServiceProvider);

final result = await authService.linkWithEmailPassword(
  'usuario@example.com',
  'password123',
);

if (result != null) {
  // Vinculación exitosa
  // Los datos locales se preservan automáticamente
} else {
  // Error - revisar logs
}
```

### 5. Vincular Cuenta Anónima con Google

```dart
final authService = ref.read(authServiceProvider);

final result = await authService.linkWithGoogle();

if (result != null) {
  // Vinculación exitosa con Google
  // Los datos locales se preservan automáticamente
} else {
  // Usuario canceló o error
}
```

### 6. Login Directo con Email (cuenta existente)

```dart
final authService = ref.read(authServiceProvider);

final result = await authService.signInWithEmailPassword(
  'usuario@example.com',
  'password123',
);

if (result != null) {
  // Login exitoso
} else {
  // Error - revisar logs
}
```

### 7. Login Directo con Google (cuenta existente)

```dart
final authService = ref.read(authServiceProvider);

final result = await authService.signInWithGoogle();

if (result != null) {
  // Login exitoso con Google
} else {
  // Usuario canceló o error
}
```

### 8. Cerrar Sesión

```dart
final authService = ref.read(authServiceProvider);

// Cerrar sesión simple (mantiene datos locales)
await authService.signOut();

// Cerrar sesión y limpiar todos los datos
await authService.signOut(
  clearCache: true,
  preservePreferences: true, // Mantiene tema, idioma, etc.
);

// O usar el método simplificado
await authService.signOutAndClear();
```

### 9. Recuperar Contraseña

```dart
final authService = ref.read(authServiceProvider);

final success = await authService.sendPasswordResetEmail(
  'usuario@example.com',
);

if (success) {
  // Email enviado
} else {
  // Error al enviar
}
```

### 10. Eliminar Cuenta Completamente

```dart
final authService = ref.read(authServiceProvider);
final dbService = ref.read(databaseServiceProvider);

final success = await authService.deleteAccount(dbService);

if (success) {
  // Cuenta eliminada
  // Datos de Firestore eliminados
  // Datos locales eliminados
  // Nueva sesión anónima iniciada
} else {
  // Error - puede requerir re-autenticación
}
```

## Manejo de Sesiones

### 11. Preparar Sesión para Usuario

```dart
final authService = ref.read(authServiceProvider);

// Después de login exitoso
await authService.prepareSession(user.uid);
```

### 12. Validar Cache de Usuario

```dart
final authService = ref.read(authServiceProvider);

final isValid = await authService.validateCacheForUser(user.uid);

if (!isValid) {
  // Cache pertenece a otro usuario
  await authService.clearCacheIfDifferentUser(user.uid);
}
```

### 13. Obtener Estadísticas de Cache

```dart
final authService = ref.read(authServiceProvider);

final stats = await authService.getCacheStats();
// stats contiene:
// - totalTasks
// - totalNotes
// - pendingSync
// - currentUserId
// - lastSession
```

### 14. Exportar Datos de Usuario (GDPR)

```dart
final authService = ref.read(authServiceProvider);

final export = await authService.exportUserData();

print('Usuario: ${export.userId}');
print('Tareas: ${export.taskCount}');
print('Notas: ${export.noteCount}');
print('Tamaño: ${export.readableSize}');

// export.data contiene todos los datos en JSON
```

## Escuchar Errores de Autenticación

### 15. Stream de Errores

```dart
// En initState o similar
ref.listen(errorStreamProvider, (previous, next) {
  next.when(
    data: (error) {
      if (error.type == ErrorType.auth) {
        // Mostrar snackbar o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.displayMessage)),
        );
      }
    },
    loading: () {},
    error: (error, stack) {},
  );
});
```

## Información del Usuario

### 16. Acceder a Información del Usuario Actual

```dart
final authService = ref.read(authServiceProvider);
final user = authService.currentUser;

if (user != null) {
  print('UID: ${user.uid}');
  print('Email: ${user.email}');
  print('Es anónimo: ${user.isAnonymous}');
  print('Proveedores: ${user.providerData.map((p) => p.providerId)}');
}
```

## Códigos de Error Comunes

### Firebase Auth Exceptions

- `email-already-in-use` - Email ya registrado
- `invalid-email` - Email inválido
- `weak-password` - Contraseña muy débil
- `credential-already-in-use` - Credencial ya en uso
- `user-not-found` - Usuario no existe
- `wrong-password` - Contraseña incorrecta
- `user-disabled` - Cuenta deshabilitada
- `requires-recent-login` - Requiere re-autenticación

El AuthService maneja automáticamente estos errores y proporciona mensajes amigables al usuario.

## Modo Offline

El sistema funciona completamente sin Firebase:
- Los métodos retornan `null` en lugar de lanzar excepciones
- Los datos se guardan localmente en Hive
- La sincronización ocurre automáticamente cuando Firebase está disponible

```dart
// Este código siempre funciona, con o sin Firebase
final authService = ref.read(authServiceProvider);
final user = authService.currentUser; // Puede ser null

if (user == null) {
  // No hay Firebase disponible o usuario no logueado
  // La app funciona en modo local
}
```

## Testing

Para tests unitarios, inicializar el binding:

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mi test', () {
    final container = ProviderContainer();
    final authService = container.read(authServiceProvider);

    // Los métodos retornan null sin Firebase
    expect(authService.currentUser, isNull);
  });
}
```

## Arquitectura

```
┌─────────────────────────────────────────────┐
│              UI Layer                       │
│  (ConsumerWidget con ref.watch/read)       │
└───────────────────┬─────────────────────────┘
                    │
                    │ Riverpod Providers
                    ↓
┌─────────────────────────────────────────────┐
│         AuthService Provider                │
│  - authServiceProvider                      │
│  - authStateProvider (Stream)               │
│  - isLinkedAccountProvider                  │
└───────────────────┬─────────────────────────┘
                    │
          ┌─────────┴──────────┐
          │                    │
          ↓                    ↓
┌──────────────────┐  ┌──────────────────┐
│  AuthService     │  │ GoogleSignIn     │
│  - Firebase Auth │  │ - OAuth Flow     │
│  - Session Cache │  │ - Credentials    │
└──────────────────┘  └──────────────────┘
          │
          ↓
┌──────────────────────────────────────────┐
│    SessionCacheManager                   │
│  - Cache validation                      │
│  - Data migration                        │
│  - GDPR export                           │
└──────────────────────────────────────────┘
          │
          ↓
┌──────────────────────────────────────────┐
│    Local Storage (Hive + SharedPrefs)    │
└──────────────────────────────────────────┘
```

## Configuración

### Verificar Firebase está inicializado

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
    debugPrint('La aplicación funcionará en modo local únicamente');
  }

  runApp(const ProviderScope(child: MyApp()));
}
```

---

Para más detalles, consulta `AUTH_SYSTEM_REPORT.md`
