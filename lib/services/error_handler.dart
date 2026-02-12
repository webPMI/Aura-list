
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/exceptions/app_exceptions.dart';
import 'logger_service.dart';

export '../core/exceptions/app_exceptions.dart';

enum ErrorType {
  database,
  network,
  auth,
  validation,
  sync,
  unknown,
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final bool isRetryable;

  AppError({
    required this.type,
    required this.severity,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    bool? isRetryable,
  }) : timestamp = DateTime.now(),
       isRetryable = isRetryable ?? _defaultIsRetryable(type, originalError);

  static bool _defaultIsRetryable(ErrorType type, dynamic originalError) {
    if (originalError is AppException) {
      return originalError.isRetryable;
    }
    switch (type) {
      case ErrorType.network:
      case ErrorType.sync:
        return true;
      case ErrorType.auth:
        return true; // Most auth errors can be retried
      case ErrorType.database:
      case ErrorType.validation:
      case ErrorType.unknown:
        return false;
    }
  }

  String get displayMessage => userMessage ?? _getDefaultUserMessage();

  String _getDefaultUserMessage() {
    switch (type) {
      case ErrorType.database:
        return 'Error al guardar datos localmente.';
      case ErrorType.network:
        return 'Sin conexion. Los cambios se guardaran localmente.';
      case ErrorType.auth:
        return 'Error de autenticacion.';
      case ErrorType.validation:
        return 'Datos invalidos.';
      case ErrorType.sync:
        return 'Error de sincronizacion. Se reintentara automaticamente.';
      case ErrorType.unknown:
        return 'Ocurrio un error inesperado.';
    }
  }

  String get logPrefix {
    switch (severity) {
      case ErrorSeverity.info:
        return '[INFO]';
      case ErrorSeverity.warning:
        return '[WARNING]';
      case ErrorSeverity.error:
        return '[ERROR]';
      case ErrorSeverity.critical:
        return '[CRITICAL]';
    }
  }

