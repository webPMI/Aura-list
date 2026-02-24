import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_alert.dart';
import '../../../services/contracts/i_cloud_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class FirestoreFinanceAlertStorage
    implements ICloudStorageWithTimeout<FinanceAlert> {
  static const String collectionName = 'finance_alerts';
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();

  FirestoreFinanceAlertStorage(this._errorHandler);

  @override
  Duration get defaultTimeout => const Duration(seconds: 10);

  @override
  bool get isAvailable => true; // Firebase is initialized in main

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName);
  }

  @override
  Future<CloudOperationResult<FinanceAlert>> create(
    FinanceAlert item,
    String userId,
  ) async {
    return createWithTimeout(item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<FinanceAlert>> createWithTimeout(
    FinanceAlert item,
    String userId,
    Duration timeout,
  ) async {
    try {
      final docRef = _collection(userId).doc(item.id);
      await docRef.set(item.toFirestore()).timeout(timeout);
      _logger.debug(
        'Finance',
        '[FirestoreFinanceAlertStorage] Created: ${item.id}',
      );
      return CloudOperationResult.success(data: item, documentId: docRef.id);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    FinanceAlert item,
    String userId,
  ) async {
    return updateWithTimeout(documentId, item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    FinanceAlert item,
    String userId,
    Duration timeout,
  ) async {
    try {
      await _collection(userId)
          .doc(documentId)
          .update(item.toFirestore())
          .timeout(timeout);
      _logger.debug(
        'Finance',
        '[FirestoreFinanceAlertStorage] Updated: $documentId',
      );
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
      _logger.debug(
        'Finance',
        '[FirestoreFinanceAlertStorage] Deleted: $documentId',
      );
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<FinanceAlert>> get(
    String documentId,
    String userId,
  ) async {
    try {
      final doc = await _collection(userId).doc(documentId).get();
      if (!doc.exists) return CloudOperationResult.failure('Not found');
      return CloudOperationResult.success(
        data: FinanceAlert.fromFirestore(doc.id, doc.data()!),
        documentId: doc.id,
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<FinanceAlert>>> getAll(String userId) async {
    try {
      final query =
          await _collection(userId).where('deleted', isEqualTo: false).get();
      final items = query.docs
          .map((doc) => FinanceAlert.fromFirestore(doc.id, doc.data()))
          .toList();
      _logger.debug(
        'Finance',
        '[FirestoreFinanceAlertStorage] Fetched ${items.length} items',
      );
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<FinanceAlert>>> getModifiedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final query = await _collection(userId)
          .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
          .get();
      final items = query.docs
          .map((doc) => FinanceAlert.fromFirestore(doc.id, doc.data()))
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<FinanceAlert> items,
    String userId,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in items) {
        batch.set(_collection(userId).doc(item.id), item.toFirestore());
      }
      await batch.commit();
      _logger.debug(
        'Finance',
        '[FirestoreFinanceAlertStorage] Batch write: ${items.length} items',
      );
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<FinanceAlert>> watchAll(String userId) {
    return _collection(userId)
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinanceAlert.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<FinanceAlert>> watchModifiedSince(String userId, DateTime since) {
    return _collection(userId)
        .where('lastUpdatedAt', isGreaterThan: since.millisecondsSinceEpoch)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinanceAlert.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }
}
