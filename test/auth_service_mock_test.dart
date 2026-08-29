import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/services/google_sign_in_service.dart';
import 'package:checklist_app/services/session_cache_manager.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockErrorHandler extends Mock implements ErrorHandler {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}

class MockSessionCacheManager extends Mock implements SessionCacheManager {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockErrorHandler mockErrorHandler;
  late MockGoogleSignInService mockGoogleSignIn;
  late MockSessionCacheManager mockSessionCache;

  setUpAll(() {
    registerFallbackValue(ErrorType.unknown);
    registerFallbackValue(ErrorSeverity.error);
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockErrorHandler = MockErrorHandler();
    mockGoogleSignIn = MockGoogleSignInService();
    mockSessionCache = MockSessionCacheManager();

    authService = AuthService(
      mockErrorHandler,
      mockGoogleSignIn,
      mockSessionCache,
      auth: mockAuth,
    );

    // Default behaviors
    when(() => mockAuth.currentUser).thenReturn(null);
    when(
      () => mockAuth.authStateChanges(),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockErrorHandler.handle(
        any(),
        type: any(named: 'type'),
        severity: any(named: 'severity'),
        message: any(named: 'message'),
        userMessage: any(named: 'userMessage'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(
      AppError(
        type: ErrorType.unknown,
        severity: ErrorSeverity.error,
        message: 'mock error',
      ),
    );
  });

  group('AuthService Mocked Implementation Tests', () {
    test('signInAnonymously returns null graciously when Firebase unavailable', () async {
      // El mockAuth (MockFirebaseAuth) no tiene Firebase apps configuradas.
      // signInAnonymously() debería retornar null sin lanzar excepciones.
      // Este test verifica la graceful degradation del servicio.
      final result = await authService.signInAnonymously();
      // Retorna null porque no hay Firebase disponible (no hay apps)
      expect(result, isNull);
      // Nota: isFirebaseAvailable es true porque _auth fue inyectado,
      // pero el metodo devuelve null porque la operación subyacente falla
      // o porque Firebase no está realmente disponible en este entorno de test.
    });

    test('registerWithEmailPassword returns UserCredential on success', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.registerWithEmailPassword(
        'test@example.com',
        'Password123',
      );

      expect(result, mockCredential);
      verify(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).called(1);
    });

    test('registerWithEmailPassword handles FirebaseAuthException gracefully', () async {
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await authService.registerWithEmailPassword(
        'test@example.com',
        'Password123',
      );

      expect(result, isNull);
      verify(
        () => mockErrorHandler.handle(
          any(),
          type: ErrorType.auth,
          severity: ErrorSeverity.error,
          message: any(named: 'message'),
          userMessage: any(named: 'userMessage'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    });

    test('signInWithEmailPassword returns UserCredential on success', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInWithEmailPassword(
        'test@example.com',
        'Password123',
      );

      expect(result, mockCredential);
      verify(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'Password123',
        ),
      ).called(1);
    });

    test('signOut cleans cache and signs out from Firebase', () async {
      when(
        () => mockSessionCache.clearUserData(
          preservePreferences: any(named: 'preservePreferences'),
        ),
      ).thenAnswer((_) async => {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => {});
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      await authService.signOut(clearCache: true);

      verify(
        () => mockSessionCache.clearUserData(preservePreferences: true),
      ).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('isLinkedAccount returns true for non-anonymous user', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.isAnonymous).thenReturn(false);

      expect(authService.isLinkedAccount, isTrue);
    });

    test('isLinkedAccount returns false for anonymous user', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.isAnonymous).thenReturn(true);

      expect(authService.isLinkedAccount, isFalse);
    });
  });
}
