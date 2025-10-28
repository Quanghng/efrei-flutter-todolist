import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;

import 'auth_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
  MockSpec<UserCredential>(),
])
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    late StreamController<User?> authController;

    setUp(() {
      authController = StreamController<User?>.broadcast();
    });

    tearDown(() async {
      await authController.close();
    });

    local_auth.AuthProvider createProvider(MockFirebaseAuth auth) {
      return local_auth.AuthProvider(
        auth: auth,
        authStateChangesStream: authController.stream,
      );
    }

    test('authStateChanges updates current user', () async {
      final auth = MockFirebaseAuth();
      final provider = createProvider(auth);
      final user = MockUser();

      authController.add(user);
      await Future<void>.delayed(Duration.zero);

      expect(provider.user, equals(user));
      provider.dispose();
    });

    test('signIn succeeds and clears loading state', () async {
      final auth = MockFirebaseAuth();
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => MockUserCredential());
      final provider = createProvider(auth);

      final result = await provider.signIn('john@example.com', 'secret');

      expect(result, isTrue);
      expect(provider.isLoading, isFalse);
      verify(auth.signInWithEmailAndPassword(
        email: 'john@example.com',
        password: 'secret',
      )).called(1);
      provider.dispose();
    });

    test('signIn surfaces FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();
      when(auth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));
      final provider = createProvider(auth);

      final result = await provider.signIn('missing@example.com', 'secret');

      expect(result, isFalse);
      expect(
        provider.errorMessage,
        contains('Aucun utilisateur'),
      );
      provider.dispose();
    });

    test('signUp updates display name and user cache', () async {
      final auth = MockFirebaseAuth();
      final credential = MockUserCredential();
      final user = MockUser();

      when(auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => credential);
      when(credential.user).thenReturn(user);
      when(user.updateDisplayName('John')).thenAnswer((_) async {});
      when(user.reload()).thenAnswer((_) async {});
      when(auth.currentUser).thenReturn(user);

      final provider = createProvider(auth);

      final result = await provider.signUp('john@example.com', 'secret', 'John');

      expect(result, isTrue);
      expect(provider.user, equals(user));
      verify(user.updateDisplayName('John')).called(1);
      provider.dispose();
    });

    test('signUp handles FirebaseAuthException', () async {
      final auth = MockFirebaseAuth();

      when(auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final provider = createProvider(auth);

      final result = await provider.signUp('john@example.com', 'secret', 'John');

      expect(result, isFalse);
      expect(provider.errorMessage, contains('existe déjà'));
      provider.dispose();
    });

    test('resetPassword propagates success and failure', () async {
      final auth = MockFirebaseAuth();
      when(auth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {});
      final provider = createProvider(auth);

      final ok = await provider.resetPassword('john@example.com');
      expect(ok, isTrue);

      when(auth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final fail = await provider.resetPassword('bad-email');
      expect(fail, isFalse);
      expect(provider.errorMessage, contains('Format d\'email invalide'));
      provider.dispose();
    });
  });
}
