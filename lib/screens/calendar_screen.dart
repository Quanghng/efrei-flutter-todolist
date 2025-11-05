import 'package:efrei_todolist/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../config/theme.dart'; // Assuming your theme file is here
import '../providers/todo_provider.dart';

// Using the same Priority enum as in home_screen.dart for consistency
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

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Utility: compare if same day ignoring time
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final todos = todoProvider.todos;

    // Build map of day -> highest priority string
    final Map<DateTime, String> dayPriority = {};
    for (var todo in todos) {
      if (todo.dueDate == null) continue;
      final day = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      final current = dayPriority[day];
      if (current == null ||
          (Priority.fromString(todo.priority).value) >
              (Priority.fromString(current).value)) {
        dayPriority[day] = todo.priority;
      }
    }

    // Todos for the selected date
    final selectedTodos = todos.where((todo) {
      if (todo.dueDate == null || _selectedDay == null) return false;
      return _isSameDay(todo.dueDate!, _selectedDay!);
    }).toList();

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
            const SizedBox(width: 23),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text(
                'Tâches',
                style: TextStyle(color: Colors.white, fontSize: 18),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
                      onPressed: () =>
                          _showDeleteAllCompletedDialog(todoProvider),
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
      body: Column(
        children: [
          // Calendar Widget
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null ? _isSameDay(_selectedDay!, day) : false,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppColors.primaryRose,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primaryRose,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryRose,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                // Days with tasks
                defaultBuilder: (context, day, focusedDay) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  final priorityString = dayPriority[dayKey];
                  if (priorityString != null) {
                    final priority = Priority.fromString(priorityString);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: priority.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: priority.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return null; // default rendering for other days
                },
                // Today's date
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryRose,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: AppColors.primaryRose),
                    ),
                  );
                },
                // Selected date
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRose,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List of tasks for the selected day
          Expanded(
            child: selectedTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsBold.calendarCheck,
                          size: 80,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDay == null
                              ? 'Sélectionnez une date'
                              : 'Aucune tâche prévue ce jour-là',
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: selectedTodos.length,
                    itemBuilder: (context, index) {
                      final todo = selectedTodos[index];
                      return _buildTodoListItem(todo, todoProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Styled task item widget
  Widget _buildTodoListItem(dynamic todo, TodoProvider todoProvider) {
    final priority = Priority.fromString(todo.priority ?? 'moyen');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: AppColors.grey400.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: priority.color.withOpacity(0.3), width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (value) {
            todoProvider.toggleTodoStatus(todo.id);
          },
          activeColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? AppColors.grey500 : AppColors.black,
          ),
        ),
        subtitle: todo.description.isNotEmpty ? Text(todo.description) : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: priority.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            priority.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
            child: Text('Annuler', style: TextStyle(color: AppColors.grey700)),
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
            child: Text('Annuler', style: TextStyle(color: AppColors.grey700)),
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
