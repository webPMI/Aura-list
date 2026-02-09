import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'error_handler.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// Get Google OAuth credential for Firebase Auth
  /// Returns null if user cancels or there's an error
  Future<OAuthCredential?> getGoogleCredential() async {
    try {
      // Trigger the sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication auth = await account.authentication;

      // Create a credential
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      return credential;
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'GoogleSignInService.getGoogleCredential',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Sign in with Google and return UserCredential
  /// This is for direct sign-in (not linking)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final credential = await getGoogleCredential();
      if (credential == null) return null;

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.error,
        message: 'GoogleSignInService.signInWithGoogle',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get current signed-in Google account (if any)
  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  /// Check if signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.warning,
        message: 'GoogleSignInService.signOut',
        stackTrace: stack,
      );
    }
  }

  /// Disconnect from Google (revokes access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.auth,
        severity: ErrorSeverity.warning,
        message: 'GoogleSignInService.disconnect',
        stackTrace: stack,
      );
    }
  }
}
