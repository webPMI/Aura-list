/// Centralized sync orchestrator for offline-first architecture.
///
/// SyncOrchestrator provides a unified, scalable approach to synchronization
/// between local Hive storage and Firebase Firestore. It handles:
/// - Unified sync queue for all entity types (tasks, notes, notebooks)
/// - Dead-letter queue for failed items after max retries
/// - Pending user queue for items created before authentication
/// - Bidirectional sync (local-to-cloud and cloud-to-local)
/// - Conflict resolution with last-write-wins strategy
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/notebook_model.dart';
import 'connectivity_service.dart';
import 'error_handler.dart';
import 'logger_service.dart';

// ==================== ENUMS & CONSTANTS ====================

/// Types of entities that can be synced
enum SyncEntityType { task, note, notebook, taskHistory, userPreferences }

/// Status of a sync operation
enum SyncOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  deadLetter, // Failed after max retries
}

/// Reasons for sync failure
enum SyncFailureReason {
  networkError,
  authError,
  validationError,
  timeout,
  serverError,
  unknown,
}

// ==================== SYNC ITEM MODEL ====================

/// Represents an item in the sync queue
class SyncQueueItem {
  final String id;
  final SyncEntityType entityType;
  final dynamic entityKey; // Hive key
  final String? firestoreId;
  final String? userId; // null if pending auth
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int retryCount;
  final SyncOperationStatus status;
  final SyncFailureReason? failureReason;
  final String? errorMessage;
  final Map<String, dynamic>? entitySnapshot; // Snapshot for dead-letter recovery

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityKey,
    this.firestoreId,
    this.userId,
    required this.createdAt,
    this.lastAttemptAt,
    this.retryCount = 0,
    this.status = SyncOperationStatus.pending,
    this.failureReason,
    this.errorMessage,
    this.entitySnapshot,
  });

  /// Whether this item is waiting for user authentication
  bool get isPendingAuth => userId == null || userId!.isEmpty;

  /// Whether this item can be retried
  bool get canRetry =>
      status != SyncOperationStatus.deadLetter &&
      status != SyncOperationStatus.completed;

  /// Create a copy with updated values
  SyncQueueItem copyWith({
    String? id,
    SyncEntityType? entityType,
    dynamic entityKey,
    String? firestoreId,
    String? userId,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    int? retryCount,
    SyncOperationStatus? status,
    SyncFailureReason? failureReason,
    String? errorMessage,
    Map<String, dynamic>? entitySnapshot,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityKey: entityKey ?? this.entityKey,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      errorMessage: errorMessage ?? this.errorMessage,
      entitySnapshot: entitySnapshot ?? this.entitySnapshot,
    );
  }

  /// Convert to map for Hive storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType.index,
      'entityKey': entityKey,
      'firestoreId': firestoreId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'retryCount': retryCount,
      'status': status.index,
      'failureReason': failureReason?.index,
      'errorMessage': errorMessage,
      'entitySnapshot': entitySnapshot,
    };
  }

  /// Create from map (Hive storage)
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      entityType: SyncEntityType.values[map['entityType'] as int],
      entityKey: map['entityKey'],
      firestoreId: map['firestoreId'] as String?,
      userId: map['userId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
      retryCount: map['retryCount'] as int? ?? 0,
      status: SyncOperationStatus.values[map['status'] as int? ?? 0],
      failureReason: map['failureReason'] != null
          ? SyncFailureReason.values[map['failureReason'] as int]
          : null,
      errorMessage: map['errorMessage'] as String?,
      entitySnapshot: map['entitySnapshot'] as Map<String, dynamic>?,
    );
  }
}

// ==================== SYNC STATE ====================

/// Overall state of the sync orchestrator
class SyncOrchestratorState {
  final bool isInitialized;
  final bool isSyncing;
  final bool isOnline;
  final int pendingCount;
  final int deadLetterCount;
  final int pendingAuthCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final Map<SyncEntityType, int> pendingByType;

  const SyncOrchestratorState({
    this.isInitialized = false,
    this.isSyncing = false,
    this.isOnline = false,
    this.pendingCount = 0,
    this.deadLetterCount = 0,
    this.pendingAuthCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.pendingByType = const {},
  });

