/// Sistema centralizado de logging para la aplicacion.
///
/// Proporciona diferentes niveles de log, seguimiento de rendimiento,
/// y preparacion para envio a Crashlytics en produccion.
///
/// Ejemplo de uso:
/// ```dart
/// final logger = LoggerService();
/// logger.info('DatabaseService', 'Tarea guardada exitosamente');
/// logger.error('AuthService', 'Error de autenticacion', error: e, stack: stackTrace);
/// ```
library;

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as pkg_logger;

/// Niveles de log disponibles en orden de severidad
enum LogLevel {
  debug,    // Informacion detallada para debugging
  info,     // Eventos normales de la aplicacion
  warning,  // Situaciones potencialmente problematicas
  error,    // Errores que afectan operaciones individuales
  critical, // Errores criticos que pueden afectar la app
}

/// Representa una entrada de log individual
class LogEntry {
  /// Nivel de severidad del log
  final LogLevel level;

  /// Tag que identifica el origen (ej: 'DatabaseService', 'AuthService')
  final String tag;

  /// Mensaje descriptivo del evento
  final String message;

  /// Momento en que ocurrio el evento
  final DateTime timestamp;

  /// Duracion de la operacion (para logs de rendimiento)
  final Duration? duration;

  /// Metadata adicional para contexto
  final Map<String, dynamic>? metadata;

  /// Error original si aplica
  final dynamic error;

  /// Stack trace si aplica
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.duration,
    this.metadata,
    this.error,
    this.stackTrace,
  });

  /// Obtiene el emoji y prefijo segun el nivel
  String get levelPrefix {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.critical:
        return '[CRITICAL]';
    }
  }

  /// Convierte a formato legible para consola
  String toConsoleFormat() {
    final time = timestamp.toString().substring(11, 23);
    final buffer = StringBuffer();

    buffer.writeln('$levelPrefix [$time] $tag');
    buffer.writeln('  $message');

    if (duration != null) {
      buffer.writeln('  Duration: ${duration!.inMilliseconds}ms');
    }

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('  Metadata: $metadata');
    }

    if (error != null) {
      buffer.writeln('  Error: $error');
    }

    if (stackTrace != null && (level == LogLevel.error || level == LogLevel.critical)) {
      final lines = stackTrace.toString().split('\n').take(5).join('\n    ');
      buffer.writeln('  Stack:\n    $lines');
    }

    return buffer.toString();
  }

  /// Convierte a Map para serializacion
  Map<String, dynamic> toMap() => {
    'level': level.name,
    'tag': tag,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    if (duration != null) 'durationMs': duration!.inMilliseconds,
    if (metadata != null) 'metadata': metadata,
    if (error != null) 'error': error.toString(),
  };
}

/// Servicio centralizado de logging (Singleton)
///
/// Proporciona metodos para registrar eventos con diferentes niveles,
/// mantiene un historial de logs recientes, y prepara datos para Crashlytics.
class LoggerService {
  // Singleton pattern
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal() {
    _logger = pkg_logger.Logger(
      printer: pkg_logger.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: pkg_logger.DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: kDebugMode ? pkg_logger.DevelopmentFilter() : pkg_logger.ProductionFilter(),
    );
  }

  late final pkg_logger.Logger _logger;

  /// Buffer circular para logs recientes (maximo 500 entradas)
  final Queue<LogEntry> _logBuffer = Queue<LogEntry>();
  static const int _maxBufferSize = 500;

  /// Nivel minimo de log a registrar
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Configura el nivel minimo de log
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Registra un mensaje de debug
  void debug(String tag, String message, {Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, tag, message, metadata: metadata);
  }

  /// Registra un mensaje informativo
  void info(String tag, String message, {Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, tag, message, metadata: metadata);
  }

  /// Registra una advertencia
  void warning(String tag, String message, {Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, tag, message, metadata: metadata);
  }

