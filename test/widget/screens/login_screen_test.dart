import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/screens/auth/login_screen.dart';
import 'package:efrei_todolist/screens/auth/register_screen.dart';
import '../helpers/fake_auth_provider.dart';

void main() {
  group('LoginScreen widget', () {
    late FakeAuthProvider authProvider;

    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<local_auth.AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: LoginScreen(),
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

    testWidgets('renders email, password fields and primary actions', (tester) async {
      await pumpLogin(tester);

      expect(find.text('EFREI Taskip'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Pas de compte ? S\'inscrire'), findsOneWidget);
    });

    testWidgets('valid submission calls provider with trimmed credentials', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'user@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), '123456');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(authProvider.lastEmail, 'user@example.com');
      expect(authProvider.lastPassword, '123456');
    });

    testWidgets('shows validation messages when form is empty', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

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

      expect(find.text('Erreur de connexion test'), findsOneWidget);
    });

    testWidgets('navigates to register screen when link tapped', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text("Pas de compte ? S'inscrire"));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('password visibility toggle swaps icons', (tester) async {
      await pumpLogin(tester);

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
