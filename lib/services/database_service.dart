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

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return DatabaseService(errorHandler);
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

class DatabaseService {
  final ErrorHandler _errorHandler;
  final _logger = LoggerService();

  DatabaseService(this._errorHandler);

  static const String _boxName = 'tasks';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _historyBoxName = 'task_history';
  static const String _notesBoxName = 'notes';
  static const String _notesSyncQueueBoxName = 'notes_sync_queue';
  static const String _userPrefsBoxName = 'user_prefs';
  static const String _notebooksBoxName = 'notebooks';
  static const String _notebooksSyncQueueBoxName = 'notebooks_sync_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _syncDebounceDelay = Duration(seconds: 3);

  Box<Task>? _taskBox;
  Box<Map>? _syncQueueBox;
  Box<TaskHistory>? _historyBox;
  Box<Note>? _notesBox;
  Box<Map>? _notesSyncQueueBox;
  Box<UserPreferences>? _userPrefsBox;
  Box<Notebook>? _notebooksBox;
  Box<Map>? _notebooksSyncQueueBox;
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

  // Debouncing for sync
  Timer? _syncDebounceTimer;
  final Set<int> _pendingSyncTaskKeys = {};
  final Set<int> _pendingSyncNoteKeys = {};
  String? _pendingSyncUserId;

  FirebaseFirestore? get firestore {
    if (!_firebaseAvailable) return null;
    _firestore ??= FirebaseFirestore.instance;
    return _firestore;
  }

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

      // Open boxes safely - check if already open first
      _taskBox = Hive.isBoxOpen(_boxName)
          ? Hive.box<Task>(_boxName)
          : await Hive.openBox<Task>(_boxName);
      _syncQueueBox = Hive.isBoxOpen(_syncQueueBoxName)
          ? Hive.box<Map>(_syncQueueBoxName)
          : await Hive.openBox<Map>(_syncQueueBoxName);
      _historyBox = Hive.isBoxOpen(_historyBoxName)
          ? Hive.box<TaskHistory>(_historyBoxName)
          : await Hive.openBox<TaskHistory>(_historyBoxName);
      _notesBox = Hive.isBoxOpen(_notesBoxName)
          ? Hive.box<Note>(_notesBoxName)
          : await Hive.openBox<Note>(_notesBoxName);
      _notesSyncQueueBox = Hive.isBoxOpen(_notesSyncQueueBoxName)
          ? Hive.box<Map>(_notesSyncQueueBoxName)
          : await Hive.openBox<Map>(_notesSyncQueueBoxName);
      _userPrefsBox = Hive.isBoxOpen(_userPrefsBoxName)
          ? Hive.box<UserPreferences>(_userPrefsBoxName)
          : await Hive.openBox<UserPreferences>(_userPrefsBoxName);
      _notebooksBox = Hive.isBoxOpen(_notebooksBoxName)
          ? Hive.box<Notebook>(_notebooksBoxName)
          : await Hive.openBox<Notebook>(_notebooksBoxName);
      _notebooksSyncQueueBox = Hive.isBoxOpen(_notebooksSyncQueueBoxName)
          ? Hive.box<Map>(_notebooksSyncQueueBoxName)
          : await Hive.openBox<Map>(_notebooksSyncQueueBoxName);

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

      // Initialize performance components (only if not already initialized)
      _integrityChecker ??= HiveIntegrityChecker(errorHandler: _errorHandler);
      if (_firebaseAvailable && _quotaManager == null) {
        _quotaManager = FirebaseQuotaManager(errorHandler: _errorHandler);
      }

      _initialized = true;
      _initCompleter!.complete();

      // Run integrity check on all boxes
      await _runIntegrityCheck();

      // Run migrations for existing data
      await _runMigrations();

      // Intentar sincronizar tareas y notas pendientes al iniciar
      if (_firebaseAvailable) {
        _processSyncQueue();
        _processNotesSyncQueue();
      }
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

