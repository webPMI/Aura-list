/// Generic sync queue implementation.
///
/// Provides a unified queue for managing sync operations with
/// retry logic, exponential backoff, and dead-letter handling.
library;

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../contracts/i_sync_service.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import 'sync_utils.dart';

/// Generic sync queue that can handle any entity type
class GenericSyncQueue<T> {
  final String queueBoxName;
  final String deadLetterBoxName;
  final ErrorHandler errorHandler;
  final SyncConfig config;
  final Future<T?> Function(dynamic key) findLocalItem;
  final Future<void> Function(T item, String userId) syncItem;
  final LoggerService _logger = LoggerService();

  Box<Map>? _queueBox;
  Box<Map>? _deadLetterBox;
  bool _isProcessing = false;

  GenericSyncQueue({
    required this.queueBoxName,
    required this.deadLetterBoxName,
    required this.errorHandler,
    required this.findLocalItem,
    required this.syncItem,
    this.config = const SyncConfig(),
  });

  /// Initialize the queue boxes
  Future<void> init() async {
    _queueBox = Hive.isBoxOpen(queueBoxName)
        ? Hive.box<Map>(queueBoxName)
        : await Hive.openBox<Map>(queueBoxName);

    _deadLetterBox = Hive.isBoxOpen(deadLetterBoxName)
        ? Hive.box<Map>(deadLetterBoxName)
        : await Hive.openBox<Map>(deadLetterBoxName);
  }

  /// Add an item to the sync queue
  Future<void> enqueue({
    required dynamic localKey,
    String? firestoreId,
    required String userId,
  }) async {
    if (_queueBox == null) await init();

    await _queueBox!.add({
      'localKey': localKey,
      'firestoreId': firestoreId,
      'userId': userId,
      'enqueuedAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
      'lastRetryAt': null,
    });

    _logger.debug(
      'Service',
      '[SyncQueue:$queueBoxName] Item enqueued: key=$localKey',
    );
  }

