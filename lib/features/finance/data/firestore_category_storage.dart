import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_category.dart';
import '../../../services/contracts/i_cloud_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

class FirestoreCategoryStorage
    implements ICloudStorageWithTimeout<FinanceCategory> {
  static const String collectionName = 'finance_categories';
  final ErrorHandler _errorHandler;

  FirestoreCategoryStorage(this._errorHandler);

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
  Future<CloudOperationResult<FinanceCategory>> create(
    FinanceCategory item,
    String userId,
  ) async {
    return createWithTimeout(item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<FinanceCategory>> createWithTimeout(
    FinanceCategory item,
    String userId,
    Duration timeout,
  ) async {
    try {
      final docRef = _collection(userId).doc(item.id);
      await docRef.set(item.toFirestore()).timeout(timeout);
      return CloudOperationResult.success(data: item, documentId: docRef.id);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<void>> update(
    String documentId,
    FinanceCategory item,
    String userId,
  ) async {
    return updateWithTimeout(documentId, item, userId, defaultTimeout);
  }

  @override
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    FinanceCategory item,
    String userId,
    Duration timeout,
  ) async {
    try {
      await _collection(
        userId,
      ).doc(documentId).update(item.toFirestore()).timeout(timeout);
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
  Future<CloudOperationResult<FinanceCategory>> get(
    String documentId,
    String userId,
  ) async {
    try {
      final doc = await _collection(userId).doc(documentId).get();
      if (!doc.exists) return CloudOperationResult.failure('Not found');
      return CloudOperationResult.success(
        data: FinanceCategory.fromFirestore(doc.id, doc.data()!),
        documentId: doc.id,
      );
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<FinanceCategory>>> getAll(
    String userId,
  ) async {
    try {
      final query = await _collection(userId).get();
      final items = query.docs
          .map((doc) => FinanceCategory.fromFirestore(doc.id, doc.data()))
          .toList();
      return CloudOperationResult.success(data: items);
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Future<CloudOperationResult<List<FinanceCategory>>> getModifiedSince(
    String userId,
    DateTime since,
  ) async {
    // Current models don't have a reliable server-side timestamp for categories yet
    // but we can filter by client-side if needed. For categories, getAll is usually fine.
    return getAll(userId);
  }

  @override
  Future<CloudOperationResult<void>> batchWrite(
    List<FinanceCategory> items,
    String userId,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in items) {
        batch.set(_collection(userId).doc(item.id), item.toFirestore());
      }
      await batch.commit();
      return CloudOperationResult.success();
    } catch (e, stack) {
      _errorHandler.handle(e, type: ErrorType.network, stackTrace: stack);
      return CloudOperationResult.failure(e.toString());
    }
  }

  @override
  Stream<List<FinanceCategory>> watchAll(String userId) {
    return _collection(userId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => FinanceCategory.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Stream<List<FinanceCategory>> watchModifiedSince(
    String userId,
    DateTime since,
  ) {
    return watchAll(userId);
  }
}
