# Sistema de Autenticacion - AuraList

## Resumen

El sistema de autenticacion de AuraList ha sido completamente renovado con formularios modernos, validacion robusta y una experiencia de usuario mejorada. La app ahora ofrece multiples opciones de autenticacion manteniendo la funcionalidad offline-first.

## Pantallas de Autenticacion

### 1. **WelcomeScreen** (`lib/screens/welcome_screen.dart`)
Pantalla inicial que se muestra en el primer uso de la app.

**Caracteristicas:**
- Presentacion visual atractiva de la app
- Tres opciones principales:
  - Crear cuenta nueva
  - Iniciar sesion con cuenta existente
  - Continuar sin cuenta (modo anonimo)
- Lista de caracteristicas clave de la app
- Se muestra solo una vez (usa SharedPreferences)

**Navegacion:**
- Primera vez: `WelcomeScreen` → Login/Register/MainScaffold
- Usos posteriores: Directamente a `MainScaffold`

### 2. **LoginScreen** (`lib/screens/login_screen.dart`)
Pantalla de inicio de sesion con email/password o Google.

**Caracteristicas:**
- Formulario de email y contrasena con validacion
- Toggle para mostrar/ocultar contrasena
- Boton "Olvidaste tu contrasena?" con dialogo de recuperacion
- Opcion de inicio de sesion con Google
- Link para registrarse
- Opcion para continuar sin cuenta
- Estados de carga con indicadores visuales
- Mensajes de error claros y en espanol

**Validacion:**
- Email: Formato valido de correo electronico
- Contrasena: Minimo 6 caracteres

### 3. **RegisterScreen** (`lib/screens/register_screen.dart`)
Pantalla de registro con validacion completa.

**Caracteristicas:**
- Formulario de registro con email, contrasena y confirmacion
- Validacion de contrasena robusta (mayusculas, numeros)
- Checkbox de aceptacion de terminos y condiciones
- Opcion de registro con Google
- Toggle para mostrar/ocultar contrasenas
- Estados de carga y mensajes de error
- Link para iniciar sesion si ya tiene cuenta

**Validacion:**
- Email: Formato valido
- Contrasena:
  - Minimo 6 caracteres
  - Al menos una letra mayuscula
  - Al menos un numero
- Confirmacion: Debe coincidir con la contrasena
- Terminos: Debe aceptar antes de registrarse

### 4. **ForgotPasswordDialog** (`lib/widgets/dialogs/forgot_password_dialog.dart`)
Dialogo modal para recuperacion de contrasena.

**Caracteristicas:**
- Formulario simple con campo de email
- Validacion de email
- Envia correo de recuperacion via Firebase Auth
- Mensajes de exito/error claros
- Cierra automaticamente despues de enviar

### 5. **LinkAccountDialog** (Mejorado - `lib/widgets/dialogs/link_account_dialog.dart`)
Dialogo para vincular cuenta anonima con email/password o Google.

**Mejoras implementadas:**
- Validacion de contrasena mejorada (mayusculas y numeros)
- Mensajes de ayuda para requisitos de contrasena
- Mejor manejo de errores de Google Sign-In
- Interfaz visual mejorada
- Estados de carga mas claros

## Flujos de Autenticacion

### Flujo 1: Primera vez (Usuario nuevo)
```
App Start → WelcomeScreen → (Elegir opcion)
  ├─> Crear cuenta → RegisterScreen → MainScaffold (autenticado)
  ├─> Ya tengo cuenta → LoginScreen → MainScaffold (autenticado)
  └─> Continuar sin cuenta → MainScaffold (anonimo)
```

### Flujo 2: Usuario recurrente
```
App Start → MainScaffold (sesion existente)
```

### Flujo 3: Vincular cuenta anonima
```
MainScaffold → ProfileScreen → "Vincular cuenta" → LinkAccountDialog
  ├─> Email/Password → Cuenta vinculada
  └─> Google → Cuenta vinculada
```

### Flujo 4: Recuperar contrasena
```
LoginScreen → "Olvidaste tu contrasena?" → ForgotPasswordDialog
→ Enviar email → Verificar bandeja → Restablecer contrasena
```

## Validacion de Formularios

### Validacion de Email
- Campo obligatorio
- Regex: `^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$`
- Mensaje de error: "Ingresa un correo electronico valido"

### Validacion de Contrasena
- Campo obligatorio
- Minimo 6 caracteres
- Al menos una letra mayuscula (A-Z)
- Al menos un numero (0-9)
- Mensajes especificos para cada requisito

### Validacion de Confirmacion de Contrasena
- Campo obligatorio
- Debe coincidir exactamente con la contrasena
- Mensaje: "Las contrasenas no coinciden"

## Estados de Carga

Todas las pantallas implementan estados de carga consistentes:
- Boton deshabilitado durante la operacion
- Indicador de progreso circular en el boton
- Texto del boton cambia (ej: "Iniciando sesion...")
- Campos de texto deshabilitados durante la carga

## Manejo de Errores

