import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/task_history.dart';
import '../models/note_model.dart';
import '../models/notebook_model.dart';
import '../models/user_preferences.dart';
import '../models/sync_metadata.dart';
import '../models/guide_achievement_model.dart';
import '../core/cache/cache_policy.dart';
import 'error_handler.dart';
import 'hive_integrity_checker.dart';
import 'firebase_quota_manager.dart';
import 'logger_service.dart';

// Import new architecture
import 'repositories/task_repository.dart';
import 'repositories/note_repository.dart';
import 'repositories/notebook_repository.dart';
import '../providers/task_providers.dart';
import '../providers/note_providers.dart';
import '../providers/notebook_providers.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  final taskRepo = ref.read(taskRepositoryProvider);
  final noteRepo = ref.read(noteRepositoryProvider);
  final notebookRepo = ref.read(notebookRepositoryProvider);
  return DatabaseService(
    errorHandler,
    taskRepository: taskRepo,
    noteRepository: noteRepo,
    notebookRepository: notebookRepo,
  );
});

/// Provider for cloud sync enabled preference
/// Returns a stream that watches the cloudSyncEnabled preference
final cloudSyncEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  final db = ref.read(databaseServiceProvider);
  final prefs = await db.getUserPreferences();
  return prefs.cloudSyncEnabled;
});

/// Result of a sync operation
class SyncResult {
  final int tasksDownloaded;
  final int notesDownloaded;
  final int errors;

  SyncResult({
    required this.tasksDownloaded,
    required this.notesDownloaded,
    required this.errors,
  });

  bool get hasErrors => errors > 0;
  bool get hasChanges => tasksDownloaded > 0 || notesDownloaded > 0;
  int get totalDownloaded => tasksDownloaded + notesDownloaded;
}

/// DatabaseService - Facade for data operations
///
/// This service coordinates between repositories and maintains
/// user preferences, task history, and system-level operations.
///
/// For direct task/note/notebook operations, prefer using the
/// respective providers (tasksByTypeProvider, allNotesProvider, etc.)
class DatabaseService {
  final ErrorHandler _errorHandler;
  final TaskRepository _taskRepository;
  final NoteRepository _noteRepository;
  final NotebookRepository _notebookRepository;
  final _logger = LoggerService();

  DatabaseService(
    this._errorHandler, {
    required TaskRepository taskRepository,
    required NoteRepository noteRepository,
    required NotebookRepository notebookRepository,
  })  : _taskRepository = taskRepository,
        _noteRepository = noteRepository,
        _notebookRepository = notebookRepository;

  // Box names for services managed directly by DatabaseService
  static const String _historyBoxName = 'task_history';
  static const String _userPrefsBoxName = 'user_prefs';

  Box<TaskHistory>? _historyBox;
  Box<UserPreferences>? _userPrefsBox;
  bool _initialized = false;
  Completer<void>? _initCompleter;
  bool _isReinitializing = false;
  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = false;

  // Performance optimization components
  HiveIntegrityChecker? _integrityChecker;
  FirebaseQuotaManager? _quotaManager;
  IntegrityReport? _lastIntegrityReport;

  // Cache policies for different data types
  final Map<String, CachePolicy> _cachePolicies = {
    'tasks': CachePolicies.tasks,
    'notes': CachePolicies.notes,
    'preferences': CachePolicies.userPreferences,
    'history': CachePolicies.history,
  };

  // Last sync timestamps per collection
  final Map<String, DateTime> _collectionLastSync = {};

  FirebaseFirestore? get firestore {
    if (!_firebaseAvailable) return null;
    _firestore ??= FirebaseFirestore.instance;
    return _firestore;
  }

  bool get isFirebaseAvailable => _firebaseAvailable;

