/// Firestore implementation of cloud note storage.
///
/// Provides cloud storage for notes using Firebase Firestore,
/// with support for batch operations, timeout handling, and real-time listeners.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../models/note_model.dart';
import '../../contracts/i_cloud_storage.dart';
import '../../error_handler.dart';
import '../../logger_service.dart';

/// Firestore-based cloud storage for notes
class FirestoreNoteStorage implements ICloudStorageWithTimeout<Note> {
  static const String collectionName = 'notes';

  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = false;

  @override
  final Duration defaultTimeout = const Duration(seconds: 10);

  FirestoreNoteStorage(this._errorHandler) {
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
        'FirestoreNoteStorage',
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

  CollectionReference<Map<String, dynamic>> _notesCollection(String userId) {
    return _firestore!.collection('users').doc(userId).collection(collectionName);
  }

  @override
  Future<CloudOperationResult<Note>> create(Note note, String userId) async {
    return createWithTimeout(note, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<Note>> createWithTimeout(
    Note note,
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
      final docRef = _notesCollection(userId).doc();

      await docRef.set(note.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Create note timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Created note: ${docRef.id}',
      );

      return CloudOperationResult.success(
        data: note,
        documentId: docRef.id,
      );
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error creating note in Firestore',
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
        message: 'Unexpected error creating note',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    Note note,
    String userId,
  ) async {
    return updateWithTimeout(documentId, note, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    Note note,
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
      await _notesCollection(userId).doc(documentId).update(note.toFirestore()).timeout(
            timeout,
            onTimeout: () => throw TimeoutException('Update note timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Updated note: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error updating note in Firestore',
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
        message: 'Unexpected error updating note',
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
      await _notesCollection(userId).doc(documentId).delete().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Delete note timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Deleted note: $documentId',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error deleting note in Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error deleting note',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<Note>> get(String documentId, String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty || documentId.isEmpty) {
      return CloudOperationResult.failure('User ID or Document ID is empty');
    }

    try {
      final doc = await _notesCollection(userId).doc(documentId).get().timeout(
            defaultTimeout,
            onTimeout: () => throw TimeoutException('Get note timeout'),
          );

      if (!doc.exists || doc.data() == null) {
        return CloudOperationResult.failure('Note not found');
      }

      final note = Note.fromFirestore(doc.id, doc.data()!);
      return CloudOperationResult.success(data: note, documentId: doc.id);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting note from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting note',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Note>>> getAll(String userId) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    try {
      final snapshot = await _notesCollection(userId).get().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get all notes timeout'),
          );

      final notes = snapshot.docs.map((doc) {
        return Note.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Retrieved ${notes.length} notes',
      );

      return CloudOperationResult.success(data: notes);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting all notes from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting all notes',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Note>>> getModifiedSince(
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
      final snapshot = await _notesCollection(userId)
          .where('updatedAt', isGreaterThan: since.toIso8601String())
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Get modified notes timeout'),
          );

      final notes = snapshot.docs.map((doc) {
        return Note.fromFirestore(doc.id, doc.data());
      }).toList();

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Retrieved ${notes.length} modified notes since $since',
      );

      return CloudOperationResult.success(data: notes);
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error getting modified notes from Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error getting modified notes',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<Note> notes,
    String userId,
  ) async {
    if (!isAvailable) {
      return CloudOperationResult.failure('Firebase not available');
    }

    if (userId.isEmpty) {
      return CloudOperationResult.failure('User ID is empty');
    }

    if (notes.isEmpty) {
      return CloudOperationResult.success();
    }

    try {
      final batch = _firestore!.batch();
      final notesRef = _notesCollection(userId);

      for (final note in notes) {
        final docRef = note.firestoreId.isNotEmpty
            ? notesRef.doc(note.firestoreId)
            : notesRef.doc();

        if (note.firestoreId.isEmpty) {
          note.firestoreId = docRef.id;
        }

        batch.set(docRef, note.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Batch write timeout'),
          );

      _logger.debug(
        'Service',
        '[FirestoreNoteStorage] Batch wrote ${notes.length} notes',
      );

      return CloudOperationResult.success();
    } on FirebaseException catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error batch writing notes to Firestore',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.message ?? e.toString());
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Unexpected error batch writing notes',
        stackTrace: stack,
      );
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<Note>> watchAll(String userId) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _notesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching notes',
        stackTrace: stackTrace,
      );
      return <Note>[];
    });
  }

  @override
  Stream<List<Note>> watchModifiedSince(String userId, DateTime since) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value([]);
    }

    return _notesCollection(userId)
        .where('updatedAt', isGreaterThan: since.toIso8601String())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromFirestore(doc.id, doc.data());
      }).toList();
    }).handleError((error, stackTrace) {
      _errorHandler.handle(
        error,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error watching modified notes',
        stackTrace: stackTrace,
      );
      return <Note>[];
    });
  }

  /// Create or update a note (upsert)
  Future<CloudOperationResult<String>> upsert(Note note, String userId) async {
    if (note.firestoreId.isEmpty) {
      final result = await create(note, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: result.documentId,
          documentId: result.documentId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    } else {
      final result = await update(note.firestoreId, note, userId);
      if (result.success) {
        return CloudOperationResult.success(
          data: note.firestoreId,
          documentId: note.firestoreId,
        );
      }
      return CloudOperationResult.failure(result.error ?? 'Unknown error');
    }
  }

  void refreshAvailability() {
    _checkFirebaseAvailability();
  }
}
