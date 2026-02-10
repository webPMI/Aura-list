# Guia Rapida - Sistema de Autenticacion AuraList

## Inicio Rapido para Desarrolladores

### Ver el Sistema en Accion

1. **Resetear el estado de bienvenida** (para ver la WelcomeScreen):
   ```dart
   // En cualquier parte del codigo donde tengas acceso a ref:
   await ref.read(onboardingServiceProvider).resetWelcome();
   // Luego reinicia la app
   ```

2. **Ejecutar la app**:
   ```bash
   flutter run
   ```

3. **Ver las pantallas**:
   - Primera vez: Veras WelcomeScreen
   - Siguiente vez: Veras MainScaffold directamente

### Flujo de Prueba Completo

#### 1. WelcomeScreen (Primera Vez)
```
App Launch → WelcomeScreen
- Click "Crear cuenta" → RegisterScreen
- Click "Ya tengo cuenta" → LoginScreen
- Click "Continuar sin cuenta" → MainScaffold (anonimo)
```

#### 2. RegisterScreen
```
Completar formulario:
- Email: test@ejemplo.com
- Contrasena: Password123
- Confirmar: Password123
- ✓ Aceptar terminos

Click "Crear cuenta" → MainScaffold (autenticado)
```

#### 3. LoginScreen
```
Ingresar credenciales:
- Email: test@ejemplo.com
- Contrasena: Password123

Click "Iniciar sesion" → MainScaffold (autenticado)
```

#### 4. Vincular Cuenta Anonima
```
MainScaffold → Drawer → Perfil → "Vincular cuenta"
→ LinkAccountDialog
  - Opcion 1: Email/Password
  - Opcion 2: Google
```

#### 5. Recuperar Contrasena
```
LoginScreen → "Olvidaste tu contrasena?"
→ ForgotPasswordDialog
  - Ingresar email
  - Click "Enviar"
  - Verificar bandeja de entrada
```

## Uso Programatico

### Navegar a Login
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const LoginScreen(),
  ),
);
```

### Navegar a Registro
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const RegisterScreen(),
  ),
);
```

### Mostrar Dialogo de Recuperacion
```dart
import '../widgets/dialogs/forgot_password_dialog.dart';

await showForgotPasswordDialog(
  context: context,
  ref: ref,
);
```

### Mostrar Dialogo de Vincular Cuenta
```dart
import '../widgets/dialogs/link_account_dialog.dart';

await showLinkAccountDialog(
  context: context,
  ref: ref,
);
```

### Verificar Estado de Autenticacion
```dart
// Obtener usuario actual
final authService = ref.read(authServiceProvider);
final user = authService.currentUser;

if (user != null) {
  if (user.isAnonymous) {
    print('Usuario anonimo: ${user.uid}');
  } else {
    print('Usuario autenticado: ${user.email}');
  }
} else {
  print('Sin usuario');
}

// Verificar si cuenta esta vinculada
final isLinked = ref.read(isLinkedAccountProvider);
print('Cuenta vinculada: $isLinked');

// Obtener email vinculado
final email = authService.linkedEmail;
print('Email: $email');

// Obtener proveedor vinculado
final provider = authService.linkedProvider; // 'email' o 'google'
print('Proveedor: $provider');
```

### Operaciones de Autenticacion
```dart
final authService = ref.read(authServiceProvider);

// Login con email/password
final result = await authService.signInWithEmailPassword(
  'test@ejemplo.com',
  'Password123',
);
if (result != null) {
  print('Login exitoso: ${result.user?.email}');
}

// Login con Google
final googleResult = await authService.signInWithGoogle();
if (googleResult != null) {
  print('Login con Google exitoso');
}

// Vincular cuenta anonima con email
final linkResult = await authService.linkWithEmailPassword(
  'test@ejemplo.com',
  'Password123',
);
if (linkResult != null) {
  print('Cuenta vinculada exitosamente');
}

// Vincular cuenta anonima con Google
final (:credential, :error) = await authService.linkWithGoogle();
if (credential != null) {
  print('Vinculado con Google exitosamente');
} else if (error != null) {
  print('Error: $error');
}

// Enviar email de recuperacion
final success = await authService.sendPasswordResetEmail(
  'test@ejemplo.com',
);
if (success) {
  print('Email de recuperacion enviado');
}

// Cerrar sesion
await authService.signOut();
```

## Personalizacion

### Cambiar Colores
Los colores se toman del tema de la app. Para cambiar:

```dart
// En main.dart
theme: ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4), // Cambiar este color
    brightness: Brightness.light,
  ),
),
```