  Future<void> init({String? path}) async {
    // Already initialized, return immediately
    if (_initialized) return;

    // If initialization is in progress, wait for it to complete
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Start initialization
    _initCompleter = Completer<void>();

    try {
      if (path != null) {
        Hive.init(path);
      } else {
        await Hive.initFlutter();
      }

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NoteAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(TaskHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(SyncMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(NotebookAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(ChecklistItemAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(GuideAchievementAdapter());
      }

      // Open boxes managed directly by DatabaseService
      _historyBox = Hive.isBoxOpen(_historyBoxName)
          ? Hive.box<TaskHistory>(_historyBoxName)
          : await Hive.openBox<TaskHistory>(_historyBoxName);
      _userPrefsBox = Hive.isBoxOpen(_userPrefsBoxName)
          ? Hive.box<UserPreferences>(_userPrefsBoxName)
          : await Hive.openBox<UserPreferences>(_userPrefsBoxName);

      // Check if Firebase is available
      try {
        _firebaseAvailable = Firebase.apps.isNotEmpty;
      } catch (e) {
        _firebaseAvailable = false;
        _logger.warning(
          'DatabaseService',
          'Firebase no disponible',
          metadata: {'error': e.toString()},
        );
      }

      // Initialize performance components
      _integrityChecker ??= HiveIntegrityChecker(errorHandler: _errorHandler);
      if (_firebaseAvailable && _quotaManager == null) {
        _quotaManager = FirebaseQuotaManager(errorHandler: _errorHandler);
      }

      // Initialize repositories
      await _taskRepository.init();
      await _noteRepository.init();
      await _notebookRepository.init();

      _initialized = true;
      _initCompleter!.complete();

      // Run integrity check on all boxes
      await _runIntegrityCheck();

      // Run migrations for existing data
      await _runMigrations();

      _logger.debug('Service', '[DatabaseService] Initialized with repositories');
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Check if a box is open and usable
  bool _isBoxUsable<T>(Box<T>? box) {
    if (box == null) return false;
    try {
      return box.isOpen;
    } catch (e) {
      return false;
    }
  }

  /// Reinitialize boxes after connection closed (iOS/Web IndexedDB issue)
  Future<void> _reinitializeBoxes() async {
    if (_isReinitializing) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    _isReinitializing = true;
    _logger.info(
      'DatabaseService',
      'Reinitializando conexión a base de datos...',
    );

    try {
      // Close existing boxes if they exist
      try {
        if (_historyBox != null && _historyBox!.isOpen) {
          await _historyBox!.close();
        }
        if (_userPrefsBox != null && _userPrefsBox!.isOpen) {
          await _userPrefsBox!.close();
        }
      } catch (e) {
        _logger.warning('DatabaseService', 'Error cerrando boxes: $e');
      }

      // Small delay to let IndexedDB clean up
      await Future.delayed(const Duration(milliseconds: 100));

      // Reopen boxes
      _historyBox = await Hive.openBox<TaskHistory>(_historyBoxName);
      _userPrefsBox = await Hive.openBox<UserPreferences>(_userPrefsBoxName);

      _logger.info('DatabaseService', 'Conexión reinicializada exitosamente');
    } catch (e, stack) {
      _logger.error('DatabaseService', 'Error reinicializando', error: e);
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error reinicializando base de datos',
        stackTrace: stack,
      );
    } finally {
      _isReinitializing = false;
    }
  }

  /// Run integrity check on all Hive boxes
  Future<void> _runIntegrityCheck() async {
    final checker = _integrityChecker;
    if (checker == null) return;

    try {
      _lastIntegrityReport = await checker.checkAllBoxes();

      if (!_lastIntegrityReport!.allHealthy) {
        _logger.debug(
          'Service',
          '[Database] Some boxes need attention, attempting repair...',
        );
        _lastIntegrityReport = await checker.repairAllBoxes();

        if (!_lastIntegrityReport!.allUsable) {
          _errorHandler.handle(
            'Database integrity issues detected',
            type: ErrorType.database,
            severity: ErrorSeverity.warning,
            message: 'Some database boxes could not be fully repaired',
            userMessage: 'Algunos datos pueden haberse perdido',
          );
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error running integrity check',
        stackTrace: stack,
      );
    }
  }

  /// Get the last integrity report
  IntegrityReport? get lastIntegrityReport => _lastIntegrityReport;

  /// Get cache policy for a collection
  CachePolicy getCachePolicy(String collection) {
    return _cachePolicies[collection] ?? CachePolicies.tasks;
  }

  /// Set cache policy for a collection
  void setCachePolicy(String collection, CachePolicy policy) {
    _cachePolicies[collection] = policy;
  }

  /// Check if cache is valid for a collection
  bool isCacheValid(String collection) {
    final policy = getCachePolicy(collection);
    final lastSync = _collectionLastSync[collection];
    return policy.isCacheValid(lastSync);
  }

  /// Update last sync time for a collection
  void updateCollectionSync(String collection) {
    _collectionLastSync[collection] = DateTime.now();
    _quotaManager?.updateCollectionSync(collection);
  }

  /// Get quota manager for tracking Firebase operations
  FirebaseQuotaManager? get quotaManager => _quotaManager;

  /// Check if we should use cache for a collection
  bool shouldUseCacheFor(String collection) {
    return _quotaManager?.shouldUseCache(collection) ??
        isCacheValid(collection);
  }

  /// Run migrations for existing data
  Future<void> _runMigrations() async {
    try {
      // Initialize default user preferences if not exists
      if (_userPrefsBox!.isEmpty) {
        await _userPrefsBox!.add(UserPreferences());
      }

      _logger.debug('Service', 'Migraciones completadas');
    } catch (e) {
      _logger.debug('Service', 'Error en migraciones: $e');
    }
  }

  Future<Box<TaskHistory>> get _historyBoxGetter async {
    await init();
    if (!_isBoxUsable(_historyBox)) {
      await _reinitializeBoxes();
    }
    return _historyBox!;
  }

  // ==================== USER PREFERENCES ====================

  Future<Box<UserPreferences>> get _userPrefs async {
    await init();
    if (!_isBoxUsable(_userPrefsBox)) {
      await _reinitializeBoxes();
    }
    return _userPrefsBox!;
  }

  /// Get user preferences
  Future<UserPreferences> getUserPreferences() async {
    final box = await _userPrefs;
    if (box.isEmpty) {
      final prefs = UserPreferences();
      await box.add(prefs);
      return prefs;
    }
    return box.values.first;
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences prefs) async {
    if (prefs.isInBox) {
      await prefs.save();
    } else {
      final box = await _userPrefs;
      await box.add(prefs);
    }
  }

  /// Check if user has accepted legal requirements
  Future<bool> hasAcceptedLegal() async {
    final prefs = await getUserPreferences();
    return prefs.hasAcceptedAll;
  }

  /// Accept legal requirements
  Future<void> acceptLegal() async {
    final prefs = await getUserPreferences();
    prefs.acceptAll();
    await prefs.save();
  }

  /// Check if cloud sync is enabled
  Future<bool> isCloudSyncEnabled() async {
    final prefs = await getUserPreferences();
    return prefs.cloudSyncEnabled;
  }

  /// Enable or disable cloud sync
  Future<void> setCloudSyncEnabled(bool enabled) async {
    final prefs = await getUserPreferences();
    prefs.cloudSyncEnabled = enabled;
    await prefs.save();
    _logger.debug(
      'Service',
      'Cloud sync ${enabled ? "habilitado" : "deshabilitado"}',
    );
  }

  // ==================== TASK OPERATIONS (Delegated to Repository) ====================

  /// Get local tasks by type
  Future<List<Task>> getLocalTasks(String type) async {
    try {
      final tasks = (await _taskRepository.getByType(type)).cast<Task>();
      return tasks..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener tareas locales',
        userMessage: 'No se pudieron cargar las tareas',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save task locally and sync to cloud
  Future<void> saveTaskLocally(Task task) async {
    try {
      // Save without sync - caller should use syncTaskToCloudDebounced separately
      task.lastUpdatedAt = DateTime.now();
      await _taskRepository.localStorage.save(task);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al guardar tarea localmente',
        userMessage: 'No se pudo guardar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Delete task locally (hard delete)
  Future<void> deleteTaskLocally(dynamic key) async {
    try {
      await _taskRepository.localStorage.delete(key);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar tarea localmente',
        userMessage: 'No se pudo eliminar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Sync task to cloud immediately
  Future<void> syncTaskToCloud(Task task, String userId) async {
    await _taskRepository.save(task, userId);
  }

  /// Sync task to cloud with debouncing
  Future<void> syncTaskToCloudDebounced(Task task, String userId) async {
    await _taskRepository.save(task, userId);
  }

  /// Soft delete a task
  Future<void> softDeleteTask(Task task, String userId) async {
    await _taskRepository.delete(task.key, userId);
  }

  /// Watch local tasks by type
  Stream<List<Task>> watchLocalTasks(String type) {
    return _taskRepository.watchByType(type).map((tasks) => tasks.cast<Task>());
  }

  /// Force sync pending tasks
  Future<void> forceSyncPendingTasks() async {
    await _taskRepository.processSyncQueue();
  }

  /// Get pending task sync count
  Future<int> getPendingSyncCount() async {
    return _taskRepository.getPendingSyncCount();
  }

  // ==================== NOTE OPERATIONS (Delegated to Repository) ====================

  /// Get all independent notes (not linked to tasks)
  Future<List<Note>> getIndependentNotes() async {
    try {
      final notes = await _noteRepository.getRootNotes();
      return notes..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener notas',
        userMessage: 'No se pudieron cargar las notas',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    try {
      final notes = (await _noteRepository.getAll()).cast<Note>();
      return notes..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener notas',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get notes for a specific task
  Future<List<Note>> getNotesForTask(String taskId) async {
    try {
      return await _noteRepository.getByTask(taskId);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener notas de tarea',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save note locally
  Future<void> saveNoteLocally(Note note) async {
    try {
      note.updatedAt = DateTime.now();
      await _noteRepository.localStorage.save(note);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al guardar nota localmente',
        userMessage: 'No se pudo guardar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Delete note locally
  Future<void> deleteNoteLocally(dynamic key) async {
    try {
      await _noteRepository.localStorage.delete(key);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar nota',
        userMessage: 'No se pudo eliminar la nota',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Sync note to cloud
  Future<void> syncNoteToCloud(Note note, String userId) async {
    await _noteRepository.save(note, userId);
  }

  /// Sync note to cloud with debouncing
  Future<void> syncNoteToCloudDebounced(Note note, String userId) async {
    await _noteRepository.save(note, userId);
  }

  /// Soft delete a note
  Future<void> softDeleteNote(Note note, String userId) async {
    await _noteRepository.delete(note.key, userId);
  }

  /// Watch independent notes
  Stream<List<Note>> watchIndependentNotes() {
    return _noteRepository.watchRootNotes();
  }

  /// Watch archived notes
  Stream<List<Note>> watchArchivedNotes() async* {
    try {
      final localStorage = _noteRepository.localStorage;
      await localStorage.init();

      List<Note> getArchived() {
        final allNotes = localStorage.box?.values.toList() ?? [];
        return allNotes
            .where((note) => !note.deleted && note.status == 'archived')
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      yield getArchived();

      if (localStorage.box != null) {
        await for (final _ in localStorage.box!.watch()) {
          yield getArchived();
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al observar notas archivadas',
        stackTrace: stack,
      );
      yield [];
    }
  }

  /// Watch notes for a task
  Stream<List<Note>> watchNotesForTask(String taskId) async* {
    try {
      final localStorage = _noteRepository.localStorage;
      await localStorage.init();

      List<Note> getTaskNotes() {
        final allNotes = localStorage.box?.values.toList() ?? [];
        return allNotes
            .where((note) => !note.deleted && note.taskId == taskId)
            .toList()
          ..sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
      }

      yield getTaskNotes();

      if (localStorage.box != null) {
        await for (final _ in localStorage.box!.watch()) {
          yield getTaskNotes();
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al observar notas de tarea',
        stackTrace: stack,
      );
      yield [];
    }
  }

  /// Search notes
  Future<List<Note>> searchNotes(String query, {int maxResults = 50}) async {
    try {
      final results = (await _noteRepository.searchContent(query)).cast<Note>();
      return results.take(maxResults).toList();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al buscar notas',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get task notes count
  Future<int> getTaskNotesCount(String taskId) async {
    try {
      final notes = await _noteRepository.getByTask(taskId);
      return notes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete all notes for a task
  Future<void> deleteNotesForTask(String taskId) async {
    try {
      final notes = await _noteRepository.getByTask(taskId);
      for (final note in notes) {
        await _noteRepository.localStorage.delete(note.key);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al eliminar notas de tarea',
        stackTrace: stack,
      );
    }
  }

  /// Get pending notes sync count
  Future<int> getPendingNotesSyncCount() async {
    return _noteRepository.getDeadLetterCount();
  }

  /// Get total pending sync count
  Future<int> getTotalPendingSyncCount() async {
    final taskCount = await getPendingSyncCount();
    final noteCount = await getPendingNotesSyncCount();
    final notebookCount = await getPendingNotebooksSyncCount();
    return taskCount + noteCount + notebookCount;
  }

  /// Force sync pending notes
  Future<void> forceSyncPendingNotes() async {
    await _noteRepository.processSyncQueue();
  }

  // ==================== NOTEBOOK OPERATIONS (Delegated to Repository) ====================

  /// Save notebook locally
  Future<void> saveNotebookLocally(Notebook notebook) async {
    try {
      notebook.updatedAt = DateTime.now();
      await _notebookRepository.localStorage.save(notebook);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al guardar notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Delete notebook locally
  Future<void> deleteNotebookLocally(dynamic key) async {
    try {
      await _notebookRepository.delete(key, '');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar notebook',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Watch all notebooks
  Stream<List<Notebook>> watchNotebooks() {
    return _notebookRepository.watchAll().map((items) {
      final notebooks = items.cast<Notebook>();
      return notebooks..sort((a, b) {
        if (a.isFavorited && !b.isFavorited) return -1;
        if (!a.isFavorited && b.isFavorited) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    });
  }

  /// Get all notebooks
  Future<List<Notebook>> getAllNotebooks() async {
    try {
      return (await _notebookRepository.getAll()).cast<Notebook>();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener notebooks',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Move notes out of a notebook
  Future<void> moveNotesOutOfNotebook(
    String notebookId, {
    String? userId,
  }) async {
    try {
      final localStorage = _noteRepository.localStorage;
      await localStorage.init();

      final allNotes = localStorage.box?.values.toList() ?? [];
      final notesInNotebook = allNotes
          .where((note) => note.notebookId == notebookId)
          .toList();

      for (final note in notesInNotebook) {
        note.updateInPlace(clearNotebookId: true);
        await note.save();
        if (userId != null && userId.isNotEmpty) {
          await _noteRepository.save(note, userId);
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al mover notas fuera del notebook',
        stackTrace: stack,
      );
    }
  }

  /// Sync notebook to cloud
  Future<void> syncNotebookToCloud(Notebook notebook, String userId) async {
    await _notebookRepository.save(notebook, userId);
  }

  /// Delete notebook from cloud
  Future<void> deleteNotebookFromCloud(
    String firestoreId,
    String userId,
  ) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) return;

    if (!_firebaseAvailable || firestore == null || userId.isEmpty) return;

    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('notebooks')
          .doc(firestoreId)
          .delete();
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al eliminar notebook de Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Get pending notebooks sync count
  Future<int> getPendingNotebooksSyncCount() async {
    return _notebookRepository.getDeadLetterCount();
  }

  /// Force sync pending notebooks
  Future<void> forceSyncPendingNotebooks() async {
    await _notebookRepository.processSyncQueue();
  }

  // ==================== SYNC COORDINATION ====================

  /// Force sync all pending items
  Future<void> forceSyncAll() async {
    await forceSyncPendingTasks();
    await forceSyncPendingNotes();
    await forceSyncPendingNotebooks();
  }

  /// Flush pending syncs
  Future<void> flushPendingSyncs() async {
    await _taskRepository.flushPendingSyncs();
    await _noteRepository.flushPendingSyncs();
    await _notebookRepository.flushPendingSyncs();
  }

  /// Sync from cloud
  Future<SyncResult> syncFromCloud(String userId) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    if (!_firebaseAvailable || userId.isEmpty) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    int tasksDownloaded = 0;
    int notesDownloaded = 0;
    int errors = 0;

    try {
      // Sync tasks from cloud
      final taskResult = await _taskRepository.sync(userId);
      if (taskResult.isSuccess) {
        tasksDownloaded = taskResult.itemsSynced;
      } else {
        errors += taskResult.itemsFailed;
      }

      // Sync notes from cloud
      final noteResult = await _noteRepository.sync(userId);
      if (noteResult.isSuccess) {
        notesDownloaded = noteResult.itemsSynced;
      } else {
        errors += noteResult.itemsFailed;
      }

      // Sync notebooks from cloud
      final notebookResult = await _notebookRepository.sync(userId);
      if (!notebookResult.isSuccess) {
        errors += notebookResult.itemsFailed;
      }

      updateCollectionSync('tasks');
      updateCollectionSync('notes');
      updateCollectionSync('notebooks');

      _logger.debug(
        'Service',
        '[SYNC] Sync from cloud completed: $tasksDownloaded tasks, $notesDownloaded notes, $errors errors',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.sync,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar desde Firebase',
        userMessage: 'No se pudieron descargar todos los datos',
        stackTrace: stack,
      );
      errors++;
    }

    return SyncResult(
      tasksDownloaded: tasksDownloaded,
      notesDownloaded: notesDownloaded,
      errors: errors,
    );
  }

  /// Perform full bidirectional sync
  Future<SyncResult> performFullSync(String userId) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    if (!_firebaseAvailable || userId.isEmpty) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    _logger.debug(
      'Service',
      '[SYNC] Starting full bidirectional sync',
    );

    // First, download from cloud
    final downloadResult = await syncFromCloud(userId);

    // Then, upload pending local changes
    await forceSyncAll();

    return downloadResult;
  }

  // ==================== TASK HISTORY OPERATIONS ====================

  /// Records a task completion or missed status for a given date
  Future<void> recordTaskCompletion(
    String taskId,
    bool completed, {
    DateTime? date,
  }) async {
    try {
      final box = await _historyBoxGetter;
      final targetDate = TaskHistory.normalizeDate(date ?? DateTime.now());
      final historyKey =
          '${taskId}_${targetDate.year}_${targetDate.month}_${targetDate.day}';

      TaskHistory? existingEntry;
      for (final entry in box.values) {
        if (entry.historyKey == historyKey) {
          existingEntry = entry;
          break;
        }
      }

      if (existingEntry != null) {
        existingEntry.wasCompleted = completed;
        existingEntry.completedAt = completed ? DateTime.now() : null;
        await existingEntry.save();
      } else {
        final newEntry = TaskHistory(
          taskId: taskId,
          date: targetDate,
          wasCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
        );
        await box.add(newEntry);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al registrar historial de tarea',
        userMessage: 'No se pudo guardar el historial',
        stackTrace: stack,
      );
    }
  }

  /// Gets the task history for a specific task
  Future<List<TaskHistory>> getTaskHistory(
    String taskId, {
    int days = 30,
  }) async {
    try {
      final box = await _historyBoxGetter;
      final cutoffDate = TaskHistory.normalizeDate(
        DateTime.now().subtract(Duration(days: days)),
      );

      return box.values
          .where(
            (entry) =>
                entry.taskId == taskId &&
                entry.date.isAfter(
                  cutoffDate.subtract(const Duration(days: 1)),
                ),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener historial de tarea',
        userMessage: 'No se pudo cargar el historial',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Gets the current streak for a task
  Future<int> getCurrentStreak(String taskId) async {
    try {
      final history = await getTaskHistory(taskId, days: 365);
      if (history.isEmpty) return 0;

      history.sort((a, b) => b.date.compareTo(a.date));

      int streak = 0;
      final today = TaskHistory.normalizeDate(DateTime.now());
      DateTime expectedDate = today;

      for (final entry in history) {
        final entryDate = TaskHistory.normalizeDate(entry.date);

        if (streak == 0) {
          final daysDiff = today.difference(entryDate).inDays;
          if (daysDiff > 1) {
            return 0;
          }
          expectedDate = entryDate;
        }

        if (entryDate.year == expectedDate.year &&
            entryDate.month == expectedDate.month &&
            entryDate.day == expectedDate.day) {
          if (entry.wasCompleted) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        } else if (entryDate.isBefore(expectedDate)) {
          break;
        }
      }

      return streak;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al calcular racha',
        stackTrace: stack,
      );
      return 0;
    }
  }

  /// Gets the longest streak for a task
  Future<int> getLongestStreak(String taskId) async {
    try {
      final history = await getTaskHistory(taskId, days: 365);
      if (history.isEmpty) return 0;

      history.sort((a, b) => a.date.compareTo(b.date));

      int longestStreak = 0;
      int currentStreak = 0;
      DateTime? lastDate;

      for (final entry in history) {
        if (!entry.wasCompleted) {
          currentStreak = 0;
          lastDate = null;
          continue;
        }

        final entryDate = TaskHistory.normalizeDate(entry.date);

        if (lastDate == null) {
          currentStreak = 1;
        } else {
          final daysDiff = entryDate.difference(lastDate).inDays;
          if (daysDiff == 1) {
            currentStreak++;
          } else if (daysDiff > 1) {
            currentStreak = 1;
          }
        }

        lastDate = entryDate;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      }

      return longestStreak;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al calcular racha mas larga',
        stackTrace: stack,
      );
      return 0;
    }
  }

  /// Gets completion stats for a task
  Future<Map<String, dynamic>> getCompletionStats(String taskId) async {
    try {
      final now = DateTime.now();
      final today = TaskHistory.normalizeDate(now);

      final weekday = now.weekday;
      final monday = today.subtract(Duration(days: weekday - 1));

      final history = await getTaskHistory(taskId, days: 30);

      int completedThisWeek = 0;
      int totalThisWeek = 0;
      final List<bool?> last7Days = List.filled(7, null);

      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        if (day.isAfter(today)) continue;

        totalThisWeek++;

        final entry = history.firstWhere(
          (e) {
            final entryDate = TaskHistory.normalizeDate(e.date);
            return entryDate.year == day.year &&
                entryDate.month == day.month &&
                entryDate.day == day.day;
          },
          orElse: () =>
              TaskHistory(taskId: taskId, date: day, wasCompleted: false),
        );

        if (entry.wasCompleted) {
          completedThisWeek++;
          last7Days[i] = true;
        } else {
          last7Days[i] = false;
        }
      }

      final monthStart = DateTime(now.year, now.month, 1);
      int completedThisMonth = 0;
      int totalThisMonth = 0;

      for (final entry in history) {
        final entryDate = TaskHistory.normalizeDate(entry.date);
        if (entryDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            !entryDate.isAfter(today)) {
          totalThisMonth++;
          if (entry.wasCompleted) {
            completedThisMonth++;
          }
        }
      }

      if (totalThisMonth == 0) {
        totalThisMonth = today.day;
      }

      final currentStreak = await getCurrentStreak(taskId);
      final longestStreak = await getLongestStreak(taskId);

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'completedThisWeek': completedThisWeek,
        'totalThisWeek': totalThisWeek,
        'completedThisMonth': completedThisMonth,
        'totalThisMonth': totalThisMonth,
        'last7Days': last7Days,
        'completionRateWeek': totalThisWeek > 0
            ? completedThisWeek / totalThisWeek
            : 0.0,
        'completionRateMonth': totalThisMonth > 0
            ? completedThisMonth / totalThisMonth
            : 0.0,
      };
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al obtener estadisticas',
        stackTrace: stack,
      );
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'completedThisWeek': 0,
        'totalThisWeek': 0,
        'completedThisMonth': 0,
        'totalThisMonth': 0,
        'last7Days': List.filled(7, null),
        'completionRateWeek': 0.0,
        'completionRateMonth': 0.0,
      };
    }
  }

  /// Cleans up old history entries
  Future<void> cleanupOldHistory({int keepDays = 365}) async {
    try {
      final box = await _historyBoxGetter;
      final cutoffDate = TaskHistory.normalizeDate(
        DateTime.now().subtract(Duration(days: keepDays)),
      );

      final keysToDelete = <dynamic>[];
      for (final entry in box.toMap().entries) {
        if (entry.value.date.isBefore(cutoffDate)) {
          keysToDelete.add(entry.key);
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      _logger.debug(
        'Service',
        'Cleaned up ${keysToDelete.length} old history entries',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al limpiar historial antiguo',
        stackTrace: stack,
      );
    }
  }

  /// Gets history entry for today
  Future<TaskHistory?> getTodayHistory(String taskId) async {
    try {
      final box = await _historyBoxGetter;
      final today = TaskHistory.normalizeDate(DateTime.now());
      final historyKey = '${taskId}_${today.year}_${today.month}_${today.day}';

      for (final entry in box.values) {
        if (entry.historyKey == historyKey) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Purge soft deleted items
  Future<void> purgeSoftDeletedItems({int olderThanDays = 30}) async {
    try {
      final tasksPurged = await _taskRepository.purgeSoftDeleted(
        olderThanDays: olderThanDays,
      );
      final notesPurged = await _noteRepository.purgeSoftDeleted(
        olderThanDays: olderThanDays,
      );

      _logger.debug(
        'Service',
        'Purged $tasksPurged tasks, $notesPurged notes',
      );
    } catch (e) {
      _logger.debug('Service', 'Error purging soft-deleted items: $e');
    }
  }

  // ==================== ACCOUNT DELETION ====================

  /// Delete all user data from Firestore
  Future<void> deleteAllUserDataFromCloud(String userId) async {
    if (!_firebaseAvailable || firestore == null) return;
    if (userId.isEmpty) return;

    try {
      final userDoc = firestore!.collection('users').doc(userId);

      // Delete all tasks
      final tasksSnapshot = await userDoc.collection('tasks').get();
      for (final doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all notes
      final notesSnapshot = await userDoc.collection('notes').get();
      for (final doc in notesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all notebooks
      final notebooksSnapshot = await userDoc.collection('notebooks').get();
      for (final doc in notebooksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user preferences
      try {
        final prefsSnapshot = await userDoc.collection('preferences').get();
        for (final doc in prefsSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}

      // Delete user document
      await userDoc.delete();

      _logger.debug(
        'Service',
        'Todos los datos del usuario eliminados de Firebase',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar datos de Firebase',
        userMessage: 'No se pudieron eliminar todos los datos de la nube',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Clear all local Hive data
  Future<void> clearAllLocalData() async {
    try {
      await init();

      // Clear repository data
      await _taskRepository.localStorage.box?.clear();
      await _noteRepository.localStorage.box?.clear();
      await _notebookRepository.localStorage.box?.clear();

      // Clear history and user prefs
      await _historyBox?.clear();
      await _userPrefsBox?.clear();

      // Re-initialize user preferences
      await _userPrefsBox?.add(UserPreferences());

      _logger.debug('Service', 'Todos los datos locales eliminados');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar datos locales',
        userMessage: 'No se pudieron eliminar todos los datos locales',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Export all user data as JSON
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final tasks = (await _taskRepository.getAll()).cast<Task>();
      final notes = (await _noteRepository.getAll()).cast<Note>();
      final historyBox = await _historyBoxGetter;
      final prefs = await getUserPreferences();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'tasks': tasks
            .where((t) => !t.deleted)
            .map((t) => t.toFirestore())
            .toList(),
        'notes': notes
            .where((n) => !n.deleted)
            .map((n) => n.toFirestore())
            .toList(),
        'history': historyBox.values
            .map(
              (h) => {
                'taskId': h.taskId,
                'date': h.date.toIso8601String(),
                'wasCompleted': h.wasCompleted,
                'completedAt': h.completedAt?.toIso8601String(),
              },
            )
            .toList(),
        'preferences': prefs.toJson(),
      };
    } catch (e) {
      _logger.debug('Service', 'Error exporting data: $e');
      return {'error': 'Failed to export data'};
    }
  }

  /// Delete task from cloud
  Future<void> deleteTaskFromCloud(String firestoreId, String userId) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) return;

    if (!_firebaseAvailable || firestore == null) return;
    if (firestoreId.isEmpty || userId.isEmpty) return;

    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(firestoreId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al eliminar tarea de Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Delete note from cloud
  Future<void> deleteNoteFromCloud(String firestoreId, String userId) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) return;

    if (!_firebaseAvailable || firestore == null) return;
    if (firestoreId.isEmpty || userId.isEmpty) return;

    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(firestoreId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al eliminar nota de Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      _logger.debug('Service', '[DatabaseService] Disposing resources...');

      // Flush any pending syncs
      await flushPendingSyncs().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.debug(
            'Service',
            '[DatabaseService] Timeout flushing pending syncs on dispose',
          );
        },
      );

      // Print quota summary
      _quotaManager?.printSummary();

      // Close repositories
      await _taskRepository.close();
      await _noteRepository.close();
      await _notebookRepository.close();

      // Close local boxes
      try {
        if (_historyBox?.isOpen ?? false) {
          await _historyBox!.close();
        }
        if (_userPrefsBox?.isOpen ?? false) {
          await _userPrefsBox!.close();
        }
      } catch (e) {
        _logger.debug('Service', '[DatabaseService] Error closing boxes: $e');
      }

      _initialized = false;
      _logger.debug('Service', '[DatabaseService] Disposed successfully');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error disposing DatabaseService',
        stackTrace: stack,
      );
    }
  }

  /// Run a manual integrity check
  Future<IntegrityReport> runIntegrityCheck() async {
    await init();
    final checker = _integrityChecker;
    if (checker == null) {
      throw StateError('IntegrityChecker not initialized');
    }
    return checker.checkAllBoxes();
  }

  /// Attempt to repair database issues
  Future<IntegrityReport> repairDatabase() async {
    await init();
    final checker = _integrityChecker;
    if (checker == null) {
      throw StateError('IntegrityChecker not initialized');
    }
    _lastIntegrityReport = await checker.repairAllBoxes();
    return _lastIntegrityReport!;
  }

  /// Get quota statistics
  QuotaStats? getQuotaStats() {
    return _quotaManager?.stats;
  }

  /// Reset quota statistics
  void resetQuotaStats() {
    _quotaManager?.resetStats();
  }
}
