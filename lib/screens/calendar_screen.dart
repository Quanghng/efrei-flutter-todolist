import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider.dart';

enum Priority {
  faible(1, 'Faible', Colors.green),
  moyen(2, 'Moyen', Colors.orange),
  fort(3, 'Fort', Colors.red);

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

  // Priority ordering (higher = more important)
  // static const Map<String, int> _priorityOrder = {
  //   'fort': 3,
  //   'moyen': 2,
  //   'faible': 1,
  // };

  // static const Map<String, MaterialColor> _priorityColors = {
  //   'fort': Colors.red,
  //   'moyen': Colors.orange,
  //   'faible': Colors.green,
  // };

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
      appBar: AppBar(
        title: const Text('Calendrier des tâches'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
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
      body: Column(
        children: [
          TableCalendar(
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
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dayKey = DateTime(day.year, day.month, day.day);
                final priority = dayPriority[dayKey];
                if (priority != null) {
                  final Color color = Priority.fromString(priority).color;
                  // use withAlpha instead of withOpacity (deprecated)
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: (color as MaterialColor).shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return null; // default rendering
              },
              todayBuilder: (context, day, focusedDay) {
                final dayKey = DateTime(day.year, day.month, day.day);
                final priority = dayPriority[dayKey];
                final Color color = priority != null
                    ? (Priority.fromString(priority).color)
                    : Colors.blue;
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
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
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
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
          const SizedBox(height: 12),
          Expanded(
            child: selectedTodos.isEmpty
                ? Center(
                    child: Text(
                      _selectedDay == null
                          ? 'Sélectionnez une date'
                          : 'Aucune tâche prévue ce jour-là',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedTodos.length,
                    itemBuilder: (context, index) {
                      final todo = selectedTodos[index];
                      final Color color = Priority.fromString(
                        todo.priority,
                      ).color;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
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
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(todo.description),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              todo.priority,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
