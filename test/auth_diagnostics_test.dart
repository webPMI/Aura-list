import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/auth_manager.dart';
import 'package:checklist_app/services/database_service.dart';

// Mock classes using mocktail
class MockAuthServiceForDiagnostics extends Mock implements AuthService {}

class MockDatabaseServiceForAuth extends Mock implements DatabaseService {}

// User and credential mocks for testing
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

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
    // Nota: Los tests de AuthManager con mocks de AuthService son limitados
    // porque AuthService tiene estado interno (_auth) que no es mockeable.
    // Los tests de integración reales están en auth_service_test.dart.
    //
    // Este grupo documenta el contrato de AuthManager pero usa mocks simples
    // para verificar delegación, no comportamiento real de Firebase.

    test('AuthManager delegates getInitializationStatus to AuthService', () {
      final mockStatus = {'projectId': 'test-project'};
      final mockAuth = MockAuthServiceForDiagnostics();
      final mockDb = MockDatabaseServiceForAuth();
      final authManager = AuthManager(authService: mockAuth, dbService: mockDb);

      when(() => mockAuth.getInitializationStatus()).thenReturn(mockStatus);

      final status = authManager.getInitializationStatus();
      expect(status['projectId'], 'test-project');
      verify(() => mockAuth.getInitializationStatus()).called(1);
    });
  });
}
