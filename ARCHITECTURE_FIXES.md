# Correcciones y Refactorizaciones - AuraList

**Fecha:** 2026-02-10
**Relacionado con:** ARCHITECTURE_REPORT.md

Este documento contiene correcciones concretas y código ejemplo para las mejoras sugeridas en el reporte de arquitectura.

---

## 1. Refactorización de DatabaseService

### 1.1 Crear Interfaces

**Archivo:** `lib/repositories/interfaces.dart`

```dart
/// Interface base para repositorios
abstract class IRepository<T> {
  Future<void> init();
  Future<T?> getById(dynamic id);
  Future<List<T>> getAll();
  Future<void> save(T entity);
  Future<void> delete(dynamic id);
  Stream<List<T>> watchAll();
}

/// Interface para repositorio de tareas
abstract class ITaskRepository extends IRepository<Task> {
  Future<List<Task>> getByType(String type);
  Stream<List<Task>> watchByType(String type);
  Future<void> toggleCompleted(Task task);
  Future<void> softDelete(Task task);
  Future<void> syncToCloud(Task task, String userId);
}

/// Interface para repositorio de notas
abstract class INoteRepository extends IRepository<Note> {
  Future<List<Note>> getIndependentNotes();
  Future<List<Note>> getNotesForTask(String taskId);
  Stream<List<Note>> watchIndependentNotes();
  Stream<List<Note>> watchNotesForTask(String taskId);
  Future<List<Note>> searchNotes(String query);
  Future<void> softDelete(Note note);
  Future<void> syncToCloud(Note note, String userId);
}

/// Interface para servicio de sincronización
abstract class ISyncService {
  Future<void> syncTaskToCloud(Task task, String userId);
  Future<void> syncNoteToCloud(Note note, String userId);
  Future<SyncResult> syncFromCloud(String userId);
  Future<SyncResult> performFullSync(String userId);
  Future<void> forceSyncAll();
  Future<int> getPendingSyncCount();
}
```

### 1.2 Implementar TaskRepository

