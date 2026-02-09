/// Firebase quota management for optimizing reads/writes.
///
/// This service tracks and manages Firebase Firestore operations to:
/// - Track reads/writes per session
/// - Use Source.cache when data is fresh
/// - Batch operations when possible
/// - Log quota usage for monitoring
///
/// Firebase Firestore pricing is based on reads, writes, and deletes.
/// This manager helps minimize costs while maintaining data freshness.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cache/cache_policy.dart';
import 'error_handler.dart';

/// Statistics for Firebase operations
class QuotaStats {
  final int readsThisSession;
  final int writesThisSession;
  final int deletesThisSession;
  final int cacheHitsThisSession;
  final int batchOperationsThisSession;
  final DateTime sessionStart;

  const QuotaStats({
    this.readsThisSession = 0,
    this.writesThisSession = 0,
    this.deletesThisSession = 0,
    this.cacheHitsThisSession = 0,
    this.batchOperationsThisSession = 0,
    required this.sessionStart,
  });

  /// Total billable operations (reads + writes + deletes)
  int get totalOperations =>
      readsThisSession + writesThisSession + deletesThisSession;

  /// Cache hit rate as percentage
  double get cacheHitRate {
    final total = readsThisSession + cacheHitsThisSession;
    if (total == 0) return 0.0;
    return (cacheHitsThisSession / total) * 100;
  }

  /// Session duration
  Duration get sessionDuration => DateTime.now().difference(sessionStart);

  QuotaStats copyWith({
    int? readsThisSession,
    int? writesThisSession,
    int? deletesThisSession,
    int? cacheHitsThisSession,
    int? batchOperationsThisSession,
  }) {
    return QuotaStats(
      readsThisSession: readsThisSession ?? this.readsThisSession,
      writesThisSession: writesThisSession ?? this.writesThisSession,
      deletesThisSession: deletesThisSession ?? this.deletesThisSession,
      cacheHitsThisSession: cacheHitsThisSession ?? this.cacheHitsThisSession,
      batchOperationsThisSession:
          batchOperationsThisSession ?? this.batchOperationsThisSession,
      sessionStart: sessionStart,
    );
  }

  @override
  String toString() {
    return 'QuotaStats('
        'reads: $readsThisSession, '
        'writes: $writesThisSession, '
        'deletes: $deletesThisSession, '
        'cacheHits: $cacheHitsThisSession, '
        'cacheHitRate: ${cacheHitRate.toStringAsFixed(1)}%, '
        'batches: $batchOperationsThisSession)';
  }
}

/// Configuration for quota management
class QuotaConfig {
  /// Maximum reads per session before warning
  final int warnReadsThreshold;

  /// Maximum writes per session before warning
  final int warnWritesThreshold;

  /// Minimum interval between same-collection reads
  final Duration minReadInterval;

  /// Whether to log quota operations
  final bool enableLogging;

  /// Whether to use cache aggressively
  final bool aggressiveCaching;

  const QuotaConfig({
    this.warnReadsThreshold = 100,
    this.warnWritesThreshold = 50,
    this.minReadInterval = const Duration(seconds: 10),
    this.enableLogging = true,
    this.aggressiveCaching = true,
  });

  /// Conservative config for low-bandwidth/quota scenarios
  static const conservative = QuotaConfig(
    warnReadsThreshold: 50,
    warnWritesThreshold: 25,
    minReadInterval: Duration(seconds: 30),
    enableLogging: true,
    aggressiveCaching: true,
  );

  /// Normal config for typical usage
  static const normal = QuotaConfig(
    warnReadsThreshold: 100,
    warnWritesThreshold: 50,
    minReadInterval: Duration(seconds: 10),
    enableLogging: true,
    aggressiveCaching: true,
  );

  /// Relaxed config for high-bandwidth scenarios
  static const relaxed = QuotaConfig(
    warnReadsThreshold: 500,
    warnWritesThreshold: 200,
    minReadInterval: Duration(seconds: 5),
    enableLogging: false,
    aggressiveCaching: false,
  );
}

/// Manages Firebase quota to optimize costs
class FirebaseQuotaManager {
  final ErrorHandler _errorHandler;
  final QuotaConfig config;

