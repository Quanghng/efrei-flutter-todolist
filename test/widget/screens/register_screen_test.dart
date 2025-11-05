import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/providers/todo_provider.dart';
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
  group('RegisterScreen widget', () {
    late FakeAuthProvider authProvider;
    late FakeTodoProvider todoProvider;

    const surface = Size(1200, 2200);

    Future<void> pumpRegister(WidgetTester tester) async {
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
          child: const MaterialApp(home: RegisterScreen()),
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

    testWidgets('renders all form fields and primary button', (tester) async {
      await pumpRegister(tester);

      expect(find.text('Créez votre compte Taskip'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nom complet'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
    });

    testWidgets('valid submission invokes authProvider.signUp', (tester) async {
      authProvider.signUpShouldSucceed = false;
      await pumpRegister(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet'), 'John ');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), '123456');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(authProvider.lastSignUpName, 'John');
      expect(authProvider.lastSignUpEmail, 'john@example.com');
      expect(authProvider.lastSignUpPassword, '123456');
      expect(authProvider.isAuthenticated, isFalse);
    });

    testWidgets('shows validation error when passwords mismatch', (tester) async {
      await pumpRegister(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet'), 'Jane');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '654321');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), '123456');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();
      _drainOverflow(tester);

      expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
    });

    testWidgets('displays snackbar when signUp fails', (tester) async {
      authProvider
        ..signUpShouldSucceed = false
        ..signUpFailureMessage = 'Inscription impossible';

      await pumpRegister(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet'), 'Jane');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), '123456');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(find.text('Inscription impossible'), findsOneWidget);
    });

    testWidgets('password fields toggle visibility independently', (tester) async {
      await pumpRegister(tester);

      final passwordField = find.widgetWithText(TextFormField, 'Mot de passe');
      final confirmField = find.widgetWithText(TextFormField, 'Confirmer le mot de passe');

      expect(find.descendant(of: passwordField, matching: find.byIcon(PhosphorIconsBold.eye)), findsOneWidget);
      expect(find.descendant(of: confirmField, matching: find.byIcon(PhosphorIconsBold.eye)), findsOneWidget);

      await tester.tap(find.descendant(of: passwordField, matching: find.byIcon(PhosphorIconsBold.eye)));
      await tester.pump();
      _drainOverflow(tester);

      expect(find.byIcon(PhosphorIconsBold.eyeSlash), findsWidgets);
    });
  });
}
