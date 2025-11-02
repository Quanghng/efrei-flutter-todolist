import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:efrei_todolist/models/todo.dart';
import 'package:efrei_todolist/providers/todo_provider.dart';

import 'todo_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
])

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('TodoProvider logic', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('addTodo fails when no authenticated user', () async {
      final auth = MockFirebaseAuth();
      when(auth.currentUser).thenReturn(null);
      final provider = TodoProvider(
        firestore: firestore,
        auth: auth,
      );

      final result = await provider.addTodo('Task', 'Desc', null);

      expect(result, isFalse);
      expect(provider.errorMessage, 'Utilisateur non connecté');
    });

    test('addTodo persists data for signed-in user', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-123');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(
        firestore: firestore,
        auth: auth,
      );

      final succeeded = await provider.addTodo(
        'Task',
        'Description',
        DateTime(2024, 1, 1),
        'haut',
      );

      final docs = await firestore.collection('todos').get();

      expect(succeeded, isTrue);
      expect(docs.docs, hasLength(1));
      final stored = docs.docs.first.data();
      expect(stored['title'], 'Task');
      expect(stored['description'], 'Description');
      expect(stored['priority'], 'haut');
      expect(stored['userId'], 'user-123');
    });

    test('startListening hydrates todos sorted by createdAt desc', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-1');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      final older = firestore.collection('todos').doc();
      await older.set({
        'id': older.id,
        'title': 'Older',
        'description': 'First',
        'isCompleted': false,
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'userId': 'user-1',
        'priority': 'moyen',
      });
      final newer = firestore.collection('todos').doc();
      await newer.set({
        'id': newer.id,
        'title': 'Newer',
        'description': 'Second',
        'isCompleted': false,
        'createdAt': DateTime(2024, 1, 2).millisecondsSinceEpoch,
        'userId': 'user-1',
        'priority': 'moyen',
      });

      provider.startListening();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(provider.todos, hasLength(2));
      expect(provider.todos.first.title, 'Newer');
      expect(provider.todos.last.title, 'Older');
    });

    test('toggleTodoStatus updates completion', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-toggle');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      final ref = firestore.collection('todos').doc();
      await ref.set({
        'id': ref.id,
        'title': 'Toggle me',
        'description': 'Desc',
        'isCompleted': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'userId': 'user-toggle',
        'priority': 'moyen',
      });

      provider.startListening();
      await Future.delayed(const Duration(milliseconds: 20));

      final success = await provider.toggleTodoStatus(ref.id);
      await Future.delayed(const Duration(milliseconds: 20));

      final updated =
          await firestore.collection('todos').doc(ref.id).get();

      expect(success, isTrue);
      expect(updated.data()?['isCompleted'], isTrue);
      expect(provider.completedCount, 1);
    });

    test('updateTodo overwrites existing document fields', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-update');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      final ref = firestore.collection('todos').doc('update-1');
      final todo = Todo(
        id: ref.id,
        title: 'Initial',
        description: 'Desc',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        userId: 'user-update',
        priority: 'moyen',
        dueDate: null,
        completedAt: null,
      );
      await ref.set(todo.toMap());

      final updated = todo.copyWith(
        title: 'Updated title',
        description: 'Desc updated',
        priority: 'haut',
      );

      final success = await provider.updateTodo(updated);
      final snapshot = await ref.get();

      expect(success, isTrue);
      expect(snapshot.data()?['title'], 'Updated title');
      expect(snapshot.data()?['priority'], 'haut');
      expect(snapshot.data()?['description'], 'Desc updated');
    });

    test('deleteTodo removes document and resets loading', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-delete');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      final ref = firestore.collection('todos').doc('delete-1');
      await ref.set({
        'id': ref.id,
        'title': 'To delete',
        'description': 'Desc',
        'isCompleted': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'userId': 'user-delete',
        'priority': 'moyen',
      });

      final result = await provider.deleteTodo(ref.id);
      final snapshot = await ref.get();

      expect(result, isTrue);
      expect(snapshot.exists, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('deleteCompletedTodos removes only completed entries', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-batch');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      final completedRef = firestore.collection('todos').doc('completed-1');
      final pendingRef = firestore.collection('todos').doc('pending-1');

      await completedRef.set({
        'id': completedRef.id,
        'title': 'Done task',
        'description': 'Finished',
        'isCompleted': true,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'userId': 'user-batch',
        'priority': 'moyen',
      });

      await pendingRef.set({
        'id': pendingRef.id,
        'title': 'Pending task',
        'description': 'Not finished',
        'isCompleted': false,
        'createdAt': DateTime(2024, 1, 2).millisecondsSinceEpoch,
        'userId': 'user-batch',
        'priority': 'moyen',
      });

      provider.startListening();
      await Future.delayed(const Duration(milliseconds: 30));

      final success = await provider.deleteCompletedTodos();
      final remaining = await firestore.collection('todos').get();

      expect(success, isTrue);
      expect(remaining.docs, hasLength(1));
      expect(remaining.docs.first.id, pendingRef.id);
    });

    test('searchTodos matches title or description case-insensitively', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-search');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      Future<void> save(String id, String title, String description) async {
        final ref = firestore.collection('todos').doc(id);
        await ref.set({
          'id': ref.id,
          'title': title,
          'description': description,
          'isCompleted': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'userId': 'user-search',
          'priority': 'moyen',
        });
      }

      await save('todo-1', 'Study Algebra', 'Review equations');
      await save('todo-2', 'Buy groceries', 'milk and bread');
      await save('todo-3', 'Call tom', 'football game plan');

      provider.startListening();
      await Future.delayed(const Duration(milliseconds: 30));

      final results = provider.searchTodos('study');

      expect(results, hasLength(1));
      expect(results.map((t) => t.id), containsAll(['todo-1']));
    });

    test('getStatistics reports totals and completion counts', () async {
      final auth = MockFirebaseAuth();
      final user = MockUser();
      when(user.uid).thenReturn('user-stats');
      when(auth.currentUser).thenReturn(user);
      final provider = TodoProvider(firestore: firestore, auth: auth);

      Future<void> save(String id, bool completed) async {
        final ref = firestore.collection('todos').doc(id);
        await ref.set({
          'id': ref.id,
          'title': 'Task $id',
          'description': 'Desc',
          'isCompleted': completed,
          'completedAt': completed ? DateTime.now().millisecondsSinceEpoch : null,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'userId': 'user-stats',
          'priority': 'moyen',
        });
      }

      await save('todo-1', true);
      await save('todo-2', true);
      await save('todo-3', false);

      provider.startListening();
      await Future.delayed(const Duration(milliseconds: 30));

      final stats = provider.getStatistics();

      expect(stats['total'], 3);
      expect(stats['completed'], 2);
      expect(stats['pending'], 1);
      expect(stats['completionRate'], 67); // rounded integer
    });
  });
}
