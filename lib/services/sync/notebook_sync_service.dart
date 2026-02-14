/// Notebook synchronization service.
///
/// Handles bidirectional sync of notebooks between local Hive storage
/// and Firebase Firestore, with retry logic and debouncing.
library;

import 'dart:async';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_notebook_storage.dart';
import '../storage/cloud/firestore_notebook_storage.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/notebook_model.dart';
import 'sync_queue.dart';
import 'sync_utils.dart';

/// Service for synchronizing notebooks between local and cloud storage
class NotebookSyncService implements ISyncService<Notebook> {
  final HiveNotebookStorage _localStorage;
  final FirestoreNotebookStorage _cloudStorage;
  final ErrorHandler _errorHandler;
  final Future<bool> Function() _isCloudSyncEnabled;
  final LoggerService _logger = LoggerService();

  late final GenericSyncQueue<Notebook> _syncQueue;
  late final DebouncedSyncManager _debouncedSync;

  final SyncConfig config;
  bool _isSyncing = false;
  bool _initialized = false;

  NotebookSyncService({
    required HiveNotebookStorage localStorage,
    required FirestoreNotebookStorage cloudStorage,
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    this.config = const SyncConfig(),
  })  : _localStorage = localStorage,
        _cloudStorage = cloudStorage,
        _errorHandler = errorHandler,
        _isCloudSyncEnabled = isCloudSyncEnabled {
    _syncQueue = GenericSyncQueue<Notebook>(
      queueBoxName: 'notebook_sync_queue_v2',
      deadLetterBoxName: 'notebook_dead_letter_queue',
      errorHandler: errorHandler,
      findLocalItem: (key) => _localStorage.get(key),
      syncItem: _syncSingleNotebook,
      config: config,
    );

    _debouncedSync = DebouncedSyncManager(
      debounceDelay: config.debounceDelay,
      onFlush: _flushDebouncedItems,
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    await _syncQueue.init();
    _initialized = true;
    _logger.debug('Service', '[NotebookSyncService] Initialized');
  }

  @override
  Future<bool> get isSyncEnabled => _isCloudSyncEnabled();

  @override
  bool get isSyncing => _isSyncing;

  /// Elimina un notebook de Firestore por su ID de documento.
  /// No falla si el documento no existe o si el cloud no está disponible.
  Future<void> deleteFromCloud(String firestoreId, String userId) async {
    if (!_cloudStorage.isAvailable) return;
    if (userId.isEmpty || firestoreId.isEmpty) return;
    try {
      await _cloudStorage.delete(firestoreId, userId);
      _logger.debug(
          'Service', '[NotebookSyncService] Deleted from cloud: $firestoreId');
    } catch (e) {
      _logger.warning(
          'Service', '[NotebookSyncService] Error deleting from cloud: $e');
    }
  }

  @override
  Future<SyncOperationResult> syncToCloud(Notebook notebook, String userId) async {
    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    if (!_cloudStorage.isAvailable) {
      return SyncOperationResult.offline();
    }

    if (userId.isEmpty) {
      return SyncOperationResult.skipped('User not authenticated');
    }

    try {
      await _syncSingleNotebook(notebook, userId);
      return SyncOperationResult.success();
    } catch (e) {
      await addToQueue(notebook, userId);
      return SyncOperationResult.failed(e.toString());
    }
  }

  @override
  Future<void> syncToCloudDebounced(Notebook notebook, String userId) async {
    if (!await isSyncEnabled) return;
    if (!_cloudStorage.isAvailable) return;
    if (userId.isEmpty) return;

    notebook.updatedAt = DateTime.now();
    if (notebook.isInBox) await notebook.save();

    if (notebook.key != null) {
      _debouncedSync.add(notebook.key, userId);
    }
  }

  Future<void> _syncSingleNotebook(Notebook notebook, String userId) async {
    final result = await _cloudStorage.upsert(notebook, userId);

    if (!result.success) {
      throw Exception(result.error);
    }

    if (result.documentId != null && notebook.firestoreId != result.documentId) {
      notebook.firestoreId = result.documentId!;
      if (notebook.isInBox) {
        await notebook.save();
      } else {
        final localNotebook = await _localStorage.findByFirestoreId(result.documentId!) ??
            await _localStorage.findByCreatedAt(notebook.createdAt);
        if (localNotebook != null) {
          localNotebook.firestoreId = result.documentId!;
          await localNotebook.save();
        }
      }
    }

    _logger.debug(
      'Service',
      '[NotebookSyncService] Notebook synced: ${notebook.firestoreId}',
    );
  }

  @override
  Future<SyncOperationResult> syncFromCloud(
    String userId, {
    DateTime? since,
  }) async {
    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    if (!_cloudStorage.isAvailable) {
      return SyncOperationResult.offline();
    }

    if (userId.isEmpty) {
      return SyncOperationResult.skipped('User not authenticated');
    }

    try {
      final result = since != null
          ? await _cloudStorage.getModifiedSince(userId, since)
          : await _cloudStorage.getAll(userId);

      if (!result.success) {
        return SyncOperationResult.failed(result.error ?? 'Unknown error');
      }

      final cloudNotebooks = result.data ?? [];
      int imported = 0;

      for (final cloudNotebook in cloudNotebooks) {
        await _mergeCloudNotebook(cloudNotebook);
        imported++;
      }

      _logger.debug(
        'Service',
        '[NotebookSyncService] Synced $imported notebooks from cloud',
      );

      return SyncOperationResult.success(itemsSynced: imported);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error syncing notebooks from cloud',
        stackTrace: stack,
      );
      return SyncOperationResult.failed(e.toString());
    }
  }

