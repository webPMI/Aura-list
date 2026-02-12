/// Firestore implementation of cloud task storage.
///
/// Provides cloud storage for tasks using Firebase Firestore,
/// with support for batch operations, timeout handling, and real-time listeners.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../models/task_model.dart';
import '../../contracts/i_cloud_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Firestore-based cloud storage for tasks
class FirestoreTaskStorage implements ICloudStorageWithTimeout<Task> {
  static const String collectionName = 'tasks';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = false;

  @override
  final Duration defaultTimeout = const Duration(seconds: 10);

  FirestoreTaskStorage(this._errorHandler) {
    _checkFirebaseAvailability();
  }

  void _checkFirebaseAvailability() {
    try {
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      if (_firebaseAvailable) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      _firebaseAvailable = false;
      _logger.warning(
        'FirestoreTaskStorage',
        'Firebase not available',
        metadata: {'error': e.toString()},
      );
    }
  }

  @override
  bool get isAvailable {
    if (!_firebaseAvailable) {
      _checkFirebaseAvailability();
    }
    return _firebaseAvailable && _firestore != null;
  }

  /// Get the user's task collection reference
  CollectionReference<Map<String, dynamic>> _tasksCollection(String userId) {
    return _firestore!.collection('users').doc(userId).collection(collectionName);
  }

  @override
  Future<CloudOperationResult<Task>> create(Task task, String userId) async {
    return createWithTimeout(task, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<Task>> createWithTimeout(
    Task task,
    String userId,
    Duration timeout,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    try {
      final docRef = _tasksCollection(userId).doc();

      await docRef.set(task.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Create task timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Created task: ${docRef.id}',
      );

      return CloudOperationResult.success(
        data: task,
        documentId: docRef.id,
      );
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error creating task in Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } on TimeoutException catch (e) {
      return CloudOperationResult.failure(e.message ?? 'Timeout');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error creating task',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    Task task,
    String userId,
  ) async {
    return updateWithTimeout(documentId, task, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    Task task,
    String userId,
    Duration timeout,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty || documentId.isEmpty) {
      return CloudOperationResult.failure('User ID or Document ID is empty');
    }

    try {
      await _tasksCollection(userId).doc(documentId).update(task.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Update task timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Updated task: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error updating task in Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } on TimeoutException catch (e) {
      return CloudOperationResult.failure(e.message ?? 'Timeout');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error updating task',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> delete(String documentId, String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty || documentId.isEmpty) {
      return CloudOperationResult.failure('User ID or Document ID is empty');
    }

    try {
      await _tasksCollection(userId).doc(documentId).delete().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Delete task timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Deleted task: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error deleting task in Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error deleting task',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<Task>> get(String documentId, String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty || documentId.isEmpty) {
      return CloudOperationResult.failure('User ID or Document ID is empty');
    }

    try {
      final doc = await _tasksCollection(userId).doc(documentId).get().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Get task timeout'),
          );

      if (!doc.exists || doc.data() == null) {
        return CloudOperationResult.failure('Task not found');
      }

      final task = Task.fromFirestore(doc.id, doc.data()!);
      return CloudOperationResult.success(data: task, documentId: doc.id);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting task from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting task',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Task>>> getAll(String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    try {
      final snapshot = await _tasksCollection(userId).get().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get all tasks timeout'),
          );

      final tasks = snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Retrieved ${tasks.length} tasks',
      );

      return CloudOperationResult.success(data: tasks);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting all tasks from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting all tasks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Task>>> getModifiedSince(
    String userId,
    DateTime since,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    try {
      final snapshot = await _tasksCollection(userId)
          .where('lastUpdatedAt', isGreaterThan: since.toIso8601String())
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get modified tasks timeout'),
          );

      final tasks = snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Retrieved ${tasks.length} modified tasks since $since',
      );

      return CloudOperationResult.success(data: tasks);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting modified tasks from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting modified tasks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<Task> tasks,
    String userId,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    if (tasks.isEmpty) {
      return CloudOperationResult.success();
    }

    try {
      final batch = _firestore!.batch();
      final tasksRef = _tasksCollection(userId);

      for (final task in tasks) {
        final docRef = task.firestoreId.isNotEmpty
            ? tasksRef.doc(task.firestoreId)
            : tasksRef.doc();

        if (task.firestoreId.isEmpty) {
          task.firestoreId = docRef.id;
        }

        batch.set(docRef, task.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Batch write timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreTaskStorage] Batch wrote ${tasks.length} tasks',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error batch writing tasks to Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error batch writing tasks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<Task>> watchAll(String userId) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _tasksCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching tasks',
        stackTrace: stackTrace,
      );
      return <Task>[];
    });
  }

  @override
  Stream<List<Task>> watchModifiedSince(String userId, DateTime since) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _tasksCollection(userId)
        .where('lastUpdatedAt', isGreaterThan: since.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching modified tasks',
        stackTrace: stackTrace,
      );
      return <Task>[];
    });
  }

  /// Create or update a task (upsert)
  Future<CloudOperationResult<String>> upsert(Task task, String userId) async {
    if (task.firestoreId.isEmpty) {
      final result = await create(task, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: result.documentId,
          documentId: result.documentId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    } else {
      final result = await update(task.firestoreId, task, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: task.firestoreId,
          documentId: task.firestoreId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    }
  }

  /// Refresh Firebase availability (call when app resumes)
  void refreshAvailability() {
    _checkFirebaseAvailability();
  }
}
