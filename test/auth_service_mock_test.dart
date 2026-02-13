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
    test('signInAnonymously returns UserCredential on success', () async {
      final mockCredential = MockUserCredential();
      when(
        () => mockAuth.signInAnonymously(),
      ).thenAnswer((_) async => mockCredential);

      final result = await authService.signInAnonymously();

      expect(result, mockCredential);
      verify(() => mockAuth.signInAnonymously()).called(1);
    });

    test('signInAnonymously handles FirebaseAuthException', () async {
      when(
        () => mockAuth.signInAnonymously(),
      ).thenThrow(FirebaseAuthException(code: 'operation-not-allowed'));

      final result = await authService.signInAnonymously();

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