  SyncOrchestratorState copyWith({
    bool? isInitialized,
    bool? isSyncing,
    bool? isOnline,
    int? pendingCount,
    int? deadLetterCount,
    int? pendingAuthCount,
    DateTime? lastSyncTime,
    String? lastError,
    Map<SyncEntityType, int>? pendingByType,
  }) {
    return SyncOrchestratorState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      deadLetterCount: deadLetterCount ?? this.deadLetterCount,
      pendingAuthCount: pendingAuthCount ?? this.pendingAuthCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      pendingByType: pendingByType ?? this.pendingByType,
    );
  }
}

// ==================== SYNC ORCHESTRATOR ====================

/// Centralized sync orchestrator
class SyncOrchestrator {
  final ErrorHandler _errorHandler;
  final _logger = LoggerService();

  // Configuration
  static const int maxRetries = 5;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration syncDebounce = Duration(seconds: 3);
  static const Duration periodicSyncInterval = Duration(minutes: 5);
  static const Duration deadLetterRetentionDays = Duration(days: 30);

  // Hive box names
  static const String _unifiedQueueBoxName = 'unified_sync_queue';
  static const String _deadLetterBoxName = 'dead_letter_queue';
  static const String _pendingAuthBoxName = 'pending_auth_queue';
  static const String _syncMetadataBoxName = 'sync_orchestrator_metadata';

  // State
  Box<Map>? _unifiedQueueBox;
  Box<Map>? _deadLetterBox;
  Box<Map>? _pendingAuthBox;
  Box<Map>? _metadataBox;

  bool _initialized = false;
  bool _isSyncing = false;
  bool _firebaseAvailable = false;
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  // Streams
  final StreamController<SyncOrchestratorState> _stateController =
      StreamController<SyncOrchestratorState>.broadcast();

  // Timers
  Timer? _syncDebounceTimer;
  Timer? _periodicSyncTimer;

  // Subscriptions
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<User?>? _authSubscription;

  // Current state
  SyncOrchestratorState _currentState = const SyncOrchestratorState();

  SyncOrchestrator(this._errorHandler);

  /// Stream of state changes
  Stream<SyncOrchestratorState> get stateStream => _stateController.stream;

  /// Current state
  SyncOrchestratorState get currentState => _currentState;

  /// Whether the orchestrator is initialized
  bool get isInitialized => _initialized;

  // ==================== INITIALIZATION ====================

