import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';
import 'database_service.dart';
import 'google_sign_in_service.dart';
import 'session_cache_manager.dart';
import 'logger_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  final googleSignIn = ref.read(googleSignInServiceProvider);
  final sessionCache = ref.read(sessionCacheProvider);
  return AuthService(errorHandler, googleSignIn, sessionCache);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isLinkedAccountProvider = Provider.autoDispose<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLinkedAccount;
});

final authInitializationProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);

  try {
    await Future.delayed(const Duration(milliseconds: 200));
    authService.refreshFirebaseAvailability();

    if (!authService.isFirebaseAvailable) {
      LoggerService().info(
        'AuthInit',
        'Firebase Auth no disponible - app funcionara en modo local',
      );
      return;
    }

    if (authService.currentUser != null) {
      LoggerService().info(
        'AuthInit',
        'Usuario ya autenticado: ${authService.currentUser?.uid}',
      );
    } else {
      LoggerService().info(
        'AuthInit',
        'No hay usuario, la app funcionará en modo local.',
      );
    }
  } catch (e) {
    LoggerService().error(
      'AuthInit',
      'Error durante inicializacion de auth',
      error: e,
    );
    LoggerService().info('AuthInit', 'App funcionara en modo local');
  }
});

class AuthService {
  final ErrorHandler _errorHandler;
  final GoogleSignInService _googleSignIn;
  final SessionCacheManager _sessionCache;
  final _logger = LoggerService();
  FirebaseAuth? _auth;
  bool _firebaseAvailable = false;
  bool _initialized = false;
  String? _lastInitError;
  bool _disposed = false;

  AuthService(
    this._errorHandler,
    this._googleSignIn,
    this._sessionCache, {
    FirebaseAuth? auth,
  }) : _auth = auth;

  void _ensureFirebaseAvailable() {
    if (_initialized) return;

    try {
      // If _auth was injected (testing), use it
      if (_auth != null) {
        _firebaseAvailable = true;
        _initialized = true;
        return;
      }

      // Normal initialization
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      if (_firebaseAvailable) {
        _auth = FirebaseAuth.instance;
        _initialized = true;
        _lastInitError = null;
        _logger.info('AuthService', 'Firebase Auth inicializado correctamente');
      } else {
        _lastInitError = 'No hay apps de Firebase inicializadas';
      }
    } catch (e) {
      _firebaseAvailable = false;
      _lastInitError = e.toString();
      _logger.warning(
        'AuthService',
        'Firebase Auth no disponible',
        metadata: {'error': e.toString()},
      );
    }
  }

  /// Categoría de estado de inicialización
  Map<String, dynamic> getInitializationStatus() {
    _ensureFirebaseAvailable();
    return {
      'isInitialized': _initialized,
      'firebaseAvailable': _firebaseAvailable,
      'authAvailable': _auth != null,
      'lastError': _lastInitError,
      'activeApps': Firebase.apps.map((app) => app.name).toList(),
      'projectId': _firebaseAvailable ? Firebase.app().options.projectId : null,
      'isWeb': kIsWeb,
    };
  }

  void refreshFirebaseAvailability() {
    _initialized = false;
    _ensureFirebaseAvailable();
  }

  Stream<User?> get authStateChanges {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  User? get currentUser {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      return null;
    }
    return _auth!.currentUser;
  }

  bool get isFirebaseAvailable {
    _ensureFirebaseAvailable();
    return _firebaseAvailable;
  }

