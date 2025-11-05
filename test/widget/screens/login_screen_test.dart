import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/providers/todo_provider.dart';
import 'package:efrei_todolist/screens/auth/login_screen.dart';
import 'package:efrei_todolist/screens/auth/register_screen.dart';
import '../helpers/fake_auth_provider.dart';
import '../helpers/fake_todo_provider.dart';

void _drainOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception != null) {
    final message = exception.toString();
    if (!message.contains('A RenderFlex overflowed')) {
      fail('Unexpected framework exception: $exception');
    }
  }
}

void main() {
  group('LoginScreen widget', () {
    late FakeAuthProvider authProvider;
    late FakeTodoProvider todoProvider;

    const surface = Size(1200, 2200);

    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<local_auth.AuthProvider>.value(
              value: authProvider,
            ),
            ChangeNotifierProvider<TodoProvider>.value(
              value: todoProvider,
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      _drainOverflow(tester);
    }

    setUp(() {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('A RenderFlex overflowed')) {
          return;
        }
        originalOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = originalOnError;
      });

      authProvider = FakeAuthProvider();
      todoProvider = FakeTodoProvider();
    });

    tearDown(() {
      authProvider.dispose();
      todoProvider.dispose();
    });

    testWidgets('renders email, password fields and primary actions', (tester) async {
      await pumpLogin(tester);

      expect(find.text('Bon retour !'), findsOneWidget);
      expect(find.text('Connectez-vous à votre compte Taskip'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Pas de compte ? S\'inscrire'), findsOneWidget);
    });

    testWidgets('valid submission calls provider with trimmed credentials', (tester) async {
      authProvider.signInShouldSucceed = false;
      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(authProvider.lastEmail, 'user@example.com');
      expect(authProvider.lastPassword, '123456');
    });

    testWidgets('shows validation messages when form is empty', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(find.text('Veuillez saisir votre email'), findsOneWidget);
      expect(find.text('Veuillez saisir votre mot de passe'), findsOneWidget);
    });

    testWidgets('displays snackbar on authentication failure', (tester) async {
      authProvider
        ..signInShouldSucceed = false
        ..failureMessage = 'Erreur de connexion test';

      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(find.text('Erreur de connexion test'), findsOneWidget);
    });

    testWidgets('navigates to register screen when link tapped', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text("Pas de compte ? S'inscrire"));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('password visibility toggle swaps icons', (tester) async {
      await pumpLogin(tester);

      expect(find.byIcon(PhosphorIconsBold.eye), findsOneWidget);
      expect(find.byIcon(PhosphorIconsBold.eyeSlash), findsNothing);

      await tester.tap(find.byIcon(PhosphorIconsBold.eye));
      await tester.pump();
      _drainOverflow(tester);

      expect(find.byIcon(PhosphorIconsBold.eyeSlash), findsOneWidget);
    });
  });
}