  /// Registra un error
  void error(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stack,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.error,
      tag,
      message,
      error: error,
      stackTrace: stack,
      metadata: metadata,
    );
  }

  /// Registra un error critico
  void critical(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stack,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.critical,
      tag,
      message,
      error: error,
      stackTrace: stack,
      metadata: metadata,
    );
  }

  /// Metodo interno para registrar logs
  void _log(
    LogLevel level,
    String tag,
    String message, {
    Duration? duration,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // Filtrar por nivel minimo
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );

    // Agregar al buffer
    _addToBuffer(entry);

    // Imprimir en consola (solo en debug)
    if (kDebugMode) {
      _printToConsole(entry);
    }
  }

  /// Agrega entrada al buffer circular
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    while (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeFirst();
    }
  }

  /// Imprime entrada en consola usando el paquete logger
  void _printToConsole(LogEntry entry) {
    final fullMessage = _buildLogMessage(entry);

    switch (entry.level) {
      case LogLevel.debug:
        _logger.d(fullMessage);
        break;
      case LogLevel.info:
        _logger.i(fullMessage);
        break;
      case LogLevel.warning:
        _logger.w(fullMessage);
        break;
      case LogLevel.error:
        _logger.e(fullMessage, error: entry.error, stackTrace: entry.stackTrace);
        break;
      case LogLevel.critical:
        _logger.f(fullMessage, error: entry.error, stackTrace: entry.stackTrace);
        break;
    }
  }

  /// Construye mensaje completo para el logger
  String _buildLogMessage(LogEntry entry) {
    final buffer = StringBuffer();
    buffer.write('[${entry.tag}] ${entry.message}');

    if (entry.duration != null) {
      buffer.write(' (${entry.duration!.inMilliseconds}ms)');
    }

    if (entry.metadata != null && entry.metadata!.isNotEmpty) {
      buffer.write('\n  Metadata: ${entry.metadata}');
    }

    return buffer.toString();
  }

  // ==================== Performance Tracking ====================

  /// Inicia el seguimiento de una operacion
  ///
  /// Retorna un Stopwatch que debe pasarse a [endOperation]
  ///
  /// Ejemplo:
  /// ```dart
  /// final stopwatch = logger.startOperation('loadTasks');
  /// await loadTasks();
  /// logger.endOperation(stopwatch, 'loadTasks');
  /// ```
  Stopwatch startOperation(String operationName) {
    debug('Performance', 'Starting: $operationName');
    return Stopwatch()..start();
  }

  /// Finaliza el seguimiento de una operacion
  ///
  /// [stopwatch] - El Stopwatch retornado por [startOperation]
  /// [operationName] - Nombre de la operacion (debe coincidir con startOperation)
  /// [success] - Si la operacion fue exitosa
  void endOperation(
    Stopwatch stopwatch,
    String operationName, {
    bool success = true,
    Map<String, dynamic>? metadata,
  }) {
    stopwatch.stop();
    final duration = stopwatch.elapsed;

    final level = success ? LogLevel.info : LogLevel.warning;
    final status = success ? 'completed' : 'failed';

    _log(
      level,
      'Performance',
      '$operationName $status',
      duration: duration,
      metadata: {
        'operation': operationName,
        'success': success,
        'durationMs': duration.inMilliseconds,
        ...?metadata,
      },
    );

    // Log adicional si la operacion fue muy lenta (> 1 segundo)
    if (duration.inMilliseconds > 1000) {
      warning(
        'Performance',
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
        metadata: {'threshold': 1000},
      );
    }
  }

  // ==================== Log Retrieval ====================

  /// Obtiene los logs recientes del buffer
  ///
  /// [count] - Numero maximo de logs a retornar (default: 100)
  /// [minLevel] - Nivel minimo de logs a incluir
  List<LogEntry> getRecentLogs({int count = 100, LogLevel? minLevel}) {
    var logs = _logBuffer.toList().reversed.toList();

    if (minLevel != null) {
      logs = logs.where((e) => e.level.index >= minLevel.index).toList();
    }

    return logs.take(count).toList();
  }

  /// Obtiene logs filtrados por tag
  List<LogEntry> getLogsByTag(String tag, {int count = 100}) {
    return _logBuffer
        .where((e) => e.tag == tag)
        .toList()
        .reversed
        .take(count)
        .toList();
  }

  /// Exporta logs recientes como texto formateado (util para debugging)
  String exportLogs({int count = 100}) {
    final logs = getRecentLogs(count: count);
    final buffer = StringBuffer();

    buffer.writeln('=== AuraList Log Export ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('');

    for (final log in logs) {
      buffer.writeln(log.toConsoleFormat());
    }

    return buffer.toString();
  }

  /// Limpia el buffer de logs
  void clearLogs() {
    _logBuffer.clear();
    info('LoggerService', 'Log buffer cleared');
  }

  // ==================== Crashlytics Integration ====================

  /// Callback para enviar logs a Crashlytics
  /// Se configura desde CrashlyticsService
  Future<void> Function(LogEntry entry)? onCrashlyticsLog;

  /// Envia una entrada a Crashlytics si esta configurado
  Future<void> sendToCrashlytics(LogEntry entry) async {
    if (onCrashlyticsLog != null) {
      await onCrashlyticsLog!(entry);
    }
  }

  /// Envia todos los logs de error/critical recientes a Crashlytics
  Future<void> flushErrorsToCrashlytics() async {
    if (onCrashlyticsLog == null) return;

    final errorLogs = getRecentLogs(minLevel: LogLevel.error);
    for (final log in errorLogs) {
      await sendToCrashlytics(log);
    }
  }
}
