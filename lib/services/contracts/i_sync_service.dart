/// Interface for synchronization services.
///
/// Provides a consistent API for syncing data between local and cloud storage,
/// managing sync queues, and handling retry logic.
library;

/// Status of a sync operation
enum SyncOperationStatus {
  success,
  failed,
  pending,
  skipped,
  offline,
}

/// Result of a sync operation
class SyncOperationResult {
  final SyncOperationStatus status;
  final int itemsSynced;
  final int itemsFailed;
  final List<String> errors;
  final DateTime timestamp;

  const SyncOperationResult({
    required this.status,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
    this.errors = const [],
    required this.timestamp,
  });

  factory SyncOperationResult.success({int itemsSynced = 1}) {
    return SyncOperationResult(
      status: SyncOperationStatus.success,
      itemsSynced: itemsSynced,
      timestamp: DateTime.now(),
    );
  }

  factory SyncOperationResult.failed(String error) {
    return SyncOperationResult(
      status: SyncOperationStatus.failed,
      errors: [error],
      timestamp: DateTime.now(),
    );
  }

  factory SyncOperationResult.offline() {
    return SyncOperationResult(
      status: SyncOperationStatus.offline,
      timestamp: DateTime.now(),
    );
  }

  factory SyncOperationResult.skipped(String reason) {
    return SyncOperationResult(
      status: SyncOperationStatus.skipped,
      errors: [reason],
      timestamp: DateTime.now(),
    );
  }

  bool get isSuccess => status == SyncOperationStatus.success;
  bool get hasErrors => errors.isNotEmpty;
}

/// Item in the sync queue
class SyncQueueItem<T> {
  final dynamic localKey;
  final String? firestoreId;
  final String userId;
  final T? entitySnapshot;
  final DateTime enqueuedAt;
  final int retryCount;
  final DateTime? lastRetryAt;

  const SyncQueueItem({
    required this.localKey,
    this.firestoreId,
    required this.userId,
    this.entitySnapshot,
    required this.enqueuedAt,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  SyncQueueItem<T> incrementRetry() {
    return SyncQueueItem<T>(
      localKey: localKey,
      firestoreId: firestoreId,
      userId: userId,
      entitySnapshot: entitySnapshot,
      enqueuedAt: enqueuedAt,
      retryCount: retryCount + 1,
      lastRetryAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'localKey': localKey,
      'firestoreId': firestoreId,
      'userId': userId,
      'enqueuedAt': enqueuedAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.millisecondsSinceEpoch,
    };
  }
}

/// Generic interface for sync services
abstract class ISyncService<T> {
  /// Check if sync is enabled
  Future<bool> get isSyncEnabled;

  /// Check if currently syncing
  bool get isSyncing;

  /// Sync a single item to cloud
  Future<SyncOperationResult> syncToCloud(T item, String userId);

  /// Sync a single item to cloud with debouncing
  Future<void> syncToCloudDebounced(T item, String userId);

  /// Sync all items from cloud to local
  Future<SyncOperationResult> syncFromCloud(String userId, {DateTime? since});

  /// Perform full bidirectional sync
  Future<SyncOperationResult> performFullSync(String userId);

  /// Add item to sync queue for later processing
  Future<void> addToQueue(T item, String userId);

  /// Process all items in the sync queue
  Future<SyncOperationResult> processQueue();

  /// Get number of items pending in queue
  Future<int> getPendingCount();

  /// Flush any pending debounced syncs immediately
  Future<void> flushPendingSyncs();

  /// Clear all items from sync queue
  Future<void> clearQueue();

  /// Move failed items to dead-letter queue
  Future<void> moveToDeadLetter(SyncQueueItem<T> item);

  /// Get items from dead-letter queue
  Future<List<SyncQueueItem<T>>> getDeadLetterItems();

  /// Retry an item from dead-letter queue
  Future<SyncOperationResult> retryDeadLetterItem(SyncQueueItem<T> item);
}

/// Configuration for sync services
class SyncConfig {
  final int maxRetries;
  final Duration initialBackoff;
  final double backoffMultiplier;
  final Duration maxBackoff;
  final Duration debounceDelay;
  final int maxAgeDays;
  final Duration syncTimeout;

  const SyncConfig({
    this.maxRetries = 3,
    this.initialBackoff = const Duration(seconds: 2),
    this.backoffMultiplier = 2.0,
    this.maxBackoff = const Duration(minutes: 5),
    this.debounceDelay = const Duration(seconds: 3),
    this.maxAgeDays = 7,
    this.syncTimeout = const Duration(seconds: 10),
  });

  /// Calculate backoff duration for a given retry count
  Duration calculateBackoff(int retryCount) {
    if (retryCount == 0) return Duration.zero;
    final delay = initialBackoff * (backoffMultiplier * retryCount);
    return delay > maxBackoff ? maxBackoff : delay;
  }
}