  Future<void> _mergeCloudNotebook(Notebook cloudNotebook) async {
    final localNotebook = await _localStorage.findByFirestoreId(cloudNotebook.firestoreId);

    if (localNotebook == null) {
      await _localStorage.save(cloudNotebook);
      return;
    }

    // Conflict resolution: last write wins
    final cloudUpdated = cloudNotebook.updatedAt;
    final localUpdated = localNotebook.updatedAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      localNotebook.updateInPlace(
        name: cloudNotebook.name,
        icon: cloudNotebook.icon,
        color: cloudNotebook.color,
        updatedAt: cloudNotebook.updatedAt,
        isFavorited: cloudNotebook.isFavorited,
        parentId: cloudNotebook.parentId,
      );
      await localNotebook.save();
    }
  }

  @override
  Future<SyncOperationResult> performFullSync(String userId) async {
    if (_isSyncing) {
      return SyncOperationResult.skipped('Sync already in progress');
    }

    if (!await isSyncEnabled) {
      return SyncOperationResult.skipped('Cloud sync disabled');
    }

    _isSyncing = true;
    int totalSynced = 0;
    final errors = <String>[];

    try {
      await flushPendingSyncs();

      final queueResult = await processQueue();
      if (queueResult.isSuccess) {
        totalSynced += queueResult.itemsSynced;
      } else {
        errors.addAll(queueResult.errors);
      }

      final localOnlyNotebooks = await _localStorage.getPendingSync();
      for (final notebook in localOnlyNotebooks) {
        try {
          await _syncSingleNotebook(notebook, userId);
          totalSynced++;
        } catch (e) {
          await addToQueue(notebook, userId);
          errors.add(e.toString());
        }
      }

      final cloudResult = await syncFromCloud(userId);
      if (cloudResult.isSuccess) {
        totalSynced += cloudResult.itemsSynced;
      } else {
        errors.addAll(cloudResult.errors);
      }

      _logger.debug(
        'Service',
        '[NotebookSyncService] Full sync complete: $totalSynced items',
      );

      return SyncOperationResult(
        status: errors.isEmpty
            ? SyncOperationStatus.success
            : SyncOperationStatus.failed,
        itemsSynced: totalSynced,
        itemsFailed: errors.length,
        errors: errors,
        timestamp: DateTime.now(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> addToQueue(Notebook notebook, String userId) async {
    if (!_initialized) await init();
    await _syncQueue.enqueue(
      localKey: notebook.key,
      firestoreId: notebook.firestoreId.isNotEmpty ? notebook.firestoreId : null,
      userId: userId,
    );
  }

  @override
  Future<SyncOperationResult> processQueue() async {
    if (!_initialized) await init();
    return _syncQueue.processQueue();
  }

  @override
  Future<int> getPendingCount() async {
    if (!_initialized) await init();
    return _syncQueue.getPendingCount();
  }

  @override
  Future<void> flushPendingSyncs() async {
    await _debouncedSync.flush();
  }

  Future<void> _flushDebouncedItems(Set<PendingSyncItem> items) async {
    if (items.isEmpty) return;

    _logger.debug(
      'Service',
      '[NotebookSyncService] Flushing ${items.length} debounced items',
    );

    final byUser = <String, List<dynamic>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.userId, () => []).add(item.key);
    }

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final keys = entry.value;

      final notebooks = <Notebook>[];
      for (final key in keys) {
        final notebook = await _localStorage.get(key);
        if (notebook != null) {
          notebooks.add(notebook);
        }
      }

      if (notebooks.isNotEmpty) {
        final result = await _cloudStorage.batchWrite(notebooks, userId);
        if (result.success) {
          for (final notebook in notebooks) {
            if (notebook.isInBox) await notebook.save();
          }
        } else {
          for (final notebook in notebooks) {
            await addToQueue(notebook, userId);
          }
        }
      }
    }
  }

  @override
  Future<void> clearQueue() async {
    if (!_initialized) await init();
    await _syncQueue.clear();
  }

  @override
  Future<void> moveToDeadLetter(SyncQueueItem<Notebook> item) async {}

  @override
  Future<List<SyncQueueItem<Notebook>>> getDeadLetterItems() async => [];

  @override
  Future<SyncOperationResult> retryDeadLetterItem(SyncQueueItem<Notebook> item) async {
    return SyncOperationResult.skipped('Not implemented');
  }

  Future<int> getDeadLetterCount() async {
    if (!_initialized) await init();
    return _syncQueue.getDeadLetterCount();
  }

  Future<int> retryAllDeadLetterItems() async {
    if (!_initialized) await init();
    return _syncQueue.retryDeadLetterItems();
  }
}
