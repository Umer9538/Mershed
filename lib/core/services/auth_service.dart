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













/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mershed/core/models/user.dart' as app_user;
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase User to our app-specific User model
  app_user.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    try {
      return app_user.User(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
      );
    } catch (e) {
      print('Error converting Firebase User to app_user.User: $e');
      return null;
    }
  }

  // Stream to listen to auth state changes
  Stream<app_user.User?> get user {
    return _auth.authStateChanges().map(_userFromFirebase).handleError((e) {
      print('Auth state stream error: $e');
    });
  }

  // Sign up with email and password
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

  // Sign in with email and password
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

  // Initiate phone number sign-in (sends OTP)
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

  // Verify OTP and complete phone sign-in
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

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}*/
