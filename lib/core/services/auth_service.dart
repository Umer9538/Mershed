import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mershed/core/models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  app_user.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    try {
      print('Converting Firebase User: uid=${user.uid}, email=${user.email}, displayName=${user.displayName}');
      return app_user.User(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
      );
    } catch (e) {
      print('Error converting Firebase User to app_user.User: $e');
      rethrow;
    }
  }

  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebase).handleError((e) {
      print('Auth state stream error: $e');
    });
  }

  Future<app_user.User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      print('Signin error: $e');
      rethrow;
    }
  }

  Future<app_user.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the sign-in
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      return _userFromFirebase(result.user);
    } catch (e) {
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  Future<void> send2FACode(String email, Function(String) onCodeSent) async {
    try {
      // Send an email verification link as a simple 2FA mechanism
      await _auth.currentUser?.sendEmailVerification();
      // For simplicity, we'll use a dummy "verificationId" since email link doesn't provide one directly
      onCodeSent('email-2fa-link');
    } catch (e) {
      print('2FA email error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Ensure Google Sign-In is also signed out
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}











/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mershed/core/models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  app_user.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    try {
      print('Converting Firebase User: uid=${user.uid}, email=${user.email}, displayName=${user.displayName}');
      return app_user.User(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
      );
    } catch (e) {
      print('Error converting Firebase User to app_user.User: $e');
      rethrow; // Rethrow to catch this in the provider
    }
  }

  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebase).handleError((e) {
      print('Auth state stream error: $e');
    });
  }

  Future<app_user.User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<app_user.User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } catch (e) {
      print('Signin error: $e');
      rethrow;
    }
  }

  Future<void> signInWithPhone(String phoneNumber, Function(String) onCodeSent) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: $e');
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print('Phone sign-in error: $e');
      rethrow;
    }
  }

  Future<app_user.User?> verifyPhoneOtp(String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      return _userFromFirebase(result.user);
    } catch (e) {
      print('OTP verification error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}

*/