**Archivo:** `lib/repositories/task_repository.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../services/error_handler.dart';
import 'interfaces.dart';

class TaskRepository implements ITaskRepository {
  final ErrorHandler _errorHandler;
  static const String _boxName = 'tasks';

  Box<Task>? _box;
  bool _initialized = false;

  TaskRepository(this._errorHandler);

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TaskAdapter());
      }

      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<Task>(_boxName)
          : await Hive.openBox<Task>(_boxName);

      _initialized = true;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al inicializar TaskRepository',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Box<Task> get _safeBox {
    if (!_initialized || _box == null || !_box!.isOpen) {
      throw HiveStorageException(
        message: 'TaskRepository no inicializado o box cerrado',
        userMessage: 'Error de base de datos. Reinicia la app.',
      );
    }
    return _box!;
  }

  @override
  Future<Task?> getById(dynamic id) async {
    try {
      await init();
      return _safeBox.get(id);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener tarea por ID',
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<Task>> getAll() async {
    try {
      await init();
      return _safeBox.values
          .where((task) => !task.deleted)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener todas las tareas',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<List<Task>> getByType(String type) async {
    try {
      await init();
      return _safeBox.values
          .where((task) => task.type == type && !task.deleted)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener tareas por tipo',
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> save(Task task) async {
    try {
      await init();

      if (task.isInBox) {
        task.lastUpdatedAt = DateTime.now();
        await task.save();
      } else {
        // Verificar duplicados antes de agregar
        final existing = await _findExistingTask(task);

        if (existing != null) {
          // Actualizar existente en lugar de crear duplicado
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
            lastUpdatedAt: DateTime.now(),
          );
          await existing.save();
        } else {
          task.lastUpdatedAt = DateTime.now();
          await _safeBox.add(task);
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Error al guardar tarea',
        userMessage: 'No se pudo guardar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(dynamic id) async {
    try {
      await init();
      await _safeBox.delete(id);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> softDelete(Task task) async {
    try {
      await init();

      if (task.isInBox) {
        task.updateInPlace(
          deleted: true,
          deletedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
        );
        await task.save();
      } else {
        final existing = await _findExistingTask(task);
        if (existing != null) {
          existing.updateInPlace(
            deleted: true,
            deletedAt: DateTime.now(),
            lastUpdatedAt: DateTime.now(),
          );
          await existing.save();
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error en soft delete',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> toggleCompleted(Task task) async {
    try {
      await init();

      if (task.isInBox) {
        task.updateInPlace(
          isCompleted: !task.isCompleted,
          lastUpdatedAt: DateTime.now(),
        );
        await task.save();
      } else {
        final existing = await _findExistingTask(task);
        if (existing != null) {
          existing.updateInPlace(
            isCompleted: !existing.isCompleted,
            lastUpdatedAt: DateTime.now(),
          );
          await existing.save();
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al cambiar estado de tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> watchAll() async* {
    try {
      await init();

      List<Task> getFilteredTasks() {
        return _safeBox.values
            .where((task) => !task.deleted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      yield getFilteredTasks();
      yield* _safeBox.watch().map((_) => getFilteredTasks());
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

  @override
  Stream<List<Task>> watchByType(String type) async* {
    try {
      await init();

      List<Task> getFilteredTasks() {
        return _safeBox.values
            .where((task) => task.type == type && !task.deleted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      yield getFilteredTasks();
      yield* _safeBox.watch().map((_) => getFilteredTasks());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al observar tareas por tipo',
        stackTrace: stack,
      );
      yield [];
    }
  }

  @override
  Future<void> syncToCloud(Task task, String userId) async {
    // Implementación delegada a SyncService
    throw UnimplementedError('Usar SyncService para sincronización');
  }

  /// Encuentra una tarea existente por múltiples identidades
  Future<Task?> _findExistingTask(Task task) async {
    // 1. Por Hive key
    if (task.key != null) {
      final t = _safeBox.get(task.key);
      if (t != null) return t;
    }

    // 2. Por firestoreId (para tareas sincronizadas)
    if (task.firestoreId.isNotEmpty) {
      final t = _safeBox.values.cast<Task?>().firstWhere(
        (t) => t?.firestoreId == task.firestoreId,
        orElse: () => null,
      );
      if (t != null) return t;
    }

    // 3. Por createdAt (para tareas locales)
    return _safeBox.values.cast<Task?>().firstWhere(
      (t) =>
          t != null &&
          t.createdAt.millisecondsSinceEpoch ==
              task.createdAt.millisecondsSinceEpoch,
      orElse: () => null,
    );
  }

  /// Limpia duplicados existentes
  Future<void> cleanupDuplicates() async {
    try {
      await init();

      final seenFirestoreIds = <String>{};
      final seenTimestamps = <int>{};
      final tasksToDelete = <dynamic>[];

      for (final task in _safeBox.values) {
        bool isDuplicate = false;

        if (task.firestoreId.isNotEmpty) {
          if (seenFirestoreIds.contains(task.firestoreId)) {
            isDuplicate = true;
          } else {
            seenFirestoreIds.add(task.firestoreId);
          }
        }

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
        await _safeBox.delete(key);
      }

      if (tasksToDelete.isNotEmpty) {
        print('TaskRepository: Eliminados ${tasksToDelete.length} duplicados');
      }
    } catch (e) {
      print('Error limpiando duplicados: $e');
    }
  }
}
```

### 1.3 Crear SyncService

**Archivo:** `lib/services/sync_service.dart`

```dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../repositories/interfaces.dart';
import 'error_handler.dart';

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

class SyncService implements ISyncService {
  final ITaskRepository _taskRepo;
  final INoteRepository _noteRepo;
  final ErrorHandler _errorHandler;
  final FirebaseFirestore? _firestore;

  static const Duration _syncDebounceDelay = Duration(seconds: 3);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Debouncing state
  Timer? _syncDebounceTimer;
  final Set<String> _pendingSyncTaskIds = {};
  final Set<String> _pendingSyncNoteIds = {};
  String? _pendingSyncUserId;

  SyncService({
    required ITaskRepository taskRepository,
    required INoteRepository noteRepository,
    required ErrorHandler errorHandler,
    FirebaseFirestore? firestore,
  })  : _taskRepo = taskRepository,
        _noteRepo = noteRepository,
        _errorHandler = errorHandler,
        _firestore = firestore;

  bool get _isFirebaseAvailable => _firestore != null;

  @override
  Future<void> syncTaskToCloud(Task task, String userId) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[Sync] Firebase no disponible');
      return;
    }

    if (userId.isEmpty) {
      debugPrint('[Sync] userId vacío');
      return;
    }

    try {
      await _syncTaskWithRetry(task, userId);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.sync,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar tarea',
        stackTrace: stack,
      );
      // TODO: Agregar a sync queue
    }
  }

  @override
  Future<void> syncNoteToCloud(Note note, String userId) async {
    if (!_isFirebaseAvailable) return;
    if (userId.isEmpty) return;

    try {
      await _syncNoteWithRetry(note, userId);
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.sync,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar nota',
        stackTrace: stack,
      );
      // TODO: Agregar a sync queue
    }
  }

  Future<void> _syncTaskWithRetry(
    Task task,
    String userId, {
    int retryCount = 0,
  }) async {
    if (!_isFirebaseAvailable) return;

    try {
      final docRef = _firestore!
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.firestoreId.isNotEmpty ? task.firestoreId : null);

      if (task.firestoreId.isEmpty) {
        await docRef.set(task.toFirestore());
        task.firestoreId = docRef.id;
        await _taskRepo.save(task);
        debugPrint('[Sync] Tarea sincronizada (nueva)');
      } else {
        await docRef.update(task.toFirestore());
        debugPrint('[Sync] Tarea sincronizada (actualizada)');
      }
    } on FirebaseException catch (e, stack) {
      if (retryCount < _maxRetries && _shouldRetryFirebaseError(e)) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncTaskWithRetry(task, userId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<void> _syncNoteWithRetry(
    Note note,
    String userId, {
    int retryCount = 0,
  }) async {
    if (!_isFirebaseAvailable) return;

    try {
      final docRef = _firestore!
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.firestoreId.isNotEmpty ? note.firestoreId : null);

      if (note.firestoreId.isEmpty) {
        await docRef.set(note.toFirestore());
        note.firestoreId = docRef.id;
        await _noteRepo.save(note);
        debugPrint('[Sync] Nota sincronizada (nueva)');
      } else {
        await docRef.update(note.toFirestore());
        debugPrint('[Sync] Nota sincronizada (actualizada)');
      }
    } on FirebaseException catch (e) {
      if (retryCount < _maxRetries && _shouldRetryFirebaseError(e)) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _syncNoteWithRetry(note, userId, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  @override
  Future<SyncResult> syncFromCloud(String userId) async {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      return SyncResult(tasksDownloaded: 0, notesDownloaded: 0, errors: 0);
    }

    int tasksDownloaded = 0;
    int notesDownloaded = 0;
    int errors = 0;

    try {
      final userDoc = _firestore!.collection('users').doc(userId);

      // Sync tasks
      try {
        final tasksSnapshot = await userDoc.collection('tasks').get();

        for (final doc in tasksSnapshot.docs) {
          try {
            final cloudTask = Task.fromFirestore(doc.id, doc.data());

            if (cloudTask.deleted) continue;

            final localTasks = await _taskRepo.getAll();
            final existing = localTasks.cast<Task?>().firstWhere(
              (t) => t?.firestoreId == doc.id,
              orElse: () => null,
            );

            if (existing == null) {
              await _taskRepo.save(cloudTask);
              tasksDownloaded++;
            } else {
              final cloudUpdated = cloudTask.lastUpdatedAt ?? cloudTask.createdAt;
              final localUpdated = existing.lastUpdatedAt ?? existing.createdAt;

              if (cloudUpdated.isAfter(localUpdated)) {
                existing.updateInPlace(
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
                  lastUpdatedAt: cloudUpdated,
                );
                await _taskRepo.save(existing);
                tasksDownloaded++;
              }
            }
          } catch (e) {
            errors++;
            debugPrint('[Sync] Error procesando tarea ${doc.id}: $e');
          }
        }
      } catch (e) {
        errors++;
        debugPrint('[Sync] Error obteniendo tareas: $e');
      }

      // Sync notes (similar logic)
      // TODO: Implementar sync de notes

    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.sync,
        severity: ErrorSeverity.warning,
        message: 'Error en sync desde cloud',
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

  @override
  Future<SyncResult> performFullSync(String userId) async {
    debugPrint('[Sync] Iniciando sync bidireccional completo');

    // 1. Download from cloud
    final downloadResult = await syncFromCloud(userId);

    // 2. Upload pending local changes
    await forceSyncAll();

    return downloadResult;
  }

  @override
  Future<void> forceSyncAll() async {
    await _flushPendingSyncs();
  }

  @override
  Future<int> getPendingSyncCount() async {
    return _pendingSyncTaskIds.length + _pendingSyncNoteIds.length;
  }

  Future<void> _flushPendingSyncs() async {
    final userId = _pendingSyncUserId;
    if (userId == null || userId.isEmpty) return;

    final taskIds = Set<String>.from(_pendingSyncTaskIds);
    final noteIds = Set<String>.from(_pendingSyncNoteIds);
    _pendingSyncTaskIds.clear();
    _pendingSyncNoteIds.clear();

    if (taskIds.isEmpty && noteIds.isEmpty) return;

    debugPrint('[Sync] Flushing ${taskIds.length} tasks, ${noteIds.length} notes');

    for (final taskId in taskIds) {
      final task = await _taskRepo.getById(taskId);
      if (task != null) {
        await syncTaskToCloud(task, userId);
      }
    }

    for (final noteId in noteIds) {
      final note = await _noteRepo.getById(noteId);
      if (note != null) {
        await syncNoteToCloud(note, userId);
      }
    }
  }

  bool _shouldRetryFirebaseError(FirebaseException error) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'unknown' ||
        error.code == 'cancelled' ||
        error.code == 'resource-exhausted';
  }

  void dispose() {
    _syncDebounceTimer?.cancel();
  }
}
```

