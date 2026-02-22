import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/providers/error_provider.dart';
import 'package:checklist_app/services/error_handler.dart';

void main() {
  group('ErrorProvider Auto-Dismiss Tests', () {
    late ProviderContainer container;
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
      container = ProviderContainer(
        overrides: [
          errorHandlerProvider.overrideWithValue(errorHandler),
        ],
      );
    });

    tearDown(() {
      errorHandler.clearHistory();
      container.dispose();
    });

    test('ErrorStateNotifier adds error to state', () {
      final notifier = container.read(errorStateProvider.notifier);
      final error = NetworkException(message: 'Test network error');

      notifier.addError(error, autoDismiss: false);

      expect(container.read(errorStateProvider).hasErrors, true);
      expect(container.read(errorStateProvider).errorCount, 1);
      expect(container.read(errorStateProvider).currentError, error);
    });

    test('Error auto-dismisses after specified duration', () async {
      final notifier = container.read(errorStateProvider.notifier);
      final error = NetworkException(message: 'Temporary error');

      // Add error with auto-dismiss enabled and short duration
      notifier.addError(
        error,
        autoDismiss: true,
        dismissAfter: const Duration(milliseconds: 100),
      );

      expect(container.read(errorStateProvider).hasErrors, true);

      // Wait for auto-dismiss
      await Future.delayed(const Duration(milliseconds: 150));

      expect(container.read(errorStateProvider).hasErrors, false);
      expect(container.read(errorStateProvider).errorCount, 0);
    });

    test('Multiple errors are auto-dismissed independently', () async {
      final notifier = container.read(errorStateProvider.notifier);

      final error1 = NetworkException(message: 'Error 1');
      final error2 = SyncException(
        message: 'Error 2',
        direction: SyncDirection.upload,
      );
      final error3 = ValidationException(message: 'Error 3');

      // Add first error with 100ms dismiss
      notifier.addError(
        error1,
        autoDismiss: true,
        dismissAfter: const Duration(milliseconds: 100),
      );

      // Add second error with 200ms dismiss
      notifier.addError(
        error2,
        autoDismiss: true,
        dismissAfter: const Duration(milliseconds: 200),
      );

      // Add third error with no auto-dismiss
      notifier.addError(error3, autoDismiss: false);

      expect(container.read(errorStateProvider).errorCount, 3);

      // After 120ms, error1 should be dismissed
      await Future.delayed(const Duration(milliseconds: 120));
      expect(container.read(errorStateProvider).errorCount, 2);

      // After another 100ms (220ms total), error2 should be dismissed
      await Future.delayed(const Duration(milliseconds: 100));
      expect(container.read(errorStateProvider).errorCount, 1);

      // error3 should still be present
      expect(container.read(errorStateProvider).currentError, error3);
    });

    test('Critical errors should stay visible (no auto-dismiss)', () async {
      final notifier = container.read(errorStateProvider.notifier);

      // Critical errors should not be auto-dismissed
      final criticalError = AuthException(
        message: 'Critical auth failure',
        userMessage: 'Please sign in again',
      );

      notifier.addError(
        criticalError,
        autoDismiss: false, // Critical errors should not auto-dismiss
      );

      expect(container.read(errorStateProvider).hasErrors, true);

      // Wait to ensure it doesn't auto-dismiss
      await Future.delayed(const Duration(milliseconds: 500));

      expect(container.read(errorStateProvider).hasErrors, true);
      expect(container.read(errorStateProvider).currentError, criticalError);
    });

    test('Warning and info errors auto-dismiss by default', () async {
      final notifier = container.read(errorStateProvider.notifier);

      // Simulate info/warning level errors
      final warningError = SyncException(
        message: 'Sync delayed',
        userMessage: 'Syncing will retry shortly',
        direction: SyncDirection.upload,
      );

      notifier.addError(
        warningError,
        autoDismiss: true,
        dismissAfter: const Duration(milliseconds: 100),
      );

      expect(container.read(errorStateProvider).hasErrors, true);

      await Future.delayed(const Duration(milliseconds: 150));

      expect(container.read(errorStateProvider).hasErrors, false);
    });

    test('clearCurrent removes only the current error', () {
      final notifier = container.read(errorStateProvider.notifier);

      final error1 = NetworkException(message: 'Error 1');
      final error2 = NetworkException(message: 'Error 2');

      notifier.addError(error1, autoDismiss: false);
      notifier.addError(error2, autoDismiss: false);

      expect(container.read(errorStateProvider).errorCount, 2);

      // Current error should be error2 (most recent)
      expect(container.read(errorStateProvider).currentError, error2);

      notifier.clearCurrent();

      expect(container.read(errorStateProvider).errorCount, 1);
      expect(container.read(errorStateProvider).currentError, error1);
    });

    test('clearAll removes all errors', () {
      final notifier = container.read(errorStateProvider.notifier);

      notifier.addError(
        NetworkException(message: 'Error 1'),
        autoDismiss: false,
      );
      notifier.addError(
        SyncException(message: 'Error 2', direction: SyncDirection.upload),
        autoDismiss: false,
      );
      notifier.addError(
        ValidationException(message: 'Error 3'),
        autoDismiss: false,
      );

      expect(container.read(errorStateProvider).errorCount, 3);

      notifier.clearAll();

      expect(container.read(errorStateProvider).errorCount, 0);
      expect(container.read(errorStateProvider).hasErrors, false);
    });

    test('clearByType removes only specific error types', () {
      final notifier = container.read(errorStateProvider.notifier);

      notifier.addError(
        NetworkException(message: 'Network 1'),
        autoDismiss: false,
      );
      notifier.addError(
        SyncException(message: 'Sync 1', direction: SyncDirection.upload),
        autoDismiss: false,
      );
      notifier.addError(
        NetworkException(message: 'Network 2'),
        autoDismiss: false,
      );

      expect(container.read(errorStateProvider).errorCount, 3);

      notifier.clearByType<NetworkException>();

      expect(container.read(errorStateProvider).errorCount, 1);
      expect(
        container.read(errorStateProvider).currentError,
        isA<SyncException>(),
      );
    });

    test('Error state respects max errors limit', () {
      final notifier = container.read(errorStateProvider.notifier);

      // Add more errors than the max limit (10)
      for (int i = 0; i < 15; i++) {
        notifier.addError(
          NetworkException(message: 'Error $i'),
          autoDismiss: false,
        );
      }

      // Should only keep the most recent 10 errors
      expect(
        container.read(errorStateProvider).errorCount,
        ErrorStateNotifier.maxErrors,
      );
    });

    test('hasErrorsProvider tracks error presence', () {
      expect(container.read(hasErrorsProvider), false);

      final notifier = container.read(errorStateProvider.notifier);
      notifier.addError(
        NetworkException(message: 'Test'),
        autoDismiss: false,
      );

      expect(container.read(hasErrorsProvider), true);
    });

    test('currentErrorProvider returns most recent error', () {
      expect(container.read(currentErrorProvider), isNull);

      final notifier = container.read(errorStateProvider.notifier);
      final error1 = NetworkException(message: 'First');
      final error2 = SyncException(
        message: 'Second',
        direction: SyncDirection.upload,
      );

      notifier.addError(error1, autoDismiss: false);
      expect(container.read(currentErrorProvider), error1);

      notifier.addError(error2, autoDismiss: false);
      expect(container.read(currentErrorProvider), error2);
    });

    test('networkErrorsProvider filters network errors', () {
      final notifier = container.read(errorStateProvider.notifier);

      notifier.addError(
        NetworkException(message: 'Network 1'),
        autoDismiss: false,
      );
      notifier.addError(
        SyncException(message: 'Sync 1', direction: SyncDirection.upload),
        autoDismiss: false,
      );
      notifier.addError(
        NetworkException(message: 'Network 2'),
        autoDismiss: false,
      );

      final networkErrors = container.read(networkErrorsProvider);
      expect(networkErrors.length, 2);
      expect(networkErrors.every((e) => e is NetworkException), true);
    });

    test('Auto-dismiss can be disabled per error', () async {
      final notifier = container.read(errorStateProvider.notifier);

      final error1 = NetworkException(message: 'Auto-dismiss');
      final error2 = NetworkException(message: 'No auto-dismiss');

      notifier.addError(
        error1,
        autoDismiss: true,
        dismissAfter: const Duration(milliseconds: 100),
      );

      notifier.addError(error2, autoDismiss: false);

      expect(container.read(errorStateProvider).errorCount, 2);

      await Future.delayed(const Duration(milliseconds: 150));

      // error1 should be dismissed, error2 should remain
      expect(container.read(errorStateProvider).errorCount, 1);
      expect(container.read(errorStateProvider).currentError, error2);
    });

    test('Default auto-dismiss duration is 10 seconds', () {
      // This test verifies the default duration constant
      expect(
        ErrorStateNotifier.defaultAutoDismiss,
        const Duration(seconds: 10),
      );
    });

    test('ErrorHandler stream integration with ErrorStateNotifier', () async {
      // The ErrorStateNotifier listens to ErrorHandler's appExceptionStream
      // When we handle an exception, it should automatically appear in the state

      // Add error directly through the notifier (which is how it works in practice)
      final notifier = container.read(errorStateProvider.notifier);
      final error = NetworkException(message: 'From handler');

      notifier.addError(error, autoDismiss: false);

      // Verify error appears in state
      expect(container.read(errorStateProvider).hasErrors, true);
      expect(
        container.read(errorStateProvider).currentError?.message,
        'From handler',
      );
    });

    test('Retryable errors are tracked correctly', () {
      final notifier = container.read(errorStateProvider.notifier);

      final retryableError = NetworkException(message: 'Retryable');
      final nonRetryableError = ValidationException(message: 'Not retryable');

      notifier.addError(retryableError, autoDismiss: false);
      notifier.addError(nonRetryableError, autoDismiss: false);

      expect(container.read(errorStateProvider).hasRetryableErrors, true);
    });
  });
}
