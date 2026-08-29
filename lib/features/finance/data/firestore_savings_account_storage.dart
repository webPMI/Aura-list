import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_account.dart';
import '../../../services/contracts/i_cloud_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/encryption/encryption_service.dart';

class FirestoreSavingsAccountStorage
    implements ICloudStorageWithTimeout<SavingsAccount> {
  static const String collectionName = 'finance_savings_accounts';
  final ErrorHandler _errorHandler;
  final EncryptionService _encryption = EncryptionService();

  FirestoreSavingsAccountStorage(this._errorHandler);

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
  Future<CloudOperationResult<SavingsAccount>> create(
    SavingsAccount item,
    String userId,
  ) async {
    return createWithTimeout(item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<SavingsAccount>> createWithTimeout(
    SavingsAccount item,
    String userId,
    Duration timeout,
  ) async {
    try {
      final docRef = _collection(userId).doc(item.id);
      await docRef
          .set(
            _encryption.encryptMap(item.toFirestore()),
            SetOptions(merge: true),
          )
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
    SavingsAccount item,
    String userId,
  ) async {
    return updateWithTimeout(documentId, item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    SavingsAccount item,
    String userId,
    Duration timeout,
  ) async {
    try {
      await _collection(userId)
          .doc(documentId)
          .set(
            _encryption.encryptMap(item.toFirestore()),
            SetOptions(merge: true),
          )
          .timeout(timeout);
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
  Future<CloudOperationResult<SavingsAccount>> get(
    String documentId,
    String userId,
  ) async {
    try {
      final doc = await _collection(userId).doc(documentId).get();
      if (!doc.exists) return CloudOperationResult.failure('Not found');
      return CloudOperationResult.success(
        data: SavingsAccount.fromFirestore(
          doc.id,
          _encryption.decryptMap(doc.data()!),
        ),
        documentId: doc.id,
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<SavingsAccount>>> getAll(
    String userId,
  ) async {
    try {
      final query = await _collection(userId).get();
      final items = query.docs
          .map(
            (doc) => SavingsAccount.fromFirestore(
              doc.id,
              _encryption.decryptMap(doc.data()),
            ),
          )
          .where((a) => !a.deleted)
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<SavingsAccount>>> getModifiedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final query = await _collection(userId)
          .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
          .get();
      final items = query.docs
          .map(
            (doc) => SavingsAccount.fromFirestore(
              doc.id,
              _encryption.decryptMap(doc.data()),
            ),
          )
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<SavingsAccount> items,
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
  Stream<List<SavingsAccount>> watchAll(String userId) {
    return _collection(userId).snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => SavingsAccount.fromFirestore(
              doc.id,
              _encryption.decryptMap(doc.data()),
            ),
          )
          .where((a) => !a.deleted)
          .toList(),
    );
  }

  @override
  Stream<List<SavingsAccount>> watchModifiedSince(
    String userId,
    DateTime since,
  ) {
    return _collection(userId)
        .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SavingsAccount.fromFirestore(
                  doc.id,
                  _encryption.decryptMap(doc.data()),
                ),
              )
              .toList(),
        );
  }
}
