# Configuration Firebase - EFREI TodoList

## Accès au projet Firebase

**Nom du projet** : `taskip-1`
**URL Console** : https://console.firebase.google.com/project/taskip-1

## Pour les nouveaux développeurs

### 1. Accès à la console Firebase
- Demander l'ajout de votre email Google au projet
- Rôles disponibles : Editor (recommandé pour les devs), Viewer (pour consultation)

### 2. Configuration locale

Les clés Firebase sont déjà configurées dans le projet. Vous n'avez besoin que de :

```bash
# Cloner le projet
git clone https://github.com/Quanghng/efrei-flutter-todolist.git
cd efrei-flutter-todolist

# Installer les dépendances Flutter
flutter pub get

# Lancer l'app en mode web
flutter run -d web-server
```

### 3. Accès aux services Firebase

#### Authentication
- **Méthodes activées** : Email/Password
- **Domaines autorisés** : localhost, Firebase Hosting
- **Utilisateurs de test** : Créés automatiquement via l'app

#### Firestore Database
- **Mode** : Production (sécurisé)
- **Collection principale** : `todos`
- **Structure** :
  ```
  todos/
    {userId}/
      {todoId}/
        - title: string
        - description: string
        - isCompleted: boolean
        - priority: string
        - createdAt: timestamp
        - updatedAt: timestamp
  ```

#### Règles de sécurité Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Les utilisateurs ne peuvent accéder qu'à leurs propres todos
    match /todos/{userId}/todos/{todoId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Environnements

### Development
- **URL** : http://localhost:60211 (port variable)
- **Base de données** : Firestore Production (isolée par utilisateur)

### Production (à venir)
- **Hosting** : Firebase Hosting
- **URL** : https://taskip-1.web.app

## Commandes utiles

```bash
# Démarrer en mode debug
flutter run -d web-server

# Build pour production
flutter build web

# Déployer sur Firebase Hosting (quand configuré)
firebase deploy --only hosting
```

## Support

**Responsable technique** : Thibaut
**Cours** : EFREI M2 - Prof. Jérôme Commaret
**Repository** : https://github.com/Quanghng/efrei-flutter-todolist
