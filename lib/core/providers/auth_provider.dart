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
}