  /// Inicio de sesion anonimo (para usuarios que no quieren registrar cuenta todavia)
  ///
  /// Este método permite que usuarios que no desean crear una cuenta registrada
  /// puedan usar la app con un usuario anónimo de Firebase. Los datos se guardan
  /// localmente (Hive) y están disponibles sin conexión.
  ///
  /// Flujo de uso:
  /// 1. Se llama automáticamente desde main.dart:_initializeAuth() cuando no hay
  ///    usuario autenticado (primera vez o tras cerrar sesión).
  /// 2. El usuario anónimo puede después vincularse con email/password o Google
  ///    mediante linkWithEmailPassword() o linkWithGoogle().
  ///
  /// Importante: El usuario anónimo de Firebase NO es persistente entre dispositivos.
  /// Para tener sync entre dispositivos, el usuario debe vincularse con una cuenta
  /// registrada (email o Google).
  ///
  /// Retorna null si Firebase no está disponible (modo local sin Auth).
  Future<UserCredential?> signInAnonymously() async {
    _ensureFirebaseAvailable();

    if (!_firebaseAvailable || _auth == null) {
      _logger.info(
        'AuthService',
        'Firebase no configurado, omitiendo login anonimo',
      );
      return null;
    }

    try {
      final result = await _auth!.signInAnonymously();
      _logger.info(
        'AuthService',
        'Usuario anonimo creado: ${result.user?.uid}',
      );
      return result;
    } catch (e) {
      _logger.error(
        'AuthService',
        'Error al crear usuario anonimo',
        error: e,
      );
      return null;
    }
  }

