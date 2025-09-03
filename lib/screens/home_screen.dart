import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();
    // Commencer à écouter les todos de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().startListening();
    });

    // Écouter les changements de recherche
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredTodos(TodoProvider todoProvider) {
    List<dynamic> filteredTodos;
    
    // Appliquer le filtre de statut
    switch (_filterStatus) {
      case 'completed':
        filteredTodos = todoProvider.completedTodos;
        break;
      case 'pending':
        filteredTodos = todoProvider.pendingTodos;
        break;
      default:
        filteredTodos = todoProvider.todos;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filteredTodos = filteredTodos.where((todo) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               todo.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredTodos;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, _) {
        // Afficher les erreurs s'il y en a
        if (todoProvider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(todoProvider.errorMessage!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    todoProvider.clearError();
                  },
                ),
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'EFREI TodoList',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
        actions: [
          // Bouton pour supprimer les tâches terminées
          Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              return todoProvider.completedTodos.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Supprimer les tâches terminées',
                      onPressed: () => _showDeleteAllCompletedDialog(todoProvider),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // Statistiques
          Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              final stats = todoProvider.getStatistics();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Text(
                    '${stats['completed']}/${stats['total']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final filteredTodos = _getFilteredTodos(todoProvider);

          if (todoProvider.isLoading && todoProvider.todos.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Barre de statistiques
              _buildStatsBar(todoProvider),
              
              // Barre de recherche et filtres
              _buildSearchAndFilters(),
              
              // Liste des todos ou état vide
              Expanded(
                child: filteredTodos.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTodos.length,
                        itemBuilder: (context, index) {
                          final todo = filteredTodos[index];
                          return _buildTodoItem(todo, todoProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    
    if (_searchQuery.isNotEmpty) {
      message = 'Aucun résultat';
      subtitle = 'Aucune tâche ne correspond à "${_searchQuery}"';
    } else if (_filterStatus == 'completed') {
      message = 'Aucune tâche terminée';
      subtitle = 'Les tâches terminées apparaîtront ici';
    } else if (_filterStatus == 'pending') {
      message = 'Aucune tâche en cours';
      subtitle = 'Parfait ! Toutes vos tâches sont terminées';
    } else {
      message = 'Aucune tâche pour le moment';
      subtitle = 'Appuyez sur + pour ajouter votre première tâche';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.checklist_rounded,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(TodoProvider todoProvider) {
    final stats = todoProvider.getStatistics();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          _buildStatItem('Total', stats['total'].toString(), Colors.blue),
          const SizedBox(width: 24),
          _buildStatItem('Terminées', stats['completed'].toString(), Colors.green),
          const SizedBox(width: 24),
          _buildStatItem('En cours', stats['pending'].toString(), Colors.orange),
          const Spacer(),
          Text(
            '${stats['completionRate']}% terminé',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une tâche...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('En cours', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Terminées', 'completed'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade800,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(todo, TodoProvider todoProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (value) {
            todoProvider.toggleTodoStatus(todo.id);
          },
          activeColor: Colors.green,
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                todo.description,
                style: TextStyle(
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey : Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(todo.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditTodoDialog(todo, todoProvider);
                break;
              case 'delete':
                _showDeleteDialog(todo.id, todoProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddTodoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle tâche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                context.read<TodoProvider>().addTodo(
                  titleController.text.trim(),
                  descriptionController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(todo, TodoProvider todoProvider) {
    final titleController = TextEditingController(text: todo.title);
    final descriptionController = TextEditingController(text: todo.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la tâche'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final updatedTodo = todo.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                todoProvider.updateTodo(updatedTodo);
                Navigator.pop(context);
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String todoId, TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              todoProvider.deleteTodo(todoId);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllCompletedDialog(TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les tâches terminées'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer les ${todoProvider.completedTodos.length} tâche(s) terminée(s) ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              todoProvider.deleteCompletedTodos();
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TodoProvider>().stopListening();
              context.read<AuthProvider>().signOut();
              Navigator.pop(context);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
