/// Firestore implementation of cloud notebook storage.
///
/// Provides cloud storage for notebooks using Firebase Firestore,
/// with support for batch operations, timeout handling, and real-time listeners.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../models/notebook_model.dart';
import '../../contracts/i_cloud_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Firestore-based cloud storage for notebooks
class FirestoreNotebookStorage implements ICloudStorageWithTimeout<Notebook> {
  static const String collectionName = 'notebooks';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = false;

  @override
  final Duration defaultTimeout = const Duration(seconds: 10);

  FirestoreNotebookStorage(this._errorHandler) {
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
        'FirestoreNotebookStorage',
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

  CollectionReference<Map<String, dynamic>> _notebooksCollection(String userId) {
    return _firestore!.collection('users').doc(userId).collection(collectionName);
  }

  @override
  Future<CloudOperationResult<Notebook>> create(Notebook notebook, String userId) async {
    return createWithTimeout(notebook, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<Notebook>> createWithTimeout(
    Notebook notebook,
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
      final docRef = _notebooksCollection(userId).doc();

      await docRef.set(notebook.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Create notebook timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Created notebook: ${docRef.id}',
      );

      return CloudOperationResult.success(
        data: notebook,
        documentId: docRef.id,
      );
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error creating notebook in Firestore',
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
        message: 'Unexpected error creating notebook',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    Notebook notebook,
    String userId,
  ) async {
    return updateWithTimeout(documentId, notebook, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    Notebook notebook,
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
      await _notebooksCollection(userId).doc(documentId).update(notebook.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Update notebook timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Updated notebook: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error updating notebook in Firestore',
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
        message: 'Unexpected error updating notebook',
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
      await _notebooksCollection(userId).doc(documentId).delete().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Delete notebook timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Deleted notebook: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error deleting notebook in Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error deleting notebook',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<Notebook>> get(String documentId, String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty || documentId.isEmpty) {
      return CloudOperationResult.failure('User ID or Document ID is empty');
    }

    try {
      final doc = await _notebooksCollection(userId).doc(documentId).get().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Get notebook timeout'),
          );

      if (!doc.exists || doc.data() == null) {
        return CloudOperationResult.failure('Notebook not found');
      }

      final notebook = Notebook.fromFirestore(doc.id, doc.data()!);
      return CloudOperationResult.success(data: notebook, documentId: doc.id);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting notebook from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting notebook',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Notebook>>> getAll(String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    try {
      final snapshot = await _notebooksCollection(userId).get().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get all notebooks timeout'),
          );

      final notebooks = snapshot.docs.map((doc) {
        return Notebook.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Retrieved ${notebooks.length} notebooks',
      );

      return CloudOperationResult.success(data: notebooks);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting all notebooks from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting all notebooks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Notebook>>> getModifiedSince(
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
      final snapshot = await _notebooksCollection(userId)
          .where('updatedAt', isGreaterThan: since.toIso8601String())
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get modified notebooks timeout'),
          );

      final notebooks = snapshot.docs.map((doc) {
        return Notebook.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Retrieved ${notebooks.length} modified notebooks since $since',
      );

      return CloudOperationResult.success(data: notebooks);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting modified notebooks from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting modified notebooks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<Notebook> notebooks,
    String userId,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    if (notebooks.isEmpty) {
      return CloudOperationResult.success();
    }

    try {
      final batch = _firestore!.batch();
      final notebooksRef = _notebooksCollection(userId);

      for (final notebook in notebooks) {
        final docRef = notebook.firestoreId.isNotEmpty
            ? notebooksRef.doc(notebook.firestoreId)
            : notebooksRef.doc();

        if (notebook.firestoreId.isEmpty) {
          notebook.firestoreId = docRef.id;
        }

        batch.set(docRef, notebook.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Batch write timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNotebookStorage] Batch wrote ${notebooks.length} notebooks',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error batch writing notebooks to Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error batch writing notebooks',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<Notebook>> watchAll(String userId) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _notebooksCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Notebook.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching notebooks',
        stackTrace: stackTrace,
      );
      return <Notebook>[];
    });
  }

  @override
  Stream<List<Notebook>> watchModifiedSince(String userId, DateTime since) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _notebooksCollection(userId)
        .where('updatedAt', isGreaterThan: since.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Notebook.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching modified notebooks',
        stackTrace: stackTrace,
      );
      return <Notebook>[];
    });
  }

  /// Create or update a notebook (upsert)
  Future<CloudOperationResult<String>> upsert(Notebook notebook, String userId) async {
    if (notebook.firestoreId.isEmpty) {
      final result = await create(notebook, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: result.documentId,
          documentId: result.documentId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    } else {
      final result = await update(notebook.firestoreId, notebook, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: notebook.firestoreId,
          documentId: notebook.firestoreId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    }
  }

  void refreshAvailability() {
    _checkFirebaseAvailability();
  }
}