  /// Current quota statistics
  QuotaStats _stats;

  /// Last read time per collection
  final Map<String, DateTime> _lastReadTimes = {};

  /// Cache policies per collection
  final Map<String, CachePolicy> _collectionPolicies = {};

  /// Last sync timestamps per collection
  final Map<String, DateTime> _collectionLastSync = {};

  FirebaseQuotaManager({
    required ErrorHandler errorHandler,
    this.config = const QuotaConfig(),
  })  : _errorHandler = errorHandler,
        _stats = QuotaStats(sessionStart: DateTime.now()) {
    // Set up default collection policies
    _collectionPolicies['tasks'] = CachePolicies.tasks;
    _collectionPolicies['notes'] = CachePolicies.notes;
    _collectionPolicies['preferences'] = CachePolicies.userPreferences;
    _collectionPolicies['history'] = CachePolicies.history;
  }

  /// Number of reads this session
  int get readsThisSession => _stats.readsThisSession;

  /// Number of writes this session
  int get writesThisSession => _stats.writesThisSession;

  /// Current quota stats
  QuotaStats get stats => _stats;

  /// Set cache policy for a collection
  void setCachePolicy(String collection, CachePolicy policy) {
    _collectionPolicies[collection] = policy;
  }

  /// Get cache policy for a collection
  CachePolicy getCachePolicy(String collection) {
    return _collectionPolicies[collection] ?? CachePolicies.tasks;
  }

  /// Update last sync time for a collection
  void updateCollectionSync(String collection) {
    _collectionLastSync[collection] = DateTime.now();
  }

  /// Get last sync time for a collection
  DateTime? getCollectionLastSync(String collection) {
    return _collectionLastSync[collection];
  }

  /// Check if cache should be used for a collection
  bool shouldUseCache(String collection, {DateTime? lastFetch}) {
    final policy = getCachePolicy(collection);
    final lastSync = lastFetch ?? _collectionLastSync[collection];

    // Check if we've read too recently
    final lastRead = _lastReadTimes[collection];
    if (lastRead != null) {
      final timeSinceRead = DateTime.now().difference(lastRead);
      if (timeSinceRead < config.minReadInterval) {
        _log('[Quota] Using cache: too recent read ($timeSinceRead < ${config.minReadInterval})');
        return true;
      }
    }

    // Check cache policy
    if (policy.isCacheValid(lastSync)) {
      _log('[Quota] Using cache: policy says valid');
      return true;
    }

    return false;
  }

  /// Determine the Firestore source to use
  Source getSource(String collection, {bool forceNetwork = false}) {
    if (forceNetwork) {
      return Source.server;
    }

    if (config.aggressiveCaching && shouldUseCache(collection)) {
      return Source.cache;
    }

    return Source.serverAndCache;
  }