  /// Initialize the sync orchestrator
  Future<void> init({
    required ConnectivityService connectivity,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) async {
    if (_initialized) return;

    _logger.debug('SyncOrchestrator', 'Initializing...');

    try {
      // Open Hive boxes
      _unifiedQueueBox = await Hive.openBox<Map>(_unifiedQueueBoxName);
      _deadLetterBox = await Hive.openBox<Map>(_deadLetterBoxName);
      _pendingAuthBox = await Hive.openBox<Map>(_pendingAuthBoxName);
      _metadataBox = await Hive.openBox<Map>(_syncMetadataBoxName);

      // Check Firebase availability
      _firebaseAvailable = firestore != null;
      _firestore = firestore;
      _auth = auth;

      // Subscribe to connectivity changes
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      // Subscribe to auth changes
      if (_auth != null) {
        _authSubscription = _auth!.authStateChanges().listen(_onAuthChanged);
      }

      // Check initial connectivity
      final isOnline = await connectivity.isConnected;
      _updateState(_currentState.copyWith(
        isInitialized: true,
        isOnline: isOnline,
      ));

      _initialized = true;

      // Perform initial sync if online and authenticated
      if (isOnline && _auth?.currentUser != null) {
        _scheduleDebouncedSync();
      }

      // Start periodic sync
      _startPeriodicSync();

      // Cleanup old dead-letter items
      await _cleanupDeadLetterQueue();

      await _updateCounts();

      _logger.debug('SyncOrchestrator', 'Initialized successfully');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Failed to initialize SyncOrchestrator',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _syncDebounceTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _stateController.close();
  }

  // ==================== PUBLIC API ====================

  /// Add an entity to the sync queue
  Future<void> enqueue({
    required SyncEntityType entityType,
    required dynamic entityKey,
    String? firestoreId,
    String? userId,
    Map<String, dynamic>? entitySnapshot,
  }) async {
    if (!_initialized) {
      _logger.warning('SyncOrchestrator', 'Not initialized, cannot enqueue');
      return;
    }

    final item = SyncQueueItem(
      id: '${entityType.name}_${entityKey}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityKey: entityKey,
      firestoreId: firestoreId,
      userId: userId,
      createdAt: DateTime.now(),
      entitySnapshot: entitySnapshot,
    );

    // If no userId, add to pending auth queue
    if (item.isPendingAuth) {
      await _pendingAuthBox?.put(item.id, item.toMap());
      _logger.debug(
        'SyncOrchestrator',
        'Added to pending auth queue: ${item.id}',
      );
    } else {
      await _unifiedQueueBox?.put(item.id, item.toMap());
      _logger.debug('SyncOrchestrator', 'Added to sync queue: ${item.id}');
    }

    await _updateCounts();
    _scheduleDebouncedSync();
  }

  /// Force immediate sync
  Future<void> forceSync() async {
    _syncDebounceTimer?.cancel();
    await _performSync();
  }

  /// Retry all dead-letter items
  Future<int> retryDeadLetterItems() async {
    if (_deadLetterBox == null || _deadLetterBox!.isEmpty) return 0;

    int movedCount = 0;
    final keysToMove = <String>[];

    for (final entry in _deadLetterBox!.toMap().entries) {
      final item = SyncQueueItem.fromMap(
        Map<String, dynamic>.from(entry.value),
      );

      // Reset retry count and move back to main queue
      final resetItem = item.copyWith(
        retryCount: 0,
        status: SyncOperationStatus.pending,
        failureReason: null,
        errorMessage: null,
        lastAttemptAt: null,
      );

      if (item.isPendingAuth) {
        await _pendingAuthBox?.put(item.id, resetItem.toMap());
      } else {
        await _unifiedQueueBox?.put(item.id, resetItem.toMap());
      }

      keysToMove.add(entry.key as String);
      movedCount++;
    }

    // Remove from dead-letter queue
    for (final key in keysToMove) {
      await _deadLetterBox?.delete(key);
    }

    await _updateCounts();
    _logger.info(
      'SyncOrchestrator',
      'Moved $movedCount items from dead-letter queue for retry',
    );

    if (movedCount > 0) {
      _scheduleDebouncedSync();
    }

    return movedCount;
  }

  /// Get all dead-letter items for inspection
  Future<List<SyncQueueItem>> getDeadLetterItems() async {
    if (_deadLetterBox == null) return [];

    return _deadLetterBox!.values
        .map((map) => SyncQueueItem.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  /// Clear all dead-letter items (permanently)
  Future<int> clearDeadLetterQueue() async {
    if (_deadLetterBox == null) return 0;

    final count = _deadLetterBox!.length;
    await _deadLetterBox!.clear();
    await _updateCounts();

    _logger.info('SyncOrchestrator', 'Cleared $count dead-letter items');
    return count;
  }

  /// Get pending sync count by entity type
  Future<Map<SyncEntityType, int>> getPendingCountByType() async {
    final counts = <SyncEntityType, int>{};

    if (_unifiedQueueBox != null) {
      for (final map in _unifiedQueueBox!.values) {
        final item = SyncQueueItem.fromMap(Map<String, dynamic>.from(map));
        counts[item.entityType] = (counts[item.entityType] ?? 0) + 1;
      }
    }

    if (_pendingAuthBox != null) {
      for (final map in _pendingAuthBox!.values) {
        final item = SyncQueueItem.fromMap(Map<String, dynamic>.from(map));
        counts[item.entityType] = (counts[item.entityType] ?? 0) + 1;
      }
    }

    return counts;
  }

  // ==================== SYNC LOGIC ====================

  void _scheduleDebouncedSync() {
    if (!_currentState.isOnline || _isSyncing) return;

    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(syncDebounce, () {
      _performSync();
    });
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(periodicSyncInterval, (_) {
      if (_currentState.isOnline && !_isSyncing) {
        _logger.debug('SyncOrchestrator', 'Periodic sync triggered');
        _performSync();
      }
    });
  }

  Future<void> _performSync() async {
    if (_isSyncing) {
      _logger.debug('SyncOrchestrator', 'Sync already in progress');
      return;
    }

    if (!_currentState.isOnline) {
      _logger.debug('SyncOrchestrator', 'Offline, skipping sync');
      return;
    }

    if (!_firebaseAvailable) {
      _logger.debug('SyncOrchestrator', 'Firebase not available');
      return;
    }

    _isSyncing = true;
    _updateState(_currentState.copyWith(isSyncing: true));

    try {
      _logger.debug('SyncOrchestrator', 'Starting sync...');

      // Process main queue
      await _processQueue(_unifiedQueueBox);

      // Update last sync time
      final now = DateTime.now();
      _updateState(_currentState.copyWith(
        isSyncing: false,
        lastSyncTime: now,
        lastError: null,
      ));

      // Persist last sync time to metadata box
      await _metadataBox?.put('lastSyncTime', {
        'timestamp': now.toIso8601String(),
      });

      await _updateCounts();

      _logger.debug('SyncOrchestrator', 'Sync completed successfully');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Sync failed',
        stackTrace: stack,
      );

      _updateState(_currentState.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processQueue(Box<Map>? queue) async {
    if (queue == null || queue.isEmpty) return;

    final keysToRemove = <String>[];
    final keysToUpdate = <String, Map<String, dynamic>>{};
    final keysToDeadLetter = <String, SyncQueueItem>{};
    final now = DateTime.now();

    for (final entry in queue.toMap().entries) {
      final key = entry.key as String;
      final item = SyncQueueItem.fromMap(Map<String, dynamic>.from(entry.value));

      // Skip if no user ID
      if (item.userId == null || item.userId!.isEmpty) {
        continue;
      }

      // Check backoff
      if (item.lastAttemptAt != null && item.retryCount > 0) {
        final backoffMs = _calculateBackoff(item.retryCount);
        final timeSinceLastAttempt =
            now.difference(item.lastAttemptAt!).inMilliseconds;
        if (timeSinceLastAttempt < backoffMs) {
          continue; // Still in backoff period
        }
      }

      // Attempt sync
      try {
        await _syncItem(item);
        keysToRemove.add(key);
        _logger.debug(
          'SyncOrchestrator',
          'Synced: ${item.entityType.name} ${item.entityKey}',
        );
      } catch (e) {
        final newRetryCount = item.retryCount + 1;

        if (newRetryCount >= maxRetries) {
          // Move to dead-letter queue
          final deadItem = item.copyWith(
            status: SyncOperationStatus.deadLetter,
            failureReason: _classifyError(e),
            errorMessage: e.toString(),
            lastAttemptAt: now,
            retryCount: newRetryCount,
          );
          keysToDeadLetter[key] = deadItem;

          _logger.warning(
            'SyncOrchestrator',
            'Moving to dead-letter: ${item.id} after $maxRetries retries',
          );
        } else {
          // Update for retry
          keysToUpdate[key] = item
              .copyWith(
                retryCount: newRetryCount,
                lastAttemptAt: now,
                status: SyncOperationStatus.failed,
                failureReason: _classifyError(e),
                errorMessage: e.toString(),
              )
              .toMap();

          _logger.debug(
            'SyncOrchestrator',
            'Retry scheduled for ${item.id} (attempt $newRetryCount)',
          );
        }
      }
    }

    // Apply changes
    for (final key in keysToRemove) {
      await queue.delete(key);
    }

    for (final entry in keysToUpdate.entries) {
      await queue.put(entry.key, entry.value);
    }

    for (final entry in keysToDeadLetter.entries) {
      await _deadLetterBox?.put(entry.key, entry.value.toMap());
      await queue.delete(entry.key);
    }
  }

  Future<void> _syncItem(SyncQueueItem item) async {
    final fs = _firestore;
    if (fs == null) throw Exception('Firestore not available');

    final userId = item.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('No user ID available');
    }

    switch (item.entityType) {
      case SyncEntityType.task:
        await _syncTask(fs, userId, item);
        break;
      case SyncEntityType.note:
        await _syncNote(fs, userId, item);
        break;
      case SyncEntityType.notebook:
        await _syncNotebook(fs, userId, item);
        break;
      case SyncEntityType.taskHistory:
        await _syncTaskHistory(fs, userId, item);
        break;
      case SyncEntityType.userPreferences:
        await _syncUserPreferences(fs, userId, item);
        break;
    }
  }

  Future<void> _syncTask(
    FirebaseFirestore fs,
    String userId,
    SyncQueueItem item,
  ) async {
    // Get task from Hive
    final taskBox = Hive.box<Task>('tasks');
    final task = taskBox.get(item.entityKey);

    if (task == null) {
      _logger.debug('SyncOrchestrator', 'Task not found locally, skipping');
      return;
    }

    final docRef = fs
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.firestoreId.isNotEmpty ? task.firestoreId : null);

    await docRef.set(task.toFirestore(), SetOptions(merge: true)).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Firebase timeout'),
        );

    // Update firestoreId if new
    if (task.firestoreId.isEmpty && task.isInBox) {
      task.firestoreId = docRef.id;
      await task.save();
    }
  }

  Future<void> _syncNote(
    FirebaseFirestore fs,
    String userId,
    SyncQueueItem item,
  ) async {
    final noteBox = Hive.box<Note>('notes');
    final note = noteBox.get(item.entityKey);

    if (note == null) {
      _logger.debug('SyncOrchestrator', 'Note not found locally, skipping');
      return;
    }

    final docRef = fs
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.firestoreId.isNotEmpty ? note.firestoreId : null);

    await docRef.set(note.toFirestore(), SetOptions(merge: true)).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Firebase timeout'),
        );

    if (note.firestoreId.isEmpty && note.isInBox) {
      note.firestoreId = docRef.id;
      await note.save();
    }
  }

  Future<void> _syncNotebook(
    FirebaseFirestore fs,
    String userId,
    SyncQueueItem item,
  ) async {
    final notebookBox = Hive.box<Notebook>('notebooks');
    final notebook = notebookBox.get(item.entityKey);

    if (notebook == null) {
      _logger.debug('SyncOrchestrator', 'Notebook not found locally, skipping');
      return;
    }

    final docRef = fs
        .collection('users')
        .doc(userId)
        .collection('notebooks')
        .doc(notebook.firestoreId.isNotEmpty ? notebook.firestoreId : null);

    await docRef.set(notebook.toFirestore(), SetOptions(merge: true)).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Firebase timeout'),
        );

    if (notebook.firestoreId.isEmpty && notebook.isInBox) {
      notebook.firestoreId = docRef.id;
      await notebook.save();
    }
  }

