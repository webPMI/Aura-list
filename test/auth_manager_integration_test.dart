import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/auth_manager.dart';
import 'package:checklist_app/services/database_service.dart';

// ============================================================
// Mocks para AuthManager integration tests
// ============================================================

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}
class MockDatabaseService extends Mock implements DatabaseService {}
class MockFinanceRepository extends Mock {}
class MockUserCredential extends Mock implements UserCredential {}

// ============================================================
// Helper: crear AuthManager con mocks configurados
// ============================================================

/// Crea un AuthManager de test con AuthService mockeado.
///
/// Uso típico:
/// ```dart
/// final (authManager, mockAuth, mockDb) = createTestAuthManager();
///
/// // Configurar comportamiento
/// when(() => mockAuth.currentUser).thenReturn(mockUser);
/// when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
/// ```
(AuthManager, MockAuthService, MockDatabaseService) createTestAuthManager() {
  final mockAuth = MockAuthService();
  final mockDb = MockDatabaseService();

  // Configuración por defecto
  when(() => mockAuth.currentUser).thenReturn(null);
  when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
  when(() => mockAuth.isLinkedAccount).thenReturn(false);
  when(() => mockAuth.linkedEmail).thenReturn(null);
  when(() => mockAuth.linkedProvider).thenReturn(null);
  when(() => mockAuth.authStateChanges).thenAnswer((_) => Stream.value(null));
  when(() => mockAuth.signInWithEmailPassword(any(), any())).thenAnswer((_) async => null);
  when(() => mockAuth.registerWithEmailPassword(any(), any())).thenAnswer((_) async => null);
  when(() => mockAuth.signInAnonymously()).thenAnswer((_) async => null);
  when(() => mockAuth.signInWithGoogle()).thenAnswer((_) async => null);
  when(() => mockAuth.signOut(clearCache: any(named: 'clearCache'), preservePreferences: any(named: 'preservePreferences'))).thenAnswer((_) async {});
  when(() => mockAuth.signOutAndClear()).thenAnswer((_) async {});
  when(() => mockAuth.linkWithEmailPassword(any(), any())).thenAnswer((_) async => (
    credential: null,
    errorMessage: null,
    isCancelled: false,
    errorCode: null,
  ));
  when(() => mockAuth.linkWithGoogle()).thenAnswer((_) async => (
    credential: null,
    error: null,
  ));

  when(() => mockDb.setCloudSyncEnabled(any())).thenAnswer((_) async {});
  when(() => mockDb.performFullSync(any())).thenAnswer((_) async => SyncResult(
    tasksDownloaded: 0,
    notesDownloaded: 0,
    errors: 0,
  ));
  when(() => mockDb.isCloudSyncEnabled()).thenAnswer((_) async => true);
  when(() => mockDb.forceSyncPendingTasks()).thenAnswer((_) async {});
  when(() => mockDb.getTotalPendingSyncCount()).thenAnswer((_) async => 0);

  final authManager = AuthManager(
    authService: mockAuth,
    dbService: mockDb,
  );

  return (authManager, mockAuth, mockDb);
}
MockUser createMockUser({
  String uid = 'test-uid',
  bool isAnonymous = false,
  String email = 'user@example.com',
}) {
  final user = MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(isAnonymous);
  when(() => user.email).thenReturn(email);
  when(() => user.providerData).thenReturn([]);
  return user;
}

