/// Providers de Riverpod para servicios de logging y monitoreo.
///
/// Proporciona acceso global a LoggerService y CrashlyticsService
/// a traves de dependency injection con Riverpod.
///
/// Ejemplo de uso:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final logger = ref.watch(loggerServiceProvider);
///     logger.info('MyWidget', 'Widget built');
///     return Container();
///   }
/// }
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logger_service.dart';
import '../services/crashlytics_service.dart';

/// Provider para el servicio de logging centralizado
///
/// Uso:
/// ```dart
/// final logger = ref.watch(loggerServiceProvider);
/// logger.info('Tag', 'Message');
/// ```
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

/// Provider para el servicio de Crashlytics
///
/// Uso:
/// ```dart
/// final crashlytics = ref.watch(crashlyticsServiceProvider);
/// await crashlytics.recordError(error, stack);
/// ```
final crashlyticsServiceProvider = Provider<CrashlyticsService>((ref) {
  return CrashlyticsService();
});

/// Provider para obtener logs recientes (util para pantallas de debug)
///
/// Uso:
/// ```dart
/// final logs = ref.watch(recentLogsProvider);
/// // Retorna los ultimos 100 logs
/// ```
final recentLogsProvider = Provider<List<LogEntry>>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  return logger.getRecentLogs(count: 100);
});

/// Provider para verificar si Crashlytics esta inicializado
final crashlyticsInitializedProvider = Provider<bool>((ref) {
  final crashlytics = ref.watch(crashlyticsServiceProvider);
  return crashlytics.isInitialized;
});

/// Extension para facilitar el logging desde providers
extension LoggerRefExtension on Ref {
  /// Acceso rapido al logger
  LoggerService get logger => read(loggerServiceProvider);

  /// Log de debug rapido
  void logDebug(String tag, String message, {Map<String, dynamic>? metadata}) {
    logger.debug(tag, message, metadata: metadata);
  }

  /// Log de info rapido
  void logInfo(String tag, String message, {Map<String, dynamic>? metadata}) {
    logger.info(tag, message, metadata: metadata);
  }

  /// Log de warning rapido
  void logWarning(
    String tag,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    logger.warning(tag, message, metadata: metadata);
  }

  /// Log de error rapido
  void logError(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stack,
    Map<String, dynamic>? metadata,
  }) {
    logger.error(tag, message, error: error, stack: stack, metadata: metadata);
  }
}

/// Extension para facilitar el logging desde widgets
extension LoggerWidgetRefExtension on WidgetRef {
  /// Acceso rapido al logger
  LoggerService get logger => read(loggerServiceProvider);

  /// Log de debug rapido
  void logDebug(String tag, String message, {Map<String, dynamic>? metadata}) {
    logger.debug(tag, message, metadata: metadata);
  }

  /// Log de info rapido
  void logInfo(String tag, String message, {Map<String, dynamic>? metadata}) {
    logger.info(tag, message, metadata: metadata);
  }

  /// Log de warning rapido
  void logWarning(
    String tag,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    logger.warning(tag, message, metadata: metadata);
  }

  /// Log de error rapido
  void logError(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stack,
    Map<String, dynamic>? metadata,
  }) {
    logger.error(tag, message, error: error, stack: stack, metadata: metadata);
  }
}
