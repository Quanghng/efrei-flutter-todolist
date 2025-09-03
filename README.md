# EFREI TodoList - Flutter Web App

Application TodoList développée en Flutter pour le cours M2 EFREI avec le professeur Jérôme Commaret.

## 🎯 Objectifs pédagogiques

- Développement d'une application Flutter Web
- Intégration Firebase (Authentication + Firestore)
- Gestion d'état avec Provider
- Architecture MVVM
- Git workflow avec branches

## 🚀 Démarrage rapide

### Prérequis
- Flutter SDK 3.35.2+
- Git
- Accès au projet Firebase `taskip-1`

### Installation pour l'équipe

```bash
# 1. Cloner le projet
git clone https://github.com/Quanghng/efrei-flutter-todolist.git
cd efrei-flutter-todolist

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run -d web-server
```

### Accès Firebase

**Important** : Demander l'ajout de votre email Google au projet Firebase `taskip-1`.

Voir le fichier [FIREBASE_SETUP.md](FIREBASE_SETUP.md) pour les détails complets.

## 📱 Fonctionnalités

- ✅ Authentification (inscription/connexion)
- ✅ Gestion des todos (CRUD)
- ✅ Priorités et filtres
- ✅ Synchronisation temps réel
- ✅ Interface responsive Material Design

## 🏗️ Architecture

```
lib/
├── main.dart                 # Point d'entrée + Config Firebase
├── models/
│   └── todo.dart            # Modèle de données Todo
├── providers/
│   ├── auth_provider.dart   # Gestion authentification
│   └── todo_provider.dart   # Gestion des todos
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    └── home_screen.dart     # Interface principale
```

## 🔧 Technologies utilisées

- **Flutter Web** : Framework principal
- **Firebase Auth** : Authentification utilisateur
- **Cloud Firestore** : Base de données NoSQL
- **Provider** : Gestion d'état
- **Material Design** : Interface utilisateur

## 📋 Workflow Git

```bash
# Branches principales
main       # Production
staging    # Pré-production  
dev        # Développement
feature/*  # Fonctionnalités

# Workflow
git checkout dev
git checkout -b feature/ma-fonctionnalite
# ... développement ...
git add .
git commit -m "feat: ma nouvelle fonctionnalité"
git push origin feature/ma-fonctionnalite
# ... Pull Request vers dev ...
```