  /// Cierra la sesion del usuario.
  ///
  /// [clearCache] - Si es true, limpia todos los datos locales
  /// [preservePreferences] - Si es true y clearCache es true, mantiene preferencias
  Future<void> signOut({
    bool clearCache = false,
    bool preservePreferences = true,
  }) async {
    try {
      // Limpiar cache si se solicita
      if (clearCache) {
        await _sessionCache.clearUserData(
          preservePreferences: preservePreferences,
        );
      }

      _ensureFirebaseAvailable();
      if (!_firebaseAvailable || _auth == null) {
        return;
      }

      // Also sign out from Google if linked
      await _googleSignIn.signOut();
      await _auth!.signOut();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al cerrar sesion',
        userMessage: 'No se pudo cerrar sesion',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Cierra sesion y limpia todos los datos del usuario.
  ///
  /// Util para cambiar de cuenta en el mismo dispositivo.
  Future<void> signOutAndClear() async {
    await signOut(clearCache: true, preservePreferences: true);
  }

  // ==================== ACCOUNT_LINKING ====================
  //
  // DESGLOSE DEL FLUJO DE AUTENTICACIÓN EN LA APP
  // =============================================
  //
  // Escenario A — Primera vez (sin sesión):
  //   1. main.dart:_initializeAuth() detecta currentUser == null
  //   2. Crea usuario anónimo via signInAnonymously()
  //   3. WelcomeScreen decide si mostrar (shouldShowWelcomeProvider)
  //   4. Usuario elige: registrar, login, o continuar anónimo
  //
  // Escenario B — Usuario existente con cuenta vinculada:
  //   1. main.dart:_initializeAuth() detecta currentUser != null
  //   2. Si isLinkedAccount, realiza sincronización inicial
  //   3. App abre directamente en MainScaffold
  //
  // Escenario C — Usuario anónimo que quiere vincularse:
  //   1. User anónimo activo (currentUser?.isAnonymous == true)
  //   2. UI muestra AuthActionSheet → AuthForm(mode: AuthMode.link)
  //   3. AuthForm llama a authManager.linkWithEmailPassword() o linkWithGoogle()
  //   4. AuthManager delega a AuthService.linkWith*()
  //   5. Si éxito → AuthService hace linkWithCredential / linkWithPopup
  //   6. AuthManager._enableSyncAfterAuth() activa sync
  //
  // Escenario D — Login directo con Google:
  //   1. currentUser == null (no hay sesión)
  //   2. UI llama a authenticateWithGoogle()
  //   3. authenticateWithGoogle() → signInWithGoogle() (logueo directo)
  //   4. Si éxito → sync automático
  //
  // Escenario E — Vincular cuenta anónima con email/password:
  //   1. currentUser?.isAnonymous == true
  //   2. AuthForm(mode: AuthMode.link) → authManager.linkWithEmailPassword()
  //   3. AuthManager → AuthService.linkWithEmailPassword(email, password)
  //   4. AuthService verifica: Firebase OK? usuario anónimo? credenciales válidas?
  //   5. Si éxito → (credential, null error). AuthManager activa sync.
  //
  // Códigos de error de FirebaseAuth a saber:
  //   - email-already-in-use: el email ya tiene cuenta con otro método
  //   - credential-already-in-use: esa credencial ya está vinculada a otro usuario
  //   - requires-recent-login: el usuario debe re-autenticarse antes (seguridad)
  //   - popup-closed-by-user: usuario cerró el popup de Google (no es error)
  //   - network-request-failed: problema de conexión (no es error de credenciales)
  //
  // NOTA SOBRE EL RETURN TYPE DE linkWith*():
  //   Antes: UserCredential? (null = error genérico, sin distinguir causa)
  //   Ahora: record con errorCode → permite mensajes de usuario específicos
  //   Esto es crítico para UX: el usuario necesita saber "email ya en uso"
  //   vs "credenciales incorrectas" vs "Firebase no disponible".

  /// Check if current user has linked their account (not anonymous)
  bool get isLinkedAccount {
    final user = currentUser;
    if (user == null) return false;
    return !user.isAnonymous;
  }

  /// Get linked email if available
  String? get linkedEmail {
    return currentUser?.email;
  }

  /// Get linked provider (password, google.com, etc.)
  String? get linkedProvider {
    final user = currentUser;
    if (user == null || user.isAnonymous) return null;

    for (final info in user.providerData) {
      if (info.providerId == 'password') return 'email';
      if (info.providerId == 'google.com') return 'google';
    }
    return null;
  }

  /// Link anonymous account with email and password
  /// Preserves all local data
  /// Returns a detailed result distinguishing failure causes
  ///
  /// Por qué un record en vez de UserCredential?:
  /// - errorCode permite al UI decidir qué mostrar sin adivinar
  /// - errorMessage es traducido al español con contexto específico
  /// - isCancelled distingue "usuario cerró popup" de "error real"
  ///
  /// Flujo:
  /// 1. Verificar Firebase disponible
  /// 2. Verificar existe usuario anónimo activo
  /// 3. Intentar linkWithCredential(email+password)
  /// 4. Si éxito: devolver credential + habilitar sync
  /// 5. Si FirebaseAuthException: mapear código → mensaje en español
  Future<({UserCredential? credential, String? errorMessage, bool isCancelled, String? errorCode})>
      linkWithEmailPassword(String email, String password) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      _errorHandler.handle(
        'Firebase no disponible',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Servicio no disponible',
      );
      return (
        credential: null,
        errorMessage: 'Firebase no disponible. Verifica tu conexión e inténtalo de nuevo.',
        isCancelled: false,
        errorCode: 'firebase_unavailable',
      );
    }

    final user = currentUser;
    if (user == null) {
      _errorHandler.handle(
        'No hay usuario activo',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Debes iniciar sesión primero',
      );
      return (
        credential: null,
        errorMessage: 'No hay sesión activa. Reinicia la app e intenta de nuevo.',
        isCancelled: false,
        errorCode: 'no_active_user',
      );
    }

    if (!user.isAnonymous) {
      _errorHandler.handle(
        'Usuario ya vinculado',
        type: ErrorType.auth,
        severity: ErrorSeverity.info,
        userMessage: 'Tu cuenta ya está vinculada',
      );
      return (
        credential: null,
        errorMessage: 'Tu cuenta ya está vinculada con otro método.',
        isCancelled: false,
        errorCode: 'already_linked',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final result = await user.linkWithCredential(credential);
      _logger.info(
        'AuthService',
        'Cuenta vinculada exitosamente con email: $email',
      );
      return (
        credential: result,
        errorMessage: null,
        isCancelled: false,
        errorCode: null,
      );
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = _getLinkErrorMessage(e.code);

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con email: ${e.code}',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return (
        credential: null,
        errorMessage: userMessage,
        isCancelled: false,
        errorCode: e.code,
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta',
        userMessage: 'Error inesperado al vincular la cuenta',
        stackTrace: stack,
      );
      return (
        credential: null,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
        isCancelled: false,
        errorCode: 'unknown',
      );
    }
  }

