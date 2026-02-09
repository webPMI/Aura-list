/// Background sync coordinator for offline-first architecture.
///
/// SyncWatcher monitors connectivity changes and coordinates background
/// synchronization of local data to Firebase. It implements debouncing
/// to avoid excessive sync calls and provides status updates for the UI.
///
/// Features:
/// - Watches connectivity and triggers sync when online
/// - Debounces syncs to avoid excessive calls
/// - Tracks pending changes count
/// - Provides stream of sync status for UI
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'error_handler.dart';

/// Status of the synchronization process
enum SyncStatus {
  /// No sync activity, all data is synchronized
  idle,

  /// Currently syncing data to/from server
  syncing,

  /// There are pending changes waiting to be synced
  pendingChanges,

  /// Sync failed with an error
  error,

  /// Device is offline, sync will resume when connected
  offline,
}

/// Details about the current sync state
class SyncState {
  final SyncStatus status;
  final int pendingTasksCount;
  final int pendingNotesCount;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingTasksCount = 0,
    this.pendingNotesCount = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  /// Total number of pending items
  int get totalPendingCount => pendingTasksCount + pendingNotesCount;

  /// Whether there are any pending changes
  bool get hasPendingChanges => totalPendingCount > 0;

  /// Whether sync is active
  bool get isSyncing => status == SyncStatus.syncing;

  /// Whether device is online
  bool get isOnline => status != SyncStatus.offline;

  /// Create a copy with modified values
  SyncState copyWith({
    SyncStatus? status,
    int? pendingTasksCount,
    int? pendingNotesCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingTasksCount: pendingTasksCount ?? this.pendingTasksCount,
      pendingNotesCount: pendingNotesCount ?? this.pendingNotesCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'SyncState(status: $status, pending: $totalPendingCount, '
        'lastSync: $lastSyncTime)';
  }
}

/// Background sync coordinator
///
/// Watches connectivity and coordinates data synchronization between
/// local Hive storage and Firebase Firestore.
class SyncWatcher {
  final ConnectivityService _connectivity;
  final DatabaseService _database;
  final ErrorHandler _errorHandler;

  /// Stream controller for sync status updates
  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  /// Current sync state
  SyncState _currentState = const SyncState(status: SyncStatus.offline);

  /// Timer for debouncing sync operations
  Timer? _syncDebounceTimer;

  /// Subscription to connectivity changes
  StreamSubscription<bool>? _connectivitySubscription;

  /// Timer for periodic sync checks
  Timer? _periodicSyncTimer;

  /// Whether the watcher is currently active
  bool _isWatching = false;

  /// Debounce duration before triggering sync
  final Duration syncDebounce;

  /// Periodic sync interval when online
  final Duration periodicSyncInterval;

  SyncWatcher({
    required ConnectivityService connectivity,
    required DatabaseService database,
    required ErrorHandler errorHandler,
    this.syncDebounce = const Duration(seconds: 5),
    this.periodicSyncInterval = const Duration(minutes: 5),
  })  : _connectivity = connectivity,
        _database = database,
        _errorHandler = errorHandler;

  /// Stream of sync status changes
  Stream<SyncState> get syncStateStream => _stateController.stream;

  /// Current sync state
  SyncState get currentState => _currentState;

  /// Current sync status
  SyncStatus get status => _currentState.status;

  /// Number of pending changes
  int get pendingChangesCount => _currentState.totalPendingCount;

  /// Whether the watcher is actively monitoring
  bool get isWatching => _isWatching;

  /// Start watching for connectivity changes and manage sync
  Future<void> startWatching() async {
    if (_isWatching) return;

    _isWatching = true;
    debugPrint('[SyncWatcher] Starting sync watcher');

    // Check initial connectivity
    final isConnected = await _connectivity.isConnected;
    await _updateConnectivityState(isConnected);

    // Subscribe to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (isConnected) => _updateConnectivityState(isConnected),
      onError: (error) {
        _errorHandler.handle(
          error,
          type: ErrorType.network,
          severity: ErrorSeverity.warning,
          message: 'Error monitoring connectivity',
        );
      },
    );

    // Start periodic sync timer (only syncs when online)
    _startPeriodicSync();

    // Initial sync if online
    if (isConnected) {
      _scheduleDebouncedSync();
    }
  }

  /// Stop watching for changes
  Future<void> stopWatching() async {
    if (!_isWatching) return;

    _isWatching = false;
    debugPrint('[SyncWatcher] Stopping sync watcher');

    _syncDebounceTimer?.cancel();
    _periodicSyncTimer?.cancel();
    await _connectivitySubscription?.cancel();

    _syncDebounceTimer = null;
    _periodicSyncTimer = null;
    _connectivitySubscription = null;
  }

  /// Force an immediate sync
  Future<void> forceSync() async {
    debugPrint('[SyncWatcher] Force sync requested');

    _syncDebounceTimer?.cancel();

    if (!_currentState.isOnline) {
      debugPrint('[SyncWatcher] Cannot sync: device is offline');
      return;
    }

    await _performSync();
  }