### Modificar Validacion de Contrasena
En `lib/screens/register_screen.dart` y `lib/widgets/dialogs/link_account_dialog.dart`:

```dart
String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contrasena es obligatoria';
  }
  if (value.length < 8) { // Cambiar minimo
    return 'Minimo 8 caracteres';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Debe tener al menos una mayuscula';
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Debe tener al menos un numero';
  }
  // Agregar validacion de caracteres especiales
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    return 'Debe tener al menos un caracter especial';
  }
  return null;
}
```

### Personalizar WelcomeScreen
En `lib/screens/welcome_screen.dart`, modifica las caracteristicas mostradas:

```dart
_FeatureItem(
  icon: Icons.tu_icono,
  title: 'Tu titulo',
  description: 'Tu descripcion',
  colorScheme: colorScheme,
),
```

### Desactivar WelcomeScreen
Si no quieres mostrar la pantalla de bienvenida, en `lib/main.dart`:

```dart
// Cambiar esto:
home: const AppRouter(),

// Por esto:
home: const MainScaffold(),
```

## Debugging

### Ver Logs de Autenticacion
```dart
// Los servicios ya tienen debug prints
// Solo ejecuta con:
flutter run --verbose
```

### Resetear Estado de Onboarding
```dart
// Para testing, agrega un boton temporal:
ElevatedButton(
  onPressed: () async {
    await ref.read(onboardingServiceProvider).resetWelcome();
    // Reinicia la app manualmente
  },
  child: Text('Reset Onboarding'),
)
```

### Verificar Firebase
```dart
final authService = ref.read(authServiceProvider);
print('Firebase disponible: ${authService.isFirebaseAvailable}');

if (!authService.isFirebaseAvailable) {
  print('Firebase no esta configurado - app en modo local');
}
```

## Errores Comunes

### "Firebase not available"
**Problema**: Firebase no esta inicializado
**Solucion**: Verifica que `google-services.json` (Android) o `GoogleService-Info.plist` (iOS) esten en sus lugares correctos

### "Email already in use"
**Problema**: El email ya esta registrado
**Solucion**: Usa otro email o inicia sesion con ese email

### "Weak password"
**Problema**: La contrasena no cumple requisitos de Firebase
**Solucion**: Asegurate de cumplir todos los requisitos de validacion

### Validacion no se actualiza
**Problema**: PasswordStrengthIndicator no se actualiza
**Solucion**: Asegurate de tener `onChanged: (_) => setState(() {})` en el TextField

## Testing

### Unit Tests
```dart
// Test de validacion de email
test('Email validation', () {
  expect(validateEmail('test@test.com'), null);
  expect(validateEmail('invalid'), isNotNull);
});

// Test de validacion de contrasena
test('Password validation', () {
  expect(validatePassword('Pass123'), null);
  expect(validatePassword('pass'), isNotNull);
});
```

### Widget Tests
```dart
testWidgets('LoginScreen displays', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: LoginScreen(),
      ),
    ),
  );

  expect(find.text('AuraList'), findsOneWidget);
  expect(find.byType(TextFormField), findsNWidgets(2));
});
```

### Integration Tests
```dart
testWidgets('Complete login flow', (tester) async {
  // 1. Pump app
  await tester.pumpWidget(MyApp());

  // 2. Wait for welcome screen
  await tester.pumpAndSettle();

  // 3. Click "Ya tengo cuenta"
  await tester.tap(find.text('Ya tengo cuenta'));
  await tester.pumpAndSettle();

  // 4. Enter credentials
  await tester.enterText(
    find.byType(TextFormField).first,
    'test@test.com',
  );
  await tester.enterText(
    find.byType(TextFormField).last,
    'Password123',
  );

  // 5. Submit
  await tester.tap(find.text('Iniciar sesion'));
  await tester.pumpAndSettle();

  // 6. Verify navigation
  expect(find.byType(MainScaffold), findsOneWidget);
});
```

## Recursos Adicionales

- **Documentacion completa**: Ver `AUTHENTICATION_GUIDE.md`
- **Resumen de cambios**: Ver `AUTHENTICATION_IMPROVEMENTS_SUMMARY.md`
- **Firebase Auth Docs**: https://firebase.google.com/docs/auth
- **Riverpod Docs**: https://riverpod.dev/docs/introduction

## Soporte

Si encuentras problemas:
1. Revisa los logs de Flutter
2. Verifica la configuracion de Firebase
3. Consulta la documentacion
4. Contacto: servicioweb.pmi@gmail.com
