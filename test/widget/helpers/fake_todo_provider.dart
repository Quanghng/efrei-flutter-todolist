import 'package:flutter/foundation.dart';

import 'package:efrei_todolist/models/todo.dart';
import 'package:efrei_todolist/providers/todo_provider.dart';

class FakeTodoProvider extends ChangeNotifier implements TodoProvider {
  final List<Todo> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool listeningStarted = false;
  bool deleteCompletedInvoked = false;
  String? lastDeletedId;
  String? lastToggledId;
  Todo? lastUpdatedTodo;

  void setTodos(Iterable<Todo> todos) {
    _todos
      ..clear()
      ..addAll(todos);
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // TodoProvider interface ---------------------------------------------------

  @override
  List<Todo> get todos => List<Todo>.from(_todos);

  @override
  List<Todo> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).map((e) => e).toList();

  @override
  List<Todo> get pendingTodos =>
      _todos.where((todo) => !todo.isCompleted).map((e) => e).toList();

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  int get totalTodos => _todos.length;

  @override
  int get completedCount => completedTodos.length;

  @override
  int get pendingCount => pendingTodos.length;

  @override
  void clearError() {
    setError(null);
  }

  @override
  void startListening() {
    listeningStarted = true;
  }

  @override
  void stopListening() {
    listeningStarted = false;
    _todos.clear();
    notifyListeners();
  }

  @override
  Future<bool> addTodo(String title, String description, DateTime? dueDate,
      [String priority = 'moyen']) async {
    _todos.add(
      Todo(
        id: 'fake-${_todos.length}',
        title: title,
        description: description,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: 'fake-user',
        priority: priority,
        dueDate: dueDate,
        completedAt: null,
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return false;
    _todos[index] = todo;
    lastUpdatedTodo = todo;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> toggleTodoStatus(String todoId) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index == -1) return false;
    final current = _todos[index];
    lastToggledId = todoId;
    _todos[index] = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: current.isCompleted ? null : DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteTodo(String todoId) async {
    final before = _todos.length;
    _todos.removeWhere((t) => t.id == todoId);
    final removed = before != _todos.length;
    if (removed) {
      lastDeletedId = todoId;
      notifyListeners();
    }
    return removed;
  }

  @override
  Future<bool> deleteCompletedTodos() async {
    deleteCompletedInvoked = true;
    final before = _todos.length;
    _todos.removeWhere((todo) => todo.isCompleted);
    final changed = before != _todos.length;
    if (changed) notifyListeners();
    return changed;
  }

  @override
  List<Todo> searchTodos(String query) {
    if (query.isEmpty) return todos;
    return _todos
        .where((todo) => todo.title.toLowerCase().contains(query.toLowerCase()) ||
            todo.description.toLowerCase().contains(query.toLowerCase()))
        .map((e) => e)
        .toList();
  }

  @override
  Map<String, dynamic> getStatistics() {
    final total = _todos.length;
    final completed = completedTodos.length;
    final pending = total - completed;
    final completionRate = total == 0 ? 0 : (completed / total * 100).round();
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': completionRate,
    };
  }
}