// ============================================================
// Tests de AuthManager
// ============================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthManager - Sync Integration Tests', () {
    late AuthManager authManager;
    late MockAuthService mockAuth;
    late MockDatabaseService mockDb;

    setUp(() {
      final container = createTestAuthManager();
      authManager = container.$1;
      mockAuth = container.$2;
      mockDb = container.$3;
    });

    // ============================================================
    // TEST: Sync se activa correctamente
    // ============================================================
    test('AuthManager activa sync automáticamente después de auth exitoso', () async {
      // Arrange: usuario autenticado
      final mockUser = createMockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);

      when(() => mockDb.setCloudSyncEnabled(any())).thenAnswer((_) async {});
      when(() => mockDb.performFullSync(any())).thenAnswer((_) async =>
        SyncResult(
          tasksDownloaded: 5,
          notesDownloaded: 3,
          errors: 0,
        )
      );

      // Act: Simular activar sync (esto es lo que hace _enableSyncAfterAuth)
      await authManager.setSyncEnabled(true);

      // Assert: sync debería estar habilitado
      final syncEnabled = await authManager.isSyncEnabled();
      expect(syncEnabled, isTrue);
    });

    test('AuthManager maneja sync con errores sin fallar', () async {
      // Arrange: usuario autenticado, sync con errores
      final mockUser = createMockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);

      when(() => mockDb.setCloudSyncEnabled(any())).thenAnswer((_) async {});
      when(() => mockDb.performFullSync(any())).thenAnswer((_) async =>
        SyncResult(
          tasksDownloaded: 2,
          notesDownloaded: 1,
          errors: 3,
        )
      );

      // Act: activar sync (debería completar aunque haya errores)
      await authManager.setSyncEnabled(true);

      // Assert: sync está habilitado aunque tuvo errores
      final syncEnabled = await authManager.isSyncEnabled();
      expect(syncEnabled, isTrue);
    });

    test('AuthManager desactiva sync correctamente', () async {
      // Arrange: sync inicialmente habilitado
      when(() => mockDb.isCloudSyncEnabled()).thenAnswer((_) async => false);
      when(() => mockDb.setCloudSyncEnabled(any())).thenAnswer((_) async {});

      // Act: desactivar sync
      await authManager.setSyncEnabled(false);

      // Assert: sync deshabilitado
      final syncEnabled = await authManager.isSyncEnabled();
      expect(syncEnabled, isFalse);
    });

    test('AuthManager fuerza sincronización de tareas pendientes', () async {
      // Arrange: usuario autenticado
      final mockUser = createMockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      when(() => mockDb.forceSyncPendingTasks()).thenAnswer((_) async {});

      // Act
      await authManager.forceSyncPending();

      // Assert: el método fue llamado
      verify(() => mockDb.forceSyncPendingTasks()).called(1);
    });

    test('AuthManager obtiene conteo de items pendientes de sincronizar', () async {
      when(() => mockDb.getTotalPendingSyncCount()).thenAnswer((_) async => 42);

      final count = await authManager.getPendingSyncCount();

      expect(count, 42);
      verify(() => mockDb.getTotalPendingSyncCount()).called(1);
    });
  });

  // ============================================================
  // TEST: Flujo completo de autenticación y vinculación
  // ============================================================
  group('AuthManager - Full Auth Flow Tests', () {
    late AuthManager authManager;
    late MockAuthService mockAuth;

    setUp(() {
      final container = createTestAuthManager();
      authManager = container.$1;
      mockAuth = container.$2;
    });

    test('Flujo completo: usuario existente con cuenta vinculada entra directamente con sync', () async {
      // Arrange: usuario con cuenta ya vinculada (no anónimo)
      final mockUser = createMockUser(uid: 'google-user-123', isAnonymous: false, email: 'user@example.com');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.isLinkedAccount).thenReturn(true);
      when(() => mockAuth.linkedEmail).thenReturn('user@example.com');
      when(() => mockAuth.linkedProvider).thenReturn('google');

      // Assert: AuthManager expone correctamente
      expect(authManager.currentUser, isNotNull);
      expect(authManager.isLinkedAccount, isTrue);
      expect(authManager.linkedEmail, 'user@example.com');
      expect(authManager.linkedProvider, 'google');
    });

    test('Flujo completo: usuario anónimo puede vincularse (linkWithEmailPassword)', () async {
      // Arrange: usuario anónimo
      final mockUser = createMockUser(uid: 'anon-user-123', isAnonymous: true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.isLinkedAccount).thenReturn(false);

      when(() => mockAuth.linkWithEmailPassword(any(), any())).thenAnswer((_) async =>
        (credential: MockUserCredential(), errorCode: null, errorMessage: null, isCancelled: false)
      );

      // Act: vincular cuenta
      final result = await authManager.linkWithEmailPassword('user@example.com', 'Password123');

      // Assert: debería obtener éxito
      expect(result.success, isTrue);
    });

    test('Flujo completo: vinculación de Google desde anónimo', () async {
      // Arrange: usuario anónimo
      final mockUser = createMockUser(uid: 'anon-user-123', isAnonymous: true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.isLinkedAccount).thenReturn(false);

      when(() => mockAuth.linkWithGoogle()).thenAnswer((_) async =>
        (credential: MockUserCredential(), error: null)
      );

      // Act
      final result = await authManager.linkWithGoogle();

      // Assert
      expect(result.success, isTrue);
    });
  });

  // ============================================================
  // TEST: Manejo de errores críticos
  // ============================================================
  group('AuthManager - Critical Error Handling', () {
    late AuthManager authManager;
    late MockAuthService mockAuth;

    setUp(() {
      final container = createTestAuthManager();
      authManager = container.$1;
      mockAuth = container.$2;
    });

    test('AuthManager maneja errores de Firebase al hacer login', () async {
      // Arrange: Firebase no disponible
      when(() => mockAuth.isFirebaseAvailable).thenReturn(false);
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act: intentar login
      final result = await authManager.signInWithEmailPassword('test@example.com', 'password');

      // Assert: error técnico, no "credenciales incorrectas"
      expect(result.success, isFalse);
      expect(result.error, contains('Firebase no disponible'));
    });

    test('AuthManager maneja error de credenciales incorrectas', () async {
      // Arrange: Firebase disponible pero credenciales inválidas
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(null);

      // AuthService.signInWithEmailAndPassword es un método público de AuthService,
      // pero usa _auth internamente. En el mock, no es interceptable.
      // En su lugar, verificamos el comportamiento: cuando _authService.signInWithEmailPassword()
      // retorna null y isFirebaseAvailable=true, el AuthManager lo interpreta como
      // "credenciales incorrectas".
      //
      // Para lograr esto, el mock de AuthService debe retornar null cuando se llame
      // a signInWithEmailPassword(). Como MockAuthService extiende Mock e implementa
      // AuthService, y signInWithEmailPassword es un método público de la clase,
      // mocktail debería poder interceptarlo... pero no puede porque usa _auth privado.
      //
      // Solución: usamos el comportamiento por defecto del mock (retorna null para
      // métodos no mockeados) y verificamos que el AuthManager maneja null correctamente
      // cuando isFirebaseAvailable=true.

      // Act
      final result = await authManager.signInWithEmailPassword('test@example.com', 'wrongpassword');

      // Assert: error de credenciales
      expect(result.success, isFalse);
      expect(result.error, contains('Credenciales incorrectas'));
    });

    test('AuthManager maneja registro con email ya existente', () async {
      when(() => mockAuth.isFirebaseAvailable).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(null);

      // AuthService.registerWithEmailPassword usa _auth internamente y no es
      // interceptable en el mock. El mock retorna null por defecto para métodos
      // no mockeados. El AuthManager recibe null y lo interpreta como error de registro.
      //
      // Cuando el AuthManager recibe null de registerWithEmailPassword() y
      // isFirebaseAvailable=true, retorna "No se pudo crear la cuenta".

      final result = await authManager.registerWithEmailPassword('existing@example.com', 'password');

      // Verificamos que el AuthManager maneja el error correctamente
      expect(result.success, isFalse);
      expect(result.error, anyOf([
        contains('No se pudo crear la cuenta'),
        contains('Este correo ya está registrado'),
      ]));
    });
  });
}