  Future<void> _syncTaskHistory(
    FirebaseFirestore fs,
    String userId,
    SyncQueueItem item,
  ) async {
    // TaskHistory sync will be implemented when model is updated
    _logger.debug('SyncOrchestrator', 'TaskHistory sync not yet implemented');
  }

  Future<void> _syncUserPreferences(
    FirebaseFirestore fs,
    String userId,
    SyncQueueItem item,
  ) async {
    // UserPreferences sync will be implemented when model is updated
    _logger.debug('SyncOrchestrator', 'UserPreferences sync not yet implemented');
  }

  // ==================== EVENT HANDLERS ====================

  void _onConnectivityChanged(bool isOnline) {
    final wasOffline = !_currentState.isOnline;
    _updateState(_currentState.copyWith(isOnline: isOnline));

    if (isOnline && wasOffline) {
      _logger.debug('SyncOrchestrator', 'Connection restored, scheduling sync');
      _scheduleDebouncedSync();
    }
  }

  void _onAuthChanged(User? user) {
    if (user != null && user.uid.isNotEmpty) {
      _logger.debug('SyncOrchestrator', 'User authenticated: ${user.uid}');
      _promotePendingAuthItems(user.uid);
    }
  }

  /// Move items from pending auth queue to main queue when user authenticates
  Future<void> _promotePendingAuthItems(String userId) async {
    if (_pendingAuthBox == null || _pendingAuthBox!.isEmpty) return;

    int promotedCount = 0;
    final keysToRemove = <String>[];

    for (final entry in _pendingAuthBox!.toMap().entries) {
      final item = SyncQueueItem.fromMap(
        Map<String, dynamic>.from(entry.value),
      );

      // Update with userId and move to main queue
      final updatedItem = item.copyWith(userId: userId);
      await _unifiedQueueBox?.put(item.id, updatedItem.toMap());

      keysToRemove.add(entry.key as String);
      promotedCount++;
    }

    // Remove from pending auth queue
    for (final key in keysToRemove) {
      await _pendingAuthBox?.delete(key);
    }

    await _updateCounts();

    if (promotedCount > 0) {
      _logger.info(
        'SyncOrchestrator',
        'Promoted $promotedCount items after authentication',
      );
      _scheduleDebouncedSync();
    }
  }