  /// Mensajes de error específicos para vinculación con email/password
  ///
  /// Cada código de FirebaseAuthException se mapea a un mensaje en español
  /// que es accionable para el usuario (no solo "error genérico").
  ///
  /// Diseño: centralizar los mensajes aquí evita código duplicado y hace
  /// fácil añadir nuevos códigos de error en el futuro sin revisar toda
  /// la función linkWithEmailPassword.
  String _getLinkErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está en uso por otra cuenta. Usa otro correo o inicia sesión con él.';
      case 'invalid-email':
        return 'Correo electrónico inválido. Verifica que esté bien escrito.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 6 caracteres, una mayúscula y un número.';
      case 'credential-already-in-use':
        return 'Este correo y contraseña ya están en uso. Inicia sesión directamente con esas credenciales.';
      case 'requires-recent-login':
        return 'Por seguridad, cierra sesión y vuelve a entrar antes de vincular tu cuenta.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet e inténtalo de nuevo.';
      case 'invalid-credential':
        return 'Credencial inválida. Verifica email y contraseña e inténtalo de nuevo.';
      default:
        return 'No se pudo vincular la cuenta (error: $code). Intenta de nuevo.';
    }
  }

  /// Link anonymous account with Google
  /// Preserves all local data
  /// Returns a record with UserCredential and optional error message
  ///
  /// Diferencias entre plataformas:
  /// - Web (kIsWeb=true): usa `user.linkWithPopup(googleProvider)` directamente
  ///   porque el paquete google_sign_in no provee idToken de forma confiable en web.
  /// - Mobile: usa el flujo completo de google_sign_in (signIn → authentication → credential).
  ///
  /// Casos manejados:
  /// - Usuario cancela el popup → (credential: null, error: null) [no es error]
  /// - Cuenta de Google ya vinculada a otro usuario → error específico
  /// - Credencial inválida → error específico
  /// - FirebaseAuthException genérica → mensaje default
  Future<({UserCredential? credential, String? error})> linkWithGoogle() async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      _errorHandler.handle(
        'Firebase no disponible',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Servicio no disponible',
      );
      return (
        credential: null,
        error: 'Servicio no disponible. Intenta mas tarde.',
      );
    }

    final user = currentUser;
    if (user == null) {
      _errorHandler.handle(
        'No hay usuario activo',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Debes iniciar sesion primero',
      );
      return (credential: null, error: 'Debes iniciar sesion primero');
    }

    if (!user.isAnonymous) {
      _errorHandler.handle(
        'Usuario ya vinculado',
        type: ErrorType.auth,
        severity: ErrorSeverity.info,
        userMessage: 'Tu cuenta ya esta vinculada',
      );
      return (credential: null, error: 'Tu cuenta ya esta vinculada');
    }

    try {
      UserCredential userCredential;

      // On web, use linkWithPopup directly (google_sign_in doesn't provide idToken reliably)
      if (kIsWeb) {
        _logger.info('AuthService', 'Usando linkWithPopup para web...');
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await user.linkWithPopup(googleProvider);
        _logger.info(
          'AuthService',
          'Cuenta vinculada exitosamente con Google (web): ${userCredential.user?.email}',
        );
        return (credential: userCredential, error: null);
      }

      // On mobile, use google_sign_in package
      final result = await _googleSignIn.getGoogleCredentialWithError();

      if (result.isCancelled) {
        _logger.info(
          'AuthService',
          'Usuario cancelo el inicio de sesion con Google',
        );
        return (credential: null, error: null); // No error, just cancelled
      }

      if (result.isError) {
        final errorMessage = _getGoogleErrorMessage(result.error!);
        _logger.error(
          'AuthService',
          'Error obteniendo credencial de Google',
          metadata: {'error': result.error.toString()},
        );
        return (credential: null, error: errorMessage);
      }

      if (result.credential == null) {
        return (
          credential: null,
          error: 'No se pudo obtener credencial de Google',
        );
      }

      userCredential = await user.linkWithCredential(result.credential!);
      _logger.info(
        'AuthService',
        'Cuenta vinculada exitosamente con Google: ${userCredential.user?.email}',
      );
      return (credential: userCredential, error: null);
    } on FirebaseAuthException catch (e, stack) {
      // Handle popup cancelled by user (not an error)
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        _logger.info('AuthService', 'Usuario cerro el popup de Google');
        return (credential: null, error: null); // No error, just cancelled
      }

      String userMessage = 'No se pudo vincular con Google';

      switch (e.code) {
        case 'credential-already-in-use':
          userMessage = 'Esta cuenta de Google ya esta en uso por otro usuario';
          break;
        case 'email-already-in-use':
          userMessage = 'Este correo ya esta registrado con otro metodo';
          break;
        case 'provider-already-linked':
          userMessage = 'Ya tienes una cuenta de Google vinculada';
          break;
        case 'invalid-credential':
          userMessage = 'Credencial invalida. Intenta de nuevo.';
          break;
        case 'operation-not-allowed':
          userMessage = 'Google Sign-In no esta habilitado';
          break;
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con Google: ${e.code}',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return (credential: null, error: userMessage);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con Google',
        userMessage: 'No se pudo vincular con Google',
        stackTrace: stack,
      );
      return (credential: null, error: 'Error inesperado. Intenta de nuevo.');
    }
  }

  /// Convierte GoogleSignInError a mensaje de usuario
  String _getGoogleErrorMessage(GoogleSignInError error) {
    switch (error) {
      case GoogleSignInError.networkError:
        return 'Sin conexion a internet. Verifica tu conexion.';
      case GoogleSignInError.configurationError:
        return 'Error de configuracion. Contacta al desarrollador.';
      case GoogleSignInError.apiError:
        return 'Google Play Services no disponible.';
      case GoogleSignInError.cancelled:
        return 'Inicio de sesion cancelado.';
      case GoogleSignInError.unknown:
        return 'Error desconocido. Intenta de nuevo.';
    }
  }

  // ==================== ACCOUNT DELETION ====================
  /// Delete user account completely
  ///
  /// Pasos ejecutados en orden:
  /// 1. Si Firebase no disponible → solo limpiar datos locales y retornar éxito
  /// 2. Si no hay usuario → solo limpiar datos locales y retornar éxito
  /// 3. Eliminar datos de Firestore (deleteAllUserDataFromCloud)
  /// 4. Limpiar datos locales Hive (clearAllLocalData)
  /// 5. Desconectar de Google si estaba vinculado
  /// 6. Borrar cuenta de Firebase Auth (user.delete())
  ///
  /// ERROR CRÍTICO - requires-recent-login:
  /// Firebase exige que la cuenta haya iniciado sesión recientemente para
  /// poder eliminarla (protección contra eliminación remota por atacantes).
  /// Si el usuario no ha hecho login en las últimas 5 min, Firebase rechaza
  /// con este código. La solución es que el usuario cierre sesión y vuelva
  /// a entrar antes de intentar eliminar.
  ///
  /// NOTA: Al borrar la cuenta NO se crea un nuevo anónimo automáticamente.
  /// Esto es intencional: tras eliminar, el usuario debe decidir si crear
  /// una cuenta nueva o continuar sin cuenta.
  Future<bool> deleteAccount(DatabaseService dbService) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      // If Firebase not available, just clear local data
      await dbService.clearAllLocalData();
      return true;
    }

    final user = currentUser;
    if (user == null) {
      await dbService.clearAllLocalData();
      return true;
    }

    final userId = user.uid;

    try {
      // 1. Delete all Firestore data
      await dbService.deleteAllUserDataFromCloud(userId);

      // 2. Clear all local Hive data
      await dbService.clearAllLocalData();

      // 3. Sign out from Google if linked
      await _googleSignIn.disconnect();

      // 4. Delete Firebase Auth account
      await user.delete();

      _logger.info('AuthService', 'Cuenta eliminada completamente');

      // 5. Sign in anonymously for fresh start
      // await signInAnonymously();

      return true;
    } on FirebaseAuthException catch (e, stack) {
      if (e.code == 'requires-recent-login') {
        _errorHandler.handle(
          e,
          type: ErrorType.auth,
          severity: ErrorSeverity.error,
          message: 'Se requiere reautenticacion',
          userMessage:
              'Por seguridad, cierra sesion y vuelve a entrar antes de eliminar tu cuenta',
          stackTrace: stack,
        );
      } else {
        _errorHandler.handle(
          e,
          type: ErrorType.auth,
          severity: ErrorSeverity.error,
          message: 'Error al eliminar cuenta',
          userMessage: 'No se pudo eliminar la cuenta',
          stackTrace: stack,
        );
      }
      return false;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar cuenta',
        userMessage: 'No se pudo eliminar la cuenta',
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Sign in with email and password (for existing linked accounts)
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      return null;
    }

    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = 'No se pudo iniciar sesion';

      switch (e.code) {
        case 'user-not-found':
          userMessage = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          userMessage = 'Contrasena incorrecta';
          break;
        case 'invalid-email':
          userMessage = 'Correo electronico invalido';
          break;
        case 'user-disabled':
          userMessage = 'Esta cuenta ha sido deshabilitada';
          break;
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al iniciar sesion',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Registrar una nueva cuenta con email y contraseña
  Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      _errorHandler.handle(
        'Firebase no disponible',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Servicio no disponible en este momento',
      );
      return null;
    }

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.info('AuthService', 'Cuenta creada exitosamente para: $email');
      return credential;
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = 'No se pudo crear la cuenta';

      switch (e.code) {
        case 'email-already-in-use':
          userMessage = 'Este correo ya está registrado. Inicia sesión.';
          break;
        case 'weak-password':
          userMessage = 'La contraseña es demasiado débil';
          break;
        case 'invalid-email':
          userMessage = 'El correo electrónico no es válido';
          break;
        case 'operation-not-allowed':
          userMessage = 'El registro con email/contraseña no está habilitado';
          break;
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al registrar usuario: ${e.code}',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error inesperado al registrar usuario',
        userMessage: 'Ocurrió un error inesperado al registrar la cuenta',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Sign in with Google (for existing linked accounts)
  Future<UserCredential?> signInWithGoogle() async {
    return await _googleSignIn.signInWithGoogle();
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      return false;
    }

    try {
      await _auth!.sendPasswordResetEmail(email: email);
      return true;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al enviar correo de recuperacion',
        userMessage: 'No se pudo enviar el correo',
        stackTrace: stack,
      );
      return false;
    }
  }

  // ==================== SESSION CACHE MANAGEMENT ====================

  /// Prepara la sesion para un usuario.
  ///
  /// Se llama despues de iniciar sesion exitosamente.
  Future<void> prepareSession(String userId) async {
    await _sessionCache.prepareForUser(userId);
  }

  /// Verifica si el cache pertenece al usuario actual.
  Future<bool> validateCacheForUser(String userId) async {
    return await _sessionCache.validateCacheOwnership(userId);
  }

  /// Limpia el cache si pertenece a otro usuario.
  Future<void> clearCacheIfDifferentUser(String newUserId) async {
    await _sessionCache.clearIfDifferentUser(newUserId);
  }

  /// Migra datos anonimos al vincular cuenta.
  Future<void> migrateAnonymousData(String oldUserId, String newUserId) async {
    await _sessionCache.migrateAnonymousData(oldUserId, newUserId);
  }

  /// Exporta datos del usuario (GDPR).
  Future<DataExport> exportUserData() async {
    return await _sessionCache.exportBeforeClear();
  }

  /// Obtiene estadisticas del cache actual.
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _sessionCache.getCacheStats();
  }

  /// Dispose resources and cleanup
  /// Should be called when the service is no longer needed
  Future<void> dispose() async {
    if (_disposed) return;

    try {
      _logger.debug('AuthService', 'Disposing resources...');
      _disposed = true;

      // No need to close streams or sign out - just mark as disposed
      // Firebase Auth manages its own lifecycle

      _logger.debug('AuthService', 'Disposed successfully');
    } catch (e) {
      _logger.error('AuthService', 'Error during dispose', error: e);
    }
  }

  /// Check if the service has been disposed
  bool get isDisposed => _disposed;
}



