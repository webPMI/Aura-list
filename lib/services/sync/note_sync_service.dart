/// Note synchronization service.
///
/// Handles bidirectional sync of notes between local Hive storage
/// and Firebase Firestore, with retry logic and debouncing.
library;

import 'dart:async';
import '../contracts/i_sync_service.dart';
import '../storage/local/hive_note_storage.dart';
import '../storage/cloud/firestore_note_storage.dart';
import '../error_handler.dart';
import '../logger_service.dart';
import '../../../models/note_model.dart';
import 'sync_queue.dart';
import 'sync_utils.dart';

/// Service for synchronizing notes between local and cloud storage
class NoteSyncService implements ISyncService<Note> {
  final HiveNoteStorage _localStorage;
  final FirestoreNoteStorage _cloudStorage;
  final ErrorHandler _errorHandler;
  final Future<bool> Function() _isCloudSyncEnabled;
  final LoggerService _logger = LoggerService();

  late final GenericSyncQueue<Note> _syncQueue;
  late final DebouncedSyncManager _debouncedSync;

  final SyncConfig config;
  bool _isSyncing = false;
  bool _initialized = false;

  NoteSyncService({
    required HiveNoteStorage localStorage,
    required FirestoreNoteStorage cloudStorage,
    required ErrorHandler errorHandler,
    required Future<bool> Function() isCloudSyncEnabled,
    this.config = const SyncConfig(),
  })  : _localStorage = localStorage,
        _cloudStorage = cloudStorage,
        _errorHandler = errorHandler,
        _isCloudSyncEnabled = isCloudSyncEnabled {
    _syncQueue = GenericSyncQueue<Note>(
      queueBoxName: 'note_sync_queue_v2',
      deadLetterBoxName: 'note_dead_letter_queue',
      errorHandler: errorHandler,
      findLocalItem: (key) => _localStorage.get(key),
      syncItem: _syncSingleNote,
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
    _logger.debug('Service', '[NoteSyncService] Initialized');
  }

  @override
  Future<bool> get isSyncEnabled => _isCloudSyncEnabled();

  @override
  bool get isSyncing => _isSyncing;

  @override
  Future<SyncOperationResult> syncToCloud(Note note, String userId) async {
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
      await _syncSingleNote(note, userId);
      return SyncOperationResult.success();
    } catch (e) {
      await addToQueue(note, userId);
      return SyncOperationResult.failed(e.toString());
    }
  }

  @override
  Future<void> syncToCloudDebounced(Note note, String userId) async {
    if (!await isSyncEnabled) return;
    if (!_cloudStorage.isAvailable) return;
    if (userId.isEmpty) return;

    note.updatedAt = DateTime.now();
    if (note.isInBox) await note.save();

    if (note.key != null) {
      _debouncedSync.add(note.key, userId);
    }
  }

  Future<void> _syncSingleNote(Note note, String userId) async {
    final result = await _cloudStorage.upsert(note, userId);

    if (!result.success) {
      throw Exception(result.error);
    }

    if (result.documentId != null && note.firestoreId != result.documentId) {
      note.firestoreId = result.documentId!;
      if (note.isInBox) {
        await note.save();
      } else {
        final localNote = await _localStorage.findByFirestoreId(result.documentId!) ??
            await _localStorage.findByCreatedAt(note.createdAt);
        if (localNote != null) {
          localNote.firestoreId = result.documentId!;
          await localNote.save();
        }
      }
    }

    _logger.debug(
      'Service',
      '[NoteSyncService] Note synced: ${note.firestoreId}',
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

      final cloudNotes = result.data ?? [];
      int imported = 0;

      for (final cloudNote in cloudNotes) {
        await _mergeCloudNote(cloudNote);
        imported++;
      }

      _logger.debug(
        'Service',
        '[NoteSyncService] Synced $imported notes from cloud',
      );

      return SyncOperationResult.success(itemsSynced: imported);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error syncing notes from cloud',
        stackTrace: stack,
      );
      return SyncOperationResult.failed(e.toString());
    }
  }

  Future<void> _mergeCloudNote(Note cloudNote) async {
    final localNote = await _localStorage.findByFirestoreId(cloudNote.firestoreId);

    if (localNote == null) {
      await _localStorage.save(cloudNote);
      return;
    }

    // Conflict resolution: last write wins
    final cloudUpdated = cloudNote.updatedAt;
    final localUpdated = localNote.updatedAt;

    if (cloudUpdated.isAfter(localUpdated)) {
      localNote.updateInPlace(
        title: cloudNote.title,
        content: cloudNote.content,
        updatedAt: cloudNote.updatedAt,
        taskId: cloudNote.taskId,
        color: cloudNote.color,
        isPinned: cloudNote.isPinned,
        tags: cloudNote.tags,
        deleted: cloudNote.deleted,
        deletedAt: cloudNote.deletedAt,
        checklist: cloudNote.checklist,
        notebookId: cloudNote.notebookId,
        status: cloudNote.status,
        richContent: cloudNote.richContent,
        contentType: cloudNote.contentType,
      );
      await localNote.save();
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

      final localOnlyNotes = await _localStorage.getPendingSync();
      for (final note in localOnlyNotes) {
        try {
          await _syncSingleNote(note, userId);
          totalSynced++;
        } catch (e) {
          await addToQueue(note, userId);
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
        '[NoteSyncService] Full sync complete: $totalSynced items',
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
  Future<void> addToQueue(Note note, String userId) async {
    if (!_initialized) await init();
    await _syncQueue.enqueue(
      localKey: note.key,
      firestoreId: note.firestoreId.isNotEmpty ? note.firestoreId : null,
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
      '[NoteSyncService] Flushing ${items.length} debounced items',
    );

    final byUser = <String, List<dynamic>>{};
    for (final item in items) {
      byUser.putIfAbsent(item.userId, () => []).add(item.key);
    }

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final keys = entry.value;

      final notes = <Note>[];
      for (final key in keys) {
        final note = await _localStorage.get(key);
        if (note != null && !note.deleted) {
          notes.add(note);
        }
      }

      if (notes.isNotEmpty) {
        final result = await _cloudStorage.batchWrite(notes, userId);
        if (result.success) {
          for (final note in notes) {
            if (note.isInBox) await note.save();
          }
        } else {
          for (final note in notes) {
            await addToQueue(note, userId);
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
  Future<void> moveToDeadLetter(SyncQueueItem<Note> item) async {}

  @override
  Future<List<SyncQueueItem<Note>>> getDeadLetterItems() async => [];

  @override
  Future<SyncOperationResult> retryDeadLetterItem(SyncQueueItem<Note> item) async {
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
