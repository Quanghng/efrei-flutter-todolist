import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Config
import 'config/theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';

// Screens
import 'screens/landing_page.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAR71SLSuRPlZ-d91szzlewS506qLQVMSI",
      authDomain: "taskip-1.firebaseapp.com",
      projectId: "taskip-1",
      storageBucket: "taskip-1.firebasestorage.app",
      messagingSenderId: "540064083426",
      appId: "1:540064083426:web:0b57a3c595b76cabe3ddbb",
    ),
  );

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Gérer les listeners TodoProvider en fonction de l'état d'authentification
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final todoProvider = Provider.of<TodoProvider>(context, listen: false);
            if (authProvider.user != null) {
              // Utilisateur connecté : démarrer les listeners
              todoProvider.startListening(authProvider.user!);
            } else {
              // Utilisateur déconnecté : arrêter les listeners
              todoProvider.stopListening();
            }
          });

          return MaterialApp(
            title: 'Taskip - EFREI TodoList',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authProvider.user != null ? const HomeScreen() : const LandingPage(),
          );
        },
      ),
    );
  }
}