### Errores de Firebase Auth (Traducidos al espanol)
- `user-not-found`: "No existe una cuenta con este correo"
- `wrong-password`: "Contrasena incorrecta"
- `email-already-in-use`: "Este correo ya esta en uso"
- `weak-password`: "La contrasena es muy debil"
- `invalid-email`: "Correo electronico invalido"
- `user-disabled`: "Esta cuenta ha sido deshabilitada"
- Y mas...

### Errores de Google Sign-In
- Network error: "Sin conexion a internet"
- Configuration error: "Error de configuracion"
- Cancelled: No muestra error (usuario cancelo)

## Integracion con AuthService

El `AuthService` (`lib/services/auth_service.dart`) proporciona:

### Metodos de autenticacion:
- `signInAnonymously()`: Login anonimo
- `signInWithEmailPassword(email, password)`: Login con email
- `signInWithGoogle()`: Login con Google
- `linkWithEmailPassword(email, password)`: Vincular cuenta anonima
- `linkWithGoogle()`: Vincular con Google
- `sendPasswordResetEmail(email)`: Recuperar contrasena
- `signOut()`: Cerrar sesion
- `deleteAccount(dbService)`: Eliminar cuenta

### Properties utiles:
- `currentUser`: Usuario actual o null
- `isLinkedAccount`: true si no es anonimo
- `linkedEmail`: Email vinculado
- `linkedProvider`: "email" o "google"
- `isFirebaseAvailable`: true si Firebase esta configurado

## OnboardingService

Nuevo servicio para manejar el estado de primera vez:

```dart
final onboardingService = ref.read(onboardingServiceProvider);

// Verificar si ya vio la pantalla de bienvenida
final hasSeenWelcome = await onboardingService.hasSeenWelcome();

// Marcar como visto
await onboardingService.markWelcomeAsSeen();

// Resetear (util para testing)
await onboardingService.resetWelcome();
```

## Responsive Design

Todas las pantallas usan:
- `context.horizontalPadding` para padding adaptativo
- `Breakpoints.maxFormWidth` para ancho maximo de formularios
- `context.isMobile` para detectar dispositivos moviles
- ScrollView para contenido que puede ser largo

## Temas y Colores

Todas las pantallas respetan:
- Material 3 Design
- Modo claro y oscuro
- ColorScheme del tema
- Fuentes Google Fonts (Outfit)

## Accesibilidad

- Todos los campos tienen labels descriptivos
- Iconos con significado claro
- Textos de ayuda (helperText) para requisitos
- Mensajes de error en espanol claro
- Navegacion con teclado funcional
- TextInputAction apropiados (next, done)

## Testing

Para probar el flujo completo:

1. **Primera vez:**
   ```dart
   await ref.read(onboardingServiceProvider).resetWelcome();
   // Reiniciar app para ver WelcomeScreen
   ```

2. **Login:**
   - Email invalido: Debe mostrar error de validacion
   - Contrasena corta: Debe mostrar error
   - Credenciales incorrectas: Debe mostrar error de Firebase

3. **Registro:**
   - Todos los campos vacios: Validacion debe bloquear
   - Contrasena sin mayuscula/numero: Error especifico
   - Contrasenas no coinciden: Error claro
   - Sin aceptar terminos: No permite registro

4. **Recuperacion:**
   - Email invalido: Error de validacion
   - Email no registrado: Mensaje apropiado
   - Email valido: Exito y cierre de dialogo

## Proximas Mejoras Sugeridas

1. **Autenticacion biometrica**: Touch ID / Face ID
2. **Login social adicional**: Facebook, Apple
3. **Verificacion de email**: Enviar email de confirmacion
4. **Cambio de contrasena**: Desde perfil
5. **Autenticacion de dos factores**: 2FA opcional
6. **Recordar dispositivo**: Session persistente
7. **Login con numero de telefono**: SMS verification
8. **Mejoras de UI**: Animaciones entre pantallas

## Archivos Modificados/Creados

### Nuevos archivos:
- `lib/screens/login_screen.dart`
- `lib/screens/register_screen.dart`
- `lib/screens/welcome_screen.dart`
- `lib/screens/app_router.dart`
- `lib/widgets/dialogs/forgot_password_dialog.dart`
- `lib/services/onboarding_service.dart`

### Archivos modificados:
- `lib/main.dart` - Usa AppRouter en lugar de MainScaffold
- `lib/screens/profile_screen.dart` - Usa LinkAccountDialog mejorado
- `lib/widgets/dialogs/link_account_dialog.dart` - Validacion mejorada

## Dependencias Requeridas

Asegurate de tener estas dependencias en `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.x.x
  firebase_auth: ^4.x.x
  firebase_core: ^2.x.x
  shared_preferences: ^2.x.x
  google_fonts: ^6.x.x
```

## Comandos Utiles

```bash
# Analizar codigo
flutter analyze

# Ejecutar tests
flutter test

# Ejecutar app
flutter run

# Limpiar y rebuild
flutter clean && flutter pub get
```

## Soporte

Para problemas o preguntas sobre el sistema de autenticacion:
- Email: servicioweb.pmi@gmail.com
- Developer: ink.enzo
