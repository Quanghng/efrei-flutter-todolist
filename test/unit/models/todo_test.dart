import 'package:test/test.dart';

import 'package:efrei_todolist/models/todo.dart';

void main() {
  group('Todo model', () {
    final baseTodo = Todo(
      id: 'todo-1',
      title: 'Flutter',
      description: 'Flutter123',
      isCompleted: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1),
      completedAt: null,
      userId: 'user-123',
      priority: 'moyen',
      dueDate: DateTime.fromMillisecondsSinceEpoch(2),
    );

    test('toMap preserves every field', () {
      final map = baseTodo.toMap();

      expect(map['id'], baseTodo.id);
      expect(map['title'], baseTodo.title);
      expect(map['description'], baseTodo.description);
      expect(map['isCompleted'], baseTodo.isCompleted);
      expect(map['createdAt'], baseTodo.createdAt.millisecondsSinceEpoch);
      expect(map['completedAt'], baseTodo.completedAt);
      expect(map['userId'], baseTodo.userId);
      expect(map['priority'], baseTodo.priority);
      expect(map['dueDate'], baseTodo.dueDate!.millisecondsSinceEpoch);
    });

    test('fromMap restores the same values', () {
      final map = baseTodo.toMap();

      final restored = Todo.fromMap(map);

      expect(restored.id, baseTodo.id);
      expect(restored.title, baseTodo.title);
      expect(restored.description, baseTodo.description);
      expect(restored.isCompleted, baseTodo.isCompleted);
      expect(restored.createdAt, baseTodo.createdAt);
      expect(restored.completedAt, baseTodo.completedAt);
      expect(restored.userId, baseTodo.userId);
      expect(restored.priority, baseTodo.priority);
      expect(restored.dueDate, baseTodo.dueDate);
    });

    test('copyWith overrides only provided values', () {
      final updated = baseTodo.copyWith(
        title: 'Flutter 456',
        isCompleted: true,
        completedAt: DateTime.fromMillisecondsSinceEpoch(3),
      );

      expect(updated.title, 'Flutter 456');
      expect(updated.isCompleted, isTrue);
      expect(updated.completedAt!.millisecondsSinceEpoch, 3);

      // unchanged fields stay identical
      expect(updated.id, baseTodo.id);
      expect(updated.description, baseTodo.description);
      expect(updated.userId, baseTodo.userId);
    });

    test('== and hashCode use the id', () {
      final other = baseTodo.copyWith();
      final different = baseTodo.copyWith(id: 'todo-2');

      expect(baseTodo, equals(other));
      expect(baseTodo.hashCode, equals(other.hashCode));
      expect(baseTodo == different, isFalse);
    });
  });
}
