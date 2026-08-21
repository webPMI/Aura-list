import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';
import '../../../services/contracts/i_cloud_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/encryption/encryption_service.dart';

class FirestoreTransactionStorage
    implements ICloudStorageWithTimeout<Transaction> {
  static const String collectionName = 'finance_transactions';
  final ErrorHandler _errorHandler;
  final EncryptionService _encryption = EncryptionService();

  FirestoreTransactionStorage(this._errorHandler);

  @override
  Duration get defaultTimeout => const Duration(seconds: 10);

  @override
  bool get isAvailable => true;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName);
  }

  @override
  Future<CloudOperationResult<Transaction>> create(
    Transaction item,
    String userId,
  ) async {
    return createWithTimeout(item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<Transaction>> createWithTimeout(
    Transaction item,
    String userId,
    Duration timeout,
  ) async {
    try {
      final docRef = _collection(userId).doc(item.id);
      await docRef
          .set(_encryption.encryptMap(item.toFirestore()), SetOptions(merge: true))
          .timeout(timeout);
      return CloudOperationResult.success(data: item, documentId: docRef.id);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    Transaction item,
    String userId,
  ) async {
    return updateWithTimeout(documentId, item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    Transaction item,
    String userId,
    Duration timeout,
  ) async {
    try {
      await _collection(
        userId,
      ).doc(documentId).set(_encryption.encryptMap(item.toFirestore()), SetOptions(merge: true)).timeout(timeout);
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> delete(
    String documentId,
    String userId,
  ) async {
    try {
      await _collection(userId).doc(documentId).delete();
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<Transaction>> get(
    String documentId,
    String userId,
  ) async {
    try {
      final doc = await _collection(userId).doc(documentId).get();
      if (!doc.exists) return CloudOperationResult.failure('Not found');
      return CloudOperationResult.success(
        data: Transaction.fromFirestore(doc.id, _encryption.decryptMap(doc.data()!)),
        documentId: doc.id,
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Transaction>>> getAll(String userId) async {
    try {
      final query = await _collection(
        userId,
      ).get();
      final items = query.docs
          .map((doc) => Transaction.fromFirestore(doc.id, _encryption.decryptMap(doc.data())))
          .where((t) => !t.deleted)
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<Transaction>>> getModifiedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final query = await _collection(userId)
          .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
          .get();
      final items = query.docs
          .map((doc) => Transaction.fromFirestore(doc.id, _encryption.decryptMap(doc.data())))
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<Transaction> items,
    String userId,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in items) {
        batch.set(
          _collection(userId).doc(item.id),
          _encryption.encryptMap(item.toFirestore()),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<Transaction>> watchAll(String userId) {
    return _collection(userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Transaction.fromFirestore(doc.id, _encryption.decryptMap(doc.data())))
              .where((t) => !t.deleted)
              .toList(),
        );
  }

  @override
  Stream<List<Transaction>> watchModifiedSince(String userId, DateTime since) {
    return _collection(userId)
        .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Transaction.fromFirestore(doc.id, _encryption.decryptMap(doc.data())))
              .toList(),
        );
  }
}
