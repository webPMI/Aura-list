import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_handler.dart';
import 'database_service.dart';
import 'google_sign_in_service.dart';
import 'session_cache_manager.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final googleSignIn = ref.watch(googleSignInServiceProvider);
  final sessionCache = ref.watch(sessionCacheProvider);
  return AuthService(errorHandler, googleSignIn, sessionCache);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provider to check if user is linked (not anonymous)
final isLinkedAccountProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLinkedAccount;
});

/// Provider that automatically signs in anonymously if no user exists
/// This should be watched at app startup to ensure authentication
/// Returns immediately and allows the app to function in offline mode if Firebase is unavailable
final authInitializationProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);

  try {
    // Wait a bit to ensure Firebase is fully initialized
    await Future.delayed(const Duration(milliseconds: 200));

    // Refresh Firebase availability check
    authService.refreshFirebaseAvailability();

    // Check if Firebase is available
    if (!authService.isFirebaseAvailable) {
      debugPrint('Firebase Auth no disponible - app funcionara en modo local');
      return;
    }

    // Check if there's already a user
    if (authService.currentUser == null) {
      debugPrint('No hay usuario, intentando login anonimo...');
      final result = await authService.signInAnonymously();
      if (result != null) {
        debugPrint('Login anonimo exitoso: ${result.user?.uid}');
      } else {
        debugPrint('Login anonimo omitido (Firebase no disponible o error)');
        debugPrint('App funcionara en modo local');
      }
    } else {
      debugPrint('Usuario ya autenticado: ${authService.currentUser?.uid}');
    }
  } catch (e) {
    // Catch any unexpected errors during initialization
    // Don't propagate the error - let the app continue in offline mode
    debugPrint('Error durante inicializacion de auth: $e');
    debugPrint('App funcionara en modo local');
  }
});

class AuthService {
  final ErrorHandler _errorHandler;
  final GoogleSignInService _googleSignIn;
  final SessionCacheManager _sessionCache;
  FirebaseAuth? _auth;
  bool _firebaseAvailable = false;
  bool _initialized = false;

  AuthService(this._errorHandler, this._googleSignIn, this._sessionCache);

  /// Ensures Firebase Auth is available before operations
  /// This method is safe to call multiple times
  void _ensureFirebaseAvailable() {
    if (_initialized && _firebaseAvailable) return;

    try {
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      if (_firebaseAvailable) {
        _auth = FirebaseAuth.instance;
        _initialized = true;
        debugPrint('Firebase Auth inicializado correctamente');
      }
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('Firebase Auth no disponible: $e');
    }
  }

  /// Re-check Firebase availability (useful after delayed initialization)
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

  /// Check if Firebase Auth is available
  bool get isFirebaseAvailable {
    _ensureFirebaseAvailable();
    return _firebaseAvailable;
  }

  Future<UserCredential?> signInAnonymously() async {
    // Ensure Firebase is available before attempting sign in
    _ensureFirebaseAvailable();

    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase no configurado, omitiendo login anonimo');
      debugPrint('La app funcionara en modo local (Hive)');
      return null;
    }

    try {
      debugPrint('Intentando login anonimo...');
      final result = await _auth!.signInAnonymously();
      debugPrint('Login anonimo exitoso: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e, stack) {
      // Handle specific Firebase Auth errors
      String userMessage = 'No se pudo iniciar sesión.';

      switch (e.code) {
        case 'operation-not-allowed':
          debugPrint('ERROR: Autenticación anónima no está habilitada en Firebase Console');
          userMessage = 'Autenticación anónima no habilitada. Contacta al administrador.';
          break;
        case 'network-request-failed':
          debugPrint('ERROR: No hay conexión a Internet');
          userMessage = 'Sin conexión a Internet. La app funcionará en modo local.';
          break;
        default:
          debugPrint('ERROR Firebase Auth: ${e.code} - ${e.message}');
          userMessage = 'Error de autenticación. La app funcionará en modo local.';
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: e.code == 'network-request-failed'
            ? ErrorSeverity.warning
            : ErrorSeverity.error,
        message: 'Error al iniciar sesión anónima: ${e.code}',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      debugPrint('ERROR inesperado en login anónimo: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error inesperado al iniciar sesión anónima',
        userMessage: 'La app funcionará en modo local.',
        stackTrace: stack,
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

  // ==================== ACCOUNT LINKING ====================

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
  Future<UserCredential?> linkWithEmailPassword(
    String email,
    String password,
  ) async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      _errorHandler.handle(
        'Firebase no disponible',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Servicio no disponible',
      );
      return null;
    }

    final user = currentUser;
    if (user == null) {
      _errorHandler.handle(
        'No hay usuario activo',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Debes iniciar sesion primero',
      );
      return null;
    }

    if (!user.isAnonymous) {
      _errorHandler.handle(
        'Usuario ya vinculado',
        type: ErrorType.auth,
        severity: ErrorSeverity.info,
        userMessage: 'Tu cuenta ya esta vinculada',
      );
      return null;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final result = await user.linkWithCredential(credential);
      debugPrint('Cuenta vinculada exitosamente con email: $email');
      return result;
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = 'No se pudo vincular la cuenta';

      switch (e.code) {
        case 'email-already-in-use':
          userMessage = 'Este correo ya esta en uso';
          break;
        case 'invalid-email':
          userMessage = 'Correo electronico invalido';
          break;
        case 'weak-password':
          userMessage = 'La contrasena es muy debil';
          break;
        case 'credential-already-in-use':
          userMessage = 'Esta credencial ya esta en uso';
          break;
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con email',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta',
        userMessage: 'No se pudo vincular la cuenta',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Link anonymous account with Google
  /// Preserves all local data
  /// Returns a record with UserCredential and optional error message
  Future<({UserCredential? credential, String? error})> linkWithGoogle() async {
    _ensureFirebaseAvailable();
    if (!_firebaseAvailable || _auth == null) {
      _errorHandler.handle(
        'Firebase no disponible',
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        userMessage: 'Servicio no disponible',
      );
      return (credential: null, error: 'Servicio no disponible. Intenta mas tarde.');
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
      final result = await _googleSignIn.getGoogleCredentialWithError();

      if (result.isCancelled) {
        debugPrint('Usuario cancelo el inicio de sesion con Google');
        return (credential: null, error: null); // No error, just cancelled
      }

      if (result.isError) {
        final errorMessage = _getGoogleErrorMessage(result.error!);
        debugPrint('Error obteniendo credencial de Google: ${result.error}');
        return (credential: null, error: errorMessage);
      }

      if (result.credential == null) {
        return (credential: null, error: 'No se pudo obtener credencial de Google');
      }

      final userCredential = await user.linkWithCredential(result.credential!);
      debugPrint('Cuenta vinculada exitosamente con Google: ${userCredential.user?.email}');
      return (credential: userCredential, error: null);
    } on FirebaseAuthException catch (e, stack) {
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
  /// Removes: Firebase Auth account, Firestore data, local Hive data
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

      debugPrint('Cuenta eliminada completamente');

      // 5. Sign in anonymously for fresh start
      await signInAnonymously();

      return true;
    } on FirebaseAuthException catch (e, stack) {
      if (e.code == 'requires-recent-login') {
        _errorHandler.handle(
          e,
          type: ErrorType.auth,
          severity: ErrorSeverity.error,
          message: 'Se requiere reautenticacion',
          userMessage: 'Por seguridad, cierra sesion y vuelve a entrar antes de eliminar tu cuenta',
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
}