---

## 2. Mixins para Reducir Duplicación

### 2.1 HiveModelMixin

**Archivo:** `lib/models/mixins/hive_model_mixin.dart`

```dart
import 'package:hive/hive.dart';

/// Mixin para comportamiento común de modelos Hive con soft delete
mixin HiveModelMixin on HiveObject {
  // Campos compartidos - deben ser implementados por la clase
  String get firestoreId;
  set firestoreId(String value);

  bool get deleted;
  set deleted(bool value);

  DateTime? get deletedAt;
  set deletedAt(DateTime? value);

  /// Marca el modelo como eliminado (soft delete)
  void markAsDeleted() {
    deleted = true;
    deletedAt = DateTime.now();
    if (isInBox) {
      save();
    }
  }

  /// Restaura un modelo eliminado
  void restore() {
    deleted = false;
    deletedAt = null;
    if (isInBox) {
      save();
    }
  }

  /// Verifica si el modelo está sincronizado con Firebase
  bool get isSynced => firestoreId.isNotEmpty;

  /// Verifica si el modelo es solo local (no sincronizado)
  bool get isLocalOnly => firestoreId.isEmpty;

  /// Verifica si el modelo está activo (no eliminado)
  bool get isActive => !deleted;
}

/// Mixin para modelos con timestamps
mixin TimestampMixin {
  DateTime get createdAt;
  set createdAt(DateTime value);

  DateTime get updatedAt;
  set updatedAt(DateTime value);

  /// Actualiza el timestamp de modificación
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Edad del modelo en días
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Verifica si el modelo fue modificado recientemente (últimas 24 horas)
  bool get wasRecentlyModified {
    return DateTime.now().difference(updatedAt).inHours < 24;
  }
}

/// Mixin para modelos con conversión Firestore
mixin FirestoreMixin {
  Map<String, dynamic> toFirestore();

  /// Prepara datos para Firestore (sin nulls)
  Map<String, dynamic> toFirestoreClean() {
    final data = toFirestore();
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
```

### 2.2 Aplicar Mixins a Task

**Modificación en:** `lib/models/task_model.dart`

```dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'mixins/hive_model_mixin.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject
    with HiveModelMixin, TimestampMixin, FirestoreMixin {

  @HiveField(0)
  @override
  late String firestoreId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late bool isCompleted;

  @HiveField(4)
  @override
  late DateTime createdAt;

  @HiveField(5)
  DateTime? dueDate;

  // ... resto de campos ...

  @HiveField(13, defaultValue: false)
  @override
  late bool deleted;

  @HiveField(14)
  @override
  DateTime? deletedAt;

  @HiveField(15)
  @override
  late DateTime updatedAt;

  Task({
    this.firestoreId = '',
    required this.title,
    required this.type,
    this.isCompleted = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.dueDate,
    this.category = 'Personal',
    this.priority = 1,
    this.dueTimeMinutes,
    this.motivation,
    this.reward,
    this.recurrenceDay,
    this.deadline,
    this.deleted = false,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  // copyWith() simplificado - solo campos específicos de Task
  Task copyWith({
    String? firestoreId,
    String? title,
    String? type,
    bool? isCompleted,
    DateTime? dueDate,
    String? category,
    int? priority,
    int? dueTimeMinutes,
    bool clearDueTime = false,
    String? motivation,
    String? reward,
    int? recurrenceDay,
    DateTime? deadline,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return Task(
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueTimeMinutes: clearDueTime ? null : (dueTimeMinutes ?? this.dueTimeMinutes),
      motivation: motivation ?? this.motivation,
      reward: reward ?? this.reward,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      deadline: deadline ?? this.deadline,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'dueTimeMinutes': dueTimeMinutes,
      'motivation': motivation,
      'reward': reward,
      'recurrenceDay': recurrenceDay,
      'deadline': deadline?.toIso8601String(),
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // updateInPlace() se mantiene para casos especiales
  // pero ahora se puede usar touch() del mixin
  void updateInPlace({
    String? firestoreId,
    String? title,
    String? type,
    bool? isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? category,
    int? priority,
    int? dueTimeMinutes,
    bool clearDueTime = false,
    String? motivation,
    bool clearMotivation = false,
    String? reward,
    bool clearReward = false,
    int? recurrenceDay,
    bool clearRecurrenceDay = false,
    DateTime? deadline,
    bool clearDeadline = false,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    if (firestoreId != null) this.firestoreId = firestoreId;
    if (title != null) this.title = title;
    if (type != null) this.type = type;
    if (isCompleted != null) this.isCompleted = isCompleted;
    if (clearDueDate) {
      this.dueDate = null;
    } else if (dueDate != null) {
      this.dueDate = dueDate;
    }
    if (category != null) this.category = category;
    if (priority != null) this.priority = priority;
    if (clearDueTime) {
      this.dueTimeMinutes = null;
    } else if (dueTimeMinutes != null) {
      this.dueTimeMinutes = dueTimeMinutes;
    }
    if (clearMotivation) {
      this.motivation = null;
    } else if (motivation != null) {
      this.motivation = motivation;
    }
    if (clearReward) {
      this.reward = null;
    } else if (reward != null) {
      this.reward = reward;
    }
    if (clearRecurrenceDay) {
      this.recurrenceDay = null;
    } else if (recurrenceDay != null) {
      this.recurrenceDay = recurrenceDay;
    }
    if (clearDeadline) {
      this.deadline = null;
    } else if (deadline != null) {
      this.deadline = deadline;
    }
    if (deleted != null) this.deleted = deleted;
    if (deletedAt != null) this.deletedAt = deletedAt;

    // Usar touch() del mixin
    touch();
  }
}
```

---

## 3. Actualizar Providers para Usar Repositorios

### 3.1 Actualizar TaskProvider

**Modificación en:** `lib/providers/task_provider.dart`

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../repositories/interfaces.dart';
import '../repositories/task_repository.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/error_handler.dart';
import 'navigation_provider.dart';

// Provider para TaskRepository
final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return TaskRepository(errorHandler);
});

// Provider para SyncService
final syncServiceProvider = Provider<ISyncService>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final noteRepo = ref.watch(noteRepositoryProvider); // TODO: crear
  final errorHandler = ref.watch(errorHandlerProvider);
  // TODO: Obtener firestore instance
  return SyncService(
    taskRepository: taskRepo,
    noteRepository: noteRepo, // TODO: implementar
    errorHandler: errorHandler,
  );
});

