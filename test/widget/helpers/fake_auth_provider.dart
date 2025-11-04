import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;

class FakeAuthProvider extends ChangeNotifier implements local_auth.AuthProvider {
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;

  // Observability helpers for tests
  String? lastEmail;
  String? lastPassword;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpName;

  bool signInShouldSucceed = true;
  String failureMessage = 'Erreur simulée';
  bool signUpShouldSucceed = true;
  String signUpFailureMessage = 'Erreur d\'inscription';

  @override
  User? get user => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  @override
  Future<bool> signIn(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    _setLoading(true);
    await Future<void>.delayed(Duration.zero);
    _setLoading(false);

    if (signInShouldSucceed) {
      _setError(null);
      return true;
    }

    _setError(failureMessage);
    return false;
  }

  @override
  Future<bool> signUp(String email, String password, String name) async {
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpName = name;
    _setLoading(true);
    await Future<void>.delayed(Duration.zero);
    _setLoading(false);

    if (signUpShouldSucceed) {
      _setError(null);
      return true;
    }

    _setError(signUpFailureMessage);
    return false;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> resetPassword(String email) async => true;

  @override
  void clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