  /// Check if IndexedDB connection error
  bool _isConnectionClosedError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('database connection is closing') ||
        errorStr.contains('invalidstateerror') ||
        errorStr.contains('the database connection is closing') ||
        errorStr.contains('transaction') && errorStr.contains('idbdatabase');
  }

  /// Reinitialize boxes after connection closed (iOS/Web IndexedDB issue)
  Future<void> _reinitializeBoxes() async {
    if (_isReinitializing) {
      // Wait for ongoing reinitialization
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
        if (_taskBox != null && _taskBox!.isOpen) {
          await _taskBox!.close();
        }
        if (_syncQueueBox != null && _syncQueueBox!.isOpen) {
          await _syncQueueBox!.close();
        }
        if (_historyBox != null && _historyBox!.isOpen) {
          await _historyBox!.close();
        }
        if (_notesBox != null && _notesBox!.isOpen) {
          await _notesBox!.close();
        }
        if (_notesSyncQueueBox != null && _notesSyncQueueBox!.isOpen) {
          await _notesSyncQueueBox!.close();
        }
        if (_userPrefsBox != null && _userPrefsBox!.isOpen) {
          await _userPrefsBox!.close();
        }
        if (_notebooksBox != null && _notebooksBox!.isOpen) {
          await _notebooksBox!.close();
        }
        if (_notebooksSyncQueueBox != null && _notebooksSyncQueueBox!.isOpen) {
          await _notebooksSyncQueueBox!.close();
        }
      } catch (e) {
        _logger.warning('DatabaseService', 'Error cerrando boxes: $e');
      }

      // Small delay to let IndexedDB clean up
      await Future.delayed(const Duration(milliseconds: 100));

      // Reopen boxes
      _taskBox = await Hive.openBox<Task>(_boxName);
      _syncQueueBox = await Hive.openBox<Map>(_syncQueueBoxName);
      _historyBox = await Hive.openBox<TaskHistory>(_historyBoxName);
      _notesBox = await Hive.openBox<Note>(_notesBoxName);
      _notesSyncQueueBox = await Hive.openBox<Map>(_notesSyncQueueBoxName);
      _userPrefsBox = await Hive.openBox<UserPreferences>(_userPrefsBoxName);
      _notebooksBox = await Hive.openBox<Notebook>(_notebooksBoxName);
      _notebooksSyncQueueBox = await Hive.openBox<Map>(
        _notebooksSyncQueueBoxName,
      );

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

  /// Execute a database operation with automatic retry on connection errors
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
    String operationName = 'operación',
  }) async {
    int attempts = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (_isConnectionClosedError(e) && attempts <= maxRetries) {
          _logger.debug(
            'Service',
            '🔄 [Database] Conexión cerrada detectada en $operationName, reintentando ($attempts/$maxRetries)...',
          );
          await _reinitializeBoxes();
          continue;
        }

        rethrow;
      }
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

      // Migrate existing tasks: set deleted = false and lastUpdatedAt
      for (final task in _taskBox!.values) {
        bool needsSave = false;

        if (task.lastUpdatedAt == null) {
          task.lastUpdatedAt = task.createdAt;
          needsSave = true;
        }

        if (needsSave && task.isInBox) {
          await task.save();
        }
      }

      // Clean up duplicate tasks and notes
      await _cleanupDuplicates();

      _logger.debug('Service', 'Migraciones completadas');
    } catch (e) {
      _logger.debug('Service', 'Error en migraciones: $e');
    }
  }

  /// Remove duplicate tasks and notes with same firestoreId or same creation timestamp
  Future<void> _cleanupDuplicates() async {
    try {
      // Clean up duplicate tasks
      final seenTaskIds = <String>{};
      final seenTimestamps = <int>{};
      final tasksToDelete = <dynamic>[];

      for (final task in _taskBox!.values) {
        bool isDuplicate = false;
        if (task.firestoreId.isNotEmpty) {
          if (seenTaskIds.contains(task.firestoreId)) {
            isDuplicate = true;
          } else {
            seenTaskIds.add(task.firestoreId);
          }
        }

        // Also check by timestamp for local-only duplicates
        final ts = task.createdAt.millisecondsSinceEpoch;
        if (!isDuplicate && ts > 0) {
          if (seenTimestamps.contains(ts)) {
            isDuplicate = true;
          } else {
            seenTimestamps.add(ts);
          }
        }

        if (isDuplicate) {
          tasksToDelete.add(task.key);
        }
      }

      for (final key in tasksToDelete) {
        await _taskBox!.delete(key);
      }

      if (tasksToDelete.isNotEmpty) {
        _logger.debug(
          'Service',
          'Eliminados ${tasksToDelete.length} tareas duplicadas',
        );
      }

      // Clean up duplicate notes
      final seenNoteIds = <String>{};
      final seenNoteTimestamps = <int>{};
      final notesToDelete = <dynamic>[];

      for (final note in _notesBox!.values) {
        bool isDuplicate = false;
        if (note.firestoreId.isNotEmpty) {
          if (seenNoteIds.contains(note.firestoreId)) {
            isDuplicate = true;
          } else {
            seenNoteIds.add(note.firestoreId);
          }
        }

        final ts = note.createdAt.millisecondsSinceEpoch;
        if (!isDuplicate && ts > 0) {
          if (seenNoteTimestamps.contains(ts)) {
            isDuplicate = true;
          } else {
            seenNoteTimestamps.add(ts);
          }
        }

        if (isDuplicate) {
          notesToDelete.add(note.key);
        }
      }

      for (final key in notesToDelete) {
        await _notesBox!.delete(key);
      }

      if (notesToDelete.isNotEmpty) {
        _logger.debug(
          'Service',
          'Eliminadas ${notesToDelete.length} notas duplicadas',
        );
      }
    } catch (e) {
      _logger.debug('Service', 'Error limpiando duplicados: $e');
    }
  }

  Future<Box<Task>> get _box async {
    await init();
    if (!_isBoxUsable(_taskBox)) {
      await _reinitializeBoxes();
    }
    return _taskBox!;
  }

  Future<Box<Map>> get _syncQueue async {
    await init();
    if (!_isBoxUsable(_syncQueueBox)) {
      await _reinitializeBoxes();
    }
    return _syncQueueBox!;
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

  // Local Operations
  Future<List<Task>> getLocalTasks(String type) async {
    try {
      final box = await _box;
      return box.values
          .where((task) => task.type == type && !task.deleted)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<void> saveTaskLocally(Task task) async {
    await _executeWithRetry(() async {
      final box = await _box;
      if (task.isInBox) {
        await task.save();
      } else {
        // IMPORTANT: Avoid duplicating local tasks.
        // AI agents often create new Task instances (via copyWith) which lose their Hive reference.
        // We must check if a task with the same identity already exists.
        final existing = await _findExistingTask(task);

        if (existing != null) {
          // Update existing instead of adding duplicate
          existing.updateInPlace(
            title: task.title,
            type: task.type,
            isCompleted: task.isCompleted,
            dueDate: task.dueDate,
            category: task.category,
            priority: task.priority,
            dueTimeMinutes: task.dueTimeMinutes,
            motivation: task.motivation,
            reward: task.reward,
            recurrenceDay: task.recurrenceDay,
            deadline: task.deadline,
            deleted: task.deleted,
            deletedAt: task.deletedAt,
            lastUpdatedAt: task.lastUpdatedAt,
          );
          await existing.save();
          // IMPORTANT: Exit to avoid box.add() creating a duplicate
          return;
        }
        await box.add(task);
      }
    }, operationName: 'guardar tarea').catchError((e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al guardar tarea localmente',
        userMessage: 'No se pudo guardar la tarea',
        stackTrace: stack,
      );
      throw e;
    });
  }

  Future<void> deleteTaskLocally(dynamic key) async {
    try {
      final box = await _box;
      await box.delete(key);
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

  // Cloud Operations & Sync con manejo de errores robusto
  Future<void> syncTaskToCloud(Task task, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Cloud sync deshabilitado, tarea guardada solo localmente',
      );
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Firebase no disponible, tarea guardada solo localmente',
      );
      return;
    }

    if (userId.isEmpty) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Usuario no autenticado (userId vacío), tarea guardada solo localmente',
      );
      _errorHandler.handle(
        'Usuario no autenticado',
        type: ErrorType.auth,
        severity: ErrorSeverity.info,
        message: 'Tarea guardada solo localmente',
        shouldLog: false,
      );
      return;
    }

    _logger.debug(
      'Service',
      '🔄 [SYNC] Iniciando sincronización de tarea "${task.title}" para usuario $userId',
    );

    try {
      await _syncTaskWithRetry(task, userId);
    } catch (e, stack) {
      _logger.debug('Service', '❌ [SYNC] Error al sincronizar tarea: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar con Firebase',
        userMessage: 'Se sincronizará cuando haya conexión',
        stackTrace: stack,
      );
      await _addToSyncQueue(task, userId);
    }
  }

  Future<void> _syncTaskWithRetry(
    Task task,
    String userId, {
    int retryCount = 0,
  }) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final docRef = fs
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.firestoreId.isNotEmpty ? task.firestoreId : null);

      if (task.firestoreId.isEmpty) {
        // Nueva tarea
        await docRef
            .set(task.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        // Actualizar ID de Firestore localmente - CRITICAL FIX
        final newFirestoreId = docRef.id;

        // Si la tarea está en Hive, actualizar directamente
        if (task.isInBox) {
          task.firestoreId = newFirestoreId;
          await task.save();
        } else {
          // Si no está en Hive, buscar la instancia correcta
          final existingTask = await _findExistingTask(task);
          if (existingTask != null && existingTask.isInBox) {
            existingTask.firestoreId = newFirestoreId;
            await existingTask.save();
            _logger.debug(
              'Service',
              '✅ [SYNC] firestoreId guardado en tarea existente: $newFirestoreId',
            );
          } else {
            _logger.debug(
              'Service',
              '⚠️ [SYNC] No se pudo guardar firestoreId - tarea no encontrada en Hive',
            );
          }
        }
        _logger.debug(
          'Service',
          '✅ Tarea sincronizada con Firebase (nueva) - ID: $newFirestoreId',
        );
      } else {
        // Actualizar tarea existente
        await docRef
            .update(task.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );
        _logger.debug(
          'Service',
          '✅ Tarea sincronizada con Firebase (actualizada)',
        );
      }
    } on FirebaseException catch (e, stack) {
      if (retryCount < _maxRetries &&
          _errorHandler.shouldRetryFirebaseError(e)) {
        _errorHandler.handle(
          e,
          type: ErrorType.network,
          severity: ErrorSeverity.warning,
          message:
              'Reintentando sincronización (${retryCount + 1}/$_maxRetries)',
          stackTrace: stack,
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncTaskWithRetry(task, userId, retryCount: retryCount + 1);
      }
      rethrow;
    } on TimeoutException catch (e, stack) {
      if (retryCount < _maxRetries) {
        _errorHandler.handle(
          e,
          type: ErrorType.network,
          severity: ErrorSeverity.warning,
          message:
              'Timeout de red, reintentando (${retryCount + 1}/$_maxRetries)',
          stackTrace: stack,
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncTaskWithRetry(task, userId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> _addToSyncQueue(Task task, String userId) async {
    try {
      final queue = await _syncQueue;
      await queue.add({
        'task': task,
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0, // NUEVO - tracking de reintentos
        'lastRetryAt': null, // NUEVO - timestamp del último intento
      });
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar a cola de sincronización',
        stackTrace: stack,
      );
    }
  }

  Future<void> _processSyncQueue() async {
    // Check if cloud sync is enabled - FIX 4
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC QUEUE] Cloud sync deshabilitado, saltando procesamiento de cola',
      );
      return;
    }

    try {
      final queue = await _syncQueue;
      if (queue.isEmpty) return;

      _logger.debug(
        'Service',
        '🔄 [SYNC QUEUE] Procesando ${queue.length} tareas pendientes',
      );
      final box = await _box;
      final keysToRemove = <dynamic>[];
      final keysToUpdate = <dynamic, Map<String, dynamic>>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var entry in queue.toMap().entries) {
        try {
          final data = entry.value;
          final queuedTask = data['task'] as Task;
          final userId = data['userId'] as String;
          final timestamp = data['timestamp'] as int?;
          final retryCount = data['retryCount'] as int? ?? 0;
          final lastRetryAt = data['lastRetryAt'] as int?;

          // Verificar si el item es muy viejo (mas de 7 dias)
          if (timestamp != null) {
            final age = DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            );
            if (age.inDays > 7) {
              _logger.debug(
                'Service',
                '🗑️ [SYNC QUEUE] Item muy viejo, eliminando',
              );
              keysToRemove.add(entry.key);
              continue;
            }
          }

          // Verificar si excede máximo de reintentos
          if (retryCount >= _maxRetries) {
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Item excede max reintentos ($_maxRetries), eliminando',
            );
            keysToRemove.add(entry.key);
            continue;
          }

          // Implementar backoff exponencial: 2s, 4s, 8s
          if (lastRetryAt != null && retryCount > 0) {
            final timeSinceLastRetry = now - lastRetryAt;
            final backoffDelay = Duration(
              seconds: 2 * (1 << retryCount),
            ); // 2s, 4s, 8s
            if (timeSinceLastRetry < backoffDelay.inMilliseconds) {
              _logger.debug(
                'Service',
                '⏸️ [SYNC QUEUE] Item en backoff (intento ${retryCount + 1}/$_maxRetries), saltando',
              );
              continue; // Saltar este item, todavía no es tiempo
            }
          }

          // Buscar la tarea actual en Hive por firestoreId o key
          Task? currentTask;
          if (queuedTask.firestoreId.isNotEmpty) {
            currentTask = box.values.cast<Task?>().firstWhere(
              (t) => t?.firestoreId == queuedTask.firestoreId,
              orElse: () => null,
            );
          }

          // Si no se encontro por firestoreId, buscar por key si existe
          if (currentTask == null && queuedTask.key != null) {
            currentTask = box.get(queuedTask.key);
          }

          // Si la tarea fue eliminada localmente, eliminar de la cola
          if (currentTask == null) {
            _logger.debug(
              'Service',
              '⚠️ [SYNC QUEUE] Tarea no encontrada localmente, eliminando de cola',
            );
            keysToRemove.add(entry.key);
            continue;
          }

          // Intentar sincronizar
          try {
            await _syncTaskWithRetry(currentTask, userId);

            // Guardar el firestoreId actualizado si cambio
            if (currentTask.isInBox && currentTask.firestoreId.isNotEmpty) {
              await currentTask.save();
            }

            keysToRemove.add(entry.key);
            _logger.debug(
              'Service',
              '✅ [SYNC QUEUE] Tarea "${currentTask.title}" sincronizada desde cola (intento ${retryCount + 1})',
            );
          } catch (e) {
            // Incrementar contador de reintentos y actualizar lastRetryAt
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Error al procesar item (intento ${retryCount + 1}/$_maxRetries): $e',
            );
            keysToUpdate[entry.key] = {
              'task': queuedTask,
              'userId': userId,
              'timestamp': timestamp,
              'retryCount': retryCount + 1,
              'lastRetryAt': now,
            };
          }
        } catch (e) {
          _logger.debug(
            'Service',
            '❌ [SYNC QUEUE] Error inesperado al procesar item: $e',
          );
          // Mantener en la cola para reintentar despues
        }
      }

      // Eliminar tareas sincronizadas exitosamente
      for (var key in keysToRemove) {
        await queue.delete(key);
      }

      // Actualizar items con retry count incrementado
      for (var entry in keysToUpdate.entries) {
        await queue.put(entry.key, entry.value);
      }

      if (keysToRemove.isNotEmpty) {
        _logger.debug(
          'Service',
          '✅ [SYNC QUEUE] ${keysToRemove.length} items procesados',
        );
      }
      if (keysToUpdate.isNotEmpty) {
        _logger.debug(
          'Service',
          '🔄 [SYNC QUEUE] ${keysToUpdate.length} items reintentarán más tarde',
        );
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al procesar cola de sincronizacion',
        stackTrace: stack,
      );
    }
  }

  // Método público para forzar sincronización manual
  Future<void> forceSyncPendingTasks() async {
    await _processSyncQueue();
  }

  // Obtener número de tareas pendientes de sincronización
  Future<int> getPendingSyncCount() async {
    try {
      final queue = await _syncQueue;
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  Stream<List<Task>> watchLocalTasks(String type) async* {
    try {
      final box = await _box;

      // Filter non-deleted tasks
      List<Task> getFilteredTasks() {
        final tasks =
            box.values
                .where((task) => task.type == type && !task.deleted)
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return tasks;
      }

      // Emit initial data
      yield getFilteredTasks();

      // Watch for changes
      await for (final _ in box.watch()) {
        yield getFilteredTasks();
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al observar tareas',
        stackTrace: stack,
      );
      yield [];
    }
  }

  // ==================== DEBOUNCED SYNC ====================

  /// Sync task to cloud with debouncing
  /// Groups multiple changes and syncs after delay
  Future<void> syncTaskToCloudDebounced(Task task, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Firebase no disponible, saltando debounce sync',
      );
      return;
    }

    if (userId.isEmpty) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Usuario vacío en debounce sync, saltando',
      );
      return;
    }

    _logger.debug(
      'Service',
      '⏱️ [SYNC] Agregando tarea "${task.title}" a cola de sincronización (debounced)',
    );

    // Update lastUpdatedAt
    task.lastUpdatedAt = DateTime.now();
    if (task.isInBox) await task.save();

    // Add to pending sync
    if (task.key != null) {
      _pendingSyncTaskKeys.add(task.key as int);
    }
    _pendingSyncUserId = userId;

    // Cancel previous timer and start new one
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      _flushPendingSyncs();
    });
  }

  /// Sync note to cloud with debouncing
  Future<void> syncNoteToCloudDebounced(Note note, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null || userId.isEmpty) {
      return;
    }

    // Update updatedAt
    note.updatedAt = DateTime.now();
    if (note.isInBox) await note.save();

    // Add to pending sync
    if (note.key != null) {
      _pendingSyncNoteKeys.add(note.key as int);
    }
    _pendingSyncUserId = userId;

    // Cancel previous timer and start new one
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(_syncDebounceDelay, () {
      _flushPendingSyncs();
    });
  }

  /// Flush all pending syncs (called after debounce delay or on app close)
  Future<void> _flushPendingSyncs() async {
    try {
      // Check if cloud sync is enabled
      final syncEnabled = await isCloudSyncEnabled();
      if (!syncEnabled) {
        _pendingSyncTaskKeys.clear();
        _pendingSyncNoteKeys.clear();
        return;
      }

      final userId = _pendingSyncUserId;
      if (userId == null || userId.isEmpty) {
        _logger.debug(
          'Service',
          '⚠️ [SYNC] No hay userId para flush pending syncs',
        );
        return;
      }

      // Copy and clear pending sets
      final taskKeys = Set<int>.from(_pendingSyncTaskKeys);
      final noteKeys = Set<int>.from(_pendingSyncNoteKeys);
      _pendingSyncTaskKeys.clear();
      _pendingSyncNoteKeys.clear();

      if (taskKeys.isEmpty && noteKeys.isEmpty) {
        _logger.debug(
          'Service',
          '⏱️ [SYNC] No hay elementos pendientes para sincronizar',
        );
        return;
      }

      _logger.debug(
        'Service',
        '🔄 [SYNC] Flushing ${taskKeys.length} tareas y ${noteKeys.length} notas pendientes',
      );

      // Collect tasks to sync
      final box = await _box;
      final tasksToSync = <Task>[];
      for (final key in taskKeys) {
        try {
          final task = box.get(key);
          if (task != null && !task.deleted) tasksToSync.add(task);
        } catch (e) {
          _logger.debug('Service', '⚠️ [SYNC] Error obteniendo tarea $key: $e');
        }
      }

      // Collect notes to sync
      final notesBox = await _notes;
      final notesToSync = <Note>[];
      for (final key in noteKeys) {
        try {
          final note = notesBox.get(key);
          if (note != null && !note.deleted) notesToSync.add(note);
        } catch (e) {
          _logger.debug('Service', '⚠️ [SYNC] Error obteniendo nota $key: $e');
        }
      }

      // Batch sync
      if (tasksToSync.isNotEmpty || notesToSync.isNotEmpty) {
        _logger.debug(
          'Service',
          '📦 [SYNC] Sincronizando lote: ${tasksToSync.length} tareas, ${notesToSync.length} notas',
        );
        await _batchSync(tasksToSync, notesToSync, userId);
      }
    } catch (e, stack) {
      _logger.debug('Service', '❌ [SYNC] Error en flush pending syncs: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error en sincronizacion por lotes',
        stackTrace: stack,
      );
    }
  }

  /// Force flush pending syncs (call on app close or manual sync)
  Future<void> flushPendingSyncs() async {
    _syncDebounceTimer?.cancel();
    await _flushPendingSyncs();
  }

  // ==================== BATCH WRITES ====================

  /// Batch sync multiple tasks and notes
  Future<void> _batchSync(
    List<Task> tasks,
    List<Note> notes,
    String userId,
  ) async {
    // Check if cloud sync is enabled - FIX 4
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [BATCH SYNC] Cloud sync deshabilitado, saltando sincronización por lotes',
      );
      return;
    }

    final fs = firestore;
    if (fs == null) return;

    try {
      final batch = fs.batch();
      final userDoc = fs.collection('users').doc(userId);

      // Add tasks to batch
      for (final task in tasks) {
        final docRef = task.firestoreId.isNotEmpty
            ? userDoc.collection('tasks').doc(task.firestoreId)
            : userDoc.collection('tasks').doc();

        if (task.firestoreId.isEmpty) {
          task.firestoreId = docRef.id;
        }

        batch.set(docRef, task.toFirestore(), SetOptions(merge: true));
      }

      // Add notes to batch
      for (final note in notes) {
        final docRef = note.firestoreId.isNotEmpty
            ? userDoc.collection('notes').doc(note.firestoreId)
            : userDoc.collection('notes').doc();

        if (note.firestoreId.isEmpty) {
          note.firestoreId = docRef.id;
        }

        batch.set(docRef, note.toFirestore(), SetOptions(merge: true));
      }

      // Commit batch
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Batch sync timeout'),
      );

      // Save updated firestoreIds locally - CRITICAL FIX
      for (final task in tasks) {
        if (task.isInBox) {
          await task.save();
        } else {
          // Si no está en Hive, buscar la instancia correcta
          final existingTask = await _findExistingTask(task);
          if (existingTask != null && existingTask.isInBox) {
            existingTask.firestoreId = task.firestoreId;
            await existingTask.save();
            _logger.debug(
              'Service',
              '✅ [BATCH] firestoreId guardado en tarea: ${task.firestoreId}',
            );
          }
        }
      }
      for (final note in notes) {
        if (note.isInBox) {
          await note.save();
        } else {
          // Si no está en Hive, buscar la instancia correcta
          final existingNote = await _findExistingNote(note);
          if (existingNote != null && existingNote.isInBox) {
            existingNote.firestoreId = note.firestoreId;
            await existingNote.save();
            _logger.debug(
              'Service',
              '✅ [BATCH] firestoreId guardado en nota: ${note.firestoreId}',
            );
          }
        }
      }

      _logger.debug(
        'Service',
        'Batch sync completado: ${tasks.length} tareas, ${notes.length} notas',
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error en batch sync',
        stackTrace: stack,
      );

      // Add failed items to sync queue
      for (final task in tasks) {
        await _addToSyncQueue(task, userId);
      }
      for (final note in notes) {
        await _addNoteToSyncQueue(note, userId);
      }
    }
  }

  // ==================== SOFT DELETE ====================

  /// Soft delete a task (marks as deleted, syncs later)
  Future<void> softDeleteTask(Task task, String userId) async {
    task.deleted = true;
    task.deletedAt = DateTime.now();
    task.lastUpdatedAt = DateTime.now();

    if (task.isInBox) {
      await task.save();
    } else {
      // IMPORTANT: Find the local instance to mark as deleted.
      // Detached instances (lost Hive key) happen often with AI agents.
      final existing = await _findExistingTask(task);
      if (existing != null) {
        existing.updateInPlace(
          deleted: true,
          deletedAt: task.deletedAt,
          lastUpdatedAt: task.lastUpdatedAt,
        );
        await existing.save();
        // Update the task object to match the identity for the sync step below
        task.firestoreId = existing.firestoreId;
      }
    }

    // Sync deletion to cloud
    if (userId.isNotEmpty) {
      await syncTaskToCloudDebounced(task, userId);
    }
  }

  /// Helper to find an existing task by any of its identities
  Future<Task?> _findExistingTask(Task task) async {
    final box = await _box;
    // 1. By Hive key
    if (task.key != null) {
      final t = box.get(task.key);
      if (t != null) return t;
    }
    // 2. By firestoreId (for synced tasks)
    if (task.firestoreId.isNotEmpty) {
      final t = box.values.cast<Task?>().firstWhere(
        (t) => t?.firestoreId == task.firestoreId,
        orElse: () => null,
      );
      if (t != null) return t;
    }
    // 3. By createdAt (for local tasks)
    return box.values.cast<Task?>().firstWhere(
      (t) =>
          t != null &&
          t.createdAt.millisecondsSinceEpoch ==
              task.createdAt.millisecondsSinceEpoch,
      orElse: () => null,
    );
  }

  Future<void> softDeleteNote(Note note, String userId) async {
    note.deleted = true;
    note.deletedAt = DateTime.now();
    note.updatedAt = DateTime.now();

    if (note.isInBox) {
      await note.save();
    } else {
      // IMPORTANT: Find the local instance to mark as deleted
      final existing = await _findExistingNote(note);
      if (existing != null) {
        existing.updateInPlace(
          deleted: true,
          deletedAt: note.deletedAt,
          updatedAt: note.updatedAt,
        );
        await existing.save();
        note.firestoreId = existing.firestoreId;
      }
    }

    // Sync deletion to cloud
    if (userId.isNotEmpty) {
      await syncNoteToCloudDebounced(note, userId);
    }
  }

  /// Helper to find an existing note by identity
  Future<Note?> _findExistingNote(Note note) async {
    final box = await _notes;
    if (note.key != null) {
      final n = box.get(note.key);
      if (n != null) return n;
    }
    if (note.firestoreId.isNotEmpty) {
      final n = box.values.cast<Note?>().firstWhere(
        (n) => n?.firestoreId == note.firestoreId,
        orElse: () => null,
      );
      if (n != null) return n;
    }
    return box.values.cast<Note?>().firstWhere(
      (n) =>
          n != null &&
          n.createdAt.millisecondsSinceEpoch ==
              note.createdAt.millisecondsSinceEpoch,
      orElse: () => null,
    );
  }

  /// Permanently delete soft-deleted items older than specified days
  Future<void> purgeSoftDeletedItems({int olderThanDays = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
      final box = await _box;
      final notesBox = await _notes;

      // Purge tasks
      final taskKeysToDelete = <dynamic>[];
      for (final entry in box.toMap().entries) {
        final task = entry.value;
        if (task.deleted &&
            task.deletedAt != null &&
            task.deletedAt!.isBefore(cutoff)) {
          taskKeysToDelete.add(entry.key);
        }
      }
      for (final key in taskKeysToDelete) {
        await box.delete(key);
      }

      // Purge notes
      final noteKeysToDelete = <dynamic>[];
      for (final entry in notesBox.toMap().entries) {
        final note = entry.value;
        if (note.deleted &&
            note.deletedAt != null &&
            note.deletedAt!.isBefore(cutoff)) {
          noteKeysToDelete.add(entry.key);
        }
      }
      for (final key in noteKeysToDelete) {
        await notesBox.delete(key);
      }

      _logger.debug(
        'Service',
        'Purged ${taskKeysToDelete.length} tasks, ${noteKeysToDelete.length} notes',
      );
    } catch (e) {
      _logger.debug('Service', 'Error purging soft-deleted items: $e');
    }
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

      // Check if entry already exists
      TaskHistory? existingEntry;
      for (final entry in box.values) {
        if (entry.historyKey == historyKey) {
          existingEntry = entry;
          break;
        }
      }

      if (existingEntry != null) {
        // Update existing entry
        existingEntry.wasCompleted = completed;
        existingEntry.completedAt = completed ? DateTime.now() : null;
        await existingEntry.save();
      } else {
        // Create new entry
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

  /// Gets the task history for a specific task, limited to a number of days
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

  /// Gets the current streak (consecutive days completed) for a task
  Future<int> getCurrentStreak(String taskId) async {
    try {
      final history = await getTaskHistory(taskId, days: 365);
      if (history.isEmpty) return 0;

      // Sort by date descending (most recent first)
      history.sort((a, b) => b.date.compareTo(a.date));

      int streak = 0;
      final today = TaskHistory.normalizeDate(DateTime.now());
      DateTime expectedDate = today;

      for (final entry in history) {
        final entryDate = TaskHistory.normalizeDate(entry.date);

        // If this is the first entry, check if it's today or yesterday
        if (streak == 0) {
          final daysDiff = today.difference(entryDate).inDays;
          if (daysDiff > 1) {
            // More than one day gap from today, no streak
            return 0;
          }
          expectedDate = entryDate;
        }

        // Check if this entry matches the expected date
        if (entryDate.year == expectedDate.year &&
            entryDate.month == expectedDate.month &&
            entryDate.day == expectedDate.day) {
          if (entry.wasCompleted) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else {
            // Task was not completed, streak breaks
            break;
          }
        } else if (entryDate.isBefore(expectedDate)) {
          // Missing day, streak breaks
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

  /// Gets the longest streak ever achieved for a task
  Future<int> getLongestStreak(String taskId) async {
    try {
      final history = await getTaskHistory(taskId, days: 365);
      if (history.isEmpty) return 0;

      // Sort by date ascending (oldest first)
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
          // daysDiff == 0 means same day, don't increment
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

      // Get this week's data (Monday to Sunday)
      final weekday = now.weekday;
      final monday = today.subtract(Duration(days: weekday - 1));

      final history = await getTaskHistory(taskId, days: 30);

      // Calculate weekly stats
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

      // Calculate monthly stats
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

      // If no history for this month, count days passed as total
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

  /// Cleans up old history entries (older than specified days)
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

  /// Gets history entry for today for a specific task
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

  // ==================== NOTE OPERATIONS ====================

  Future<Box<Note>> get _notes async {
    await init();
    if (!_isBoxUsable(_notesBox)) {
      await _reinitializeBoxes();
    }
    return _notesBox!;
  }

  Future<Box<Map>> get _notesSyncQueue async {
    await init();
    if (!_isBoxUsable(_notesSyncQueueBox)) {
      await _reinitializeBoxes();
    }
    return _notesSyncQueueBox!;
  }

  /// Get all independent notes (not linked to tasks)
  Future<List<Note>> getIndependentNotes() async {
    try {
      final box = await _notes;
      return box.values
          .where(
            (note) =>
                !note.deleted && (note.taskId == null || note.taskId!.isEmpty),
          )
          .toList()
        ..sort((a, b) {
          // Pinned first, then by updatedAt
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

  /// Get all notes (for search/dashboard)
  Future<List<Note>> getAllNotes() async {
    try {
      final box = await _notes;
      return box.values.where((note) => !note.deleted).toList()..sort((a, b) {
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

  /// Get notes linked to a specific task
  Future<List<Note>> getNotesForTask(String taskId) async {
    try {
      final box = await _notes;
      return box.values
          .where((note) => !note.deleted && note.taskId == taskId)
          .toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
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

  /// Save a note locally
  Future<void> saveNoteLocally(Note note) async {
    await _executeWithRetry(() async {
      final box = await _notes;
      note.updatedAt = DateTime.now();
      if (note.isInBox) {
        await note.save();
      } else {
        // IMPORTANT: Avoid duplicating local notes.
        // AI agents often create new Note instances (via copyWith) which lose their Hive reference.
        final existing = await _findExistingNote(note);

        if (existing != null) {
          // Update existing instead of adding duplicate
          existing.updateInPlace(
            title: note.title,
            content: note.content,
            updatedAt: note.updatedAt,
            taskId: note.taskId,
            color: note.color,
            isPinned: note.isPinned,
            tags: note.tags,
            deleted: note.deleted,
            deletedAt: note.deletedAt,
            checklist: note.checklist,
            notebookId: note.notebookId,
            status: note.status,
            richContent: note.richContent,
            contentType: note.contentType,
          );
          await existing.save();
          // IMPORTANT: Exit to avoid box.add() creating a duplicate
          return;
        }
        await box.add(note);
      }
    }, operationName: 'guardar nota').catchError((e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al guardar nota localmente',
        userMessage: 'No se pudo guardar la nota',
        stackTrace: stack,
      );
      throw e;
    });
  }

  /// Delete a note locally
  Future<void> deleteNoteLocally(dynamic key) async {
    try {
      final box = await _notes;
      await box.delete(key);
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

  /// Watch independent notes stream
  Stream<List<Note>> watchIndependentNotes() async* {
    try {
      final box = await _notes;

      List<Note> getSortedNotes() {
        return box.values
            .where(
              (note) =>
                  !note.deleted &&
                  note.status == 'active' &&
                  (note.taskId == null || note.taskId!.isEmpty),
            )
            .toList()
          ..sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
      }

      yield getSortedNotes();

      yield* box.watch().map((_) => getSortedNotes());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al observar notas',
        stackTrace: stack,
      );
      yield [];
    }
  }

  /// Watch archived notes stream
  Stream<List<Note>> watchArchivedNotes() async* {
    try {
      final box = await _notes;

      List<Note> getSortedNotes() {
        return box.values
            .where(
              (note) =>
                  !note.deleted &&
                  note.status == 'archived' &&
                  (note.taskId == null || note.taskId!.isEmpty),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      yield getSortedNotes();

      yield* box.watch().map((_) => getSortedNotes());
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

  /// Watch notes for a specific task
  Stream<List<Note>> watchNotesForTask(String taskId) async* {
    try {
      final box = await _notes;

      List<Note> getTaskNotes() {
        return box.values
            .where((note) => !note.deleted && note.taskId == taskId)
            .toList()
          ..sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
      }

      yield getTaskNotes();

      yield* box.watch().map((_) => getTaskNotes());
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

  /// Search notes by query with validation and filtering
  /// Returns up to [maxResults] notes that match the query
  Future<List<Note>> searchNotes(String query, {int maxResults = 50}) async {
    try {
      // Input validation and sanitization
      final sanitized = query.trim();
      if (sanitized.isEmpty) return [];

      final box = await _notes;
      final normalized = sanitized.toLowerCase();

      // Search with filters
      final results = box.values
          .where(
            (note) =>
                !note.deleted && // Exclude deleted notes
                (note.title.toLowerCase().contains(normalized) ||
                    note.content.toLowerCase().contains(normalized) ||
                    note.tags.any(
                      (tag) => tag.toLowerCase().contains(normalized),
                    )),
          )
          .take(maxResults) // Limit results
          .toList();

      // Sort by relevance: pinned first, then by date
      results.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return results;
    } catch (e, stack) {
      _logger.debug('Service', '❌ [Database] Error en búsqueda de notas: $e');
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

  /// Sync note to Firebase
  Future<void> syncNoteToCloud(Note note, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      _logger.debug(
        'Service',
        'Firebase no configurado, nota guardada solo localmente',
      );
      return;
    }

    if (userId.isEmpty) {
      return;
    }

    try {
      await _syncNoteWithRetry(note, userId);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar nota con Firebase',
        userMessage: 'Se sincronizara cuando haya conexion',
        stackTrace: stack,
      );
      await _addNoteToSyncQueue(note, userId);
    }
  }

  Future<void> _syncNoteWithRetry(
    Note note,
    String userId, {
    int retryCount = 0,
  }) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final docRef = fs
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.firestoreId.isNotEmpty ? note.firestoreId : null);

      if (note.firestoreId.isEmpty) {
        await docRef
            .set(note.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        // Actualizar ID de Firestore localmente - CRITICAL FIX
        final newFirestoreId = docRef.id;

        // Si la nota está en Hive, actualizar directamente
        if (note.isInBox) {
          note.firestoreId = newFirestoreId;
          await note.save();
        } else {
          // Si no está en Hive, buscar la instancia correcta
          final existingNote = await _findExistingNote(note);
          if (existingNote != null && existingNote.isInBox) {
            existingNote.firestoreId = newFirestoreId;
            await existingNote.save();
            _logger.debug(
              'Service',
              '✅ [SYNC] firestoreId guardado en nota existente: $newFirestoreId',
            );
          } else {
            _logger.debug(
              'Service',
              '⚠️ [SYNC] No se pudo guardar firestoreId - nota no encontrada en Hive',
            );
          }
        }
        _logger.debug(
          'Service',
          'Nota sincronizada con Firebase (nueva) - ID: $newFirestoreId',
        );
      } else {
        await docRef
            .update(note.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );
        _logger.debug(
          'Service',
          'Nota sincronizada con Firebase (actualizada)',
        );
      }
    } on FirebaseException catch (e) {
      if (retryCount < _maxRetries &&
          _errorHandler.shouldRetryFirebaseError(e)) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncNoteWithRetry(note, userId, retryCount: retryCount + 1);
      }
      rethrow;
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncNoteWithRetry(note, userId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> _addNoteToSyncQueue(Note note, String userId) async {
    try {
      final queue = await _notesSyncQueue;
      await queue.add({
        'note': note,
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0, // NUEVO - tracking de reintentos
        'lastRetryAt': null, // NUEVO - timestamp del último intento
      });
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar nota a cola de sincronizacion',
        stackTrace: stack,
      );
    }
  }

  /// Get count of notes linked to a task
  Future<int> getTaskNotesCount(String taskId) async {
    try {
      final box = await _notes;
      return box.values.where((note) => note.taskId == taskId).length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete all notes linked to a task
  Future<void> deleteNotesForTask(String taskId) async {
    try {
      final box = await _notes;
      final keysToDelete = box.values
          .where((note) => note.taskId == taskId)
          .map((note) => note.key)
          .toList();

      for (final key in keysToDelete) {
        await box.delete(key);
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
    try {
      final queue = await _notesSyncQueue;
      return queue.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total pending sync count (tasks + notes)
  Future<int> getTotalPendingSyncCount() async {
    final taskCount = await getPendingSyncCount();
    final noteCount = await getPendingNotesSyncCount();
    return taskCount + noteCount;
  }

  /// Process pending notes sync queue
  Future<void> _processNotesSyncQueue() async {
    // Check if cloud sync is enabled - FIX 4
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC QUEUE] Cloud sync deshabilitado, saltando procesamiento de cola de notas',
      );
      return;
    }

    try {
      final queue = await _notesSyncQueue;
      if (queue.isEmpty) return;

      _logger.debug(
        'Service',
        '🔄 [SYNC QUEUE] Procesando ${queue.length} notas pendientes',
      );
      final notesBox = await _notes;
      final keysToRemove = <dynamic>[];
      final keysToUpdate = <dynamic, Map<String, dynamic>>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var entry in queue.toMap().entries) {
        try {
          final data = entry.value;
          final queuedNote = data['note'] as Note;
          final userId = data['userId'] as String;
          final timestamp = data['timestamp'] as int?;
          final retryCount = data['retryCount'] as int? ?? 0;
          final lastRetryAt = data['lastRetryAt'] as int?;

          // Verificar si el item es muy viejo (mas de 7 dias)
          if (timestamp != null) {
            final age = DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            );
            if (age.inDays > 7) {
              _logger.debug(
                'Service',
                '🗑️ [SYNC QUEUE] Nota muy vieja, eliminando',
              );
              keysToRemove.add(entry.key);
              continue;
            }
          }

          // Verificar si excede máximo de reintentos
          if (retryCount >= _maxRetries) {
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Nota excede max reintentos ($_maxRetries), eliminando',
            );
            keysToRemove.add(entry.key);
            continue;
          }

          // Implementar backoff exponencial: 2s, 4s, 8s
          if (lastRetryAt != null && retryCount > 0) {
            final timeSinceLastRetry = now - lastRetryAt;
            final backoffDelay = Duration(
              seconds: 2 * (1 << retryCount),
            ); // 2s, 4s, 8s
            if (timeSinceLastRetry < backoffDelay.inMilliseconds) {
              _logger.debug(
                'Service',
                '⏸️ [SYNC QUEUE] Nota en backoff (intento ${retryCount + 1}/$_maxRetries), saltando',
              );
              continue; // Saltar este item, todavía no es tiempo
            }
          }

          // Buscar la nota actual en Hive por firestoreId o key
          Note? currentNote;
          if (queuedNote.firestoreId.isNotEmpty) {
            currentNote = notesBox.values.cast<Note?>().firstWhere(
              (n) => n?.firestoreId == queuedNote.firestoreId,
              orElse: () => null,
            );
          }

          // Si no se encontro por firestoreId, buscar por key si existe
          if (currentNote == null && queuedNote.key != null) {
            currentNote = notesBox.get(queuedNote.key);
          }

          // Si la nota fue eliminada localmente, eliminar de la cola
          if (currentNote == null) {
            _logger.debug(
              'Service',
              '⚠️ [SYNC QUEUE] Nota no encontrada localmente, eliminando de cola',
            );
            keysToRemove.add(entry.key);
            continue;
          }

          // Intentar sincronizar
          try {
            await _syncNoteWithRetry(currentNote, userId);

            // Guardar el firestoreId actualizado si cambio
            if (currentNote.isInBox && currentNote.firestoreId.isNotEmpty) {
              await currentNote.save();
            }

            keysToRemove.add(entry.key);
            _logger.debug(
              'Service',
              '✅ [SYNC QUEUE] Nota "${currentNote.title}" sincronizada desde cola (intento ${retryCount + 1})',
            );
          } catch (e) {
            // Incrementar contador de reintentos y actualizar lastRetryAt
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Error al procesar nota (intento ${retryCount + 1}/$_maxRetries): $e',
            );
            keysToUpdate[entry.key] = {
              'note': queuedNote,
              'userId': userId,
              'timestamp': timestamp,
              'retryCount': retryCount + 1,
              'lastRetryAt': now,
            };
          }
        } catch (e) {
          _logger.debug(
            'Service',
            '❌ [SYNC QUEUE] Error inesperado al procesar nota: $e',
          );
          // Mantener en la cola para reintentar despues
        }
      }

      // Eliminar notas sincronizadas exitosamente
      for (var key in keysToRemove) {
        await queue.delete(key);
      }

      // Actualizar items con retry count incrementado
      for (var entry in keysToUpdate.entries) {
        await queue.put(entry.key, entry.value);
      }

      if (keysToRemove.isNotEmpty) {
        _logger.debug(
          'Service',
          '✅ [SYNC QUEUE] ${keysToRemove.length} notas procesadas',
        );
      }
      if (keysToUpdate.isNotEmpty) {
        _logger.debug(
          'Service',
          '🔄 [SYNC QUEUE] ${keysToUpdate.length} notas reintentarán más tarde',
        );
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al procesar cola de sincronizacion de notas',
        stackTrace: stack,
      );
    }
  }

  /// Force sync pending notes manually
  Future<void> forceSyncPendingNotes() async {
    await _processNotesSyncQueue();
  }

  /// Force sync all pending items (tasks + notes + notebooks)
  Future<void> forceSyncAll() async {
    await _processSyncQueue();
    await _processNotesSyncQueue();
    await _processNotebooksSyncQueue();
  }

  /// Process notebooks sync queue with retry logic
  Future<void> _processNotebooksSyncQueue() async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC QUEUE] Cloud sync deshabilitado, saltando cola de notebooks',
      );
      return;
    }

    try {
      final queue = _notebooksSyncQueueBox;
      if (queue == null || queue.isEmpty) return;

      _logger.debug(
        'Service',
        '🔄 [SYNC QUEUE] Procesando ${queue.length} notebooks pendientes',
      );

      final notebookBox = await _notebooks;
      final keysToRemove = <dynamic>[];
      final keysToUpdate = <dynamic, Map<String, dynamic>>{};
      final now = DateTime.now();

      for (var entry in queue.toMap().entries) {
        try {
          final data = Map<String, dynamic>.from(entry.value);
          final notebookKey = data['notebookKey'];
          final userId = data['userId'] as String;
          final retryCount = data['retryCount'] as int? ?? 0;
          final lastRetryAt = data['lastRetryAt'] as String?;
          final timestamp = data['timestamp'] as String?;

          // Verificar si el item es muy viejo (mas de 7 dias)
          if (timestamp != null) {
            final age = now.difference(DateTime.parse(timestamp));
            if (age.inDays > 7) {
              _logger.debug(
                'Service',
                '🗑️ [SYNC QUEUE] Notebook muy viejo, eliminando de cola',
              );
              keysToRemove.add(entry.key);
              continue;
            }
          }

          // Verificar si excede máximo de reintentos
          if (retryCount >= _maxRetries) {
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Notebook excede max reintentos ($_maxRetries), moviendo a dead-letter',
            );
            // TODO: Move to dead-letter queue when SyncOrchestrator is integrated
            keysToRemove.add(entry.key);
            continue;
          }

          // Implementar backoff exponencial
          if (lastRetryAt != null && retryCount > 0) {
            final lastRetryTime = DateTime.parse(lastRetryAt);
            final timeSinceLastRetry = now.difference(lastRetryTime);
            final backoffDelay = Duration(seconds: 2 * (1 << retryCount));
            if (timeSinceLastRetry < backoffDelay) {
              continue; // Saltar, todavía en backoff
            }
          }

          // Buscar notebook en Hive
          final notebook = notebookBox.get(notebookKey);

          if (notebook == null) {
            _logger.debug(
              'Service',
              '⚠️ [SYNC QUEUE] Notebook no encontrado localmente, eliminando de cola',
            );
            keysToRemove.add(entry.key);
            continue;
          }

          // Intentar sincronizar
          try {
            await _syncNotebookWithRetry(notebook, userId);
            keysToRemove.add(entry.key);
            _logger.debug(
              'Service',
              '✅ [SYNC QUEUE] Notebook "${notebook.name}" sincronizado desde cola',
            );
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC QUEUE] Error al sincronizar notebook (intento ${retryCount + 1}/$_maxRetries): $e',
            );
            keysToUpdate[entry.key] = {
              'notebookKey': notebookKey,
              'userId': userId,
              'timestamp': timestamp ?? now.toIso8601String(),
              'retryCount': retryCount + 1,
              'lastRetryAt': now.toIso8601String(),
            };
          }
        } catch (e) {
          _logger.debug(
            'Service',
            '❌ [SYNC QUEUE] Error inesperado al procesar notebook: $e',
          );
        }
      }

      // Eliminar items procesados
      for (var key in keysToRemove) {
        await queue.delete(key);
      }

      // Actualizar items para retry
      for (var entry in keysToUpdate.entries) {
        await queue.put(entry.key, entry.value);
      }

      if (keysToRemove.isNotEmpty) {
        _logger.debug(
          'Service',
          '✅ [SYNC QUEUE] ${keysToRemove.length} notebooks procesados',
        );
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al procesar cola de sincronizacion de notebooks',
        stackTrace: stack,
      );
    }
  }

  /// Force sync pending notebooks manually
  Future<void> forceSyncPendingNotebooks() async {
    await _processNotebooksSyncQueue();
  }

  /// Get pending notebooks sync count
  Future<int> getPendingNotebooksSyncCount() async {
    try {
      return _notebooksSyncQueueBox?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ==================== NOTEBOOKS ====================

  Future<Box<Notebook>> get _notebooks async {
    await init();
    if (!_isBoxUsable(_notebooksBox)) {
      await _reinitializeBoxes();
    }
    return _notebooksBox!;
  }

  /// Save notebook locally
  Future<void> saveNotebookLocally(Notebook notebook) async {
    await _executeWithRetry(() async {
      final box = await _notebooks;
      notebook.updatedAt = DateTime.now();
      if (notebook.isInBox) {
        await notebook.save();
      } else {
        await box.add(notebook);
      }
    });
  }

  /// Delete notebook locally
  Future<void> deleteNotebookLocally(dynamic key) async {
    await _executeWithRetry(() async {
      final box = await _notebooks;
      await box.delete(key);
    });
  }

  /// Watch all notebooks
  Stream<List<Notebook>> watchNotebooks() async* {
    try {
      final box = await _notebooks;

      List<Notebook> getSortedNotebooks() {
        return box.values.toList()..sort((a, b) {
          // Favoritos primero
          if (a.isFavorited && !b.isFavorited) return -1;
          if (!a.isFavorited && b.isFavorited) return 1;
          // Luego por fecha de creación
          return b.createdAt.compareTo(a.createdAt);
        });
      }

      yield getSortedNotebooks();

      await for (final _ in box.watch()) {
        yield getSortedNotebooks();
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error watching notebooks',
        stackTrace: stack,
      );
      yield [];
    }
  }

  /// Get all notebooks
  Future<List<Notebook>> getAllNotebooks() async {
    try {
      final box = await _notebooks;
      return box.values.toList();
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

  /// Move all notes out of a notebook (set notebookId to null)
  Future<void> moveNotesOutOfNotebook(
    String notebookId, {
    String? userId,
  }) async {
    try {
      final box = await _notes;
      final notesInNotebook = box.values
          .where((note) => note.notebookId == notebookId)
          .toList();

      for (final note in notesInNotebook) {
        note.updateInPlace(clearNotebookId: true);
        await note.save();
        // Sync the note update to cloud if userId is provided
        if (userId != null && userId.isNotEmpty) {
          await syncNoteToCloudDebounced(note, userId);
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

  /// Sync notebook to Firebase
  Future<void> syncNotebookToCloud(Notebook notebook, String userId) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      _logger.debug(
        'Service',
        'Firebase no configurado, notebook guardado solo localmente',
      );
      return;
    }

    if (userId.isEmpty) {
      return;
    }

    try {
      await _syncNotebookWithRetry(notebook, userId);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar notebook con Firebase',
        userMessage: 'Se sincronizara cuando haya conexion',
        stackTrace: stack,
      );
      await _addNotebookToSyncQueue(notebook, userId);
    }
  }

  Future<void> _syncNotebookWithRetry(
    Notebook notebook,
    String userId, {
    int retryCount = 0,
  }) async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final docRef = fs
          .collection('users')
          .doc(userId)
          .collection('notebooks')
          .doc(notebook.firestoreId.isNotEmpty ? notebook.firestoreId : null);

      if (notebook.firestoreId.isEmpty) {
        await docRef
            .set(notebook.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        final newFirestoreId = docRef.id;

        if (notebook.isInBox) {
          notebook.firestoreId = newFirestoreId;
          await notebook.save();
        } else {
          final box = await _notebooks;
          final existing = box.values.firstWhere(
            (n) => n.key == notebook.key,
            orElse: () => notebook,
          );
          if (existing.isInBox) {
            existing.firestoreId = newFirestoreId;
            await existing.save();
          }
        }
      } else {
        await docRef
            .set(notebook.toFirestore(), SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );
      }
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        await _syncNotebookWithRetry(
          notebook,
          userId,
          retryCount: retryCount + 1,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Delete notebook from Firebase
  Future<void> deleteNotebookFromCloud(
    String firestoreId,
    String userId,
  ) async {
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null || userId.isEmpty) {
      return;
    }

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

  /// Add notebook to sync queue
  Future<void> _addNotebookToSyncQueue(Notebook notebook, String userId) async {
    try {
      final box = _notebooksSyncQueueBox!;
      await box.put(notebook.key, {
        'notebookKey': notebook.key,
        'userId': userId,
        'retryCount': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar notebook a cola de sincronizacion',
        stackTrace: stack,
      );
    }
  }

  // ==================== CLOUD TO LOCAL SYNC ====================

  /// Sync tasks from Firestore to local Hive (download/pull)
  /// Called on app startup or when user logs in
  /// Uses lastUpdatedAt for incremental sync
  Future<SyncResult> syncFromCloud(String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Cloud sync deshabilitado, saltando sync desde nube',
      );
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    if (!_firebaseAvailable || firestore == null) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Firebase no disponible, saltando sync desde nube',
      );
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    if (userId.isEmpty) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Usuario vacío, saltando sync desde nube',
      );
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    _logger.debug(
      'Service',
      '🔄 [SYNC] Iniciando sincronización desde Firebase para usuario $userId',
    );
    int tasksDownloaded = 0;
    int notesDownloaded = 0;
    int errors = 0;

    try {
      final box = await _box;
      final notesBox = await _notes;
      final userDoc = firestore!.collection('users').doc(userId);

      // Sync tasks from Firestore
      try {
        final tasksSnapshot = await userDoc
            .collection('tasks')
            .get()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        _logger.debug(
          'Service',
          '📥 [SYNC] Encontradas ${tasksSnapshot.docs.length} tareas en Firebase',
        );

        for (final doc in tasksSnapshot.docs) {
          try {
            final cloudTask = Task.fromFirestore(doc.id, doc.data());

            // Skip deleted tasks from cloud
            if (cloudTask.deleted) {
              // Check if we have this task locally and mark it as deleted
              final localTask = box.values.cast<Task?>().firstWhere(
                (t) => t?.firestoreId == doc.id,
                orElse: () => null,
              );
              if (localTask != null && !localTask.deleted) {
                localTask.deleted = true;
                localTask.deletedAt = cloudTask.deletedAt ?? DateTime.now();
                await localTask.save();
              }
              continue;
            }

            // Check if task exists locally by firestoreId
            final existingTask = box.values.cast<Task?>().firstWhere(
              (t) => t?.firestoreId == doc.id,
              orElse: () => null,
            );

            if (existingTask != null) {
              // Task exists locally - check which is newer
              final localUpdated =
                  existingTask.lastUpdatedAt ?? existingTask.createdAt;
              final cloudUpdated =
                  cloudTask.lastUpdatedAt ?? cloudTask.createdAt;

              if (cloudUpdated.isAfter(localUpdated)) {
                // Cloud is newer - update local
                existingTask.updateInPlace(
                  title: cloudTask.title,
                  type: cloudTask.type,
                  isCompleted: cloudTask.isCompleted,
                  dueDate: cloudTask.dueDate,
                  category: cloudTask.category,
                  priority: cloudTask.priority,
                  dueTimeMinutes: cloudTask.dueTimeMinutes,
                  motivation: cloudTask.motivation,
                  reward: cloudTask.reward,
                  recurrenceDay: cloudTask.recurrenceDay,
                  deadline: cloudTask.deadline,
                  deleted: cloudTask.deleted,
                  deletedAt: cloudTask.deletedAt,
                  lastUpdatedAt: cloudUpdated,
                );
                await existingTask.save();
                tasksDownloaded++;
                _logger.debug(
                  'Service',
                  '📥 [SYNC] Tarea actualizada: "${cloudTask.title}"',
                );
              }
              // else: local is newer or same - will be synced to cloud later
            } else {
              // Task doesn't exist locally - add it
              await box.add(cloudTask);
              tasksDownloaded++;
              _logger.debug(
                'Service',
                '📥 [SYNC] Tarea nueva descargada: "${cloudTask.title}"',
              );
            }
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error procesando tarea ${doc.id}: $e',
            );
            errors++;
          }
        }
      } catch (e) {
        _logger.debug(
          'Service',
          '❌ [SYNC] Error al obtener tareas de Firebase: $e',
        );
        errors++;
      }

      // Sync notes from Firestore
      try {
        final notesSnapshot = await userDoc
            .collection('notes')
            .get()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        _logger.debug(
          'Service',
          '📥 [SYNC] Encontradas ${notesSnapshot.docs.length} notas en Firebase',
        );

        for (final doc in notesSnapshot.docs) {
          try {
            final cloudNote = Note.fromFirestore(doc.id, doc.data());

            // Skip deleted notes from cloud
            if (cloudNote.deleted) {
              final localNote = notesBox.values.cast<Note?>().firstWhere(
                (n) => n?.firestoreId == doc.id,
                orElse: () => null,
              );
              if (localNote != null && !localNote.deleted) {
                localNote.deleted = true;
                localNote.deletedAt = cloudNote.deletedAt ?? DateTime.now();
                await localNote.save();
              }
              continue;
            }

            // Check if note exists locally by firestoreId
            final existingNote = notesBox.values.cast<Note?>().firstWhere(
              (n) => n?.firestoreId == doc.id,
              orElse: () => null,
            );

            if (existingNote != null) {
              // Note exists locally - check which is newer
              final localUpdated = existingNote.updatedAt;
              final cloudUpdated = cloudNote.updatedAt;

              if (cloudUpdated.isAfter(localUpdated)) {
                // Cloud is newer - update local
                existingNote.updateInPlace(
                  title: cloudNote.title,
                  content: cloudNote.content,
                  updatedAt: cloudUpdated,
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
                await existingNote.save();
                notesDownloaded++;
                _logger.debug(
                  'Service',
                  '📥 [SYNC] Nota actualizada: "${cloudNote.title}"',
                );
              }
            } else {
              // Note doesn't exist locally - add it
              await notesBox.add(cloudNote);
              notesDownloaded++;
              _logger.debug(
                'Service',
                '📥 [SYNC] Nota nueva descargada: "${cloudNote.title}"',
              );
            }
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error procesando nota ${doc.id}: $e',
            );
            errors++;
          }
        }
      } catch (e) {
        _logger.debug(
          'Service',
          '❌ [SYNC] Error al obtener notas de Firebase: $e',
        );
        errors++;
      }

      // Sync notebooks from Firestore
      int notebooksDownloaded = 0;
      try {
        final notebooksSnapshot = await userDoc
            .collection('notebooks')
            .get()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('Firebase timeout'),
            );

        _logger.debug(
          'Service',
          '📥 [SYNC] Encontrados ${notebooksSnapshot.docs.length} notebooks en Firebase',
        );

        final notebookBox = await _notebooks;

        for (final doc in notebooksSnapshot.docs) {
          try {
            final cloudNotebook = Notebook.fromFirestore(doc.id, doc.data());

            // Check if notebook exists locally by firestoreId
            final existingNotebook = notebookBox.values.cast<Notebook?>().firstWhere(
              (n) => n?.firestoreId == doc.id,
              orElse: () => null,
            );

            if (existingNotebook != null) {
              // Notebook exists locally - check which is newer
              final localUpdated = existingNotebook.updatedAt;
              final cloudUpdated = cloudNotebook.updatedAt;

              if (cloudUpdated.isAfter(localUpdated)) {
                // Cloud is newer - update local
                existingNotebook.name = cloudNotebook.name;
                existingNotebook.icon = cloudNotebook.icon;
                existingNotebook.color = cloudNotebook.color;
                existingNotebook.isFavorited = cloudNotebook.isFavorited;
                existingNotebook.parentId = cloudNotebook.parentId;
                existingNotebook.updatedAt = cloudNotebook.updatedAt;
                await existingNotebook.save();
                notebooksDownloaded++;
                _logger.debug(
                  'Service',
                  '📥 [SYNC] Notebook actualizado: "${cloudNotebook.name}"',
                );
              }
            } else {
              // Notebook doesn't exist locally - add it
              await notebookBox.add(cloudNotebook);
              notebooksDownloaded++;
              _logger.debug(
                'Service',
                '📥 [SYNC] Notebook nuevo descargado: "${cloudNotebook.name}"',
              );
            }
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error procesando notebook ${doc.id}: $e',
            );
            errors++;
          }
        }
      } catch (e) {
        _logger.debug(
          'Service',
          '❌ [SYNC] Error al obtener notebooks de Firebase: $e',
        );
        errors++;
      }

      // Update collection sync timestamp
      updateCollectionSync('tasks');
      updateCollectionSync('notes');
      updateCollectionSync('notebooks');

      _logger.debug(
        'Service',
        '✅ [SYNC] Sync desde nube completado: $tasksDownloaded tareas, $notesDownloaded notas, $notebooksDownloaded notebooks, $errors errores',
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
  /// 1. Download changes from cloud
  /// 2. Upload local changes to cloud
  Future<SyncResult> performFullSync(String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      _logger.debug(
        'Service',
        '⚠️ [SYNC] Cloud sync deshabilitado, saltando sync completo',
      );
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    if (!_firebaseAvailable || firestore == null || userId.isEmpty) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    _logger.debug(
      'Service',
      '🔄 [SYNC] Iniciando sincronización bidireccional completa',
    );

    // First, download from cloud
    final downloadResult = await syncFromCloud(userId);

    // Then, upload pending local changes
    await forceSyncAll();

    // Finally, sync any local-only tasks (those without firestoreId)
    await _syncLocalOnlyItems(userId);

    return downloadResult;
  }

  /// Sync local items that don't have a firestoreId yet
  Future<void> _syncLocalOnlyItems(String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) return;

    if (!_firebaseAvailable || firestore == null || userId.isEmpty) return;

    try {
      final box = await _box;
      final notesBox = await _notes;

      // Find and sync tasks without firestoreId
      final localOnlyTasks = box.values
          .where((t) => t.firestoreId.isEmpty && !t.deleted)
          .toList();

      if (localOnlyTasks.isNotEmpty) {
        _logger.debug(
          'Service',
          '📤 [SYNC] Sincronizando ${localOnlyTasks.length} tareas locales',
        );
        for (final task in localOnlyTasks) {
          try {
            await syncTaskToCloud(task, userId);
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error sincronizando tarea local: $e',
            );
          }
        }
      }

      // Find and sync notes without firestoreId
      final localOnlyNotes = notesBox.values
          .where((n) => n.firestoreId.isEmpty && !n.deleted)
          .toList();

      if (localOnlyNotes.isNotEmpty) {
        _logger.debug(
          'Service',
          '📤 [SYNC] Sincronizando ${localOnlyNotes.length} notas locales',
        );
        for (final note in localOnlyNotes) {
          try {
            await syncNoteToCloud(note, userId);
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error sincronizando nota local: $e',
            );
          }
        }
      }

      // Find and sync notebooks without firestoreId
      final notebookBox = await _notebooks;
      final localOnlyNotebooks = notebookBox.values
          .where((n) => n.firestoreId.isEmpty)
          .toList();

      if (localOnlyNotebooks.isNotEmpty) {
        _logger.debug(
          'Service',
          '📤 [SYNC] Sincronizando ${localOnlyNotebooks.length} notebooks locales',
        );
        for (final notebook in localOnlyNotebooks) {
          try {
            await syncNotebookToCloud(notebook, userId);
          } catch (e) {
            _logger.debug(
              'Service',
              '❌ [SYNC] Error sincronizando notebook local: $e',
            );
          }
        }
      }
    } catch (e) {
      _logger.debug('Service', '❌ [SYNC] Error en sync de items locales: $e');
    }
  }

  /// Delete task from Firestore
  Future<void> deleteTaskFromCloud(String firestoreId, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      return;
    }

    if (firestoreId.isEmpty || userId.isEmpty) {
      return;
    }

    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(firestoreId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Firebase timeout'),
          );
      _logger.debug('Service', 'Tarea eliminada de Firebase');
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

  /// Delete note from Firestore
  Future<void> deleteNoteFromCloud(String firestoreId, String userId) async {
    // Check if cloud sync is enabled
    final syncEnabled = await isCloudSyncEnabled();
    if (!syncEnabled) {
      return;
    }

    if (!_firebaseAvailable || firestore == null) {
      return;
    }

    if (firestoreId.isEmpty || userId.isEmpty) {
      return;
    }

    try {
      await firestore!
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(firestoreId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Firebase timeout'),
          );
      _logger.debug('Service', 'Nota eliminada de Firebase');
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

  // ==================== ACCOUNT DELETION ====================

  /// Delete all user data from Firestore (for account deletion)
  Future<void> deleteAllUserDataFromCloud(String userId) async {
    if (!_firebaseAvailable || firestore == null) {
      return;
    }

    if (userId.isEmpty) {
      return;
    }

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

      // Delete user preferences (if stored in Firestore)
      try {
        final prefsSnapshot = await userDoc.collection('preferences').get();
        for (final doc in prefsSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (_) {
        // Preferences collection may not exist
      }

      // Delete user document itself
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

  /// Clear all local Hive data (for account deletion)
  Future<void> clearAllLocalData() async {
    try {
      await init();

      // Clear all boxes
      await _taskBox?.clear();
      await _notesBox?.clear();
      await _historyBox?.clear();
      await _syncQueueBox?.clear();
      await _notesSyncQueueBox?.clear();
      await _userPrefsBox?.clear();

      // Re-initialize user preferences with defaults
      await _userPrefsBox?.add(UserPreferences());

      // Clear debounce state
      _syncDebounceTimer?.cancel();
      _pendingSyncTaskKeys.clear();
      _pendingSyncNoteKeys.clear();
      _pendingSyncUserId = null;

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

  /// Export all user data as JSON (for GDPR data portability)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final box = await _box;
      final notesBox = await _notes;
      final historyBox = await _historyBoxGetter;
      final prefs = await getUserPreferences();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'tasks': box.values
            .where((t) => !t.deleted)
            .map((t) => t.toFirestore())
            .toList(),
        'notes': notesBox.values
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

  /// Dispose resources and cleanup
  /// Should be called when the service is no longer needed
  Future<void> dispose() async {
    try {
      _logger.debug('Service', '[DatabaseService] Disposing resources...');

      // Cancel pending timers
      _syncDebounceTimer?.cancel();
      _syncDebounceTimer = null;

      // Flush any pending syncs before disposing
      await flushPendingSyncs().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.debug(
            'Service',
            '[DatabaseService] Timeout flushing pending syncs on dispose',
          );
        },
      );

      // Clear pending sync sets
      _pendingSyncTaskKeys.clear();
      _pendingSyncNoteKeys.clear();
      _pendingSyncUserId = null;

      // Print quota summary
      _quotaManager?.printSummary();

      // Close all boxes gracefully
      try {
        if (_taskBox?.isOpen ?? false) {
          await _taskBox!.close();
        }
        if (_syncQueueBox?.isOpen ?? false) {
          await _syncQueueBox!.close();
        }
        if (_historyBox?.isOpen ?? false) {
          await _historyBox!.close();
        }
        if (_notesBox?.isOpen ?? false) {
          await _notesBox!.close();
        }
        if (_notesSyncQueueBox?.isOpen ?? false) {
          await _notesSyncQueueBox!.close();
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

  /// Get quota statistics (returns null if Firebase unavailable)
  QuotaStats? getQuotaStats() {
    return _quotaManager?.stats;
  }

  /// Reset quota statistics
  void resetQuotaStats() {
    _quotaManager?.resetStats();
  }
}
