import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/providers/theme_provider.dart';
import 'package:efrei_todolist/providers/todo_provider.dart';
import 'package:efrei_todolist/screens/auth/login_screen.dart';
import 'package:efrei_todolist/screens/home_screen.dart';

import '../widget/helpers/fake_auth_provider.dart';
import '../widget/helpers/fake_todo_provider.dart';

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.authProvider,
    required this.todoProvider,
    required this.themeProvider,
  });

  final FakeAuthProvider authProvider;
  final FakeTodoProvider todoProvider;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<local_auth.AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
            ),
            home: Consumer<local_auth.AuthProvider>(
              builder: (context, auth, _) {
                return auth.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final enforcedSize = const Size(1200, 2200);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  size: enforcedSize,
                  devicePixelRatio: 1.0,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('end-to-end: login, add todo, toggle completion', (tester) async {
    final authProvider = FakeAuthProvider();
    final todoProvider = FakeTodoProvider();
    final themeProvider = ThemeProvider();

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

    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _TestApp(
        authProvider: authProvider,
        todoProvider: todoProvider,
        themeProvider: themeProvider,
      ),
    );
    await tester.pumpAndSettle();

    // Login screen validation
    expect(find.text('Bon retour !'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'integration@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'secret1',
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    // After successful sign-in, home screen should be visible.
    expect(find.text('Supprimer les tâches terminées'), findsNothing);
    expect(find.text('Aucune tâche pour le moment'), findsOneWidget);

    expect(find.text('Création de tâche'), findsOneWidget);

    final titleField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Ex: Finir le projet...',
    );
    final descriptionField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Détails de la tâche...',
    );

    await tester.enterText(titleField, 'Créer un test E2E');
    await tester.enterText(descriptionField, 'Valider le flux principal');

    await tester.tap(find.text('Fort'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer la tâche'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un test E2E'), findsOneWidget);
    expect(todoProvider.todos.length, 1);

    // Toggle completion.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(todoProvider.completedCount, 1);

    // Delete completed todos via dialog.
    await tester.tap(find.byTooltip('Supprimer les tâches terminées'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(todoProvider.completedCount, 0);
    expect(find.text('Créer un test E2E'), findsNothing);
  });
}
