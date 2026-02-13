import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'logger_service.dart';

/// Provider del AuthManager centralizado
final authManagerProvider = Provider<AuthManager>((ref) {
  return AuthManager(
    authService: ref.read(authServiceProvider),
    dbService: ref.read(databaseServiceProvider),
  );
});

/// Resultado de operaciones de autenticacion
class AuthResult {
  final bool success;
  final String? error;
  final bool cancelled;

  AuthResult.success() : success = true, error = null, cancelled = false;
  AuthResult.error(this.error) : success = false, cancelled = false;
  AuthResult.cancelled() : success = false, error = null, cancelled = true;
}

/// Manager centralizado para todas las operaciones de autenticacion
/// Punto unico de entrada para login, vinculacion y sincronizacion
class AuthManager {
  final AuthService _authService;
  final DatabaseService _dbService;
  final _logger = LoggerService();

  AuthManager({
    required AuthService authService,
    required DatabaseService dbService,
  }) : _authService = authService,
       _dbService = dbService;

  // ==================== Estado ====================

  /// Usuario actual (puede ser anonimo)
  User? get currentUser => _authService.currentUser;

  /// Si la cuenta esta vinculada (no anonima)
  bool get isLinkedAccount => _authService.isLinkedAccount;

  /// Email vinculado
  String? get linkedEmail => _authService.linkedEmail;

  /// Proveedor vinculado ('google', 'password')
  String? get linkedProvider => _authService.linkedProvider;

  /// Stream del estado de autenticacion
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Si Firebase esta disponible
  bool get isFirebaseAvailable => _authService.isFirebaseAvailable;

  // ==================== Operaciones Unificadas ====================

  /// Login anonimo
  Future<AuthResult> signInAnonymously() async {
    try {
      final result = await _authService.signInAnonymously();
      if (result == null) {
        return AuthResult.error('No se pudo iniciar sesion anonima');
      }
      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en signInAnonymously', error: e);
      return AuthResult.error('Error inesperado: $e');
    }
  }

  /// Login con email/password (cuenta existente)
  Future<AuthResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _authService.signInWithEmailPassword(
        email,
        password,
      );
      if (result == null) {
        return AuthResult.error('Credenciales incorrectas');
      }

