/// Widget que consume errores del errorStateProvider y los muestra en pantalla.
///
/// [ErrorBoundaryConsumer] se envuelve alrededor de pantallas criticas para:
/// - Mostrar errores no descartados automaticamente (criticos y de error)
/// - Permitir descarte manual de errores
/// - Mostrar banner/snackbar segun el tipo de error
/// - Prevenir fallas silenciosas
///
/// Ejemplo de uso en una pantalla:
/// ```dart
/// class MyScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ErrorBoundaryConsumer(
///       child: Scaffold(
///         appBar: AppBar(title: Text('Mi Pantalla')),
///         body: MyContent(),
///       ),
///     );
///   }
/// }
/// ```
///
/// Con configuracion personalizada:
/// ```dart
/// ErrorBoundaryConsumer(
///   showAsSnackBar: true,
///   position: ErrorPosition.bottom,
///   child: MyWidget(),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_provider.dart';
import '../services/error_handler.dart';
import 'error_boundary.dart';

/// Posicion donde mostrar el banner de error
enum ErrorPosition {
  /// Parte superior de la pantalla
  top,

  /// Parte inferior de la pantalla
  bottom,
}

/// Widget que consume errores del estado global y los muestra.
///
/// Escucha el errorStateProvider y muestra errores criticos y de error
/// que no se auto-descartan. Los errores de info/warning se auto-descartan
/// automaticamente despues de 10 segundos.
class ErrorBoundaryConsumer extends ConsumerStatefulWidget {
  /// Widget hijo a renderizar
  final Widget child;

  /// Si debe mostrar errores como SnackBar en lugar de banner
  final bool showAsSnackBar;

  /// Posicion del banner de error (solo si showAsSnackBar = false)
  final ErrorPosition position;

  /// Duracion del SnackBar si showAsSnackBar = true
  final Duration snackBarDuration;

  /// Si debe permitir reintentar la operacion
  final bool allowRetry;

  /// Callback personalizado cuando el usuario presiona reintentar
  final void Function(AppException error)? onRetry;

  /// Si debe mostrar solo el error mas reciente (true) o todos los errores (false)
  final bool showOnlyLatest;

  const ErrorBoundaryConsumer({
    super.key,
    required this.child,
    this.showAsSnackBar = false,
    this.position = ErrorPosition.top,
    this.snackBarDuration = const Duration(seconds: 4),
    this.allowRetry = true,
    this.onRetry,
    this.showOnlyLatest = true,
  });

  @override
  ConsumerState<ErrorBoundaryConsumer> createState() =>
      _ErrorBoundaryConsumerState();
}

class _ErrorBoundaryConsumerState extends ConsumerState<ErrorBoundaryConsumer> {
  /// Set de errores que ya se mostraron como SnackBar para evitar duplicados
  final Set<AppException> _shownSnackBarErrors = {};

  @override
  Widget build(BuildContext context) {
    final errorState = ref.watch(errorStateProvider);

    // Si se configuro para mostrar como SnackBar
    if (widget.showAsSnackBar) {
      _showErrorsAsSnackBar(errorState);
      return widget.child;
    }

    // Si no hay errores, solo mostrar el hijo
    if (!errorState.hasErrors) {
      return widget.child;
    }

    // Mostrar errores como banner
    return _buildWithErrorBanner(errorState);
  }