  /// Process all items in the queue
  Future<SyncOperationResult> processQueue() async {
    if (_isProcessing) {
      _logger.debug(
        'Service',
        '[SyncQueue:$queueBoxName] Already processing, skipping',
      );
      return SyncOperationResult.skipped('Already processing');
    }

    if (_queueBox == null) await init();
    if (_queueBox!.isEmpty) {
      return SyncOperationResult.success(itemsSynced: 0);
    }

    _isProcessing = true;
    int itemsSynced = 0;
    int itemsFailed = 0;
    final errors = <String>[];
    final keysToRemove = <dynamic>[];
    final keysToUpdate = <dynamic, Map<String, dynamic>>{};

    _logger.debug(
      'Service',
      '[SyncQueue:$queueBoxName] Processing ${_queueBox!.length} items',
    );

    try {
      for (final entry in _queueBox!.toMap().entries) {
        final result = await _processQueueItem(entry.key, entry.value);

        switch (result) {
          case _ProcessResult.success:
            keysToRemove.add(entry.key);
            itemsSynced++;
            break;
          case _ProcessResult.retry:
            keysToUpdate[entry.key] = _incrementRetry(entry.value);
            break;
          case _ProcessResult.deadLetter:
            await _moveToDeadLetter(entry.value);
            keysToRemove.add(entry.key);
            itemsFailed++;
            errors.add('Item moved to dead letter queue');
            break;
          case _ProcessResult.remove:
            keysToRemove.add(entry.key);
            break;
          case _ProcessResult.skip:
            // Do nothing, skip this iteration
            break;
        }
      }

      // Apply changes to queue
      for (final key in keysToRemove) {
        await _queueBox!.delete(key);
      }
      for (final entry in keysToUpdate.entries) {
        await _queueBox!.put(entry.key, entry.value);
      }

      _logger.debug(
        'Service',
        '[SyncQueue:$queueBoxName] Processed: $itemsSynced synced, $itemsFailed failed, ${keysToUpdate.length} retrying',
      );

      return SyncOperationResult(
        status: itemsFailed > 0
            ? SyncOperationStatus.failed
            : SyncOperationStatus.success,
        itemsSynced: itemsSynced,
        itemsFailed: itemsFailed,
        errors: errors,
        timestamp: DateTime.now(),
      );
    } catch (e, stack) {
      errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error processing sync queue',
        stackTrace: stack,
      );
      return SyncOperationResult.failed(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single queue item
  Future<_ProcessResult> _processQueueItem(
    dynamic key,
    Map<dynamic, dynamic> data,
  ) async {
    try {
      final localKey = data['localKey'];
      final userId = data['userId'] as String;
      final enqueuedAt = DateTime.fromMillisecondsSinceEpoch(
        data['enqueuedAt'] as int,
      );
      final retryCount = data['retryCount'] as int? ?? 0;
      final lastRetryAt = data['lastRetryAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastRetryAt'] as int)
          : null;

      // Check if item is too old
      if (isItemTooOld(enqueuedAt, maxAgeDays: config.maxAgeDays)) {
        _logger.debug(
          'Service',
          '[SyncQueue:$queueBoxName] Item too old, removing',
        );
        return _ProcessResult.remove;
      }

      // Check if max retries exceeded
      if (retryCount >= config.maxRetries) {
        _logger.debug(
          'Service',
          '[SyncQueue:$queueBoxName] Max retries exceeded, moving to dead letter',
        );
        return _ProcessResult.deadLetter;
      }

      // Check if we should wait for backoff
      if (!canRetryNow(
        retryCount,
        lastRetryAt,
        initial: config.initialBackoff,
        multiplier: config.backoffMultiplier,
      )) {
        _logger.debug(
          'Service',
          '[SyncQueue:$queueBoxName] Item in backoff, skipping',
        );
        return _ProcessResult.skip;
      }

      // Find the local item
      final item = await findLocalItem(localKey);
      if (item == null) {
        _logger.debug(
          'Service',
          '[SyncQueue:$queueBoxName] Local item not found, removing from queue',
        );
        return _ProcessResult.remove;
      }

      // Attempt sync
      await syncItem(item, userId).timeout(config.syncTimeout);

      _logger.debug(
        'Service',
        '[SyncQueue:$queueBoxName] Item synced successfully',
      );
      return _ProcessResult.success;
    } catch (e) {
      _logger.debug(
        'Service',
        '[SyncQueue:$queueBoxName] Sync failed: $e',
      );
      return _ProcessResult.retry;
    }
  }

  /// Increment retry count on a queue item
  Map<String, dynamic> _incrementRetry(Map<dynamic, dynamic> data) {
    return {
      'localKey': data['localKey'],
      'firestoreId': data['firestoreId'],
      'userId': data['userId'],
      'enqueuedAt': data['enqueuedAt'],
      'retryCount': (data['retryCount'] as int? ?? 0) + 1,
      'lastRetryAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Move an item to the dead letter queue
  Future<void> _moveToDeadLetter(Map<dynamic, dynamic> data) async {
    if (_deadLetterBox == null) await init();

    await _deadLetterBox!.add({
      ...Map<String, dynamic>.from(data),
      'movedToDeadLetterAt': DateTime.now().millisecondsSinceEpoch,
    });

    _logger.debug(
      'Service',
      '[SyncQueue:$queueBoxName] Item moved to dead letter queue',
    );
  }

  /// Get count of pending items
  Future<int> getPendingCount() async {
    if (_queueBox == null) await init();
    return _queueBox!.length;
  }

  /// Get count of dead letter items
  Future<int> getDeadLetterCount() async {
    if (_deadLetterBox == null) await init();
    return _deadLetterBox!.length;
  }

  /// Clear the queue
  Future<void> clear() async {
    if (_queueBox == null) await init();
    await _queueBox!.clear();
  }

  /// Clear the dead letter queue
  Future<void> clearDeadLetter() async {
    if (_deadLetterBox == null) await init();
    await _deadLetterBox!.clear();
  }

  /// Retry all items in dead letter queue
  Future<int> retryDeadLetterItems() async {
    if (_deadLetterBox == null) await init();
    if (_deadLetterBox!.isEmpty) return 0;

    int movedCount = 0;
    final keys = _deadLetterBox!.keys.toList();

    for (final key in keys) {
      final item = _deadLetterBox!.get(key);
      if (item != null) {
        // Reset retry count and move back to main queue
        await _queueBox!.add({
          'localKey': item['localKey'],
          'firestoreId': item['firestoreId'],
          'userId': item['userId'],
          'enqueuedAt': DateTime.now().millisecondsSinceEpoch,
          'retryCount': 0,
          'lastRetryAt': null,
        });
        await _deadLetterBox!.delete(key);
        movedCount++;
      }
    }

    _logger.debug(
      'Service',
      '[SyncQueue:$queueBoxName] Moved $movedCount items from dead letter to queue',
    );

    return movedCount;
  }

  /// Close the queue boxes
  Future<void> close() async {
    await _queueBox?.close();
    await _deadLetterBox?.close();
  }
}

/// Internal enum for process results
enum _ProcessResult {
  success,
  retry,
  deadLetter,
  remove,
  skip,
}
