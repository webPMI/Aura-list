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

class AuthService {
  final ErrorHandler _errorHandler;
  final GoogleSignInService _googleSignIn;
  final SessionCacheManager _sessionCache;
  FirebaseAuth? _auth;
  bool _firebaseAvailable = false;

  AuthService(this._errorHandler, this._googleSignIn, this._sessionCache) {
    _checkFirebaseAvailability();
  }

  void _checkFirebaseAvailability() {
    try {
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      if (_firebaseAvailable) {
        _auth = FirebaseAuth.instance;
      }
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('Firebase Auth no disponible: $e');
    }
  }

  Stream<User?> get authStateChanges {
    if (!_firebaseAvailable || _auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  User? get currentUser {
    if (!_firebaseAvailable || _auth == null) {
      return null;
    }
    return _auth!.currentUser;
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!_firebaseAvailable || _auth == null) {
      debugPrint('Firebase no configurado, omitiendo login anónimo');
      return null;
    }

    try {
      return await _auth!.signInAnonymously();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al iniciar sesión anónima',
        userMessage: 'No se pudo iniciar sesión. Intenta de nuevo.',
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
  Future<UserCredential?> linkWithGoogle() async {
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
      final credential = await _googleSignIn.getGoogleCredential();
      if (credential == null) {
        debugPrint('Usuario cancelo el inicio de sesion con Google');
        return null;
      }

      final result = await user.linkWithCredential(credential);
      debugPrint('Cuenta vinculada exitosamente con Google');
      return result;
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = 'No se pudo vincular con Google';

      if (e.code == 'credential-already-in-use') {
        userMessage = 'Esta cuenta de Google ya esta en uso';
      }

      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con Google',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'Error al vincular cuenta con Google',
        userMessage: 'No se pudo vincular con Google',
        stackTrace: stack,
      );
      return null;
    }
  }

  // ==================== ACCOUNT DELETION ====================

  /// Delete user account completely
  /// Removes: Firebase Auth account, Firestore data, local Hive data
  Future<bool> deleteAccount(DatabaseService dbService) async {
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
