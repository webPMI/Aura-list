/// Cache policies for offline-first data management.
///
/// This module provides a flexible caching system that supports multiple
/// strategies for balancing data freshness with network efficiency.
///
/// Strategies:
/// - [CacheStrategy.cacheFirst]: Read from cache, sync in background
/// - [CacheStrategy.networkFirst]: Try network, fallback to cache
/// - [CacheStrategy.cacheOnly]: Never hit network
/// - [CacheStrategy.networkOnly]: Always fresh (for critical data)
/// - [CacheStrategy.staleWhileRevalidate]: Return cache immediately, update in background
library;

import 'package:flutter/foundation.dart';
import '../../services/logger_service.dart';

/// Available caching strategies
enum CacheStrategy {
  /// Read from cache first, sync with network in background.
  /// Best for: Regular data that can be slightly stale.
  cacheFirst,

  /// Try network first, fallback to cache on failure.
  /// Best for: Data that should be fresh when possible but must work offline.
  networkFirst,

  /// Never hit the network, only use local cache.
  /// Best for: Completely offline scenarios or data that never needs sync.
  cacheOnly,

  /// Always fetch from network, never use cache.
  /// Best for: Critical data that must be real-time accurate.
  networkOnly,

  /// Return cache immediately while revalidating in background.
  /// Best for: Perceived performance - show data fast, update quietly.
  staleWhileRevalidate,
}

/// Defines caching behavior for a specific data type or operation.
///
/// Example usage:
/// ```dart
/// final taskCachePolicy = CachePolicy(
///   strategy: CacheStrategy.staleWhileRevalidate,
///   maxAge: Duration(minutes: 5),
///   staleAge: Duration(minutes: 2),
///   persistOffline: true,
/// );
///
/// if (taskCachePolicy.isCacheValid(lastFetch)) {
///   return cachedData;
/// }
/// ```
class CachePolicy {
  /// The caching strategy to use
  final CacheStrategy strategy;

  /// Maximum age of cache before it's considered expired
  final Duration maxAge;

  /// Age at which cache is considered stale and should be revalidated
  /// (only used with staleWhileRevalidate strategy)
  final Duration staleAge;

  /// Whether to persist data for offline access
  final bool persistOffline;

  /// Whether to allow cached data when network fails
  final bool allowStaleOnError;

  /// Optional priority for cache eviction (higher = keep longer)
  final int priority;

  /// Create a cache policy with the specified parameters.
  ///
  /// [strategy]: The caching strategy to use
  /// [maxAge]: How long cache is valid (default: 5 minutes)
  /// [staleAge]: When to start background revalidation (default: 2 minutes)
  /// [persistOffline]: Whether to keep data for offline use (default: true)
  /// [allowStaleOnError]: Whether to use stale data on network error (default: true)
  /// [priority]: Cache eviction priority (default: 1)
  const CachePolicy({
    this.strategy = CacheStrategy.cacheFirst,
    this.maxAge = const Duration(minutes: 5),
    this.staleAge = const Duration(minutes: 2),
    this.persistOffline = true,
    this.allowStaleOnError = true,
    this.priority = 1,
  });

  /// Check if cached data is still valid based on the last fetch time.
  ///
  /// Returns true if the cache is within [maxAge] from [lastFetch].
  /// Returns false if [lastFetch] is null (no cache exists).
  bool isCacheValid(DateTime? lastFetch) {
    if (lastFetch == null) return false;

    // For cacheOnly, cache is always valid if it exists
    if (strategy == CacheStrategy.cacheOnly) return true;

    // For networkOnly, cache is never valid
    if (strategy == CacheStrategy.networkOnly) return false;

    final age = DateTime.now().difference(lastFetch);
    return age < maxAge;
  }

  /// Check if cache should be revalidated in the background.
  ///
  /// For [CacheStrategy.staleWhileRevalidate], returns true when cache
  /// is older than [staleAge] but younger than [maxAge].
  ///
  /// For other strategies, returns whether cache has exceeded [maxAge].
  bool shouldRevalidate(DateTime? lastFetch) {
    if (lastFetch == null) return true;

    // networkOnly always revalidates
    if (strategy == CacheStrategy.networkOnly) return true;

    // cacheOnly never revalidates
    if (strategy == CacheStrategy.cacheOnly) return false;

    final age = DateTime.now().difference(lastFetch);

    if (strategy == CacheStrategy.staleWhileRevalidate) {
      // Revalidate if past stale age but not expired
      return age >= staleAge;
    }

    // For other strategies, revalidate if past maxAge
    return age >= maxAge;
  }

