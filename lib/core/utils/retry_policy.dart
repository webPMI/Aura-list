/// Politica de reintentos configurable con backoff exponencial.
///
/// Este modulo proporciona una clase [RetryPolicy] que permite ejecutar
/// operaciones con reintentos automaticos, utilizando backoff exponencial
/// para evitar sobrecargar los servicios durante fallos temporales.
///
/// Caracteristicas:
/// - Numero maximo de intentos configurable
/// - Delay base configurable
/// - Multiplicador de backoff exponencial
/// - Funcion personalizada para determinar si reintentar
/// - Callbacks para monitorear reintentos
///
/// Ejemplo de uso:
/// ```dart
/// final policy = RetryPolicy(
///   maxAttempts: 3,
///   baseDelay: Duration(seconds: 2),
///   backoffMultiplier: 2.0,
/// );
///
/// final result = await policy.execute(
///   () => fetchDataFromServer(),
///   onRetry: (attempt, error, delay) {
///     print('Intento $attempt fallido, reintentando en ${delay.inSeconds}s...');
///   },
/// );
/// ```
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';

/// Callback invocado antes de cada reintento
typedef RetryCallback = void Function(
  int attemptNumber,
  dynamic error,
  Duration nextDelay,
);

/// Funcion que determina si un error debe reintentarse
typedef ShouldRetryFunction = bool Function(dynamic error);

/// Politica de reintentos configurable con backoff exponencial.
///
/// Permite ejecutar operaciones asincronas con reintentos automaticos
/// cuando fallan, utilizando una estrategia de backoff exponencial
/// para incrementar el tiempo entre reintentos.
class RetryPolicy {
  /// Numero maximo de intentos (incluyendo el primer intento)
  final int maxAttempts;

  /// Delay base antes del primer reintento
  final Duration baseDelay;

  /// Multiplicador para el backoff exponencial
  final double backoffMultiplier;

  /// Delay maximo entre reintentos
  final Duration maxDelay;

  /// Funcion personalizada para determinar si reintentar
  final ShouldRetryFunction? shouldRetry;

  /// Si debe agregar jitter aleatorio al delay
  final bool useJitter;

