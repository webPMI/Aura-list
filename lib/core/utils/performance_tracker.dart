/// Utilidad para medir el rendimiento de operaciones asincronas.
///
/// Proporciona una forma sencilla de trackear tiempos de ejecucion
/// y registrar el resultado en el sistema de logging.
///
/// Ejemplo de uso:
/// ```dart
/// final tasks = await PerformanceTracker.track(
///   'loadAllTasks',
///   () => database.loadTasks(),
/// );
/// ```
library;

import '../../../services/logger_service.dart';

/// Clase de utilidad para medir y registrar rendimiento de operaciones
class PerformanceTracker {
  /// Tag usado para logs de rendimiento
  static const String _tag = 'Performance';

  /// Ejecuta una operacion asincrona y registra su duracion
  ///
  /// [operationName] - Nombre descriptivo de la operacion
  /// [operation] - Funcion asincrona a ejecutar
  /// [metadata] - Datos adicionales para incluir en el log
  /// [slowThresholdMs] - Umbral en ms para considerar la operacion lenta (default: 1000)
  ///
  /// Ejemplo:
  /// ```dart
  /// final result = await PerformanceTracker.track(
  ///   'fetchUserData',
  ///   () => api.getUser(userId),
  ///   metadata: {'userId': userId},
  /// );
  /// ```
  static Future<T> track<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
    int slowThresholdMs = 1000,
  }) async {
    final logger = LoggerService();
    final stopwatch = Stopwatch()..start();

    logger.debug(_tag, 'Starting: $operationName', metadata: metadata);

    try {
      final result = await operation();
      stopwatch.stop();

      final durationMs = stopwatch.elapsedMilliseconds;
      final extendedMetadata = {
        'operation': operationName,
        'durationMs': durationMs,
        'success': true,
        ...?metadata,
      };

      if (durationMs > slowThresholdMs) {
        logger.warning(
          _tag,
          'Slow operation: $operationName completed in ${durationMs}ms (threshold: ${slowThresholdMs}ms)',
          metadata: extendedMetadata,
        );
      } else {
        logger.info(
          _tag,
          '$operationName completed in ${durationMs}ms',
          metadata: extendedMetadata,
        );
      }

      return result;
    } catch (e, stack) {
      stopwatch.stop();

      logger.error(
        _tag,
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stack: stack,
        metadata: {
          'operation': operationName,
          'durationMs': stopwatch.elapsedMilliseconds,
          'success': false,
          ...?metadata,
        },
      );

      rethrow;
    }
  }

  /// Ejecuta una operacion sincrona y registra su duracion
  ///
  /// [operationName] - Nombre descriptivo de la operacion
  /// [operation] - Funcion sincrona a ejecutar
  /// [metadata] - Datos adicionales para incluir en el log
  /// [slowThresholdMs] - Umbral en ms para considerar la operacion lenta (default: 100)
  static T trackSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
    int slowThresholdMs = 100,
  }) {
    final logger = LoggerService();
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      final durationMs = stopwatch.elapsedMilliseconds;

      if (durationMs > slowThresholdMs) {
        logger.warning(
          _tag,
          'Slow sync operation: $operationName took ${durationMs}ms (threshold: ${slowThresholdMs}ms)',
          metadata: {
            'operation': operationName,
            'durationMs': durationMs,
            ...?metadata,
          },
        );
      } else {
        logger.debug(
          _tag,
          '$operationName completed in ${durationMs}ms',
          metadata: metadata,
        );
      }

      return result;
    } catch (e, stack) {
      stopwatch.stop();

      logger.error(
        _tag,
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms',
        error: e,
        stack: stack,
        metadata: {
          'operation': operationName,
          'durationMs': stopwatch.elapsedMilliseconds,
          ...?metadata,
        },
      );

      rethrow;
    }
  }

  /// Crea un scope de tracking que puede usarse con try/finally
  ///
  /// Ejemplo:
  /// ```dart
  /// final tracker = PerformanceTracker.scope('complexOperation');
  /// try {
  ///   await step1();
  ///   await step2();
  ///   tracker.complete();
  /// } catch (e) {
  ///   tracker.fail(e);
  ///   rethrow;
  /// }
  /// ```
  static PerformanceScope scope(String operationName, {Map<String, dynamic>? metadata}) {
    return PerformanceScope._(operationName, metadata);
  }
}

/// Representa un scope de medicion de rendimiento
///
/// Permite trackear operaciones que no pueden envolverse facilmente
/// en un callback.
class PerformanceScope {
  final String operationName;
  final Map<String, dynamic>? metadata;
  final Stopwatch _stopwatch;
  final LoggerService _logger;
  bool _completed = false;

  PerformanceScope._(this.operationName, this.metadata)
      : _stopwatch = Stopwatch()..start(),
        _logger = LoggerService() {
    _logger.debug('Performance', 'Starting scope: $operationName', metadata: metadata);
  }

  /// Duracion transcurrida hasta el momento
  Duration get elapsed => _stopwatch.elapsed;

  /// Marca la operacion como completada exitosamente
  void complete({Map<String, dynamic>? additionalMetadata}) {
    if (_completed) return;
    _completed = true;
    _stopwatch.stop();

    _logger.info(
      'Performance',
      '$operationName completed in ${_stopwatch.elapsedMilliseconds}ms',
      metadata: {
        'operation': operationName,
        'durationMs': _stopwatch.elapsedMilliseconds,
        'success': true,
        ...?metadata,
        ...?additionalMetadata,
      },
    );
  }

  /// Marca la operacion como fallida
  void fail(dynamic error, [StackTrace? stack]) {
    if (_completed) return;
    _completed = true;
    _stopwatch.stop();

    _logger.error(
      'Performance',
      '$operationName failed after ${_stopwatch.elapsedMilliseconds}ms',
      error: error,
      stack: stack,
      metadata: {
        'operation': operationName,
        'durationMs': _stopwatch.elapsedMilliseconds,
        'success': false,
        ...?metadata,
      },
    );
  }
}
