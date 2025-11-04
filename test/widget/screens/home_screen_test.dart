import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:efrei_todolist/models/todo.dart';
import 'package:efrei_todolist/providers/theme_provider.dart';
import 'package:efrei_todolist/providers/todo_provider.dart';
import 'package:efrei_todolist/screens/home_screen.dart';

import '../helpers/fake_auth_provider.dart';
import '../helpers/fake_todo_provider.dart';

void main() {
  group('HomeScreen widget', () {
    late FakeAuthProvider authProvider;
    late FakeTodoProvider todoProvider;
    late ThemeProvider themeProvider;

    Future<void> pumpHome(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
            ChangeNotifierProvider.value(value: themeProvider),
          ],
          child: MaterialApp(
            themeMode: themeProvider.mode,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    Todo buildTodo({
      required String id,
      required String title,
      String description = '',
      bool completed = false,
      String priority = 'moyen',
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
      );
    }

    setUp(() {
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
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(todoProvider.deleteCompletedInvoked, isTrue);
      expect(find.text('Completed task'), findsNothing);
      expect(find.text('Pending task'), findsOneWidget);
    });

    testWidgets('theme toggle switches ThemeProvider mode', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Task'),
      ]);

      await pumpHome(tester);

      expect(themeProvider.isDark, isFalse);

      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pump();

      expect(themeProvider.isDark, isTrue);
    });

    testWidgets('search field filters list of todos', (tester) async {
      todoProvider.setTodos([
        buildTodo(id: '1', title: 'Read book'),
        buildTodo(id: '2', title: 'Write tests'),
      ]);

      await pumpHome(tester);

      await tester.enterText(find.byType(TextField).first, 'write');
      await tester.pump();

      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('Read book'), findsNothing);
    });
  });
}
