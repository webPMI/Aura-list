import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'error_handler.dart';
import 'logger_service.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

/// Resultado de Google Sign-In con informacion de error
class GoogleSignInResult {
  final OAuthCredential? credential;
  final GoogleSignInError? error;

  GoogleSignInResult.success(this.credential) : error = null;
  GoogleSignInResult.cancelled() : credential = null, error = null;
  GoogleSignInResult.error(this.error) : credential = null;

  bool get isSuccess => credential != null;
  bool get isCancelled => credential == null && error == null;
  bool get isError => error != null;
}

/// Tipos de errores de Google Sign-In
enum GoogleSignInError {
  /// Error de red - sin conexion a internet
  networkError,
  /// Error de configuracion - SHA-1 faltante o Client ID incorrecto
  configurationError,
  /// Error de API - Google Play Services no disponible o desactualizado
  apiError,
  /// El usuario cancelo el flujo de inicio de sesion
  cancelled,
  /// Error desconocido
  unknown,
}

class GoogleSignInService {
  final _logger = LoggerService();
  // Web OAuth Client ID from Firebase Console
  // IMPORTANT: This MUST be the Web client type (type 3), NOT the Android client
  // Found in: Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration
  static const String _webClientId = '759264872546-nmeajdq53e82m4bugs1h0vu7h4dngcdf.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn;

  /// Track if dispose has been called
  bool _disposed = false;

