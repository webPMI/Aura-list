import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
      errorHandler.clearHistory();
    });

    test('ErrorHandler is a singleton', () {
      expect(ErrorHandler(), same(ErrorHandler()));
    });

    test('handle creates AppError and adds to history', () {
      final error = Exception('Original');
      errorHandler.handle(
        error,
        type: ErrorType.database,
        message: 'Custom msg',
      );

      expect(errorHandler.errorHistory.length, 1);
      expect(errorHandler.lastError?.type, ErrorType.database);
      expect(errorHandler.lastError?.message, 'Custom msg');
    });

    test('handleException handles AppExceptions correctly', () {
      final ex = NetworkException(message: 'No internet');
      errorHandler.handleException(ex);

      expect(errorHandler.lastError?.type, ErrorType.network);
      expect(errorHandler.lastError?.displayMessage, contains('Sin conexion'));
    });

    test('Error detection from strings works', () {
      errorHandler.handle('Auth failed');
      expect(errorHandler.lastError?.type, ErrorType.auth);

      errorHandler.handle('Database error');
      expect(errorHandler.lastError?.type, ErrorType.database);
    });

    test('shouldRetry returns correct values', () {
      expect(errorHandler.shouldRetry(NetworkException(message: 'X')), true);
      expect(
        errorHandler.shouldRetry(ValidationException(message: 'X')),
        false,
      );
    });

    test('Error stream emits errors', () async {
      final futureError = errorHandler.errorStream.first;
      errorHandler.handle('Test error');

      final emitted = await futureError;
      expect(emitted.message, 'Test error');
    });

    test('getErrorCountsByType returns correct statistics', () {
      errorHandler.handle('Auth error 1', type: ErrorType.auth);
      errorHandler.handle('Auth error 2', type: ErrorType.auth);
      errorHandler.handle('Net error 1', type: ErrorType.network);

      final counts = errorHandler.getErrorCountsByType();
      expect(counts[ErrorType.auth], 2);
      expect(counts[ErrorType.network], 1);
      expect(counts[ErrorType.database], 0);
    });
  });
}
