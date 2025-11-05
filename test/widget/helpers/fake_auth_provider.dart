import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;

/// Fake substitute for [AuthProvider] used in widget/integration tests.
class FakeAuthProvider extends ChangeNotifier implements local_auth.AuthProvider {
  bool _isLoading = false;
  String? _errorMessage;
  bool _loggedIn = false;
  User? _user;

  // Observability helpers for assertions.
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
  bool get isAuthenticated => _loggedIn;

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

  void _setLoggedIn(bool value) {
    if (_loggedIn != value) {
      _loggedIn = value;
      if (!value) {
        _user = null;
      } else {
        _user ??= const _FakeUser(uid: 'fake-user');
      }
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
      _setLoggedIn(true);
      return true;
    }

    _setLoggedIn(false);
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
      _setLoggedIn(true);
      return true;
    }

    _setLoggedIn(false);
    _setError(signUpFailureMessage);
    return false;
  }

  @override
  Future<void> signOut() async {
    _setLoggedIn(false);
  }

  @override
  Future<bool> resetPassword(String email) async => true;

  @override
  void clearError() {
    _setError(null);
  }
}

class _FakeUser implements User {
  const _FakeUser({required this.uid});

  @override
  final String uid;

  @override
  noSuchMethod(Invocation invocation) => null;
}