      // Activar sync automaticamente
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error(
        'AuthManager',
        'Error en signInWithEmailPassword',
        error: e,
      );
      if (e is FirebaseAuthException) {
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }
      return AuthResult.error('Error al iniciar sesion');
    }
  }

  /// Login con Google (directo, no vinculacion)
  Future<AuthResult> signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        return AuthResult.cancelled();
      }

      // Activar sync automaticamente
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en signInWithGoogle', error: e);
      return AuthResult.error('Error al iniciar sesion con Google');
    }
  }

  /// Unified Google authentication
  /// Handles both login and registration scenarios
  /// Detects automatically if user exists or is new
  Future<({bool isNewUser, AuthResult result})> authenticateWithGoogle({
    bool requireTermsAcceptance = false,
  }) async {
    final user = currentUser;

    // If user is anonymous, link the account
    if (user != null && user.isAnonymous) {
      try {
        final result = await linkWithGoogle();
        // Assume it's a "new" registration when linking from anonymous
        return (isNewUser: true, result: result);
      } catch (e) {
        _logger.error(
          'AuthManager',
          'Error linking anonymous to Google',
          error: e,
        );
        return (
          isNewUser: false,
          result: AuthResult.error('Error al vincular cuenta'),
        );
      }
    }

    // Otherwise, try to sign in directly
    try {
      final result = await signInWithGoogle();
      // Assume returning user if signing in directly
      return (isNewUser: false, result: result);
    } catch (e) {
      _logger.error('AuthManager', 'Error in Google authentication', error: e);
      return (
        isNewUser: false,
        result: AuthResult.error('Error de autenticación'),
      );
    }
  }

  /// Vincular cuenta anonima con Google
  /// Activa sincronizacion automaticamente
  Future<AuthResult> linkWithGoogle() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.error('No hay usuario activo');
    }
    if (!user.isAnonymous) {
      return AuthResult.error('La cuenta ya esta vinculada');
    }

    try {
      final (:credential, :error) = await _authService.linkWithGoogle();

      if (credential == null) {
        if (error != null) {
          return AuthResult.error(error);
        }
        return AuthResult.cancelled();
      }

      // Activar sync automaticamente despues de vincular
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en linkWithGoogle', error: e);
      return AuthResult.error('Error al vincular con Google');
    }
  }

  /// Vincular cuenta anonima con email/password
  /// Activa sincronizacion automaticamente
  Future<AuthResult> linkWithEmailPassword(
    String email,
    String password,
  ) async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.error('No hay usuario activo');
    }
    if (!user.isAnonymous) {
      return AuthResult.error('La cuenta ya esta vinculada');
    }

    try {
      final result = await _authService.linkWithEmailPassword(email, password);

      if (result == null) {
        return AuthResult.error('No se pudo vincular la cuenta');
      }

      // Activar sync automaticamente despues de vincular
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en linkWithEmailPassword', error: e);
      if (e is FirebaseAuthException) {
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }
      return AuthResult.error('Error al vincular cuenta');
    }
  }

  /// Activa la sincronizacion en la nube
  /// Se llama automaticamente despues de vincular/login
  Future<void> _enableSyncAfterAuth() async {
    try {
      await _dbService.setCloudSyncEnabled(true);

      final user = currentUser;
      if (user != null) {
        await _dbService.performFullSync(user.uid);
      }

      _logger.info(
        'AuthManager',
        'Sync activado automaticamente despues de auth',
      );
    } catch (e) {
      _logger.error('AuthManager', 'Error al activar sync', error: e);
    }
  }

  /// Activa o desactiva la sincronizacion manualmente
  Future<void> setSyncEnabled(bool enabled) async {
    await _dbService.setCloudSyncEnabled(enabled);

    if (enabled) {
      final user = currentUser;
      if (user != null) {
        await _dbService.performFullSync(user.uid);
      }
    }
  }

  /// Verifica si sync esta activado
  Future<bool> isSyncEnabled() async {
    return await _dbService.isCloudSyncEnabled();
  }

  /// Fuerza sincronizacion de tareas pendientes
  Future<void> forceSyncPending() async {
    final user = currentUser;
    if (user != null) {
      await _dbService.forceSyncPendingTasks();
    }
  }

  /// Obtiene el conteo de items pendientes de sincronizar
  Future<int> getPendingSyncCount() async {
    return await _dbService.getTotalPendingSyncCount();
  }

  /// Cerrar sesion
  Future<void> signOut({
    bool clearCache = false,
    bool preservePreferences = true,
  }) async {
    await _authService.signOut(
      clearCache: clearCache,
      preservePreferences: preservePreferences,
    );
  }

  /// Eliminar cuenta completamente
  Future<bool> deleteAccount() async {
    return await _authService.deleteAccount(_dbService);
  }

  /// Revocar consentimientos (desactiva sync y borra datos cloud)
  Future<void> revokeConsents() async {
    final user = currentUser;
    if (user != null) {
      await _dbService.deleteAllUserDataFromCloud(user.uid);
    }
    await _dbService.setCloudSyncEnabled(false);
  }

  /// Enviar email de recuperacion de contrasena
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      final success = await _authService.sendPasswordResetEmail(email);
      if (!success) {
        return AuthResult.error('No se pudo enviar el correo de recuperacion');
      }
      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en sendPasswordResetEmail', error: e);
      if (e is FirebaseAuthException) {
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }
      return AuthResult.error('Error al enviar email de recuperacion');
    }
  }

  /// Traduce codigos de error de Firebase a mensajes en espanol
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contrasena incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya esta registrado';
      case 'invalid-email':
        return 'Correo electronico invalido';
      case 'weak-password':
        return 'La contrasena es muy debil';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta mas tarde';
      case 'network-request-failed':
        return 'Error de conexion. Verifica tu internet';
      case 'credential-already-in-use':
        return 'Esta cuenta de Google ya esta vinculada a otro usuario';
      default:
        return 'Error de autenticacion ($code)';
    }
  }
}
