/// Providers de Riverpod para el manejo de estados de error.
///
/// Este modulo proporciona providers para:
/// - Estado global de errores con soporte para multiples errores
/// - Notificaciones de errores en tiempo real
/// - Estados de error para operaciones asincronas
/// - Manejo de errores con reintentos automaticos
///
/// Ejemplo de uso en widgets:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   Widget build(BuildContext context, WidgetRef ref) {
///     final errorState = ref.watch(errorStateProvider);
///
///     return Column(
///       children: [
///         if (errorState.hasErrors)
///           ErrorBanner(
///             error: errorState.currentError!,
///             onDismiss: () => ref.read(errorStateProvider.notifier).clearCurrent(),
///           ),
///         // ... rest of UI
///       ],
///     );
///   }
/// }
/// ```
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_handler.dart';

// =============================================================================
// ERROR STATE
// =============================================================================

/// Estado inmutable que representa los errores actuales en la aplicacion.
class ErrorState {
  /// Lista de errores activos (mas reciente primero)
  final List<AppException> errors;

  /// Ultimo error ocurrido
  final AppException? lastError;

  /// Timestamp del ultimo error
  final DateTime? lastErrorTime;

  /// Si hay al menos un error activo
  bool get hasErrors => errors.isNotEmpty;

  /// Error actual (el mas reciente)
  AppException? get currentError => errors.isNotEmpty ? errors.first : null;

  /// Numero de errores activos
  int get errorCount => errors.length;

  /// Si hay errores reintentables
  bool get hasRetryableErrors => errors.any((e) => e.isRetryable);

  /// Errores filtrados por tipo
  List<T> getErrorsByType<T extends AppException>() {
    return errors.whereType<T>().toList();
  }

  /// Errores de red activos
  List<NetworkException> get networkErrors =>
      getErrorsByType<NetworkException>();

  /// Errores de autenticacion activos
  List<AuthException> get authErrors => getErrorsByType<AuthException>();

  /// Errores de sincronizacion activos
  List<SyncException> get syncErrors => getErrorsByType<SyncException>();

  const ErrorState({
    this.errors = const [],
    this.lastError,
    this.lastErrorTime,
  });

  /// Estado inicial sin errores
  static const ErrorState initial = ErrorState();

  /// Crea una copia con modificaciones
  ErrorState copyWith({
    List<AppException>? errors,
    AppException? lastError,
    DateTime? lastErrorTime,
  }) {
    return ErrorState(
      errors: errors ?? this.errors,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }

  @override
  String toString() =>
      'ErrorState(errors: ${errors.length}, hasErrors: $hasErrors)';
}

// =============================================================================
// ERROR STATE NOTIFIER
// =============================================================================

/// Notifier para manejar el estado de errores.
///
/// Proporciona metodos para agregar, eliminar y manejar errores
/// de manera centralizada en la aplicacion.
class ErrorStateNotifier extends StateNotifier<ErrorState> {
  final ErrorHandler _errorHandler;
  StreamSubscription<AppException>? _subscription;

  /// Maximo numero de errores a mantener en el estado
  static const int maxErrors = 10;

  /// Duracion por defecto para auto-descartar errores
  static const Duration defaultAutoDismiss = Duration(seconds: 10);

  ErrorStateNotifier(this._errorHandler) : super(ErrorState.initial) {
    _init();
  }

  void _init() {
    // Escuchar el stream de excepciones del ErrorHandler
    _subscription = _errorHandler.appExceptionStream.listen(_onNewError);
  }

  void _onNewError(AppException error) {
    addError(error);
  }

  /// Agrega un nuevo error al estado.
  ///
  /// [autoDismiss] - Si es true, el error se eliminara automaticamente
  /// despues de [dismissAfter].
  void addError(
    AppException error, {
    bool autoDismiss = true,
    Duration dismissAfter = defaultAutoDismiss,
  }) {
    final newErrors = [error, ...state.errors];

    // Limitar numero de errores
    final trimmedErrors = newErrors.take(maxErrors).toList();

    state = state.copyWith(
      errors: trimmedErrors,
      lastError: error,
      lastErrorTime: DateTime.now(),
    );

    // Auto-dismiss si esta habilitado
    if (autoDismiss) {
      Future.delayed(dismissAfter, () {
        removeError(error);
      });
    }
  }

  /// Elimina un error especifico del estado.
  void removeError(AppException error) {
    final newErrors = state.errors.where((e) => e != error).toList();
    state = state.copyWith(errors: newErrors);
  }

