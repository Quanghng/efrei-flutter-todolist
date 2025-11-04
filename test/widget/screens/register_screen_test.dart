import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/screens/auth/register_screen.dart';

import '../helpers/fake_auth_provider.dart';

void main() {
  group('RegisterScreen widget', () {
    late FakeAuthProvider authProvider;

    Future<void> pumpRegister(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<local_auth.AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    setUp(() {
      authProvider = FakeAuthProvider();
    });

    tearDown(() {
      authProvider.dispose();
    });

    testWidgets('renders all form fields and primary button', (tester) async {
      await pumpRegister(tester);

      expect(find.widgetWithText(TextFormField, 'Nom complet'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('Créer mon compte'), findsOneWidget);
    });

    testWidgets('valid submission invokes authProvider.signUp', (tester) async {
      await pumpRegister(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet'), 'John ');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'john@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), '123456');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      expect(authProvider.lastSignUpName, 'John');
      expect(authProvider.lastSignUpEmail, 'john@example.com');
      expect(authProvider.lastSignUpPassword, '123456');
      // Screen should pop after success
      expect(find.byType(RegisterScreen), findsNothing);
    });

    testWidgets('shows validation error when passwords mismatch', (tester) async {
      await pumpRegister(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom complet'), 'Jane');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'jane@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '654321');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmer le mot de passe'), '123456');

      await tester.tap(find.text('Créer mon compte'));
      await tester.pump();

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

      expect(find.text('Inscription impossible'), findsOneWidget);
    });

    testWidgets('password fields toggle visibility independently', (tester) async {
      await pumpRegister(tester);

      final passwordField = find.widgetWithText(TextFormField, 'Mot de passe');
      final confirmField = find.widgetWithText(TextFormField, 'Confirmer le mot de passe');

      expect(find.descendant(of: passwordField, matching: find.byIcon(Icons.visibility)), findsOneWidget);
      expect(find.descendant(of: confirmField, matching: find.byIcon(Icons.visibility)), findsOneWidget);

      await tester.tap(find.descendant(of: passwordField, matching: find.byIcon(Icons.visibility)));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsWidgets);
    });
  });
}
