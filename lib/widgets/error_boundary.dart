/// Widget que captura errores de widgets hijos y muestra una UI amigable.
///
/// [ErrorBoundary] envuelve widgets que pueden lanzar excepciones durante
/// el build o en streams, y proporciona:
/// - Una UI de error por defecto o personalizable
/// - Boton de reintentar
/// - Logging automatico de errores
/// - Integracion con el sistema de excepciones de la app
///
/// Ejemplo de uso:
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
///   onRetry: () => ref.refresh(myProvider),
/// )
/// ```
///
/// Con builder personalizado:
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
///   errorBuilder: (error, retry) => CustomErrorWidget(
///     message: error.displayMessage,
///     onRetry: retry,
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_handler.dart';

/// Widget que captura errores y muestra una UI amigable.
class ErrorBoundary extends ConsumerStatefulWidget {
  /// Widget hijo que puede lanzar errores
  final Widget child;

  /// Builder personalizado para la UI de error
  final Widget Function(AppException error, VoidCallback retry)? errorBuilder;

  /// Callback cuando el usuario presiona reintentar
  final VoidCallback? onRetry;

  /// Si debe mostrar detalles tecnicos (solo en debug)
  final bool showDetails;

  /// Mensaje de error por defecto
  final String? defaultErrorMessage;

  /// Si debe reportar el error al ErrorHandler
  final bool reportError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onRetry,
    this.showDetails = false,
    this.defaultErrorMessage,
    this.reportError = true,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  AppException? _error;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Listen to Flutter errors
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    final error = details.exception;
    final appException = error is AppException
        ? error
        : UnknownException.from(error, stackTrace: details.stack);

    if (widget.reportError) {
      ref.read(errorHandlerProvider).handle(
            error,
            message: details.exceptionAsString(),
            stackTrace: details.stack,
          );
    }

    if (mounted) {
      setState(() {
        _error = appException;
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _hasError = false;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _retry);
      }
      return _DefaultErrorWidget(
        error: _error!,
        onRetry: widget.onRetry != null ? _retry : null,
        showDetails: widget.showDetails,
        defaultMessage: widget.defaultErrorMessage,
      );
    }

    return widget.child;
  }
}

/// Widget de error por defecto con estilo consistente.
class _DefaultErrorWidget extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;
  final bool showDetails;
  final String? defaultMessage;

  const _DefaultErrorWidget({
    required this.error,
    this.onRetry,
    this.showDetails = false,
    this.defaultMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForError(error),
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              _getTitleForError(error),
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              defaultMessage ?? error.displayMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Technical details (debug only)
            if (showDetails) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            // Retry button
            if (onRetry != null && error.isRetryable) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],

            // Non-retryable hint
            if (!error.isRetryable) ...[
              const SizedBox(height: 16),
              Text(
                _getHintForError(error),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForError(AppException error) {
    if (error is NetworkException) return Icons.wifi_off;
    if (error is FirebasePermissionException) return Icons.lock_outline;
    if (error is HiveStorageException) return Icons.storage;
    if (error is AuthException) return Icons.person_off;
    if (error is ValidationException) return Icons.warning_amber;
    if (error is SyncException) return Icons.sync_problem;
    return Icons.error_outline;
  }

  String _getTitleForError(AppException error) {
    if (error is NetworkException) return 'Sin conexion';
    if (error is FirebasePermissionException) return 'Acceso denegado';
    if (error is HiveStorageException) return 'Error de almacenamiento';
    if (error is AuthException) return 'Error de sesion';
    if (error is ValidationException) return 'Datos invalidos';
    if (error is SyncException) return 'Error de sincronizacion';
    return 'Algo salio mal';
  }

  String _getHintForError(AppException error) {
    if (error is FirebasePermissionException) {
      return 'Verifica tus permisos o inicia sesion de nuevo.';
    }
    if (error is AuthException) {
      return 'Intenta cerrar sesion e iniciar de nuevo.';
    }
    if (error is ValidationException) {
      return 'Revisa los datos ingresados.';
    }
    return 'Si el problema persiste, reinicia la aplicacion.';
  }
}

/// Widget de error compacto para listas e items.
class ErrorCard extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorCard({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.displayMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onRetry != null && error.isRetryable)
              IconButton(
                icon: const Icon(Icons.refresh),
                color: colorScheme.onErrorContainer,
                onPressed: onRetry,
                tooltip: 'Reintentar',
              ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close),
                color: colorScheme.onErrorContainer,
                onPressed: onDismiss,
                tooltip: 'Descartar',
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner de error para mostrar en la parte superior/inferior.
class ErrorBanner extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                _getIconForError(),
                color: colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.displayMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onRetry != null && error.isRetryable)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Reintentar',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: colorScheme.onErrorContainer,
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForError() {
    if (error is NetworkException) return Icons.wifi_off;
    if (error is SyncException) return Icons.sync_problem;
    return Icons.error_outline;
  }
}

/// Widget para estados de carga/error/exito.
class AsyncErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool compact;

  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final appError = error is AppException
        ? error as AppException
        : error.toAppException(stackTrace: stackTrace);

    if (compact) {
      return ErrorCard(
        error: appError,
        onRetry: onRetry,
      );
    }

    return _DefaultErrorWidget(
      error: appError,
      onRetry: onRetry,
    );
  }
}

/// Muestra un SnackBar de error.
void showErrorSnackBar(
  BuildContext context,
  AppException error, {
  VoidCallback? onRetry,
  Duration duration = const Duration(seconds: 4),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.displayMessage,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.errorContainer,
      duration: duration,
      action: onRetry != null && error.isRetryable
          ? SnackBarAction(
              label: 'Reintentar',
              textColor: colorScheme.onErrorContainer,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}

/// Muestra un dialogo de error.
Future<void> showErrorDialog(
  BuildContext context,
  AppException error, {
  String? title,
  VoidCallback? onRetry,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: colorScheme.error,
        size: 48,
      ),
      title: Text(title ?? 'Error'),
      content: Text(error.displayMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        if (onRetry != null && error.isRetryable)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Reintentar'),
          ),
      ],
    ),
  );
}

/// Extension para manejar errores en AsyncValue de Riverpod.
extension AsyncValueErrorExtension<T> on AsyncValue<T> {
  /// Construye un widget basado en el estado, con manejo de errores mejorado.
  Widget whenWithError({
    required Widget Function(T data) data,
    required Widget Function() loading,
    Widget Function(AppException error, VoidCallback? retry)? error,
    VoidCallback? onRetry,
    bool compact = false,
  }) {
    return when(
      data: data,
      loading: loading,
      error: (e, stack) {
        final appError = e is AppException
            ? e
            : e.toAppException(stackTrace: stack);

        if (error != null) {
          return error(appError, onRetry);
        }

        return AsyncErrorWidget(
          error: appError,
          stackTrace: stack,
          onRetry: onRetry,
          compact: compact,
        );
      },
    );
  }
}