  /// Elimina el error actual (el mas reciente).
  void clearCurrent() {
    if (state.currentError != null) {
      removeError(state.currentError!);
    }
  }

  /// Elimina todos los errores del estado.
  void clearAll() {
    state = ErrorState.initial;
  }

  /// Elimina todos los errores de un tipo especifico.
  void clearByType<T extends AppException>() {
    final newErrors = state.errors.where((e) => e is! T).toList();
    state = state.copyWith(errors: newErrors);
  }

  /// Elimina todos los errores reintentables.
  void clearRetryable() {
    final newErrors = state.errors.where((e) => !e.isRetryable).toList();
    state = state.copyWith(errors: newErrors);
  }

  /// Reintenta la operacion asociada al error actual si es reintentable.
  ///
  /// [operation] - La operacion a reintentar
  /// [onSuccess] - Callback si la operacion tiene exito
  /// [onError] - Callback si la operacion falla de nuevo
  Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    VoidCallback? onSuccess,
    void Function(AppException)? onError,
  }) async {
    final currentError = state.currentError;
    if (currentError == null || !currentError.isRetryable) {
      return null;
    }

    // Eliminar error actual antes de reintentar
    clearCurrent();

    try {
      final result = await operation();
      onSuccess?.call();
      return result;
    } catch (e, stack) {
      final newError = e is AppException
          ? e
          : e.toAppException(stackTrace: stack);
      addError(newError);
      onError?.call(newError);
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Callback sin argumentos para VoidCallback
typedef VoidCallback = void Function();

// =============================================================================
// PROVIDERS
// =============================================================================

/// Provider principal para el estado de errores.
///
/// Uso:
/// ```dart
/// final hasErrors = ref.watch(errorStateProvider).hasErrors;
/// ```
final errorStateProvider =
    StateNotifierProvider<ErrorStateNotifier, ErrorState>((ref) {
      final errorHandler = ref.watch(errorHandlerProvider);
      return ErrorStateNotifier(errorHandler);
    });

/// Provider para verificar si hay errores activos.
final hasErrorsProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(errorStateProvider).hasErrors;
});

/// Provider para el error actual.
final currentErrorProvider = Provider.autoDispose<AppException?>((ref) {
  return ref.watch(errorStateProvider).currentError;
});

/// Provider para errores de red.
final networkErrorsProvider = Provider.autoDispose<List<NetworkException>>((
  ref,
) {
  return ref.watch(errorStateProvider).networkErrors;
});

/// Provider para verificar si hay errores de red.
final hasNetworkErrorProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(networkErrorsProvider).isNotEmpty;
});

/// Provider para errores de sincronizacion.
final syncErrorsProvider = Provider.autoDispose<List<SyncException>>((ref) {
  return ref.watch(errorStateProvider).syncErrors;
});

/// Provider para el conteo de errores.
final errorCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(errorStateProvider).errorCount;
});

// =============================================================================
// ASYNC OPERATION STATE
// =============================================================================

/// Estado de una operacion asincrona con manejo de errores.
class AsyncOperationState<T> {
  final T? data;
  final AppException? error;
  final bool isLoading;
  final int attemptCount;

  const AsyncOperationState._({
    this.data,
    this.error,
    this.isLoading = false,
    this.attemptCount = 0,
  });

  /// Estado inicial (idle)
  factory AsyncOperationState.idle() => const AsyncOperationState._();

  /// Estado de carga
  factory AsyncOperationState.loading({int attemptCount = 1}) =>
      AsyncOperationState._(isLoading: true, attemptCount: attemptCount);

  /// Estado de exito
  factory AsyncOperationState.success(T data) =>
      AsyncOperationState._(data: data);

  /// Estado de error
  factory AsyncOperationState.failure(
    AppException error, {
    int attemptCount = 1,
  }) => AsyncOperationState._(error: error, attemptCount: attemptCount);

  bool get isIdle => !isLoading && data == null && error == null;
  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;
  bool get canRetry => error?.isRetryable ?? false;

  /// Mapea el estado a un widget
  R when<R>({
    required R Function() idle,
    required R Function(int attempt) loading,
    required R Function(T data) success,
    required R Function(AppException error, int attempts, bool canRetry) error,
  }) {
    if (isLoading) return loading(attemptCount);
    if (isSuccess) return success(data as T);
    if (isError) return error(this.error!, attemptCount, canRetry);
    return idle();
  }

