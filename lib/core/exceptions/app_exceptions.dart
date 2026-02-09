/// Jerarquia de excepciones personalizadas para AuraList.
///
/// Este modulo define excepciones especificas para diferentes tipos de errores
/// en la aplicacion, permitiendo un manejo mas granular y mensajes de usuario
/// apropiados para cada situacion.
///
/// Todas las excepciones extienden [AppException] que proporciona:
/// - Mensaje tecnico para logs
/// - Mensaje amigable para el usuario (en espanol)
/// - Flag de reintentabilidad
/// - Error original y stack trace
///
/// Ejemplo de uso:
/// ```dart
/// try {
///   await firestore.collection('users').doc(id).get();
/// } catch (e, stack) {
///   throw NetworkException(
///     message: 'Failed to fetch user data',
///     userMessage: 'No se pudo obtener los datos. Verifica tu conexion.',
///     originalError: e,
///     stackTrace: stack,
///   );
/// }
/// ```
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Excepcion base para todas las excepciones de la aplicacion.
///
/// Proporciona una estructura comun con mensajes tecnicos y de usuario,
/// ademas de informacion sobre si el error puede reintentarse.
abstract class AppException implements Exception {
  /// Mensaje tecnico para logging y debugging
  final String message;

  /// Mensaje amigable para mostrar al usuario (en espanol)
  final String? userMessage;

  /// Error original que causo esta excepcion
  final dynamic originalError;

  /// Stack trace del error original
  final StackTrace? stackTrace;

  /// Indica si la operacion puede reintentarse
  final bool isRetryable;

  /// Timestamp de cuando ocurrio la excepcion
  final DateTime timestamp;

  const AppException({
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    this.isRetryable = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _DefaultDateTime();

  /// Mensaje para mostrar al usuario, con fallback al mensaje tecnico
  String get displayMessage => userMessage ?? _getDefaultUserMessage();

  /// Mensaje por defecto segun el tipo de excepcion
  String _getDefaultUserMessage() => 'Ocurrio un error inesperado.';

  @override
  String toString() => '$runtimeType: $message';
}

/// Clase auxiliar para timestamp por defecto en const constructor
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  bool get isUtc => _now.isUtc;
  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  String toString() => _now.toString();
}

// =============================================================================
// NETWORK EXCEPTIONS
// =============================================================================

/// Excepcion para errores de red y conectividad.
///
/// Se lanza cuando hay problemas de conexion a internet, timeouts,
/// o servicios no disponibles.
class NetworkException extends AppException {
  /// Codigo HTTP del error (si aplica)
  final int? statusCode;

