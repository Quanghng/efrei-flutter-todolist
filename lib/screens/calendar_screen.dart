import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import if you need navigation back to HomeScreen

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'EFREI Taskip',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 23),
            // Top navigation menu
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              child: const Text(
                'Tâches',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Calendrier',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Calendrier à venir...',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