  /// Crea una nueva politica de reintentos.
  ///
  /// Parametros:
  /// - [maxAttempts]: Numero maximo de intentos (default: 3)
  /// - [baseDelay]: Delay inicial entre reintentos (default: 2 segundos)
  /// - [backoffMultiplier]: Factor de multiplicacion para backoff (default: 2.0)
  /// - [maxDelay]: Delay maximo permitido (default: 30 segundos)
  /// - [shouldRetry]: Funcion opcional para determinar si reintentar un error
  /// - [useJitter]: Si agregar variacion aleatoria al delay (default: true)
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 2),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
    this.useJitter = true,
  });

  /// Politica por defecto para operaciones de red
  static const RetryPolicy network = RetryPolicy(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 30),
  );

  /// Politica para operaciones de Firebase/Firestore
  static const RetryPolicy firebase = RetryPolicy(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 15),
  );

  /// Politica agresiva con mas reintentos
  static const RetryPolicy aggressive = RetryPolicy(
    maxAttempts: 5,
    baseDelay: Duration(seconds: 1),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 20),
  );

  /// Politica conservadora con menos reintentos
  static const RetryPolicy conservative = RetryPolicy(
    maxAttempts: 2,
    baseDelay: Duration(seconds: 3),
    backoffMultiplier: 2.5,
    maxDelay: Duration(seconds: 30),
  );

  /// Politica sin reintentos (solo un intento)
  static const RetryPolicy noRetry = RetryPolicy(
    maxAttempts: 1,
  );

  /// Ejecuta una operacion con la politica de reintentos configurada.
  ///
  /// Parametros:
  /// - [operation]: La operacion asincrona a ejecutar
  /// - [onRetry]: Callback opcional invocado antes de cada reintento
  ///
  /// Retorna el resultado de la operacion si tiene exito.
  /// Lanza la ultima excepcion si se agotan los reintentos.
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await policy.execute(() async {
  ///   return await apiClient.getData();
  /// });
  /// ```
  Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryCallback? onRetry,
  }) async {
    int attempt = 0;
    dynamic lastError;
    StackTrace? lastStackTrace;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        return await operation();
      } catch (e, stack) {
        lastError = e;
        lastStackTrace = stack;

        // Check if we should retry
        if (!_shouldRetryError(e) || attempt >= maxAttempts) {
          break;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt);

        // Notify about retry
        if (onRetry != null) {
          onRetry(attempt, e, delay);
        }

        if (kDebugMode) {
          debugPrint(
            '[RetryPolicy] Intento $attempt/$maxAttempts fallido. '
            'Reintentando en ${delay.inMilliseconds}ms...',
          );
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // All retries exhausted, throw the last error
    if (lastError is AppException) {
      throw lastError;
    }

    throw SyncException.maxRetriesExceeded(
      originalError: lastError,
      stackTrace: lastStackTrace,
      attemptCount: attempt,
    );
  }

  /// Ejecuta una operacion con la politica de reintentos y devuelve un Result.
  ///
  /// A diferencia de [execute], este metodo no lanza excepciones sino que
  /// devuelve un [RetryResult] que indica si la operacion tuvo exito o fallo.
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await policy.tryExecute(() async {
  ///   return await apiClient.getData();
  /// });
  ///
  /// if (result.isSuccess) {
  ///   print('Data: ${result.value}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  Future<RetryResult<T>> tryExecute<T>(
    Future<T> Function() operation, {
    RetryCallback? onRetry,
  }) async {
    try {
      final value = await execute(operation, onRetry: onRetry);
      return RetryResult.success(value);
    } catch (e, stack) {
      return RetryResult.failure(e, stack);
    }
  }

  /// Determina si un error deberia reintentarse.
  bool _shouldRetryError(dynamic error) {
    // Use custom function if provided
    if (shouldRetry != null) {
      return shouldRetry!(error);
    }

    // Default retry logic based on error type
    if (error is AppException) {
      return error.isRetryable;
    }

    // Retry network-related errors by default
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable');
  }

  /// Calcula el delay para el proximo reintento.
  Duration _calculateDelay(int attempt) {
    // Exponential backoff: baseDelay * (multiplier ^ (attempt - 1))
    final exponentialDelay = baseDelay.inMilliseconds *
        pow(backoffMultiplier, attempt - 1);

    // Apply max delay cap
    var delayMs = min(exponentialDelay.toInt(), maxDelay.inMilliseconds);

    // Add jitter if enabled (between 0-25% of the delay)
    if (useJitter && delayMs > 0) {
      final random = Random();
      final jitterRange = delayMs ~/ 4;
      delayMs = delayMs + random.nextInt(jitterRange);
    }

    return Duration(milliseconds: delayMs);
  }

  /// Crea una copia de esta politica con algunos valores modificados.
  RetryPolicy copyWith({
    int? maxAttempts,
    Duration? baseDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    ShouldRetryFunction? shouldRetry,
    bool? useJitter,
  }) {
    return RetryPolicy(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      baseDelay: baseDelay ?? this.baseDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxDelay: maxDelay ?? this.maxDelay,
      shouldRetry: shouldRetry ?? this.shouldRetry,
      useJitter: useJitter ?? this.useJitter,
    );
  }

  @override
  String toString() {
    return 'RetryPolicy('
        'maxAttempts: $maxAttempts, '
        'baseDelay: ${baseDelay.inMilliseconds}ms, '
        'backoffMultiplier: $backoffMultiplier, '
        'maxDelay: ${maxDelay.inMilliseconds}ms, '
        'useJitter: $useJitter)';
  }
}

/// Resultado de una operacion con reintentos.
///
/// Encapsula el resultado de [RetryPolicy.tryExecute], indicando
/// si la operacion tuvo exito o fallo, junto con el valor o error.
class RetryResult<T> {
  /// El valor retornado si la operacion tuvo exito
  final T? _value;

  /// El error si la operacion fallo
  final dynamic error;

  /// El stack trace del error
  final StackTrace? stackTrace;

  /// Si la operacion tuvo exito
  final bool isSuccess;

  const RetryResult._({
    T? value,
    this.error,
    this.stackTrace,
    required this.isSuccess,
  }) : _value = value;

  /// Crea un resultado exitoso.
  factory RetryResult.success(T value) {
    return RetryResult._(value: value, isSuccess: true);
  }

  /// Crea un resultado fallido.
  factory RetryResult.failure(dynamic error, [StackTrace? stackTrace]) {
    return RetryResult._(error: error, stackTrace: stackTrace, isSuccess: false);
  }

  /// Si la operacion fallo
  bool get isFailure => !isSuccess;

  /// Obtiene el valor, lanzando una excepcion si la operacion fallo.
  T get value {
    if (isFailure) {
      throw StateError('Cannot get value from a failed result. Error: $error');
    }
    return _value as T;
  }

  /// Obtiene el valor o un valor por defecto si la operacion fallo.
  T valueOr(T defaultValue) => isSuccess ? _value as T : defaultValue;

  /// Obtiene el valor o null si la operacion fallo.
  T? get valueOrNull => isSuccess ? _value : null;

  /// Mapea el valor si la operacion tuvo exito.
  RetryResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess) {
      return RetryResult.success(mapper(_value as T));
    }
    return RetryResult.failure(error, stackTrace);
  }

  /// Ejecuta una accion segun el resultado.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(dynamic error, StackTrace? stackTrace) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(_value as T);
    }
    return onFailure(error, stackTrace);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'RetryResult.success($_value)';
    }
    return 'RetryResult.failure($error)';
  }
}

/// Extension para facilitar el uso de RetryPolicy en Futures.
extension RetryFutureExtension<T> on Future<T> {
  /// Ejecuta este Future con la politica de reintentos especificada.
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await apiClient.getData()
  ///     .withRetry(RetryPolicy.network);
  /// ```
  Future<T> withRetry(
    RetryPolicy policy, {
    RetryCallback? onRetry,
  }) {
    return policy.execute(() => this, onRetry: onRetry);
  }

  /// Ejecuta este Future con la politica por defecto de red.
  Future<T> withNetworkRetry({RetryCallback? onRetry}) {
    return RetryPolicy.network.execute(() => this, onRetry: onRetry);
  }
}