// Provider actualizado para usar repository
final tasksProvider =
    StateNotifierProvider.family<TaskNotifier, List<Task>, String>((ref, type) {
      final taskRepo = ref.watch(taskRepositoryProvider);
      final syncService = ref.watch(syncServiceProvider);
      final authService = ref.watch(authServiceProvider);
      final errorHandler = ref.watch(errorHandlerProvider);
      return TaskNotifier(
        taskRepo,
        syncService,
        authService,
        errorHandler,
        type,
      );
    });

class TaskNotifier extends StateNotifier<List<Task>> {
  final ITaskRepository _taskRepo;
  final ISyncService _syncService;
  final AuthService _auth;
  final ErrorHandler _errorHandler;
  final String _type;
  StreamSubscription? _subscription;

  TaskNotifier(
    this._taskRepo,
    this._syncService,
    this._auth,
    this._errorHandler,
    this._type,
  ) : super([]) {
    _init();
  }

  void _init() {
    _subscription = _taskRepo
        .watchByType(_type)
        .listen(
          (tasks) => state = _deduplicateTasks(tasks),
          onError: (e) => debugPrint('Error watching tasks: $e'),
        );
  }

  List<Task> _deduplicateTasks(List<Task> tasks) {
    final seenFirestoreIds = <String>{};
    final seenHiveKeys = <dynamic>{};
    final seenTimestamps = <int>{};
    final unique = <Task>[];

    for (final task in tasks) {
      bool isDuplicate = false;

      if (task.firestoreId.isNotEmpty) {
        if (seenFirestoreIds.contains(task.firestoreId)) {
          isDuplicate = true;
        } else {
          seenFirestoreIds.add(task.firestoreId);
        }
      }

      if (!isDuplicate && task.key != null) {
        if (seenHiveKeys.contains(task.key)) {
          isDuplicate = true;
        } else {
          seenHiveKeys.add(task.key);
        }
      }

      if (!isDuplicate) {
        final ts = task.createdAt.millisecondsSinceEpoch;
        if (seenTimestamps.contains(ts)) {
          isDuplicate = true;
        } else {
          seenTimestamps.add(ts);
        }
      }

      if (!isDuplicate) {
        unique.add(task);
      }
    }

    return unique;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addTask(
    String title, {
    String category = 'Personal',
    int priority = 1,
    DateTime? dueDate,
    int? dueTimeMinutes,
    String? motivation,
    String? reward,
    DateTime? deadline,
    int? recurrenceDay,
  }) async {
    try {
      final newTask = Task(
        title: title,
        type: _type,
        createdAt: DateTime.now(),
        category: category,
        priority: priority,
        dueDate: dueDate,
        dueTimeMinutes: dueTimeMinutes,
        motivation: motivation,
        reward: reward,
        deadline: deadline,
        recurrenceDay: recurrenceDay,
      );

      // Usar repository en lugar de database service
      await _taskRepo.save(newTask);

      // Sincronizar con cloud
      final user = _auth.currentUser;
      if (user != null) {
        await _syncService.syncTaskToCloud(newTask, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al agregar tarea',
        userMessage: 'No se pudo agregar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      // Usar repository
      await _taskRepo.save(task);

      // Sincronizar
      final user = _auth.currentUser;
      if (user != null) {
        await _syncService.syncTaskToCloud(task, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al actualizar tarea',
        userMessage: 'No se pudo actualizar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> toggleTask(Task task) async {
    try {
      // Usar método del repository
      await _taskRepo.toggleCompleted(task);

      final user = _auth.currentUser;
      if (user != null) {
        await _syncService.syncTaskToCloud(task, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al cambiar estado de tarea',
        userMessage: 'No se pudo actualizar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      // Soft delete usando mixin
      await _taskRepo.softDelete(task);

      // Sincronizar eliminación
      final user = _auth.currentUser;
      if (user != null) {
        await _syncService.syncTaskToCloud(task, user.uid);
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar tarea',
        userMessage: 'No se pudo eliminar la tarea',
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

/// Provider for filtered tasks based on search query
final filteredTasksProvider = Provider.family<List<Task>, String>((ref, type) {
  final tasks = ref.watch(tasksProvider(type));
  final searchQuery = ref.watch(taskSearchQueryProvider).toLowerCase().trim();

  if (searchQuery.isEmpty) {
    return tasks;
  }

  return tasks.where((task) {
    final titleMatch = task.title.toLowerCase().contains(searchQuery);
    final categoryMatch = task.category.toLowerCase().contains(searchQuery);
    final motivationMatch =
        task.motivation?.toLowerCase().contains(searchQuery) ?? false;
    final rewardMatch =
        task.reward?.toLowerCase().contains(searchQuery) ?? false;

    return titleMatch || categoryMatch || motivationMatch || rewardMatch;
  }).toList();
});
```

---

## 4. Próximos Pasos

### 4.1 Checklist de Implementación

#### Semana 1: Preparación
- [ ] Crear branch `refactor/architecture-improvements`
- [ ] Crear `lib/repositories/` directory
- [ ] Crear `lib/models/mixins/` directory
- [ ] Escribir tests para comportamiento actual de DatabaseService
- [ ] Documentar API actual

#### Semana 2: Interfaces y Mixins
- [ ] Implementar `lib/repositories/interfaces.dart`
- [ ] Implementar `lib/models/mixins/hive_model_mixin.dart`
- [ ] Aplicar mixins a Task
- [ ] Aplicar mixins a Note
- [ ] Tests unitarios para mixins

#### Semana 3: TaskRepository
- [ ] Implementar `TaskRepository`
- [ ] Migrar lógica de Task desde DatabaseService
- [ ] Tests unitarios para TaskRepository
- [ ] Actualizar TaskProvider para usar repository
- [ ] Verificar que todo funciona igual

#### Semana 4: NoteRepository y SyncService
- [ ] Implementar `NoteRepository`
- [ ] Implementar `SyncService`
- [ ] Migrar lógica de sincronización
- [ ] Tests unitarios
- [ ] Actualizar providers

#### Semana 5: Limpieza y Testing
- [ ] Eliminar código legacy de DatabaseService
- [ ] Simplificar DatabaseService (solo init y commons)
- [ ] Tests de integración completos
- [ ] Verificar métricas de rendimiento
- [ ] Code review

#### Semana 6: Documentación y Deploy
- [ ] Actualizar CLAUDE.md
- [ ] Generar diagramas de arquitectura
- [ ] PR y code review
- [ ] Merge a main
- [ ] Deploy y monitoreo

### 4.2 Riesgos y Mitigación

| Riesgo | Mitigación |
|--------|------------|
| Romper funcionalidad | Tests de regresión completos |
| Problemas de rendimiento | Benchmark antes/después |
| Bugs en producción | Feature flags, rollout gradual |
| Pérdida de datos | Backups automáticos, tests exhaustivos |

---

## 5. Métricas de Éxito

### Antes de la Refactorización
- DatabaseService: 2,663 líneas
- Complejidad ciclomática: ~15
- Testabilidad: Media (acoplamiento concreto)
- Mantenibilidad: Baja (demasiadas responsabilidades)

### Después de la Refactorización (Objetivo)
- DatabaseService: <500 líneas (solo inicialización)
- TaskRepository: ~300 líneas
- NoteRepository: ~300 líneas
- SyncService: ~400 líneas
- Complejidad ciclomática: <10 por archivo
- Testabilidad: Alta (interfaces, mocks fáciles)
- Mantenibilidad: Alta (responsabilidades claras)
- Cobertura de tests: >80%

---

## 6. Comandos Útiles

```bash
# Ejecutar tests
flutter test

# Ver cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Análisis estático
flutter analyze

# Formateo automático
dart format lib/

# Linting estricto
flutter analyze --no-pub

# Generar adapters de Hive después de cambios
dart run build_runner build --delete-conflicting-outputs
```

---

**Fin del Documento de Correcciones**

Este documento proporciona código concreto y pasos específicos para implementar las mejoras sugeridas en el reporte de arquitectura.