  /// Muestra errores como SnackBar
  void _showErrorsAsSnackBar(ErrorState errorState) {
    if (!errorState.hasErrors) return;

    // Obtener el error actual si showOnlyLatest, o todos los errores
    final errorsToShow = widget.showOnlyLatest
        ? [errorState.currentError!]
        : errorState.errors;

    for (final error in errorsToShow) {
      // Evitar mostrar el mismo error multiples veces
      if (_shownSnackBarErrors.contains(error)) continue;

      _shownSnackBarErrors.add(error);

      // Mostrar SnackBar despues del siguiente frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showErrorSnackBar(
          context,
          error,
          duration: widget.snackBarDuration,
          onRetry: widget.allowRetry && error.isRetryable
              ? () => _handleRetry(error)
              : null,
        );
      });
    }

    // Limpiar errores mostrados que ya no estan en el estado
    _shownSnackBarErrors
        .removeWhere((error) => !errorState.errors.contains(error));
  }

  /// Construye el widget con banner de error
  Widget _buildWithErrorBanner(ErrorState errorState) {
    final error = errorState.currentError!;

    // Determinar la severidad del error
    final severity = _detectErrorSeverity(error);

    // Construir el widget segun la posicion del banner
    if (widget.position == ErrorPosition.top) {
      return Column(
        children: [
          _buildErrorBanner(error, severity),
          Expanded(child: widget.child),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(child: widget.child),
          _buildErrorBanner(error, severity),
        ],
      );
    }
  }

  /// Construye el banner de error con estilo basado en severidad
  Widget _buildErrorBanner(AppException error, ErrorSeverity severity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores segun severidad
    final backgroundColor = _getBackgroundColor(severity, colorScheme);
    final iconColor = _getIconColor(severity, colorScheme);
    final textColor = _getTextColor(severity, colorScheme);

    return Material(
      color: backgroundColor,
      elevation: 4,
      child: SafeArea(
        bottom: widget.position == ErrorPosition.bottom,
        top: widget.position == ErrorPosition.top,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icono de severidad
              Icon(
                _getIconForSeverity(severity, error),
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),

              // Mensaje de error
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTitleForSeverity(severity),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.displayMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Boton de reintentar (si aplica)
              if (widget.allowRetry && error.isRetryable) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _handleRetry(error),
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],

              // Boton de descartar
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: textColor,
                onPressed: () => _handleDismiss(error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                tooltip: 'Descartar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detecta la severidad de un error
  ErrorSeverity _detectErrorSeverity(AppException error) {
    // Errores criticos
    if (error is FirebasePermissionException) return ErrorSeverity.critical;
    if (error is HiveStorageException) return ErrorSeverity.critical;
    if (error is AuthException && !error.isRetryable) {
      return ErrorSeverity.critical;
    }

    // Errores de advertencia (reintentables)
    if (error is NetworkException && error.isRetryable) {
      return ErrorSeverity.warning;
    }
    if (error is SyncException && error.isRetryable) {
      return ErrorSeverity.warning;
    }

    // Errores informativos
    if (error is ValidationException) return ErrorSeverity.info;

    // Errores no reintentables son criticos
    if (!error.isRetryable) return ErrorSeverity.critical;

    // Por defecto
    return ErrorSeverity.error;
  }

  /// Obtiene el color de fondo basado en la severidad
  Color _getBackgroundColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primaryContainer;
      case ErrorSeverity.warning:
        return colorScheme.tertiaryContainer;
      case ErrorSeverity.error:
        return colorScheme.errorContainer;
      case ErrorSeverity.critical:
        return colorScheme.error;
    }
  }

  /// Obtiene el color del icono basado en la severidad
  Color _getIconColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.onPrimaryContainer;
      case ErrorSeverity.warning:
        return colorScheme.onTertiaryContainer;
      case ErrorSeverity.error:
        return colorScheme.onErrorContainer;
      case ErrorSeverity.critical:
        return colorScheme.onError;
    }
  }

  /// Obtiene el color del texto basado en la severidad
  Color _getTextColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.onPrimaryContainer;
      case ErrorSeverity.warning:
        return colorScheme.onTertiaryContainer;
      case ErrorSeverity.error:
        return colorScheme.onErrorContainer;
      case ErrorSeverity.critical:
        return colorScheme.onError;
    }
  }

  /// Obtiene el icono basado en severidad y tipo de error
  IconData _getIconForSeverity(ErrorSeverity severity, AppException error) {
    // Iconos especificos por tipo de error
    if (error is NetworkException) return Icons.wifi_off;
    if (error is SyncException) return Icons.sync_problem;
    if (error is FirebasePermissionException) return Icons.lock_outline;
    if (error is HiveStorageException) return Icons.storage;
    if (error is AuthException) return Icons.person_off;
    if (error is ValidationException) return Icons.warning_amber;

    // Iconos por severidad
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.error;
    }
  }

  /// Obtiene el titulo basado en la severidad
  String _getTitleForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Informacion';
      case ErrorSeverity.warning:
        return 'Advertencia';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Error Critico';
    }
  }

  /// Maneja el reintento de la operacion
  void _handleRetry(AppException error) {
    if (widget.onRetry != null) {
      widget.onRetry!(error);
    }

    // Eliminar el error del estado
    ref.read(errorStateProvider.notifier).removeError(error);

    // Eliminar de errores mostrados
    _shownSnackBarErrors.remove(error);
  }

  /// Maneja el descarte manual del error
  void _handleDismiss(AppException error) {
    ref.read(errorStateProvider.notifier).removeError(error);
    _shownSnackBarErrors.remove(error);
  }
}

/// Extension para envolver facilmente widgets con ErrorBoundaryConsumer
extension ErrorBoundaryExtension on Widget {
  /// Envuelve este widget con ErrorBoundaryConsumer
  Widget withErrorBoundary({
    bool showAsSnackBar = false,
    ErrorPosition position = ErrorPosition.top,
    Duration snackBarDuration = const Duration(seconds: 4),
    bool allowRetry = true,
    void Function(AppException error)? onRetry,
    bool showOnlyLatest = true,
  }) {
    return ErrorBoundaryConsumer(
      showAsSnackBar: showAsSnackBar,
      position: position,
      snackBarDuration: snackBarDuration,
      allowRetry: allowRetry,
      onRetry: onRetry,
      showOnlyLatest: showOnlyLatest,
      child: this,
    );
  }
}
