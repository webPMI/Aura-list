import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'error_handler.dart';
import 'logger_service.dart';
import '../features/finance/providers/finance_provider.dart';
import '../features/finance/repositories/finance_repository.dart';

/// Provider del AuthManager centralizado
final authManagerProvider = Provider<AuthManager>((ref) {
  return AuthManager(
    authService: ref.read(authServiceProvider),
    dbService: ref.read(databaseServiceProvider),
    financeRepository: ref.read(financeRepositoryProvider),
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
  final FinanceRepository? _financeRepository;
  final _logger = LoggerService();

  AuthManager({
    required AuthService authService,
    required DatabaseService dbService,
    FinanceRepository? financeRepository,
  }) : _authService = authService,
       _dbService = dbService,
       _financeRepository = financeRepository;

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

  /// Obtiene el estado detallado de inicializacion
  Map<String, dynamic> getInitializationStatus() =>
      _authService.getInitializationStatus();

  // ==================== Operaciones Unificadas ====================
  //
  // FLUJO DE AUTENTICACIÓN EN LA APP (resumen):
  // ============================================
  //
  // Este AuthManager es el punto de entrada centralizado para todas las
  // operaciones de autenticación. La UI (AuthForm, AuthActionSheet,
  // UnifiedGoogleAuthButton) llama siempre a los métodos de este Manager,
  // nunca directamente a AuthService.
  //
  // Flujo completo (ver auth_service.dart para el desglose detallado):
  //   A. Primera vez → main.dart crea usuario anónimo → WelcomeScreen
  //   B. Usuario existente → main.dart hace sync inicial → MainScaffold
  //   C. Anónimo quiere vincular → AuthForm(mode: link) → linkWith*()
  //   D. Login Google directo → authenticateWithGoogle() → signInWithGoogle()
  //
  // Patrón de errores: cuando AuthService retorna null/void, el Manager
  // usa isFirebaseAvailable para distinguir "Firebase down" de "credenciales
  // incorrectas". Los métodos linkWith*() usan el nuevo retorno record con
  // errorCode para mensajes de usuario específicos.
  //
  // Importante: signInAnonymously() en este Manager devuelve error porque
  // la creación de usuario anónimo se hace automáticamente en main.dart.
  // Este método existe solo por compatibilidad de interfaz.

  /// Login anonimo (disponible)
  Future<AuthResult> signInAnonymously() async {
    return AuthResult.error('El inicio de sesión anónimo está desactivado');
  }

  /// Login con email/password (cuenta existente)
  ///
  /// Flujo:
  /// 1. Llamar a AuthService.signInWithEmailPassword(email, password)
  /// 2. Si null → distinguir: ¿Firebase unavailable? → mensaje técnico,
  ///    ¿o credenciales inválidas? → "Credenciales incorrectas"
  /// 3. Si éxito → activar sync automáticamente
  ///
  /// Nota: el AuthService retorna null tanto para errores técnicos como de
  /// credenciales. Aquí discriminamos con isFirebaseAvailable para dar
  /// mensajes diferentes ("Firebase no disponible" vs "Credenciales incorrectas").
  ///
  /// Importante: este método es para USUARIOS EXISTENTES. Si el usuario es nuevo,
  /// debe usar registerWithEmailPassword() o authenticateWithGoogle().
  /// Si un usuario nuevo intenta login con credenciales que no existen,
  /// recibirá "Credenciales incorrectas" — comportamiento esperado.
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
        // Diferenciar entre error de credenciales y error técnico
        if (!_authService.isFirebaseAvailable) {
          return AuthResult.error('Firebase no disponible ($linkedEmail)');
        }
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

  /// Registro de nueva cuenta con email/password
  ///
  /// Flujo:
  /// 1. Llamar a AuthService.registerWithEmailPassword(email, password)
  /// 2. Si null → distinguir: ¿Firebase unavailable? → mensaje técnico,
  ///    ¿o error de registro (email ya usado, password débil)? → mensaje específico
  /// 3. Si éxito → activar sync automáticamente
  ///
  /// Nota: igual que signInWithEmailPassword, discriminamos el caso
  /// Firebase unavailable para no confundir al usuario.
  ///
  /// Importante: este método es para USUARIOS NUEVOS. Si el email ya existe
  /// en Firebase, recibirá "Este correo ya está registrado" — el usuario
  /// debe usar signInWithEmailPassword() en ese caso.
  /// El AuthService maneja internamente el código 'email-already-in-use'.
  Future<AuthResult> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _authService.registerWithEmailPassword(
        email,
        password,
      );
      if (result == null) {
        if (!_authService.isFirebaseAvailable) {
          return AuthResult.error('Firebase no disponible en este momento');
        }
        return AuthResult.error('No se pudo crear la cuenta');
      }

      // Activar sync automáticamente tras registrarse
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error(
        'AuthManager',
        'Error en registerWithEmailPassword',
        error: e,
      );
      if (e is FirebaseAuthException) {
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }
      return AuthResult.error('Error al crear la cuenta');
    }
  }

  /// Login con Google (directo, no vinculacion)
  ///
  /// Este método es para usuarios que YA tienen una cuenta de Google vinculada
  /// y quieren iniciar sesión. No crea cuenta nueva ni vincula anónimo.
  ///
  /// Flujo:
  /// 1. Llamar a AuthService.signInWithGoogle()
  /// 2. Si null → usuario canceló, no es error
  /// 3. Si éxito → activar sync automáticamente
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
  ///
  /// Este es el método que llama la UI (UnifiedGoogleAuthButton) cuando el
  /// usuario pulsa "Continuar con Google". Determina automáticamente qué hacer:
  ///
  /// Casos:
  /// - User anónimo activo → vincular cuenta de Google (linkWithGoogle)
  ///   → el usuario tenía datos locales y ahora se vincula para sincronizar
  /// - No hay user (null) → iniciar sesión directo con Google (signInWithGoogle)
  ///   → el usuario entra por primera vez directamente con Google
  /// - User no anónimo → intentar login directo (signInWithGoogle)
  ///   → el usuario ya tenía cuenta vinculada y quiere entrar
  ///
  /// Retorna (isNewUser, result):
  /// - isNewUser: true si vino de anónimo → puede necesitar welcome/register flow
  /// - result: AuthResult con éxito, error o cancelación
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
  ///
  /// Usa el retorno detallado de AuthService para mensajes claros:
  /// - Si se devuelve errorCode != null → error específico (ej: "Google ya en uso")
  /// - Si isCancelled = true → usuario cerró el popup, no es error
  /// - Si credential != null → éxito
  ///
  /// Este método es el punto de entrada para la UI (AuthForm, AuthActionSheet).
  /// Traduce los códigos internos de AuthService a AuthResult para que el UI
  /// pueda mostrar mensajes en español.
  Future<AuthResult> linkWithGoogle() async {
    final user = currentUser;
    if (user == null) {
      return AuthResult.error('No hay sesión activa. Reinicia la app e intenta de nuevo.');
    }
    if (!user.isAnonymous) {
      return AuthResult.error('La cuenta ya está vinculada con otro método.');
    }

    try {
      final (:credential, :error) = await _authService.linkWithGoogle();

      if (credential == null) {
        if (error != null) {
          // Error específico del servicio (ej: "Esta cuenta de Google ya está en uso")
          return AuthResult.error(error);
        }
        // Sin error pero sin credential = cancelado (popup cerrado por usuario)
        return AuthResult.cancelled();
      }

      // Activar sync automaticamente despues de vincular
      await _enableSyncAfterAuth();

      return AuthResult.success();
    } catch (e) {
      _logger.error('AuthManager', 'Error en linkWithGoogle', error: e);
      return AuthResult.error('Error al vincular con Google. Verifica tu conexión e inténtalo de nuevo.');
    }
  }

  /// Vincular cuenta anonima con email/password
  /// Activa sincronizacion automaticamente
  /// Usa el nuevo retorno detallado de AuthService para mensajes claros
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
      final (:credential, :errorMessage, :isCancelled, :errorCode) =
          await _authService.linkWithEmailPassword(email, password);

      if (isCancelled) {
        return AuthResult.cancelled();
      }

      if (credential == null) {
        // Distinguir entre error de credenciales y error técnico
        if (!_authService.isFirebaseAvailable) {
          return AuthResult.error('Firebase no disponible en este momento');
        }
        // Usar el mensaje detallado del servicio si está disponible
        return AuthResult.error(errorMessage ?? 'No se pudo vincular la cuenta');
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
  ///
  /// Este método se llama automaticamente despues de vincular o iniciar sesion
  /// exitosamente. Su funcion es:
  /// 1. Activar la sincronizacion en la nube (setCloudSyncEnabled(true))
  /// 2. Realizar la sincronizacion completa de tareas (performFullSync)
  /// 3. Si hay repositorio de finanzas, sincronizar tambien finanzas
  ///
  /// Si hay errores de sync pero no fatales, se loguean como warning y la app
  /// continua funcionando. Si hay errores criticos, se notifica al ErrorHandler.
  ///
  /// IMPORTANTE: Este método es llamado automaticamente por:
  /// - linkWithGoogle() / linkWithEmailPassword() (vinculacion de cuenta)
  /// - signInWithGoogle() / signInWithEmailPassword() (login)
  /// - registerWithEmailPassword() (registro nuevo)
  /// NO debe ser llamado directamente por la UI en circunstancias normales.
  Future<void> _enableSyncAfterAuth() async {
    try {
      await _dbService.setCloudSyncEnabled(true);

      final user = currentUser;
      if (user != null) {
        final result = await _dbService.performFullSync(user.uid);
        if (_financeRepository != null) {
          try {
            await _financeRepository.performFullSync(user.uid);
          } catch (e) {
            _logger.warning('AuthManager', 'Error al sincronizar finanzas: $e');
          }
        }
        if (result.hasErrors) {
          _logger.warning(
            'AuthManager',
            'Sync activado pero con errores: ${result.errors} errores',
          );
          ErrorHandler().handle(
            Exception('Error al sincronizar datos'),
            type: ErrorType.network,
            message:
                'La sincronización se activó pero hubo problemas al sincronizar algunos datos',
          );
        }
      }

      _logger.info(
        'AuthManager',
        'Sync activado automaticamente despues de auth',
      );
    } catch (e) {
      _logger.error('AuthManager', 'Error al activar sync', error: e);
      ErrorHandler().handle(
        e,
        type: ErrorType.network,
        message: 'No se pudo activar la sincronización en la nube',
      );
    }
  }

  /// Activa o desactiva la sincronizacion manualmente
  Future<void> setSyncEnabled(bool enabled) async {
    try {
      await _dbService.setCloudSyncEnabled(enabled);

      if (enabled) {
        final user = currentUser;
        if (user != null) {
          final result = await _dbService.performFullSync(user.uid);
          if (_financeRepository != null) {
            try {
              await _financeRepository.performFullSync(user.uid);
            } catch (e) {
              _logger.warning('AuthManager', 'Error al sincronizar finanzas: $e');
            }
          }
          if (result.hasErrors) {
            ErrorHandler().handle(
              Exception('Error al sincronizar datos'),
              type: ErrorType.network,
              message:
                  'Sincronización activada pero algunos datos no se sincronizaron correctamente',
            );
          }
        }
      }
    } catch (e) {
      _logger.error('AuthManager', 'Error al cambiar sync enabled', error: e);
      ErrorHandler().handle(
        e,
        type: ErrorType.network,
        message: enabled
            ? 'No se pudo activar la sincronización'
            : 'No se pudo desactivar la sincronización',
      );
      rethrow; // Re-throw so UI can handle it
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



