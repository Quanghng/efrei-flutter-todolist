import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo.dart';

class TodoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Todo> get todos => _todos;
  List<Todo> get completedTodos => _todos.where((todo) => todo.isCompleted).toList();
  List<Todo> get pendingTodos => _todos.where((todo) => !todo.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalTodos => _todos.length;
  int get completedCount => completedTodos.length;
  int get pendingCount => pendingTodos.length;
  
  // Écouter les changements en temps réel
  void startListening() {
    final user = _auth.currentUser;
    if (user == null) {
      print('TodoProvider: Aucun utilisateur connecté');
      return;
    }

    print('TodoProvider: Début de l\'écoute pour l\'utilisateur ${user.uid}');

    _firestore
        .collection('todos')
        .where('userId', isEqualTo: user.uid)
        // Temporairement commenté en attendant la création de l'index
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('TodoProvider: Reçu ${snapshot.docs.length} todos');
      var todosList = snapshot.docs.map((doc) {
        print('TodoProvider: Todo reçu - ${doc.id}: ${doc.data()}');
        return Todo.fromMap(doc.data());
      }).toList();
      
      // Tri côté client en attendant l'index
      todosList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _todos = todosList;
      notifyListeners();
    }, onError: (error) {
      print('TodoProvider: Erreur lors de l\'écoute - $error');
      _setError('Erreur lors du chargement des todos: $error');
    });
  }

  // Arrêter l'écoute
  void stopListening() {
    _todos = [];
    notifyListeners();
  }

  // Ajouter un todo
  Future<bool> addTodo(String title, String description, [String priority = 'moyen']) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();

      final todoId = _firestore.collection('todos').doc().id;
      final todo = Todo(
        id: todoId,
        title: title,
        description: description,
        isCompleted: false,
        createdAt: DateTime.now(),
        userId: user.uid,
        priority: priority,
      );

      print('TodoProvider: Ajout du todo ${todoId} pour l\'utilisateur ${user.uid}');
      print('TodoProvider: Données du todo - ${todo.toMap()}');

      await _firestore.collection('todos').doc(todoId).set(todo.toMap());

      print('TodoProvider: Todo ajouté avec succès');
      _setLoading(false);
      return true;
    } catch (e) {
      print('TodoProvider: Erreur lors de l\'ajout - $e');
      _setLoading(false);
      _setError('Erreur lors de l\'ajout: $e');
      return false;
    }
  }

  // Mettre à jour un todo
  Future<bool> updateTodo(Todo todo) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('todos').doc(todo.id).update(todo.toMap());

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  // Marquer comme terminé/non terminé
  Future<bool> toggleTodoStatus(String todoId) async {
    try {
      final todoIndex = _todos.indexWhere((t) => t.id == todoId);
      if (todoIndex == -1) return false;

      final todo = _todos[todoIndex];
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
      );

      return await updateTodo(updatedTodo);
    } catch (e) {
      _setError('Erreur lors du changement de statut: $e');
      return false;
    }
  }

  // Supprimer un todo
  Future<bool> deleteTodo(String todoId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('todos').doc(todoId).delete();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Supprimer tous les todos terminés
  Future<bool> deleteCompletedTodos() async {
    try {
      _setLoading(true);
      _clearError();

      final batch = _firestore.batch();
      for (final todo in completedTodos) {
        batch.delete(_firestore.collection('todos').doc(todo.id));
      }
      await batch.commit();

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Rechercher des todos
  List<Todo> searchTodos(String query) {
    if (query.isEmpty) return _todos;
    
    return _todos.where((todo) {
      return todo.title.toLowerCase().contains(query.toLowerCase()) ||
             todo.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Méthodes utilitaires
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Statistiques
  Map<String, dynamic> getStatistics() {
    return {
      'total': totalTodos,
      'completed': completedCount,
      'pending': pendingCount,
      'completionRate': totalTodos > 0 ? (completedCount / totalTodos * 100).round() : 0,
    };
  }
}
