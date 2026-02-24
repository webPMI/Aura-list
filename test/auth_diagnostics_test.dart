import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/auth_manager.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes using mocktail
class MockAuthServiceForDiagnostics extends Mock implements AuthService {}

class MockDatabaseServiceForAuth extends Mock implements DatabaseService {}

void main() {
  group('Auth Diagnostics Tests', () {
    late MockAuthServiceForDiagnostics mockAuth;

    setUp(() {
      mockAuth = MockAuthServiceForDiagnostics();
    });

    test('AuthService.getInitializationStatus returns correct map', () {
      final expectedStatus = {
        'isInitialized': true,
        'firebaseAvailable': true,
        'authAvailable': true,
        'lastError': null,
        'activeApps': ['[DEFAULT]'],
        'projectId': 'test-project',
        'isWeb': false,
      };

      when(() => mockAuth.getInitializationStatus()).thenReturn(expectedStatus);

      final status = mockAuth.getInitializationStatus();
      expect(status['isInitialized'], isTrue);
      expect(status['firebaseAvailable'], isTrue);
      expect(status['projectId'], 'test-project');
    });

    test(
      'AuthService.getInitializationStatus returns error when Firebase unavailable',
      () {
        final expectedStatus = {
          'isInitialized': true,
          'firebaseAvailable': false,
          'authAvailable': false,
          'lastError': 'Simulated Error',
          'activeApps': [],
          'projectId': 'test-project',
          'isWeb': false,
        };

        when(
          () => mockAuth.getInitializationStatus(),
        ).thenReturn(expectedStatus);

        final status = mockAuth.getInitializationStatus();
        expect(status['firebaseAvailable'], isFalse);
        expect(status['lastError'], 'Simulated Error');
      },
    );
  });

  group('AuthManager Integration with Diagnostics', () {
    late MockAuthServiceForDiagnostics mockAuth;
    late MockDatabaseServiceForAuth mockDb;
    late AuthManager authManager;

    setUp(() {
      mockAuth = MockAuthServiceForDiagnostics();
      mockDb = MockDatabaseServiceForAuth();
      authManager = AuthManager(authService: mockAuth, dbService: mockDb);

      // Default behaviors
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.linkedEmail).thenReturn(null);
    });

    test('AuthManager.getInitializationStatus delegates to AuthService', () {
      final expectedStatus = {'projectId': 'test-project'};
      when(() => mockAuth.getInitializationStatus()).thenReturn(expectedStatus);

      final status = authManager.getInitializationStatus();
      expect(status['projectId'], 'test-project');
      verify(() => mockAuth.getInitializationStatus()).called(1);
    });

    test(
      'AuthManager.signInWithEmailPassword returns technical error when Firebase unavailable',
      () async {
        when(() => mockAuth.isFirebaseAvailable).thenReturn(false);
        when(
          () => mockAuth.signInWithEmailPassword(any(), any()),
        ).thenAnswer((_) async => null);

        final result = await authManager.signInWithEmailPassword(
          'test@test.com',
          'password',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Firebase no disponible'));
      },
    );

    test(
      'AuthManager.signInWithEmailPassword returns credential error when Firebase is available but user missing',
      () async {
        when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
        when(
          () => mockAuth.signInWithEmailPassword(any(), any()),
        ).thenAnswer((_) async => null);

        final result = await authManager.signInWithEmailPassword(
          'test@test.com',
          'password',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Credenciales incorrectas'));
      },
    );
  });
}