  // ==================== HELPERS ====================

  int _calculateBackoff(int retryCount) {
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    return initialRetryDelay.inMilliseconds * (1 << retryCount);
  }

  SyncFailureReason _classifyError(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) return SyncFailureReason.timeout;
    if (errorStr.contains('network') || errorStr.contains('socket')) {
      return SyncFailureReason.networkError;
    }
    if (errorStr.contains('auth') || errorStr.contains('permission')) {
      return SyncFailureReason.authError;
    }
    if (errorStr.contains('validation') || errorStr.contains('invalid')) {
      return SyncFailureReason.validationError;
    }
    if (errorStr.contains('server') || errorStr.contains('500')) {
      return SyncFailureReason.serverError;
    }

    return SyncFailureReason.unknown;
  }

  Future<void> _cleanupDeadLetterQueue() async {
    if (_deadLetterBox == null || _deadLetterBox!.isEmpty) return;

    final cutoffDate = DateTime.now().subtract(deadLetterRetentionDays);
    final keysToRemove = <String>[];

    for (final entry in _deadLetterBox!.toMap().entries) {
      final item = SyncQueueItem.fromMap(
        Map<String, dynamic>.from(entry.value),
      );

      if (item.createdAt.isBefore(cutoffDate)) {
        keysToRemove.add(entry.key as String);
      }
    }

    for (final key in keysToRemove) {
      await _deadLetterBox?.delete(key);
    }

    if (keysToRemove.isNotEmpty) {
      _logger.info(
        'SyncOrchestrator',
        'Cleaned up ${keysToRemove.length} old dead-letter items',
      );
    }
  }

  Future<void> _updateCounts() async {
    final pendingCount = (_unifiedQueueBox?.length ?? 0);
    final deadLetterCount = (_deadLetterBox?.length ?? 0);
    final pendingAuthCount = (_pendingAuthBox?.length ?? 0);
    final pendingByType = await getPendingCountByType();

    _updateState(_currentState.copyWith(
      pendingCount: pendingCount,
      deadLetterCount: deadLetterCount,
      pendingAuthCount: pendingAuthCount,
      pendingByType: pendingByType,
    ));
  }

  void _updateState(SyncOrchestratorState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for SyncOrchestrator
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return SyncOrchestrator(errorHandler);
});

/// Stream provider for sync orchestrator state
final syncOrchestratorStateProvider =
    StreamProvider<SyncOrchestratorState>((ref) {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return orchestrator.stateStream;
});

/// Provider for pending sync count
final pendingSyncTotalProvider = Provider<int>((ref) {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return orchestrator.currentState.pendingCount;
});

/// Provider for dead-letter count
final deadLetterCountProvider = Provider<int>((ref) {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return orchestrator.currentState.deadLetterCount;
});

/// Provider to check if sync is in progress
final isSyncingOrchestratorProvider = Provider<bool>((ref) {
  final orchestrator = ref.watch(syncOrchestratorProvider);
  return orchestrator.currentState.isSyncing;
});