  /// Crea una copia del estado
  AsyncOperationState<T> copyWith({
    T? data,
    AppException? error,
    bool? isLoading,
    int? attemptCount,
  }) {
    return AsyncOperationState._(
      data: data ?? this.data,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }
}

/// Notifier para operaciones asincronas con reintentos.
class AsyncOperationNotifier<T> extends StateNotifier<AsyncOperationState<T>> {
  final ErrorHandler _errorHandler;

  AsyncOperationNotifier(this._errorHandler)
    : super(AsyncOperationState.idle());

  /// Ejecuta una operacion asincrona con manejo de errores.
  ///
  /// [operation] - La operacion a ejecutar
  /// [reportError] - Si debe reportar el error al ErrorHandler
  Future<T?> execute(
    Future<T> Function() operation, {
    bool reportError = true,
  }) async {
    state = AsyncOperationState.loading(attemptCount: state.attemptCount + 1);

    try {
      final result = await operation();
      state = AsyncOperationState.success(result);
      return result;
    } catch (e, stack) {
      final appException = e is AppException
          ? e
          : e.toAppException(stackTrace: stack);

      if (reportError) {
        _errorHandler.handleException(appException);
      }

      state = AsyncOperationState.failure(
        appException,
        attemptCount: state.attemptCount,
      );
      return null;
    }
  }

  /// Reintenta la ultima operacion si fallo.
  Future<T?> retry(Future<T> Function() operation) async {
    if (!state.canRetry) return null;
    return execute(operation);
  }

  /// Resetea el estado a idle.
  void reset() {
    state = AsyncOperationState.idle();
  }
}

// =============================================================================
// GLOBAL ERROR LISTENER
// =============================================================================

/// Provider que escucha todos los errores globalmente.
///
/// Util para mostrar banners/toasts de error globales.
/// Retorna el ultimo error en el stream.
final globalErrorListenerProvider = StreamProvider.autoDispose<AppException>((
  ref,
) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return errorHandler.appExceptionStream;
});

/// Provider para el ultimo error global.
final lastGlobalErrorProvider = Provider.autoDispose<AppException?>((ref) {
  final asyncError = ref.watch(globalErrorListenerProvider);
  return asyncError.when(
    data: (error) => error,
    loading: () => null,
    error: (e, s) => null,
  );
});

// =============================================================================
// CONNECTIVITY ERROR STATE
// =============================================================================

/// Estado especializado para errores de conectividad.
class ConnectivityErrorState {
  final bool isOffline;
  final int pendingSyncCount;
  final DateTime? lastSuccessfulSync;
  final NetworkException? lastNetworkError;

  const ConnectivityErrorState({
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.lastSuccessfulSync,
    this.lastNetworkError,
  });

  bool get hasPendingSync => pendingSyncCount > 0;

  ConnectivityErrorState copyWith({
    bool? isOffline,
    int? pendingSyncCount,
    DateTime? lastSuccessfulSync,
    NetworkException? lastNetworkError,
  }) {
    return ConnectivityErrorState(
      isOffline: isOffline ?? this.isOffline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastNetworkError: lastNetworkError ?? this.lastNetworkError,
    );
  }
}

/// Notifier para estado de conectividad.
class ConnectivityErrorNotifier extends StateNotifier<ConnectivityErrorState> {
  ConnectivityErrorNotifier() : super(const ConnectivityErrorState());

  void setOffline(bool offline) {
    state = state.copyWith(isOffline: offline);
  }

  void setPendingSyncCount(int count) {
    state = state.copyWith(pendingSyncCount: count);
  }

  void setLastSuccessfulSync(DateTime time) {
    state = state.copyWith(lastSuccessfulSync: time);
  }

  void setNetworkError(NetworkException? error) {
    state = state.copyWith(lastNetworkError: error, isOffline: error != null);
  }

  void clearNetworkError() {
    state = state.copyWith(isOffline: false);
  }
}

/// Provider para estado de conectividad.
final connectivityErrorProvider =
    StateNotifierProvider<ConnectivityErrorNotifier, ConnectivityErrorState>((
      ref,
    ) {
      return ConnectivityErrorNotifier();
    });

/// Provider para verificar si esta offline.
final isOfflineProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(connectivityErrorProvider).isOffline;
});

/// Provider para conteo de sync pendiente.
final pendingSyncCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(connectivityErrorProvider).pendingSyncCount;
});
