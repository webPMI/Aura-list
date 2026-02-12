/// AppBootstrap service for guaranteed initialization order.
///
/// This service ensures all critical services are initialized in the correct
/// order before the app starts. It handles:
/// - Hive initialization
/// - Firebase initialization
/// - Auth initialization
/// - Database service initialization
/// - Sync orchestrator initialization
/// - Initial data sync (if authenticated)
library;

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase_options.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'sync_orchestrator.dart';
import 'sync_watcher_service.dart';
import 'error_handler.dart';
import 'logger_service.dart';

/// Bootstrap state representing initialization progress
class BootstrapState {
  final bool isComplete;
  final bool firebaseReady;
  final bool hiveReady;
  final bool authReady;
  final bool databaseReady;
  final bool syncReady;
  final String? currentStep;
  final String? error;
  final double progress;

  const BootstrapState({
    this.isComplete = false,
    this.firebaseReady = false,
    this.hiveReady = false,
    this.authReady = false,
    this.databaseReady = false,
    this.syncReady = false,
    this.currentStep,
    this.error,
    this.progress = 0.0,
  });

  BootstrapState copyWith({
    bool? isComplete,
    bool? firebaseReady,
    bool? hiveReady,
    bool? authReady,
    bool? databaseReady,
    bool? syncReady,
    String? currentStep,
    String? error,
    double? progress,
  }) {
    return BootstrapState(
      isComplete: isComplete ?? this.isComplete,
      firebaseReady: firebaseReady ?? this.firebaseReady,
      hiveReady: hiveReady ?? this.hiveReady,
      authReady: authReady ?? this.authReady,
      databaseReady: databaseReady ?? this.databaseReady,
      syncReady: syncReady ?? this.syncReady,
      currentStep: currentStep ?? this.currentStep,
      error: error,
      progress: progress ?? this.progress,
    );
  }

  bool get hasError => error != null;
}

/// Result of the bootstrap process
class BootstrapResult {
  final bool success;
  final bool firebaseAvailable;
  final bool isAuthenticated;
  final String? userId;
  final String? error;

  const BootstrapResult({
    required this.success,
    this.firebaseAvailable = false,
    this.isAuthenticated = false,
    this.userId,
    this.error,
  });
}

/// AppBootstrap service
class AppBootstrap {
  final ErrorHandler _errorHandler;
  final _logger = LoggerService();

  final StreamController<BootstrapState> _stateController =
      StreamController<BootstrapState>.broadcast();

  BootstrapState _currentState = const BootstrapState();
  bool _isBootstrapping = false;

  AppBootstrap(this._errorHandler);

  /// Stream of bootstrap state changes
  Stream<BootstrapState> get stateStream => _stateController.stream;

  /// Current state
  BootstrapState get currentState => _currentState;