  /// Execute a read operation with quota tracking
  Future<T> executeRead<T>(
    Future<T> Function() operation, {
    String collection = 'unknown',
    bool forceNetwork = false,
  }) async {
    final useCache = !forceNetwork && shouldUseCache(collection);

    if (useCache) {
      _incrementCacheHits();
      _log('[Quota] Cache hit for $collection');
    } else {
      _incrementReads();
      _lastReadTimes[collection] = DateTime.now();
      _log('[Quota] Network read for $collection');
    }

    _checkReadThreshold();

    try {
      final result = await operation();
      return result;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Firebase read failed for $collection',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Execute a write operation with quota tracking
  Future<T> executeWrite<T>(
    Future<T> Function() operation, {
    String collection = 'unknown',
  }) async {
    _incrementWrites();
    _checkWriteThreshold();
    _log('[Quota] Write to $collection');

    try {
      final result = await operation();
      updateCollectionSync(collection);
      return result;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Firebase write failed for $collection',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Execute a delete operation with quota tracking
  Future<T> executeDelete<T>(
    Future<T> Function() operation, {
    String collection = 'unknown',
  }) async {
    _incrementDeletes();
    _log('[Quota] Delete in $collection');

    try {
      final result = await operation();
      return result;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Firebase delete failed for $collection',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Execute a batch operation with quota tracking
  Future<void> executeBatch(
    Future<void> Function(WriteBatch batch) operation,
    FirebaseFirestore firestore, {
    String description = 'batch operation',
  }) async {
    _incrementBatch();
    _log('[Quota] Batch: $description');

    try {
      final batch = firestore.batch();
      await operation(batch);
      await batch.commit();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Firebase batch failed: $description',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get GetOptions with the appropriate source
  GetOptions getOptionsForCollection(
    String collection, {
    bool forceNetwork = false,
  }) {
    return GetOptions(source: getSource(collection, forceNetwork: forceNetwork));
  }

  /// Increment read counter
  void _incrementReads({int count = 1}) {
    _stats = _stats.copyWith(
      readsThisSession: _stats.readsThisSession + count,
    );
  }

  /// Increment write counter
  void _incrementWrites({int count = 1}) {
    _stats = _stats.copyWith(
      writesThisSession: _stats.writesThisSession + count,
    );
  }

  /// Increment delete counter
  void _incrementDeletes({int count = 1}) {
    _stats = _stats.copyWith(
      deletesThisSession: _stats.deletesThisSession + count,
    );
  }

  /// Increment cache hit counter
  void _incrementCacheHits({int count = 1}) {
    _stats = _stats.copyWith(
      cacheHitsThisSession: _stats.cacheHitsThisSession + count,
    );
  }

  /// Increment batch counter
  void _incrementBatch({int count = 1}) {
    _stats = _stats.copyWith(
      batchOperationsThisSession: _stats.batchOperationsThisSession + count,
    );
  }

  /// Check if read threshold exceeded
  void _checkReadThreshold() {
    if (_stats.readsThisSession >= config.warnReadsThreshold) {
      _log('[Quota] WARNING: Read threshold exceeded '
          '(${_stats.readsThisSession}/${config.warnReadsThreshold})');
    }
  }

  /// Check if write threshold exceeded
  void _checkWriteThreshold() {
    if (_stats.writesThisSession >= config.warnWritesThreshold) {
      _log('[Quota] WARNING: Write threshold exceeded '
          '(${_stats.writesThisSession}/${config.warnWritesThreshold})');
    }
  }

  /// Log message if logging enabled
  void _log(String message) {
    if (config.enableLogging && kDebugMode) {
      debugPrint(message);
    }
  }

  /// Reset session statistics
  void resetStats() {
    _stats = QuotaStats(sessionStart: DateTime.now());
    _lastReadTimes.clear();
    _log('[Quota] Stats reset');
  }

  /// Print current quota usage summary
  void printSummary() {
    if (kDebugMode) {
      debugPrint('');
      debugPrint('=== Firebase Quota Summary ===');
      debugPrint('Session duration: ${_stats.sessionDuration}');
      debugPrint('Reads: ${_stats.readsThisSession}');
      debugPrint('Writes: ${_stats.writesThisSession}');
      debugPrint('Deletes: ${_stats.deletesThisSession}');
      debugPrint('Cache hits: ${_stats.cacheHitsThisSession}');
      debugPrint('Cache hit rate: ${_stats.cacheHitRate.toStringAsFixed(1)}%');
      debugPrint('Batch operations: ${_stats.batchOperationsThisSession}');
      debugPrint('Total billable: ${_stats.totalOperations}');
      debugPrint('==============================');
      debugPrint('');
    }
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for Firebase quota manager
final quotaManagerProvider = Provider<FirebaseQuotaManager>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);

  final manager = FirebaseQuotaManager(
    errorHandler: errorHandler,
    config: const QuotaConfig(),
  );

  ref.onDispose(() {
    manager.printSummary();
  });

  return manager;
});

/// Provider for current quota stats
final quotaStatsProvider = Provider<QuotaStats>((ref) {
  final manager = ref.watch(quotaManagerProvider);
  return manager.stats;
});

/// Provider for reads this session
final readsThisSessionProvider = Provider<int>((ref) {
  final manager = ref.watch(quotaManagerProvider);
  return manager.readsThisSession;
});

/// Provider for writes this session
final writesThisSessionProvider = Provider<int>((ref) {
  final manager = ref.watch(quotaManagerProvider);
  return manager.writesThisSession;
});