  AppException toAppException() {
    if (originalError is AppException) {
      return originalError as AppException;
    }

    switch (type) {
      case ErrorType.network:
        return NetworkException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );
      case ErrorType.database:
        return HiveStorageException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );
      case ErrorType.auth:
        return AuthException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );
      case ErrorType.validation:
        return ValidationException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
        );
      case ErrorType.sync:
        return SyncException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          direction: SyncDirection.upload,
          isRetryable: isRetryable,
        );
      case ErrorType.unknown:
        return UnknownException(
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
        );
    }
  }
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorStream = StreamController.broadcast();
  final StreamController<AppException> _appExceptionStream = StreamController.broadcast();
  final LoggerService _logger = LoggerService();
  static const String _tag = 'ErrorHandler';

  Stream<AppError> get errorStream => _errorStream.stream;
  Stream<AppException> get appExceptionStream => _appExceptionStream.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  AppError? get lastError => _errorHistory.isNotEmpty ? _errorHistory.last : null;
  AppException? get lastAppException => lastError?.toAppException();

  AppError handle(
    dynamic error, {
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.error,
    String? message,
    String? userMessage,
    StackTrace? stackTrace,
    bool shouldLog = true,
  }) {
    final appError = _createAppError(
      error,
      type: type,
      severity: severity,
      message: message,
      userMessage: userMessage,
      stackTrace: stackTrace,
    );

    _errorHistory.add(appError);
    _errorStream.add(appError);
    _appExceptionStream.add(appError.toAppException());

    if (shouldLog) {
      _logError(appError);
    }

    return appError;
  }

  AppError handleException(
    AppException exception, {
    ErrorSeverity severity = ErrorSeverity.error,
    bool shouldLog = true,
  }) {
    final type = _detectTypeFromException(exception);
    final appError = AppError(
      type: type,
      severity: severity,
      message: exception.message,
      userMessage: exception.userMessage,
      originalError: exception,
      stackTrace: exception.stackTrace,
      isRetryable: exception.isRetryable,
    );

    _errorHistory.add(appError);
    _errorStream.add(appError);
    _appExceptionStream.add(exception);

    if (shouldLog) {
      _logError(appError);
    }

    return appError;
  }

  AppError _createAppError(
    dynamic error, {
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.error,
    String? message,
    String? userMessage,
    StackTrace? stackTrace,
  }) {
    // Si el error es un AppException, extraer informacion
    if (error is AppException) {
      final detectedType = type ?? _detectTypeFromException(error);
      return AppError(
        type: detectedType,
        severity: severity,
        message: message ?? error.message,
        userMessage: userMessage ?? error.userMessage,
        originalError: error,
        stackTrace: stackTrace ?? error.stackTrace,
        isRetryable: error.isRetryable,
      );
    }

    // Detectar tipo automaticamente si no se especifica
    final errorType = type ?? _detectErrorType(error);
    final errorMessage = message ?? error.toString();

    return AppError(
      type: errorType,
      severity: severity,
      message: errorMessage,
      userMessage: userMessage,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  ErrorType _detectTypeFromException(AppException exception) {
    if (exception is NetworkException) return ErrorType.network;
    if (exception is FirebasePermissionException) return ErrorType.auth;
    if (exception is HiveStorageException) return ErrorType.database;
    if (exception is AuthException) return ErrorType.auth;
    if (exception is ValidationException) return ErrorType.validation;
    if (exception is SyncException) return ErrorType.sync;
    return ErrorType.unknown;
  }

  ErrorType _detectErrorType(dynamic error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied' || error.code == 'unauthenticated') {
        return ErrorType.auth;
      }
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return ErrorType.network;
      }
      return ErrorType.network; // Por defecto tratamos Firebase como network
    } else if (error is TimeoutException) {
      return ErrorType.network;
    } else if (error.toString().contains('auth') ||
        error.toString().contains('Auth')) {
      return ErrorType.auth;
    } else if (error.toString().contains('Hive') ||
        error.toString().contains('database') ||
        error.toString().contains('Database')) {
      return ErrorType.database;
    } else if (error.toString().contains('valid') ||
        error.toString().contains('Valid')) {
      return ErrorType.validation;
    } else if (error.toString().contains('sync') ||
        error.toString().contains('Sync')) {
      return ErrorType.sync;
    }
    return ErrorType.unknown;
  }

  void _logError(AppError error) {
    // Convertir ErrorSeverity a LogLevel
    final logLevel = _severityToLogLevel(error.severity);
    final typeStr = error.type.name.toUpperCase();

    // Construir metadata para el log
    final metadata = <String, dynamic>{
      'errorType': typeStr,
      'isRetryable': error.isRetryable,
      if (error.userMessage != null) 'userMessage': error.userMessage,
    };

    // Usar LoggerService para registro estructurado
    switch (logLevel) {
      case LogLevel.info:
        _logger.info(_tag, error.message, metadata: metadata);
        break;
      case LogLevel.warning:
        _logger.warning(_tag, error.message, metadata: metadata);
        break;
      case LogLevel.error:
        _logger.error(
          _tag,
          error.message,
          error: error.originalError,
          stack: error.stackTrace,
          metadata: metadata,
        );
        break;
      case LogLevel.critical:
        _logger.critical(
          _tag,
          error.message,
          error: error.originalError,
          stack: error.stackTrace,
          metadata: metadata,
        );
        break;
      case LogLevel.debug:
        _logger.debug(_tag, error.message, metadata: metadata);
        break;
    }
  }

  LogLevel _severityToLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return LogLevel.info;
      case ErrorSeverity.warning:
        return LogLevel.warning;
      case ErrorSeverity.error:
        return LogLevel.error;
      case ErrorSeverity.critical:
        return LogLevel.critical;
    }
  }

  bool shouldRetry(dynamic error) {
    if (error is AppException) {
      return error.isRetryable;
    }
    if (error is AppError) {
      return error.isRetryable;
    }
    if (error is FirebaseException) {
      return shouldRetryFirebaseError(error);
    }
    if (error is TimeoutException) {
      return true;
    }
    return false;
  }

  bool shouldRetryFirebaseError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'unknown' ||
        error.code == 'cancelled' ||
        error.code == 'resource-exhausted';
  }

  AppException toAppException(dynamic error, {StackTrace? stackTrace}) {
    if (error is AppException) return error;
    if (error is AppError) return error.toAppException();
    return error.toAppException(stackTrace: stackTrace);
  }

  List<AppError> getErrorsByType(ErrorType type, {int limit = 50}) {
    return _errorHistory
        .where((e) => e.type == type)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  List<AppError> getErrorsBySeverity(ErrorSeverity severity, {int limit = 50}) {
    return _errorHistory
        .where((e) => e.severity == severity)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  Map<ErrorType, int> getErrorCountsByType({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final recentErrors = _errorHistory.where((e) => e.timestamp.isAfter(cutoff));

    final counts = <ErrorType, int>{};
    for (final type in ErrorType.values) {
      counts[type] = recentErrors.where((e) => e.type == type).length;
    }
    return counts;
  }

  void clearHistory() {
    _errorHistory.clear();
  }

  void dispose() {
    _errorStream.close();
    _appExceptionStream.close();
  }
}

final errorHandlerProvider = Provider<ErrorHandler>((ref) => ErrorHandler());

final errorStreamProvider = StreamProvider<AppError>((ref) {
  return ref.watch(errorHandlerProvider).errorStream;
});

final appExceptionStreamProvider = StreamProvider<AppException>((ref) {
  return ref.watch(errorHandlerProvider).appExceptionStream;
});

extension ErrorHandlerExtension on dynamic {
  void handleError({
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.error,
    String? message,
    String? userMessage,
    StackTrace? stackTrace,
  }) {
    ErrorHandler().handle(
      this,
      type: type,
      severity: severity,
      message: message,
      userMessage: userMessage,
      stackTrace: stackTrace,
    );
  }
}

extension FutureErrorHandlerExtension<T> on Future<T> {
  Future<T> handleErrors({
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.error,
    String? message,
    String? userMessage,
  }) async {
    try {
      return await this;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: type,
        severity: severity,
        message: message,
        userMessage: userMessage,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<T?> handleErrorsOrNull({
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.error,
    String? message,
    String? userMessage,
  }) async {
    try {
      return await this;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: type,
        severity: severity,
        message: message,
        userMessage: userMessage,
        stackTrace: stack,
      );
      return null;
    }
  }
}
