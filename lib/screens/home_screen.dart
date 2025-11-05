import 'package:efrei_todolist/screens/calendar_screen.dart';
import 'package:efrei_todolist/screens/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';
import '../config/theme.dart';

enum Priority {
  faible(1, 'Faible', Color(0xFF4CAF50)),
  moyen(2, 'Moyen', Color(0xFFFF9800)),
  fort(3, 'Fort', Color(0xFFE57373));

  const Priority(this.value, this.label, this.color);
  final int value;
  final String label;
  final Color color;

  static Priority fromString(String str) {
    switch (str.toLowerCase()) {
      case 'faible':
        return Priority.faible;
      case 'moyen':
        return Priority.moyen;
      case 'fort':
        return Priority.fort;
      default:
        return Priority.moyen;
    }
  }
}

enum SortOption {
  dateDesc('Date (récent → ancien)', 'date', true, PhosphorIconsBold.calendarBlank),
  dateAsc('Date (ancien → récent)', 'date', false, PhosphorIconsBold.calendar),
  priorityDesc('Priorité (fort → faible)', 'priority', true, PhosphorIconsBold.arrowUp),
  priorityAsc('Priorité (faible → fort)', 'priority', false, PhosphorIconsBold.arrowDown),
  statusPendingFirst('Statut (en attente → terminé)', 'status', false, PhosphorIconsBold.checkCircle);

  const SortOption(this.label, this.type, this.descending, this.icon);
  final String label;
  final String type;
  final bool descending;
  final IconData icon;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'
  SortOption _currentSort = SortOption.dateDesc;
  int _selectedIndex = 0; // 0: Toutes, 1: En cours, 2: Terminées

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
      case 'community':
        // Afficher uniquement les tâches publiques de tous les utilisateurs
        filteredTodos = todoProvider.publicTodos;
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

