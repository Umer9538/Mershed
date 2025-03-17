import 'package:flutter/material.dart';
import 'package:mershed/core/models/user.dart';
import 'package:mershed/core/services/auth_service.dart';

class MershadAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _verificationId;
  bool _isGuest = false;

  User? get user => _user;
  String? get verificationId => _verificationId;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _user != null && !_isGuest;

  MershadAuthProvider() {
    print('Initializing MershadAuthProvider');
    _authService.user.listen((user) {
      print('Auth state changed: $user');
      _user = user;
      if (user == null) _isGuest = false;
      notifyListeners();
    }, onError: (e) {
      print('Auth stream error: $e');
    });
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      User? user = await _authService.signUpWithEmail(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      User? user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        print('User signed in: ${_user?.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('Signin error in provider: $e');
      // Provide a user-friendly error message
      String errorMsg = _parseFirebaseError(e.toString());
      throw Exception(errorMsg);
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _authService.signInWithPhone(phoneNumber, (verificationId) {
        _verificationId = verificationId;
        notifyListeners();
      });
    } catch (e) {
      print('Phone sign-in error: $e');
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp(String otp) async {
    if (_verificationId == null) return false;
    try {
      User? user = await _authService.verifyPhoneOtp(_verificationId!, otp);
      if (user != null) {
        _user = user;
        _verificationId = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('OTP verification error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _verificationId = null;
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  void setGuestMode(bool value) {
    _isGuest = value;
    if (value) _user = null;
    notifyListeners();
  }

  // Helper method to parse Firebase errors into user-friendly messages
  String _parseFirebaseError(String error) {
    if (error.contains('invalid-email')) {
      return 'The email address is badly formatted.';
    } else if (error.contains('user-not-found')) {
      return 'No user found with this email.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('PigeonUserDetails')) {
      return 'Authentication error. Please ensure your app is up to date.';
    } else {
      return 'An error occurred during sign-in. Please try again.';
    }
  }
}


/*
import 'package:flutter/material.dart';
import 'package:mershed/core/models/user.dart';
import 'package:mershed/core/services/auth_service.dart';

class MershadAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _verificationId;

  User? get user => _user;
  String? get verificationId => _verificationId;

  MershadAuthProvider() {
    print('Initializing MershadAuthProvider');
    _authService.user.listen((user) {
      print('Auth state changed: $user');
      _user = user;
      notifyListeners();
    }, onError: (e) {
      print('Auth stream error: $e');
    });
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      User? user = await _authService.signUpWithEmail(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      User? user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        print('User signed in: ${_user?.email}');
        return true;
      }
      return false;
    } catch (e) {
      print('Signin error in provider: $e');
      rethrow;
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _authService.signInWithPhone(phoneNumber, (verificationId) {
        _verificationId = verificationId;
        notifyListeners();
      });
    } catch (e) {
      print('Phone sign-in error: $e');
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp(String otp) async {
    if (_verificationId == null) return false;
    try {
      User? user = await _authService.verifyPhoneOtp(_verificationId!, otp);
      if (user != null) {
        _user = user;
        _verificationId = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('OTP verification error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _verificationId = null;
      notifyListeners();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }
}*/
