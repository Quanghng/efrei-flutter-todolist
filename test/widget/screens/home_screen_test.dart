import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/models/todo.dart';
import 'package:efrei_todolist/providers/auth_provider.dart' as local_auth;
import 'package:efrei_todolist/providers/theme_provider.dart';
import 'package:efrei_todolist/providers/todo_provider.dart';
import 'package:efrei_todolist/screens/home_screen.dart';

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
  group('HomeScreen widget', () {
    late FakeAuthProvider authProvider;
    late FakeTodoProvider todoProvider;
    late ThemeProvider themeProvider;

    const surface = Size(1400, 2200);

    Future<void> pumpHome(WidgetTester tester) async {
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
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            themeMode: themeProvider.mode,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      _drainOverflow(tester);
    }

    Todo buildTodo({
      required String id,
      required String title,
      String description = '',
      bool completed = false,
      String priority = 'moyen',
      bool isPublic = false,
    }) {
      return Todo(
        id: id,
        title: title,
        description: description,
        isCompleted: completed,
        createdAt: DateTime(2024, 1, 1).add(Duration(days: int.parse(id))),
        completedAt: completed ? DateTime(2024, 1, 2) : null,
        userId: 'fake-user',
        priority: priority,
        dueDate: null,
        isPublic: isPublic,
      );
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
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      authProvider.dispose();
      todoProvider.dispose();
      themeProvider.dispose();
    });

    testWidgets('displays stats and todo items', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Study Flutter', description: 'Widgets', completed: true, priority: 'fort'),
        buildTodo(id: '2', title: 'Write tests', description: 'Unit & widget', completed: false, priority: 'moyen'),
      ]);

      await pumpHome(tester);

      expect(find.text('Study Flutter'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget); 
      expect(find.textContaining('Terminées'), findsWidgets);
    });

    testWidgets('shows empty state when no todos present', (tester) async {
      await pumpHome(tester);

      expect(find.text('Aucune tâche pour le moment'), findsOneWidget);
      expect(find.text('Appuyez sur + pour ajouter votre première tâche'), findsOneWidget);
    });

    testWidgets('delete completed button triggers provider removal', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Completed task', completed: true),
        buildTodo(id: '2', title: 'Pending task'),
      ]);

      await pumpHome(tester);

      await tester.tap(find.byTooltip('Supprimer les tâches terminées'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(todoProvider.deleteCompletedInvoked, isTrue);
      expect(find.text('Completed task'), findsNothing);
      expect(find.text('Pending task'), findsOneWidget);
    });

    testWidgets('community tab displays public todos', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Private task'),
      ]);
      todoProvider.setPublicTodos([
        buildTodo(
          id: '2',
          title: 'Public task',
          description: 'Visible to everyone',
          priority: 'fort',
          isPublic: true,
        ),
      ]);

      await pumpHome(tester);

      await tester.tap(find.text('Communauté'));
      await tester.pumpAndSettle();
      _drainOverflow(tester);

      expect(find.text('Public task'), findsOneWidget);
      expect(find.text('Private task'), findsNothing);
    });

    testWidgets('search field filters list of todos', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Read book'),
        buildTodo(id: '2', title: 'Write tests'),
      ]);

      await pumpHome(tester);

      final searchField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Rechercher...',
      );

      await tester.enterText(searchField, 'write');
      await tester.pump();
      _drainOverflow(tester);

      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('Read book'), findsNothing);
    });
  });
}