  /// Get the remaining time until cache expires.
  ///
  /// Returns [Duration.zero] if cache is already expired or [lastFetch] is null.
  Duration timeUntilExpiry(DateTime? lastFetch) {
    if (lastFetch == null) return Duration.zero;

    final age = DateTime.now().difference(lastFetch);
    final remaining = maxAge - age;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get the remaining time until cache becomes stale.
  ///
  /// Returns [Duration.zero] if cache is already stale or [lastFetch] is null.
  Duration timeUntilStale(DateTime? lastFetch) {
    if (lastFetch == null) return Duration.zero;

    final age = DateTime.now().difference(lastFetch);
    final remaining = staleAge - age;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if cache should be used given the current network status.
  ///
  /// Returns true if:
  /// - Strategy is cacheOnly or cacheFirst
  /// - Cache is valid
  /// - Network is unavailable and allowStaleOnError is true
  bool shouldUseCache({
    required DateTime? lastFetch,
    required bool isOnline,
  }) {
    // Always use cache for cacheOnly
    if (strategy == CacheStrategy.cacheOnly) {
      return lastFetch != null;
    }

    // Never use cache for networkOnly (unless offline and allowStaleOnError)
    if (strategy == CacheStrategy.networkOnly) {
      return !isOnline && allowStaleOnError && lastFetch != null;
    }

    // If offline, use cache if available and allowed
    if (!isOnline) {
      return allowStaleOnError && lastFetch != null;
    }

    // cacheFirst: use cache if valid
    if (strategy == CacheStrategy.cacheFirst) {
      return isCacheValid(lastFetch);
    }

    // staleWhileRevalidate: always use cache if available
    if (strategy == CacheStrategy.staleWhileRevalidate) {
      return lastFetch != null;
    }

    // networkFirst: try network first, only use cache on failure
    return false;
  }

  /// Check if network should be fetched.
  ///
  /// Returns true if:
  /// - Strategy is networkOnly or networkFirst
  /// - Cache is expired or stale
  /// - Background revalidation is needed
  bool shouldFetchNetwork({
    required DateTime? lastFetch,
    required bool isOnline,
  }) {
    if (!isOnline) return false;

    // Never fetch for cacheOnly
    if (strategy == CacheStrategy.cacheOnly) return false;

    // Always fetch for networkOnly
    if (strategy == CacheStrategy.networkOnly) return true;

    // networkFirst: always try network first
    if (strategy == CacheStrategy.networkFirst) return true;

    // staleWhileRevalidate: fetch if stale or no cache
    if (strategy == CacheStrategy.staleWhileRevalidate) {
      return shouldRevalidate(lastFetch);
    }

    // cacheFirst: only fetch if cache invalid
    return !isCacheValid(lastFetch);
  }

  /// Create a copy with modified parameters.
  CachePolicy copyWith({
    CacheStrategy? strategy,
    Duration? maxAge,
    Duration? staleAge,
    bool? persistOffline,
    bool? allowStaleOnError,
    int? priority,
  }) {
    return CachePolicy(
      strategy: strategy ?? this.strategy,
      maxAge: maxAge ?? this.maxAge,
      staleAge: staleAge ?? this.staleAge,
      persistOffline: persistOffline ?? this.persistOffline,
      allowStaleOnError: allowStaleOnError ?? this.allowStaleOnError,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() {
    return 'CachePolicy('
        'strategy: $strategy, '
        'maxAge: $maxAge, '
        'staleAge: $staleAge, '
        'persistOffline: $persistOffline)';
  }
}

/// Pre-defined cache policies for common use cases.
class CachePolicies {
  CachePolicies._();

  /// For tasks: Cache first with 5-minute freshness.
  /// Syncs in background after 2 minutes stale.
  static const tasks = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    maxAge: Duration(minutes: 5),
    staleAge: Duration(minutes: 2),
    persistOffline: true,
    priority: 2,
  );

  /// For notes: Same as tasks, slightly longer cache.
  static const notes = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    maxAge: Duration(minutes: 10),
    staleAge: Duration(minutes: 5),
    persistOffline: true,
    priority: 2,
  );

  /// For user preferences: Cache longer, less critical.
  static const userPreferences = CachePolicy(
    strategy: CacheStrategy.cacheFirst,
    maxAge: Duration(hours: 1),
    staleAge: Duration(minutes: 30),
    persistOffline: true,
    priority: 3,
  );

  /// For history/statistics: Cache only, compute locally.
  static const history = CachePolicy(
    strategy: CacheStrategy.cacheOnly,
    maxAge: Duration(hours: 24),
    persistOffline: true,
    priority: 1,
  );

  /// For real-time data: Always fetch fresh.
  static const realtime = CachePolicy(
    strategy: CacheStrategy.networkOnly,
    maxAge: Duration.zero,
    persistOffline: false,
    priority: 0,
  );

  /// For dashboard: Stale while revalidate with short stale time.
  static const dashboard = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    maxAge: Duration(minutes: 3),
    staleAge: Duration(seconds: 30),
    persistOffline: true,
    priority: 2,
  );

  /// For syncing: Network first to ensure data is sent.
  static const sync = CachePolicy(
    strategy: CacheStrategy.networkFirst,
    maxAge: Duration.zero,
    persistOffline: true,
    allowStaleOnError: true,
    priority: 3,
  );
}

/// Mixin for classes that use cache policies.
mixin CachePolicyMixin {
  /// Get the cache policy for this data type.
  CachePolicy get cachePolicy;

  /// Last time data was fetched from network.
  DateTime? get lastFetchTime;

  /// Check if cache is valid.
  bool get isCacheValid => cachePolicy.isCacheValid(lastFetchTime);

  /// Check if revalidation is needed.
  bool get needsRevalidation => cachePolicy.shouldRevalidate(lastFetchTime);

  /// Log cache status for debugging.
  void logCacheStatus() {
    if (kDebugMode) {
      final status = isCacheValid ? 'VALID' : 'EXPIRED';
      final revalidate = needsRevalidation ? 'YES' : 'NO';
      LoggerService().debug('CachePolicy', 'Status: $status, Revalidate: $revalidate, LastFetch: $lastFetchTime');
    }
  }
}