  /// Mark that local changes have been made (triggers debounced sync)
  void notifyLocalChanges() {
    debugPrint('[SyncWatcher] Local changes detected');
    _updatePendingCount();
    _scheduleDebouncedSync();
  }

  /// Update connectivity state and trigger sync if coming online
  Future<void> _updateConnectivityState(bool isConnected) async {
    final wasOffline = !_currentState.isOnline;

    if (isConnected) {
      await _updatePendingCount();

      if (_currentState.hasPendingChanges) {
        _updateState(_currentState.copyWith(status: SyncStatus.pendingChanges));
      } else {
        _updateState(_currentState.copyWith(status: SyncStatus.idle));
      }

      // If we just came online, trigger sync
      if (wasOffline) {
        debugPrint('[SyncWatcher] Connection restored, scheduling sync');
        _scheduleDebouncedSync();
      }
    } else {
      _updateState(_currentState.copyWith(status: SyncStatus.offline));
      debugPrint('[SyncWatcher] Device went offline');
    }
  }

  /// Update the pending changes count
  Future<void> _updatePendingCount() async {
    try {
      final tasksCount = await _database.getPendingSyncCount();
      final notesCount = await _database.getPendingNotesSyncCount();

      _updateState(_currentState.copyWith(
        pendingTasksCount: tasksCount,
        pendingNotesCount: notesCount,
      ));
    } catch (e) {
      debugPrint('[SyncWatcher] Error getting pending count: $e');
    }
  }

  /// Schedule a debounced sync operation
  void _scheduleDebouncedSync() {
    if (!_currentState.isOnline) return;

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(syncDebounce, () {
      _performSync();
    });
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(periodicSyncInterval, (_) {
      if (_currentState.isOnline && !_currentState.isSyncing) {
        debugPrint('[SyncWatcher] Periodic sync triggered');
        _performSync();
      }
    });
  }

  /// Perform the actual sync operation
  Future<void> _performSync() async {
    if (_currentState.isSyncing) {
      debugPrint('[SyncWatcher] Sync already in progress, skipping');
      return;
    }

    if (!_currentState.isOnline) {
      debugPrint('[SyncWatcher] Cannot sync: offline');
      return;
    }

    debugPrint('[SyncWatcher] Starting sync...');
    _updateState(_currentState.copyWith(status: SyncStatus.syncing));

    try {
      // Flush any pending debounced changes first
      await _database.flushPendingSyncs();

      // Process sync queues
      await _database.forceSyncAll();

      // Update pending count after sync
      await _updatePendingCount();

      final now = DateTime.now();
      if (_currentState.hasPendingChanges) {
        _updateState(_currentState.copyWith(
          status: SyncStatus.pendingChanges,
          lastSyncTime: now,
          errorMessage: null,
        ));
      } else {
        _updateState(_currentState.copyWith(
          status: SyncStatus.idle,
          lastSyncTime: now,
          errorMessage: null,
        ));
      }

      debugPrint('[SyncWatcher] Sync completed successfully');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Sync failed',
        stackTrace: stack,
      );

      _updateState(_currentState.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      ));

      debugPrint('[SyncWatcher] Sync failed: $e');

      // Schedule retry after error
      _scheduleRetryAfterError();
    }
  }

  /// Schedule a retry after a sync error
  void _scheduleRetryAfterError() {
    // Retry after a delay (exponential backoff could be implemented)
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(const Duration(seconds: 30), () {
      if (_currentState.status == SyncStatus.error) {
        debugPrint('[SyncWatcher] Retrying sync after error');
        _performSync();
      }
    });
  }

  /// Update state and notify listeners
  void _updateState(SyncState newState) {
    if (_currentState.status != newState.status ||
        _currentState.totalPendingCount != newState.totalPendingCount) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('[SyncWatcher] State updated: $newState');
    } else {
      _currentState = newState;
    }
  }

  /// Dispose resources
  void dispose() {
    stopWatching();
    _stateController.close();
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for SyncWatcher service
final syncWatcherProvider = Provider<SyncWatcher>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final database = ref.watch(databaseServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);

  final watcher = SyncWatcher(
    connectivity: connectivity,
    database: database,
    errorHandler: errorHandler,
  );

  ref.onDispose(() {
    watcher.dispose();
  });

  return watcher;
});

/// Stream provider for sync status
final syncStatusProvider = StreamProvider<SyncState>((ref) {
  final watcher = ref.watch(syncWatcherProvider);
  return watcher.syncStateStream;
});

/// Provider for current sync state (non-stream version)
final currentSyncStateProvider = Provider<SyncState>((ref) {
  final watcher = ref.watch(syncWatcherProvider);
  return watcher.currentState;
});

/// Provider for pending sync count
final pendingSyncCountProvider = Provider<int>((ref) {
  final watcher = ref.watch(syncWatcherProvider);
  return watcher.pendingChangesCount;
});

/// Provider to check if sync is in progress
final isSyncingProvider = Provider<bool>((ref) {
  final watcher = ref.watch(syncWatcherProvider);
  return watcher.status == SyncStatus.syncing;
});