  const NetworkException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true, // Network errors are usually retryable
    this.statusCode,
  });

  @override
  String _getDefaultUserMessage() =>
      'Sin conexion a internet. Los cambios se guardaran localmente.';

  /// Crea una excepcion de timeout
  factory NetworkException.timeout({
    String? message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: message ?? 'La operacion excedio el tiempo de espera',
      userMessage: userMessage ?? 'La conexion tardo demasiado. Intenta de nuevo.',
      originalError: originalError,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// Crea una excepcion de servicio no disponible
  factory NetworkException.serviceUnavailable({
    String? message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message: message ?? 'El servicio no esta disponible',
      userMessage: userMessage ?? 'El servicio no esta disponible. Intenta mas tarde.',
      originalError: originalError,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// Crea una excepcion a partir de un error de Firebase
  factory NetworkException.fromFirebase(
    FirebaseException error, {
    StackTrace? stackTrace,
  }) {
    final isRetryable = _isFirebaseRetryable(error.code);
    return NetworkException(
      message: 'Firebase error: ${error.code} - ${error.message}',
      userMessage: _getFirebaseUserMessage(error.code),
      originalError: error,
      stackTrace: stackTrace,
      isRetryable: isRetryable,
    );
  }

  static bool _isFirebaseRetryable(String code) {
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'unknown' ||
        code == 'cancelled' ||
        code == 'resource-exhausted';
  }

  static String _getFirebaseUserMessage(String code) {
    switch (code) {
      case 'unavailable':
        return 'El servicio no esta disponible. Intenta mas tarde.';
      case 'deadline-exceeded':
        return 'La conexion tardo demasiado. Intenta de nuevo.';
      case 'resource-exhausted':
        return 'Demasiadas solicitudes. Espera un momento.';
      case 'cancelled':
        return 'La operacion fue cancelada.';
      default:
        return 'Error de conexion. Los cambios se guardaran localmente.';
    }
  }
}

// =============================================================================
// FIREBASE PERMISSION EXCEPTION
// =============================================================================

/// Excepcion para errores de permisos en Firebase.
///
/// Se lanza cuando el usuario no tiene permisos suficientes para
/// realizar una operacion en Firestore.
class FirebasePermissionException extends AppException {
  /// El path del recurso al que se intento acceder
  final String? resourcePath;

  const FirebasePermissionException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false, // Permission errors are not retryable
    this.resourcePath,
  });

  @override
  String _getDefaultUserMessage() =>
      'No tienes permiso para realizar esta accion.';

  /// Crea una excepcion a partir de un error de Firebase
  factory FirebasePermissionException.fromFirebase(
    FirebaseException error, {
    StackTrace? stackTrace,
    String? resourcePath,
  }) {
    return FirebasePermissionException(
      message: 'Permission denied: ${error.code} - ${error.message}',
      userMessage: 'No tienes permiso para acceder a este recurso.',
      originalError: error,
      stackTrace: stackTrace,
      resourcePath: resourcePath,
    );
  }
}

// =============================================================================
// HIVE STORAGE EXCEPTION
// =============================================================================

/// Excepcion para errores de almacenamiento local con Hive.
///
/// Se lanza cuando hay problemas al leer, escribir o acceder a la
/// base de datos local de Hive.
class HiveStorageException extends AppException {
  /// Nombre del box de Hive afectado
  final String? boxName;

  /// Tipo de operacion que fallo (read, write, delete, open)
  final HiveOperation? operation;

  const HiveStorageException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false, // Storage errors usually need manual fix
    this.boxName,
    this.operation,
  });

  @override
  String _getDefaultUserMessage() =>
      'Error al guardar datos localmente. Reinicia la aplicacion.';

  /// Crea una excepcion para error de apertura de box
  factory HiveStorageException.openFailed({
    required String boxName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return HiveStorageException(
      message: 'Failed to open Hive box: $boxName',
      userMessage: 'Error al abrir la base de datos local.',
      originalError: originalError,
      stackTrace: stackTrace,
      boxName: boxName,
      operation: HiveOperation.open,
    );
  }

  /// Crea una excepcion para error de escritura
  factory HiveStorageException.writeFailed({
    String? boxName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return HiveStorageException(
      message: 'Failed to write to Hive${boxName != null ? ' box: $boxName' : ''}',
      userMessage: 'No se pudo guardar. Intenta de nuevo.',
      originalError: originalError,
      stackTrace: stackTrace,
      boxName: boxName,
      operation: HiveOperation.write,
      isRetryable: true,
    );
  }

  /// Crea una excepcion para error de lectura
  factory HiveStorageException.readFailed({
    String? boxName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return HiveStorageException(
      message: 'Failed to read from Hive${boxName != null ? ' box: $boxName' : ''}',
      userMessage: 'No se pudieron cargar los datos.',
      originalError: originalError,
      stackTrace: stackTrace,
      boxName: boxName,
      operation: HiveOperation.read,
    );
  }

  /// Crea una excepcion para error de eliminacion
  factory HiveStorageException.deleteFailed({
    String? boxName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return HiveStorageException(
      message: 'Failed to delete from Hive${boxName != null ? ' box: $boxName' : ''}',
      userMessage: 'No se pudo eliminar el elemento.',
      originalError: originalError,
      stackTrace: stackTrace,
      boxName: boxName,
      operation: HiveOperation.delete,
    );
  }

  /// Crea una excepcion para datos corruptos
  factory HiveStorageException.corrupted({
    String? boxName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return HiveStorageException(
      message: 'Hive data corrupted${boxName != null ? ' in box: $boxName' : ''}',
      userMessage: 'Los datos locales estan danados. Puede ser necesario limpiar la cache.',
      originalError: originalError,
      stackTrace: stackTrace,
      boxName: boxName,
    );
  }
}

/// Tipos de operaciones de Hive
enum HiveOperation {
  open,
  read,
  write,
  delete,
}

// =============================================================================
// AUTH EXCEPTION
// =============================================================================

/// Excepcion para errores de autenticacion.
///
/// Se lanza cuando hay problemas con el inicio de sesion, cierre de sesion,
/// o verificacion de credenciales.
class AuthException extends AppException {
  /// Codigo de error de autenticacion
  final String? authCode;

  const AuthException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true, // Most auth errors can be retried
    this.authCode,
  });

  @override
  String _getDefaultUserMessage() =>
      'Error de autenticacion. Intenta de nuevo.';

  /// Crea una excepcion para credenciales invalidas
  factory AuthException.invalidCredentials({
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Invalid credentials provided',
      userMessage: 'Las credenciales no son validas.',
      originalError: originalError,
      stackTrace: stackTrace,
      authCode: 'invalid-credentials',
      isRetryable: true,
    );
  }

  /// Crea una excepcion para usuario no autenticado
  factory AuthException.notAuthenticated({
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'User is not authenticated',
      userMessage: 'Debes iniciar sesion para continuar.',
      originalError: originalError,
      stackTrace: stackTrace,
      authCode: 'not-authenticated',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para sesion expirada
  factory AuthException.sessionExpired({
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Session has expired',
      userMessage: 'Tu sesion ha expirado. Inicia sesion de nuevo.',
      originalError: originalError,
      stackTrace: stackTrace,
      authCode: 'session-expired',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para cuenta deshabilitada
  factory AuthException.accountDisabled({
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message: 'Account has been disabled',
      userMessage: 'Esta cuenta ha sido deshabilitada.',
      originalError: originalError,
      stackTrace: stackTrace,
      authCode: 'account-disabled',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para error de Google Sign-In
  factory AuthException.googleSignInFailed({
    dynamic originalError,
    StackTrace? stackTrace,
    String? details,
  }) {
    return AuthException(
      message: 'Google Sign-In failed${details != null ? ': $details' : ''}',
      userMessage: 'Error al iniciar sesion con Google. Intenta de nuevo.',
      originalError: originalError,
      stackTrace: stackTrace,
      authCode: 'google-sign-in-failed',
      isRetryable: true,
    );
  }
}

// =============================================================================
// VALIDATION EXCEPTION
// =============================================================================

/// Excepcion para errores de validacion de datos.
///
/// Se lanza cuando los datos proporcionados no cumplen con los requisitos
/// de validacion (campos vacios, formatos invalidos, etc.).
class ValidationException extends AppException {
  /// Nombre del campo que fallo la validacion
  final String? fieldName;

  /// Valor que no paso la validacion
  final dynamic invalidValue;

  const ValidationException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false, // Validation errors need user correction
    this.fieldName,
    this.invalidValue,
  });

  @override
  String _getDefaultUserMessage() =>
      'Datos invalidos. Verifica la informacion.';

  /// Crea una excepcion para campo requerido vacio
  factory ValidationException.required({
    required String fieldName,
    String? userMessage,
  }) {
    return ValidationException(
      message: 'Required field is empty: $fieldName',
      userMessage: userMessage ?? 'El campo $fieldName es obligatorio.',
      fieldName: fieldName,
    );
  }

  /// Crea una excepcion para formato invalido
  factory ValidationException.invalidFormat({
    required String fieldName,
    dynamic value,
    String? expectedFormat,
    String? userMessage,
  }) {
    return ValidationException(
      message: 'Invalid format for $fieldName${expectedFormat != null ? '. Expected: $expectedFormat' : ''}',
      userMessage: userMessage ?? 'El formato de $fieldName no es valido.',
      fieldName: fieldName,
      invalidValue: value,
    );
  }

  /// Crea una excepcion para valor fuera de rango
  factory ValidationException.outOfRange({
    required String fieldName,
    dynamic value,
    dynamic min,
    dynamic max,
    String? userMessage,
  }) {
    return ValidationException(
      message: 'Value out of range for $fieldName: $value (min: $min, max: $max)',
      userMessage: userMessage ?? 'El valor de $fieldName debe estar entre $min y $max.',
      fieldName: fieldName,
      invalidValue: value,
    );
  }

  /// Crea una excepcion para longitud invalida
  factory ValidationException.invalidLength({
    required String fieldName,
    int? actualLength,
    int? minLength,
    int? maxLength,
    String? userMessage,
  }) {
    String msg = 'Invalid length for $fieldName';
    if (actualLength != null) msg += ': $actualLength';
    if (minLength != null) msg += ' (min: $minLength)';
    if (maxLength != null) msg += ' (max: $maxLength)';

    return ValidationException(
      message: msg,
      userMessage: userMessage ?? _getLengthUserMessage(fieldName, minLength, maxLength),
      fieldName: fieldName,
    );
  }

  static String _getLengthUserMessage(String fieldName, int? min, int? max) {
    if (min != null && max != null) {
      return 'El campo $fieldName debe tener entre $min y $max caracteres.';
    } else if (min != null) {
      return 'El campo $fieldName debe tener al menos $min caracteres.';
    } else if (max != null) {
      return 'El campo $fieldName no puede tener mas de $max caracteres.';
    }
    return 'La longitud de $fieldName no es valida.';
  }
}

// =============================================================================
// SYNC EXCEPTION
// =============================================================================

/// Excepcion para errores de sincronizacion.
///
/// Se lanza cuando hay problemas al sincronizar datos entre el
/// almacenamiento local y Firebase.
class SyncException extends AppException {
  /// Tipo de sincronizacion que fallo
  final SyncDirection direction;

  /// Numero de elementos que fallaron
  final int? failedCount;

  /// Numero de intentos realizados
  final int? attemptCount;

  const SyncException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true, // Sync errors are usually retryable
    required this.direction,
    this.failedCount,
    this.attemptCount,
  });

  @override
  String _getDefaultUserMessage() =>
      'Error al sincronizar. Se reintentara automaticamente.';

  /// Crea una excepcion para fallo de subida
  factory SyncException.uploadFailed({
    dynamic originalError,
    StackTrace? stackTrace,
    int? failedCount,
    int? attemptCount,
  }) {
    return SyncException(
      message: 'Failed to upload data to cloud${failedCount != null ? ' ($failedCount items)' : ''}',
      userMessage: 'No se pudieron subir los datos. Se reintentara automaticamente.',
      originalError: originalError,
      stackTrace: stackTrace,
      direction: SyncDirection.upload,
      failedCount: failedCount,
      attemptCount: attemptCount,
    );
  }

  /// Crea una excepcion para fallo de descarga
  factory SyncException.downloadFailed({
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return SyncException(
      message: 'Failed to download data from cloud',
      userMessage: 'No se pudieron descargar los datos de la nube.',
      originalError: originalError,
      stackTrace: stackTrace,
      direction: SyncDirection.download,
    );
  }

  /// Crea una excepcion para conflicto de sincronizacion
  factory SyncException.conflict({
    dynamic originalError,
    StackTrace? stackTrace,
    String? details,
  }) {
    return SyncException(
      message: 'Sync conflict detected${details != null ? ': $details' : ''}',
      userMessage: 'Hay un conflicto de datos. Se usara la version mas reciente.',
      originalError: originalError,
      stackTrace: stackTrace,
      direction: SyncDirection.bidirectional,
      isRetryable: false,
    );
  }

  /// Crea una excepcion para maximo de reintentos alcanzado
  factory SyncException.maxRetriesExceeded({
    dynamic originalError,
    StackTrace? stackTrace,
    required int attemptCount,
  }) {
    return SyncException(
      message: 'Max sync retries exceeded ($attemptCount attempts)',
      userMessage: 'No se pudo sincronizar despues de varios intentos. Intenta mas tarde.',
      originalError: originalError,
      stackTrace: stackTrace,
      direction: SyncDirection.upload,
      attemptCount: attemptCount,
      isRetryable: false,
    );
  }
}

/// Direccion de la sincronizacion
enum SyncDirection {
  upload,
  download,
  bidirectional,
}

// =============================================================================
// UNKNOWN EXCEPTION
// =============================================================================

/// Excepcion para errores desconocidos o no categorizados.
///
/// Se usa como fallback cuando un error no encaja en ninguna otra categoria.
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false,
  });

  @override
  String _getDefaultUserMessage() =>
      'Ocurrio un error inesperado. Intenta de nuevo.';

  /// Crea una excepcion desconocida a partir de cualquier error
  factory UnknownException.from(
    dynamic error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    return UnknownException(
      message: error.toString(),
      userMessage: userMessage,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

// =============================================================================
// EXCEPTION UTILITIES
// =============================================================================

/// Extension para convertir errores genericos a AppException
extension ErrorToAppException on Object {
  /// Convierte cualquier error a un AppException apropiado
  AppException toAppException({StackTrace? stackTrace}) {
    if (this is AppException) return this as AppException;

    if (this is FirebaseException) {
      final fe = this as FirebaseException;
      if (fe.code == 'permission-denied' || fe.code == 'unauthenticated') {
        return FirebasePermissionException.fromFirebase(fe, stackTrace: stackTrace);
      }
      return NetworkException.fromFirebase(fe, stackTrace: stackTrace);
    }

    // Check for common error patterns
    final errorString = toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return NetworkException.timeout(
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return NetworkException(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('hive') ||
        errorString.contains('box') ||
        errorString.contains('storage')) {
      return HiveStorageException(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('auth') ||
        errorString.contains('credential') ||
        errorString.contains('sign')) {
      return AuthException(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('valid') ||
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return ValidationException(
        message: toString(),
        originalError: this,
        stackTrace: stackTrace,
      );
    }

    return UnknownException.from(this, stackTrace: stackTrace);
  }
}