    // Trier selon l'option choisie
    if (_currentSort.type == 'date') {
      filteredTodos.sort((a, b) {
        if (_currentSort.descending) {
          return b.createdAt.compareTo(a.createdAt); // Plus récentes en premier
        } else {
          return a.createdAt.compareTo(
            b.createdAt,
          ); // Plus anciennes en premier
        }
      });
    } else if (_currentSort.type == 'status') {
      filteredTodos.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return a.isCompleted ? 1 : -1;
      });
    } else {
      // Tri par priorité
      filteredTodos.sort((a, b) {
        final priorityA = Priority.fromString(a.priority ?? 'moyen');
        final priorityB = Priority.fromString(b.priority ?? 'moyen');

        if (_currentSort.descending) {
          return priorityB.value.compareTo(priorityA.value); // Fort -> Faible
        } else {
          return priorityA.value.compareTo(priorityB.value); // Faible -> Fort
        }
      });
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset(
                    'assets/images/Taskip_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Taskip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryRose,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Statistiques
              Consumer<TodoProvider>(
                builder: (context, todoProvider, _) {
                  final stats = todoProvider.getStatistics();
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsBold.checkCircle, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${stats['completed']}/${stats['total']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Bouton pour supprimer les tâches terminées
              Consumer<TodoProvider>(
                builder: (context, todoProvider, _) {
                  return todoProvider.completedTodos.isNotEmpty
                      ? IconButton(
                          icon: Icon(PhosphorIconsBold.trash),
                          tooltip: 'Supprimer les tâches terminées',
                          onPressed: () => _showDeleteAllCompletedDialog(todoProvider),
                        )
                      : const SizedBox.shrink();
                },
              ),
              // Bouton de déconnexion
              IconButton(
                icon: Icon(PhosphorIconsBold.signOut),
                tooltip: 'Se déconnecter',
                onPressed: () {
                  _showLogoutDialog();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
      body: Builder(
        builder: (context) {
          final filteredTodos = _getFilteredTodos(todoProvider);

          if (todoProvider.isLoading && todoProvider.todos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Sidebar gauche - Recherche et filtres
                    _buildLeftSidebar(todoProvider),
                    
                    // Zone centrale - Grille de tâches
                    Expanded(
                      child: Column(
                        children: [
                          // Grille de tâches ou état vide
                          Expanded(
                            child: filteredTodos.isEmpty
                                ? _buildEmptyState()
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Responsive: ajuster le nombre de colonnes selon la largeur
                                      int crossAxisCount = 2;
                                      if (constraints.maxWidth > 1200) {
                                        crossAxisCount = 3;
                                      } else if (constraints.maxWidth > 800) {
                                        crossAxisCount = 2;
                                      } else {
                                        crossAxisCount = 1;
                                      }
                                      
                                      return SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                                        child: _buildMasonryGrid(filteredTodos, crossAxisCount, todoProvider),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Sidebar droite - Formulaire de création
                    _buildRightSidebar(todoProvider),
                  ],
                ),
              ),
              
              // Footer de navigation
              _buildBottomNavigationBar(),
            ],
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildMasonryGrid(List todos, int columns, TodoProvider todoProvider) {
    // Distribuer les tâches dans les colonnes
    List<List> columnTodos = List.generate(columns, (_) => []);
    for (int i = 0; i < todos.length; i++) {
      columnTodos[i % columns].add(todos[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columns, (columnIndex) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: columnIndex == 0 ? 0 : 6,
              right: columnIndex == columns - 1 ? 0 : 6,
            ),
            child: Column(
              children: columnTodos[columnIndex].map((todo) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTodoCard(todo, todoProvider),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLeftSidebar(TodoProvider todoProvider) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _selectedIndex == 3 ? 'Communauté' : 'Recherche & Filtres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRose,
              ),
            ),
          ),
          
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(color: AppColors.grey500, fontSize: 14),
                prefixIcon: Icon(PhosphorIconsBold.magnifyingGlass, color: AppColors.primaryRose, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(PhosphorIconsBold.x, color: AppColors.grey600, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Tri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Options de tri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Options de tri
          _buildSortItem(SortOption.dateDesc),
          _buildSortItem(SortOption.dateAsc),
          _buildSortItem(SortOption.priorityDesc),
          _buildSortItem(SortOption.priorityAsc),
          // Afficher le filtre par statut seulement sur "Toutes les tâches"
          if (_selectedIndex == 0)
            _buildSortItem(SortOption.statusPendingFirst),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSortItem(SortOption sortOption) {
    final isSelected = _currentSort == sortOption;
    return InkWell(
      onTap: () {
        setState(() {
          _currentSort = sortOption;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRose.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRose : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              sortOption.icon,
              color: isSelected ? AppColors.primaryRose : AppColors.grey600,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sortOption.label,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryRose : AppColors.grey700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar(TodoProvider todoProvider) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildAddTodoForm(todoProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTodoForm(TodoProvider todoProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Priority selectedPriority = Priority.moyen;
    DateTime? selectedDate;
    bool isPublic = false; // Private par défaut

    return StatefulBuilder(
      builder: (context, setFormState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              'Création de tâche',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRose,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Champ Titre
            Text(
              'Titre *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Finir le projet...',
                hintStyle: TextStyle(color: AppColors.grey500, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Champ Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Détails de la tâche...',
                hintStyle: TextStyle(color: AppColors.grey500, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Priorité
            Text(
              'Priorité *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: Priority.values.map((priority) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setFormState(() {
                        selectedPriority = priority;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedPriority == priority
                            ? priority.color.withOpacity(0.1)
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedPriority == priority
                              ? priority.color
                              : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            priority.label,
                            style: TextStyle(
                              color: selectedPriority == priority
                                  ? priority.color
                                  : AppColors.grey700,
                              fontWeight: selectedPriority == priority
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Date d'échéance
            Text(
              'Date d\'échéance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primaryRose,
                          onPrimary: Colors.white,
                          onSurface: AppColors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setFormState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsBold.calendar, color: AppColors.primaryRose, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      selectedDate == null
                          ? 'Choisir une date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: TextStyle(
                        color: selectedDate == null ? AppColors.grey600 : AppColors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Accessibilité
            Text(
              'Accessibilité',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Bouton Private
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setFormState(() {
                        isPublic = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isPublic ? AppColors.primaryRose : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isPublic ? AppColors.primaryRose : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIconsBold.lock,
                            color: !isPublic ? Colors.white : AppColors.grey600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Privé',
                            style: TextStyle(
                              color: !isPublic ? Colors.white : AppColors.grey700,
                              fontWeight: !isPublic ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Public
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setFormState(() {
                        isPublic = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isPublic ? AppColors.primaryRose : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPublic ? AppColors.primaryRose : AppColors.grey300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIconsBold.globe,
                            color: isPublic ? Colors.white : AppColors.grey600,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Public',
                            style: TextStyle(
                              color: isPublic ? Colors.white : AppColors.grey700,
                              fontWeight: isPublic ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bouton Créer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  
                  // Si la tâche est publique, afficher une confirmation
                  if (isPublic) {
                    _showPublicTaskWarning(
                      context,
                      () {
                        // Callback pour créer la tâche après confirmation
                        _createTodo(
                          todoProvider,
                          titleController,
                          descriptionController,
                          selectedDate,
                          selectedPriority,
                          isPublic,
                          setFormState,
                        );
                      },
                    );
                  } else {
                    // Créer directement si privé
                    _createTodo(
                      todoProvider,
                      titleController,
                      descriptionController,
                      selectedDate,
                      selectedPriority,
                      isPublic,
                      setFormState,
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsBold.plus, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Créer la tâche',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
            _searchQuery.isNotEmpty
                ? PhosphorIconsBold.magnifyingGlass
                : PhosphorIconsBold.listChecks,
            size: 100,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(TodoProvider todoProvider) {
    final stats = todoProvider.getStatistics();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey400.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItemCompact('Total', stats['total'].toString(), AppColors.primaryRose),
            Container(width: 1, height: 30, color: AppColors.grey300),
            _buildStatItemCompact('Terminées', stats['completed'].toString(), AppColors.success),
            Container(width: 1, height: 30, color: AppColors.grey300),
            _buildStatItemCompact('En cours', stats['pending'].toString(), AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemCompact(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildNavButton('Toutes', 'all', PhosphorIconsBold.listChecks),
            ),
            Expanded(
              child: _buildNavButton('En cours', 'pending', PhosphorIconsBold.clockCountdown),
            ),
            Expanded(
              child: _buildNavButton('Terminées', 'completed', PhosphorIconsBold.checkCircle),
            ),
            Expanded(
              child: _buildNavButton('Communauté', 'community', PhosphorIconsBold.users),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = value;
          // Synchroniser _selectedIndex avec _filterStatus
          if (value == 'all') {
            _selectedIndex = 0;
          } else if (value == 'pending') {
            _selectedIndex = 1;
          } else if (value == 'completed') {
            _selectedIndex = 2;
          } else if (value == 'community') {
            _selectedIndex = 3;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRose : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isSelected ? AppColors.primaryRose : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.grey600,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(todo, TodoProvider todoProvider) {
    final priority = Priority.fromString(todo.priority ?? 'moyen');
    final bool isOverdue =
        todo.dueDate != null &&
        !todo.isCompleted &&
        todo.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    // Calculer les jours restants
    int? daysRemaining;
    if (todo.dueDate != null && !todo.isCompleted) {
      daysRemaining = todo.dueDate!.difference(DateTime.now()).inDays;
    }

    return GestureDetector(
      onTap: () => _showTodoDetailsDialog(todo),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priority.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: priority.color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Badges en haut à droite (Public + Priorité)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge "Public" si la tâche est publique
                  if (todo.isPublic) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsBold.globe,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Public',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Badge de priorité
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priority.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priority.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Boutons d'action en haut à gauche
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  // Bouton de suppression
                  GestureDetector(
                    onTap: () => _showDeleteDialog(todo.id, todoProvider),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIconsBold.trash,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Bouton d'édition
                  GestureDetector(
                    onTap: () => _showEditTodoDialog(todo, todoProvider),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        PhosphorIconsBold.pencilSimple,
                        color: AppColors.primaryRose,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu de la carte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30), // Espace pour les badges
                  
                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: todo.isCompleted,
                        onChanged: (value) {
                          todoProvider.toggleTodoStatus(todo.id);
                        },
                        activeColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                            color: todo.isCompleted ? AppColors.grey500 : AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (todo.description.isNotEmpty) ...[
                    Text(
                      todo.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: todo.isCompleted ? AppColors.grey500 : AppColors.grey700,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Date d'échéance avec jours restants
                  if (todo.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? AppColors.error.withOpacity(0.1) : AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsBold.clock,
                            color: isOverdue ? AppColors.error : AppColors.grey600,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? AppColors.error : AppColors.grey700,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (daysRemaining != null && !isOverdue) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${daysRemaining > 0 ? "$daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}" : "Aujourd'hui"})',
                              style: TextStyle(
                                fontSize: 10,
                                color: daysRemaining <= 1 ? AppColors.warning : AppColors.grey600,
                                fontWeight: daysRemaining <= 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Date de création
                  Text(
                    'Créé le ${_formatDate(todo.createdAt)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.grey500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(todo, TodoProvider todoProvider) {
    final priority = Priority.fromString(todo.priority ?? 'moyen');

    final bool isOverdue =
        todo.dueDate != null &&
        !todo.isCompleted &&
        todo.dueDate!.isBefore(
          DateTime.now().subtract(const Duration(days: 1)),
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey200, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRose.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de priorité
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: priority.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: todo.isCompleted,
                onChanged: (value) {
                  todoProvider.toggleTodoStatus(todo.id);
                },
                activeColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted ? AppColors.grey500 : AppColors.black,
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
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: todo.isCompleted ? AppColors.grey500 : AppColors.grey700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Due date
              if (todo.dueDate != null) ...[
                Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.clock,
                      color: isOverdue ? AppColors.error : AppColors.grey600,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance: ${_formatDate(todo.dueDate!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? AppColors.error : AppColors.grey600,
                        fontWeight: isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(
                    PhosphorIconsBold.calendar,
                    color: AppColors.grey600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Crée: ${_formatDate(todo.createdAt)}',
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priorité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priority.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priority.color.withOpacity(0.3)),
              ),
              child: Text(
                priority.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: priority.color,
                ),
              ),
            ),
            PopupMenuButton<String>(
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
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.pencil, color: AppColors.primaryRose),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.trash, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddTodoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Priority selectedPriority = Priority.moyen;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(PhosphorIconsBold.plus, color: AppColors.primaryRose),
              SizedBox(width: 12),
              Text(
                'Nouvelle tâche',
                style: TextStyle(
                  color: AppColors.primaryRose,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Titre *',
                  labelStyle: TextStyle(color: AppColors.grey700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  labelStyle: TextStyle(color: AppColors.grey700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Sélecteur de priorité
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priorité *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: Priority.values.map((priority) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              priority.label,
                              style: TextStyle(
                                color: selectedPriority == priority
                                    ? Colors.white
                                    : priority.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: selectedPriority == priority,
                            selectedColor: priority.color,
                            backgroundColor: priority.color.withOpacity(0.1),
                            showCheckmark: false,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedPriority = priority;
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              //Sélecteur de date d'échéance
              Row(
                children: [
                  Icon(PhosphorIconsBold.calendar, color: AppColors.grey700),
                  SizedBox(width: 8),
                  Text(
                    selectedDate == null
                        ? 'Date d\'échéance'
                        : 'Échéance: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey800,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(PhosphorIconsBold.calendarPlus, size: 18),
                    label: Text('Choisir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryRose,
                                onPrimary: Colors.white,
                                onSurface: AppColors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != selectedDate) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.grey700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRose,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  // Vous devez modifier votre méthode addTodo pour accepter la priorité
                  context.read<TodoProvider>().addTodo(
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    selectedDate,
                    selectedPriority.label,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTodoDialog(todo, TodoProvider todoProvider) {
    final titleController = TextEditingController(text: todo.title);
    final descriptionController = TextEditingController(text: todo.description);
    Priority selectedPriority = Priority.fromString(todo.priority);
    DateTime? selectedDate = todo.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(PhosphorIconsBold.pencil, color: AppColors.primaryRose),
                SizedBox(width: 12),
                Text(
                  'Modifier la tâche',
                  style: TextStyle(
                    color: AppColors.primaryRose,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre *',
                    labelStyle: TextStyle(color: AppColors.grey700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optionnel)',
                    labelStyle: TextStyle(color: AppColors.grey700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryRose, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priorité *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: Priority.values.map((priority) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(
                                priority.label,
                                style: TextStyle(
                                  color: selectedPriority == priority
                                      ? Colors.white
                                      : priority.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: selectedPriority == priority,
                              selectedColor: priority.color,
                              backgroundColor: priority.color.withOpacity(0.1),
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  setDialogState(() {
                                    selectedPriority = priority;
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sélecteur de date d'échéance
                Row(
                  children: [
                    Icon(PhosphorIconsBold.calendar, color: AppColors.grey700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Date d\'échéance'
                            : 'Échéance: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey800,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(PhosphorIconsBold.calendarPlus, size: 18),
                      label: Text('Modifier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryRose,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.grey700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRose,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final updatedTodo = todo.copyWith(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      dueDate: selectedDate,
                      priority: selectedPriority.label,
                    );
                    todoProvider.updateTodo(updatedTodo);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Modifier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTodoDetailsDialog(todo) {
    final priority = Priority.fromString(todo.priority ?? 'moyen');
    final bool isOverdue =
        todo.dueDate != null &&
        !todo.isCompleted &&
        todo.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    int? daysRemaining;
    if (todo.dueDate != null && !todo.isCompleted) {
      daysRemaining = todo.dueDate!.difference(DateTime.now()).inDays;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec titre et statut
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Badge de priorité
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: priority.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Priorité: ${priority.label}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: todo.isCompleted ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todo.isCompleted ? 'Terminée' : 'En cours',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Description
              if (todo.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.grey800,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Informations importantes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryRose.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryRose.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Date de création
                    Row(
                      children: [
                        Icon(PhosphorIconsBold.calendarPlus, color: AppColors.primaryRose, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Créé le: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey700,
                          ),
                        ),
                        Text(
                          _formatDate(todo.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey800,
                          ),
                        ),
                      ],
                    ),
                    
                    // Date d'échéance
                    if (todo.dueDate != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsBold.clock,
                            color: isOverdue ? AppColors.error : AppColors.primaryRose,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Échéance: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey700,
                            ),
                          ),
                          Text(
                            _formatDate(todo.dueDate!),
                            style: TextStyle(
                              fontSize: 14,
                              color: isOverdue ? AppColors.error : AppColors.grey800,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (daysRemaining != null && !isOverdue) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${daysRemaining > 0 ? "$daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}" : "Aujourd'hui"})',
                              style: TextStyle(
                                fontSize: 12,
                                color: daysRemaining <= 1 ? AppColors.warning : AppColors.grey600,
                                fontWeight: daysRemaining <= 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour créer une tâche
  void _createTodo(
    TodoProvider todoProvider,
    TextEditingController titleController,
    TextEditingController descriptionController,
    DateTime? selectedDate,
    Priority selectedPriority,
    bool isPublic,
    StateSetter setFormState,
  ) {
    // Capturer la valeur avant de réinitialiser
    final wasPublic = isPublic;
    
    todoProvider.addTodo(
      titleController.text.trim(),
      descriptionController.text.trim(),
      selectedDate,
      selectedPriority.label.toLowerCase(),
      isPublic,
    );
    
    titleController.clear();
    descriptionController.clear();
    setFormState(() {
      // Réinitialiser à privé (la réinitialisation de selectedPriority et selectedDate 
      // sera gérée dans le StatefulBuilder parent si nécessaire)
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasPublic ? 'Tâche publique créée avec succès !' : 'Tâche créée avec succès !'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Popup d'avertissement pour les tâches publiques
  void _showPublicTaskWarning(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIconsBold.warningCircle, color: AppColors.accentOrange, size: 28),
            SizedBox(width: 12),
            Text(
              'Tâche publique',
              style: TextStyle(
                color: AppColors.accentOrange,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de créer une tâche publique.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsBold.globe,
                    color: AppColors.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette tâche sera visible par tous les utilisateurs de l\'application dans l\'onglet Communauté.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Êtes-vous sûr de vouloir continuer ?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.grey700, fontSize: 15),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'Créer en public',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String todoId, TodoProvider todoProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIconsBold.trash, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'Supprimer la tâche',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.grey700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIconsBold.trash, color: AppColors.error),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimer les tâches terminées',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer les ${todoProvider.completedTodos.length} tâche(s) terminée(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.grey700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(PhosphorIconsBold.signOut, color: AppColors.primaryRose),
            SizedBox(width: 12),
            Text(
              'Déconnexion',
              style: TextStyle(
                color: AppColors.primaryRose,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.grey700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRose,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              context.read<TodoProvider>().stopListening();
              await context.read<AuthProvider>().signOut();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                (route) => false,
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
