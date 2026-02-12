/// Interface for cloud storage operations.
///
/// Provides a consistent API for storing and retrieving data from
/// Firebase Firestore or any other cloud storage solution.
library;

/// Result of a cloud operation
class CloudOperationResult<T> {
  final bool success;
  final T? data;
  final String? documentId;
  final String? error;

  const CloudOperationResult({
    required this.success,
    this.data,
    this.documentId,
    this.error,
  });

  factory CloudOperationResult.success({T? data, String? documentId}) {
    return CloudOperationResult(
      success: true,
      data: data,
      documentId: documentId,
    );
  }

  factory CloudOperationResult.failure(String error) {
    return CloudOperationResult(
      success: false,
      error: error,
    );
  }
}

/// Generic interface for cloud storage operations
abstract class ICloudStorage<T> {
  /// Check if cloud storage is available
  bool get isAvailable;

  /// Create a new document and return its ID
  Future<CloudOperationResult<T>> create(T item, String userId);

  /// Update an existing document
  Future<CloudOperationResult<void>> update(
    String documentId,
    T item,
    String userId,
  );

  /// Delete a document (hard delete)
  Future<CloudOperationResult<void>> delete(String documentId, String userId);

  /// Get a single document by ID
  Future<CloudOperationResult<T>> get(String documentId, String userId);

  /// Get all documents for a user
  Future<CloudOperationResult<List<T>>> getAll(String userId);

  /// Get documents modified since a timestamp
  Future<CloudOperationResult<List<T>>> getModifiedSince(
    String userId,
    DateTime since,
  );

  /// Batch create/update multiple documents
  Future<CloudOperationResult<void>> batchWrite(
    List<T> items,
    String userId,
  );

  /// Listen to real-time changes
  Stream<List<T>> watchAll(String userId);

  /// Listen to changes since a timestamp
  Stream<List<T>> watchModifiedSince(String userId, DateTime since);
}

/// Interface for cloud storage with timeout support
abstract class ICloudStorageWithTimeout<T> extends ICloudStorage<T> {
  /// Default timeout for operations
  Duration get defaultTimeout;

  /// Create with custom timeout
  Future<CloudOperationResult<T>> createWithTimeout(
    T item,
    String userId,
    Duration timeout,
  );

  /// Update with custom timeout
  Future<CloudOperationResult<void>> updateWithTimeout(
    String documentId,
    T item,
    String userId,
    Duration timeout,
  );
}