  GoogleSignInService() {
    try {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // For web, specify clientId
        // For Android, specify serverClientId to get idToken
        // The serverClientId should be the Web client ID
        clientId: kIsWeb ? _webClientId : null,
        serverClientId: kIsWeb ? null : _webClientId,
      );
      _logger.debug('Service', '[GoogleSignIn] Servicio inicializado correctamente');
    } catch (e) {
      _logger.debug('Service', '[GoogleSignIn] Error inicializando servicio: $e');
      rethrow;
    }
  }

  /// Get Google OAuth credential for Firebase Auth
  /// Returns null if user cancels or there's an error
  Future<OAuthCredential?> getGoogleCredential() async {
    final result = await getGoogleCredentialWithError();
    return result.credential;
  }

  /// Get Google OAuth credential with detailed error information
  Future<GoogleSignInResult> getGoogleCredentialWithError() async {
    try {
      _logger.debug('Service', 'GoogleSignIn: Iniciando flujo de autenticacion...');
      _logger.debug('Service', 'GoogleSignIn: Platform - isWeb: $kIsWeb');

      // On web, google_sign_in doesn't reliably provide idToken
      // We'll return a special result that tells the caller to use signInWithPopup
      if (kIsWeb) {
        _logger.debug('Service', 'GoogleSignIn: Web platform - usando signInWithPopup directamente');
        // Return null credential - the caller should use signInWithPopup for web
        return GoogleSignInResult.error(GoogleSignInError.unknown);
      }

      // Trigger the sign-in flow (mobile only)
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        _logger.debug('Service', 'GoogleSignIn: Usuario cancelo el flujo');
        return GoogleSignInResult.cancelled();
      }

      _logger.debug('Service', 'GoogleSignIn: Cuenta obtenida: ${account.email}');

      // Obtain the auth details
      final GoogleSignInAuthentication auth = await account.authentication;

      _logger.debug('Service', 'GoogleSignIn: accessToken presente: ${auth.accessToken != null}');
      _logger.debug('Service', 'GoogleSignIn: idToken presente: ${auth.idToken != null}');

      // Verify we have the required tokens
      if (auth.idToken == null) {
        _logger.debug('Service', 'GoogleSignIn: ERROR - idToken es null. Esto usualmente indica:');
        _logger.debug('Service', '  - Android: Falta SHA-1/SHA-256 en Firebase Console');
        _logger.debug('Service', '  - Android: serverClientId no configurado correctamente');

        ErrorHandler().handle(
          'idToken is null - possible configuration issue',
          type: ErrorType.auth,
          severity: ErrorSeverity.error,
          message: 'GoogleSignIn: idToken is null',
          userMessage: 'Error de configuracion. Verifica la configuracion de Firebase.',
        );

        return GoogleSignInResult.error(GoogleSignInError.configurationError);
      }

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      _logger.debug('Service', 'GoogleSignIn: Credencial creada exitosamente');
      return GoogleSignInResult.success(credential);
    } catch (e, stack) {
      _logger.debug('Service', 'GoogleSignIn: Error durante autenticacion: $e');

      final error = _classifyError(e);
      final userMessage = _getUserMessage(error);

      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'GoogleSignInService.getGoogleCredential: $error',
        userMessage: userMessage,
        stackTrace: stack,
      );

      return GoogleSignInResult.error(error);
    }
  }

  /// Clasifica el error de Google Sign-In
  GoogleSignInError _classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return GoogleSignInError.networkError;
    }

    // Configuration errors (SHA-1, Client ID, etc.)
    if (errorString.contains('configuration') ||
        errorString.contains('client_id') ||
        errorString.contains('sha') ||
        errorString.contains('sign_in_failed') ||
        errorString.contains('10:') || // Google Sign-In error code 10
        errorString.contains('12500') || // Developer error
        errorString.contains('12501')) { // User cancelled (sometimes thrown as error)
      return GoogleSignInError.configurationError;
    }

    // API errors (Google Play Services)
    if (errorString.contains('api') ||
        errorString.contains('play services') ||
        errorString.contains('unavailable')) {
      return GoogleSignInError.apiError;
    }

    // Cancelled
    if (errorString.contains('cancel') || errorString.contains('12501')) {
      return GoogleSignInError.cancelled;
    }

    return GoogleSignInError.unknown;
  }

  /// Obtiene mensaje de usuario legible
  String _getUserMessage(GoogleSignInError error) {
    switch (error) {
      case GoogleSignInError.networkError:
        return 'Sin conexion a internet. Verifica tu conexion e intenta de nuevo.';
      case GoogleSignInError.configurationError:
        return 'Error de configuracion. Por favor contacta al desarrollador.';
      case GoogleSignInError.apiError:
        return 'Google Play Services no disponible. Actualiza Google Play Services e intenta de nuevo.';
      case GoogleSignInError.cancelled:
        return 'Inicio de sesion cancelado.';
      case GoogleSignInError.unknown:
        return 'Error desconocido. Intenta de nuevo mas tarde.';
    }
  }

  /// Sign in with Google and return UserCredential
  /// This is for direct sign-in (not linking)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _logger.debug('Service', 'GoogleSignIn: signInWithGoogle iniciando...');
      _logger.debug('Service', 'GoogleSignIn: Platform - isWeb: $kIsWeb');

      // On web, use signInWithPopup directly (google_sign_in doesn't provide idToken reliably)
      if (kIsWeb) {
        _logger.debug('Service', 'GoogleSignIn: Usando signInWithPopup para web...');
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        _logger.debug('Service', 'GoogleSignIn: signInWithPopup exitoso: ${userCredential.user?.email}');
        return userCredential;
      }

      // On mobile, use google_sign_in package
      final result = await getGoogleCredentialWithError();

      if (result.isCancelled) {
        _logger.debug('Service', 'GoogleSignIn: Usuario cancelo el inicio de sesion');
        return null;
      }

      if (result.isError) {
        _logger.debug('Service', 'GoogleSignIn: Error obteniendo credencial: ${result.error}');
        return null;
      }

      if (result.credential == null) {
        _logger.debug('Service', 'GoogleSignIn: Credencial es null sin error');
        return null;
      }

      _logger.debug('Service', 'GoogleSignIn: Iniciando sesion con Firebase...');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(result.credential!);
      _logger.debug('Service', 'GoogleSignIn: Inicio de sesion exitoso: ${userCredential.user?.email}');

      return userCredential;
    } on FirebaseAuthException catch (e, stack) {
      String userMessage = 'No se pudo iniciar sesion con Google';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          userMessage = 'Ya existe una cuenta con este correo usando otro metodo de inicio de sesion';
          break;
        case 'invalid-credential':
          userMessage = 'Credencial invalida. Intenta de nuevo.';
          break;
        case 'operation-not-allowed':
          userMessage = 'Google Sign-In no esta habilitado. Contacta al administrador.';
          break;
        case 'user-disabled':
          userMessage = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'user-not-found':
          userMessage = 'No se encontro usuario con estas credenciales.';
          break;
        case 'wrong-password':
          userMessage = 'Credenciales incorrectas.';
          break;
        case 'network-request-failed':
          userMessage = 'Sin conexion a internet.';
          break;
        case 'popup-closed-by-user':
          _logger.debug('Service', 'GoogleSignIn: Usuario cerro el popup');
          return null; // Not an error, just cancelled
        case 'cancelled-popup-request':
          _logger.debug('Service', 'GoogleSignIn: Popup cancelado');
          return null; // Not an error, just cancelled
      }

      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'GoogleSignInService.signInWithGoogle: ${e.code}',
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'GoogleSignInService.signInWithGoogle',
        userMessage: 'Error inesperado al iniciar sesion con Google',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get current signed-in Google account (if any)
  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  /// Check if signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.warning,
        message: 'GoogleSignInService.signOut',
        stackTrace: stack,
      );
    }
  }

  /// Disconnect from Google (revokes access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      _logger.debug('Service', '[GoogleSignIn] Desconectado exitosamente');
    } catch (e, stack) {
      _logger.debug('Service', '[GoogleSignIn] Error al desconectar: $e');
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.warning,
        message: 'GoogleSignInService.disconnect',
        stackTrace: stack,
      );
    }
  }

  /// Dispose resources and cleanup
  /// Should be called when the service is no longer needed
  Future<void> dispose() async {
    if (_disposed) return;

    try {
      _logger.debug('Service', '[GoogleSignIn] Disposing resources...');
      _disposed = true;

      // Sign out to clean up any active sessions
      await signOut();

      _logger.debug('Service', '[GoogleSignIn] Disposed successfully');
    } catch (e) {
      _logger.debug('Service', '[GoogleSignIn] Error during dispose: $e');
    }
  }

  /// Check if the service has been disposed
  bool get isDisposed => _disposed;
}
