/// Synchronization utility functions.
///
/// Provides common utilities for sync operations including
/// backoff calculation, error handling, and retry logic.
library;

import 'dart:math';
import '../error_handler.dart';
import '../logger_service.dart';

/// Calculate exponential backoff duration
Duration calculateBackoff(
  int retryCount, {
  Duration initial = const Duration(seconds: 2),
  double multiplier = 2.0,
  Duration maximum = const Duration(minutes: 5),
}) {
  if (retryCount <= 0) return Duration.zero;
  final delayMs = initial.inMilliseconds * pow(multiplier, retryCount - 1);
  final delay = Duration(milliseconds: delayMs.toInt());
  return delay > maximum ? maximum : delay;
}

/// Check if enough time has passed since last retry
bool canRetryNow(
  int retryCount,
  DateTime? lastRetryAt, {
  Duration initial = const Duration(seconds: 2),
  double multiplier = 2.0,
}) {
  if (lastRetryAt == null || retryCount == 0) return true;

  final requiredDelay = calculateBackoff(
    retryCount,
    initial: initial,
    multiplier: multiplier,
  );
  final elapsed = DateTime.now().difference(lastRetryAt);
  return elapsed >= requiredDelay;
}

/// Check if a sync queue item is too old
bool isItemTooOld(DateTime enqueuedAt, {int maxAgeDays = 7}) {
  final age = DateTime.now().difference(enqueuedAt);
  return age.inDays > maxAgeDays;
}

/// Wrapper for executing operations with consistent error handling
Future<T> withErrorHandling<T>(
  Future<T> Function() operation, {
  required ErrorHandler errorHandler,
  required ErrorType type,
  required String operationName,
  T? fallbackValue,
  bool shouldRethrow = true,
}) async {
  final logger = LoggerService();
  try {
    return await operation();
  } catch (e, stack) {
    logger.error('SyncUtils', 'Error in $operationName', error: e);
    errorHandler.handle(
      e,
      type: type,
      severity: ErrorSeverity.error,
      message: 'Error en $operationName',
      stackTrace: stack,
    );
    if (fallbackValue != null) return fallbackValue;
    if (shouldRethrow) rethrow;
    return fallbackValue as T;
  }
}

/// Wrapper for executing operations with retry logic
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  required ErrorHandler errorHandler,
  required String operationName,
  int maxRetries = 3,
  Duration initialBackoff = const Duration(seconds: 2),
  bool Function(dynamic error)? shouldRetry,
}) async {
  final logger = LoggerService();
  int attempt = 0;

  while (true) {
    try {
      return await operation();
    } catch (e, stack) {
      attempt++;
      final canRetry = attempt < maxRetries &&
          (shouldRetry?.call(e) ?? _isRetryableError(e));

      if (canRetry) {
        final delay = calculateBackoff(attempt, initial: initialBackoff);
        logger.debug(
          'Service',
          '[$operationName] Retry $attempt/$maxRetries after ${delay.inSeconds}s',
        );
        await Future.delayed(delay);
        continue;
      }

      errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error en $operationName despues de $attempt intentos',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

/// Check if an error is retryable
bool _isRetryableError(dynamic error) {
  final errorStr = error.toString().toLowerCase();
  return errorStr.contains('timeout') ||
      errorStr.contains('network') ||
      errorStr.contains('connection') ||
      errorStr.contains('unavailable') ||
      errorStr.contains('deadline');
}

/// Pending sync item with captured userId
class PendingSyncItem {
  final dynamic key;
  final String userId;
  final DateTime timestamp;

  const PendingSyncItem({
    required this.key,
    required this.userId,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSyncItem &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// Debounced sync manager to avoid race conditions
class DebouncedSyncManager {
  final Duration debounceDelay;
  final Future<void> Function(Set<PendingSyncItem>) onFlush;
  final LoggerService _logger = LoggerService();

  final Set<PendingSyncItem> _pendingItems = {};
  Future<void>? _pendingFlush;
  DateTime? _lastScheduled;

  DebouncedSyncManager({
    required this.debounceDelay,
    required this.onFlush,
  });

  /// Add an item to pending sync with its userId captured
  void add(dynamic key, String userId) {
    _pendingItems.add(PendingSyncItem(
      key: key,
      userId: userId,
      timestamp: DateTime.now(),
    ));
    _scheduleFlush();
  }

  /// Schedule a flush after debounce delay
  void _scheduleFlush() {
    _lastScheduled = DateTime.now();

    // Cancel any existing pending flush by letting it check the timestamp
    _pendingFlush ??= _delayedFlush();
  }

  Future<void> _delayedFlush() async {
    await Future.delayed(debounceDelay);

    // Check if more items were added during the delay
    if (_lastScheduled != null &&
        DateTime.now().difference(_lastScheduled!) < debounceDelay) {
      // Reset and wait again
      _pendingFlush = _delayedFlush();
      return;
    }

    await _doFlush();
    _pendingFlush = null;
  }

  Future<void> _doFlush() async {
    if (_pendingItems.isEmpty) return;

    final items = Set<PendingSyncItem>.from(_pendingItems);
    _pendingItems.clear();

    _logger.debug(
      'Service',
      '[DebouncedSync] Flushing ${items.length} items',
    );

    await onFlush(items);
  }

  /// Force flush immediately
  Future<void> flush() async {
    _pendingFlush = null;
    await _doFlush();
  }

  /// Get count of pending items
  int get pendingCount => _pendingItems.length;

  /// Clear all pending items without flushing
  void clear() {
    _pendingItems.clear();
    _pendingFlush = null;
  }
}