  /// Run the bootstrap process
  Future<BootstrapResult> bootstrap({
    required WidgetRef ref,
  }) async {
    if (_isBootstrapping) {
      _logger.warning('AppBootstrap', 'Bootstrap already in progress');
      return const BootstrapResult(
        success: false,
        error: 'Bootstrap already in progress',
      );
    }

    _isBootstrapping = true;
    bool firebaseAvailable = false;
    bool isAuthenticated = false;
    String? userId;

    try {
      // Step 1: Initialize Firebase (20%)
      _updateState(_currentState.copyWith(
        currentStep: 'Inicializando Firebase...',
        progress: 0.0,
      ));

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseAvailable = true;
        _logger.info('AppBootstrap', 'Firebase inicializado');
      } catch (e) {
        _logger.warning(
          'AppBootstrap',
          'Firebase no disponible, continuando en modo local',
          metadata: {'error': e.toString()},
        );
      }

      _updateState(_currentState.copyWith(
        firebaseReady: true,
        progress: 0.2,
      ));

      // Step 2: Initialize Database Service (40%)
      _updateState(_currentState.copyWith(
        currentStep: 'Inicializando base de datos local...',
        progress: 0.2,
      ));

      final dbService = ref.read(databaseServiceProvider);
      await dbService.init();

      _updateState(_currentState.copyWith(
        hiveReady: true,
        databaseReady: true,
        progress: 0.4,
      ));

      _logger.info('AppBootstrap', 'Base de datos inicializada');

      // Step 3: Initialize Auth (60%)
      _updateState(_currentState.copyWith(
        currentStep: 'Verificando autenticacion...',
        progress: 0.4,
      ));

      if (firebaseAvailable) {
        final authService = ref.read(authServiceProvider);
        authService.refreshFirebaseAvailability();

        if (authService.isFirebaseAvailable) {
          User? user = authService.currentUser;

          if (user == null) {
            _logger.info('AppBootstrap', 'Iniciando sesion anonima...');
            final result = await authService.signInAnonymously();
            user = result?.user;
          }

          if (user != null) {
            isAuthenticated = true;
            userId = user.uid;
            _logger.info('AppBootstrap', 'Usuario autenticado: $userId');
          }
        }
      }

      _updateState(_currentState.copyWith(
        authReady: true,
        progress: 0.6,
      ));

      // Step 4: Initialize Sync Orchestrator (80%)
      _updateState(_currentState.copyWith(
        currentStep: 'Iniciando sincronizacion...',
        progress: 0.6,
      ));

      if (firebaseAvailable && isAuthenticated) {
        final syncOrchestrator = ref.read(syncOrchestratorProvider);
        final connectivity = ref.read(connectivityServiceProvider);

        await syncOrchestrator.init(
          connectivity: connectivity,
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        );

        // Start SyncWatcher
        final syncWatcher = ref.read(syncWatcherProvider);
        await syncWatcher.startWatching();

        _logger.info('AppBootstrap', 'SyncOrchestrator inicializado');
      }

      _updateState(_currentState.copyWith(
        syncReady: true,
        progress: 0.8,
      ));

      // Step 5: Perform Initial Sync (100%)
      _updateState(_currentState.copyWith(
        currentStep: 'Sincronizando datos...',
        progress: 0.8,
      ));

      if (firebaseAvailable && isAuthenticated && userId != null) {
        final syncEnabled = await dbService.isCloudSyncEnabled();
        if (syncEnabled) {
          try {
            final result = await dbService.performFullSync(userId);
            if (result.hasChanges) {
              _logger.info(
                'AppBootstrap',
                'Sincronizacion inicial completada: ${result.totalDownloaded} elementos',
              );
            }
          } catch (e) {
            _logger.warning(
              'AppBootstrap',
              'Error en sincronizacion inicial (no critico)',
              metadata: {'error': e.toString()},
            );
          }
        }
      }

      _updateState(_currentState.copyWith(
        isComplete: true,
        currentStep: 'Listo',
        progress: 1.0,
      ));

      _logger.info('AppBootstrap', 'Bootstrap completado exitosamente');

      return BootstrapResult(
        success: true,
        firebaseAvailable: firebaseAvailable,
        isAuthenticated: isAuthenticated,
        userId: userId,
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error durante bootstrap',
        stackTrace: stack,
      );

      _updateState(_currentState.copyWith(
        error: e.toString(),
      ));

      return BootstrapResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isBootstrapping = false;
    }
  }

  /// Quick bootstrap for tests
  Future<BootstrapResult> bootstrapMinimal({
    required DatabaseService dbService,
  }) async {
    try {
      _updateState(_currentState.copyWith(
        currentStep: 'Inicializando...',
        progress: 0.0,
      ));

      await dbService.init();

      _updateState(_currentState.copyWith(
        hiveReady: true,
        databaseReady: true,
        isComplete: true,
        progress: 1.0,
      ));

      return const BootstrapResult(success: true);
    } catch (e) {
      _updateState(_currentState.copyWith(error: e.toString()));
      return BootstrapResult(success: false, error: e.toString());
    }
  }

  void _updateState(BootstrapState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for AppBootstrap
final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  final bootstrap = AppBootstrap(errorHandler);

  ref.onDispose(() {
    bootstrap.dispose();
  });

  return bootstrap;
});

/// Stream provider for bootstrap state
final bootstrapStateProvider = StreamProvider<BootstrapState>((ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  return bootstrap.stateStream;
});

/// FutureProvider that runs bootstrap and returns result
final bootstrapResultProvider = FutureProvider<BootstrapResult>((ref) async {
  // This provider needs to be invoked with a WidgetRef, so we return a placeholder
  // The actual bootstrap should be called from the UI with ref
  return const BootstrapResult(
    success: false,
    error: 'Bootstrap must be invoked from UI',
  );
});
