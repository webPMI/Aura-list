/// Centralized performance-related providers for the AuraList app.
///
/// This module exports providers for:
/// - SyncWatcher - Background sync coordination
/// - FirebaseQuotaManager - Firebase operation tracking
/// - HiveIntegrityChecker - Database integrity monitoring
/// - CachePolicy - Caching strategies
library;

// Re-export the service providers for easy access
export '../services/sync_watcher_service.dart'
    show
        SyncWatcher,
        SyncStatus,
        SyncState,
        syncWatcherProvider,
        syncStatusProvider,
        currentSyncStateProvider,
        pendingSyncCountProvider,
        isSyncingProvider;

export '../services/firebase_quota_manager.dart'
    show
        FirebaseQuotaManager,
        QuotaStats,
        QuotaConfig,
        quotaManagerProvider,
        quotaStatsProvider,
        readsThisSessionProvider,
        writesThisSessionProvider;

export '../services/hive_integrity_checker.dart'
    show
        HiveIntegrityChecker,
        IntegrityReport,
        BoxStatus,
        BoxHealth,
        hiveIntegrityCheckerProvider,
        integrityReportProvider,
        allBoxesHealthyProvider;

export '../core/cache/cache_policy.dart'
    show CachePolicy, CacheStrategy, CachePolicies, CachePolicyMixin;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_watcher_service.dart';
import '../services/firebase_quota_manager.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';

// ==================== CONVENIENCE PROVIDERS ====================

/// Provider that combines sync status with connectivity for UI display
final syncDisplayStatusProvider = Provider.autoDispose<String>((ref) {
  final connectivity = ref.watch(connectivityStreamProvider);
  final syncState = ref.watch(currentSyncStateProvider);

  return connectivity.when(
    data: (isConnected) {
      if (!isConnected) {
        return 'Trabajando sin conexion';
      }

      switch (syncState.status) {
        case SyncStatus.idle:
          return 'Sincronizado';
        case SyncStatus.syncing:
          return 'Sincronizando...';
        case SyncStatus.pendingChanges:
          return '${syncState.totalPendingCount} cambios pendientes';
        case SyncStatus.error:
          return 'Error de sincronizacion';
        case SyncStatus.offline:
          return 'Sin conexion';
      }
    },
    loading: () => 'Verificando conexion...',
    error: (e, s) => 'Error de red',
  );
});

/// Provider for database health status
final databaseHealthProvider = FutureProvider.autoDispose<String>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  await dbService.init();

  final report = dbService.lastIntegrityReport;
  if (report == null) {
    return 'No verificado';
  }

  if (report.allHealthy) {
    return 'Saludable (${report.totalItems} items)';
  }

  if (report.allUsable) {
    return 'Degradado (${report.problemBoxes.length} issues)';
  }

  return 'Necesita atencion';
});

/// Provider for quota usage percentage
final quotaUsagePercentProvider = Provider.autoDispose<double>((ref) {
  final manager = ref.watch(quotaManagerProvider);
  final stats = manager.stats;

  // Assuming 100 reads as soft limit for warning
  const softLimit = 100.0;
  return (stats.readsThisSession / softLimit).clamp(0.0, 1.0);
});

/// Provider for cache hit rate
final cacheHitRateProvider = Provider.autoDispose<double>((ref) {
  final manager = ref.watch(quotaManagerProvider);
  return manager.stats.cacheHitRate;
});

/// Provider to check if any performance issues exist
final hasPerformanceIssuesProvider = Provider.autoDispose<bool>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final syncState = ref.watch(currentSyncStateProvider);
  final quotaManager = ref.watch(quotaManagerProvider);

  // Check database health
  final report = dbService.lastIntegrityReport;
  if (report != null && !report.allUsable) {
    return true;
  }

  // Check sync status
  if (syncState.status == SyncStatus.error) {
    return true;
  }

  // Check quota usage
  if (quotaManager.stats.readsThisSession > 100) {
    return true;
  }

  return false;
});

/// Provider that auto-starts the sync watcher
final autoStartSyncWatcherProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final watcher = ref.read(syncWatcherProvider);

  if (!watcher.isWatching) {
    await watcher.startWatching();
  }

  ref.onDispose(() {
    watcher.stopWatching();
  });
});

/// Provider for a summary of performance metrics
final performanceSummaryProvider = Provider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  final dbService = ref.watch(databaseServiceProvider);
  final syncState = ref.watch(currentSyncStateProvider);
  final quotaStats = ref.watch(quotaStatsProvider);

  return {
    'syncStatus': syncState.status.name,
    'pendingChanges': syncState.totalPendingCount,
    'lastSync': syncState.lastSyncTime?.toIso8601String(),
    'readsThisSession': quotaStats.readsThisSession,
    'writesThisSession': quotaStats.writesThisSession,
    'cacheHitRate': quotaStats.cacheHitRate,
    'databaseHealthy': dbService.lastIntegrityReport?.allHealthy ?? true,
    'totalItems': dbService.lastIntegrityReport?.totalItems ?? 0,
  };
});
