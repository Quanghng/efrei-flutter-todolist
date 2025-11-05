# Instructions pour appliquer les règles Firestore

## 📋 À faire maintenant dans Firebase Console :

### 1. Ouvrir la Console Firebase
- Aller sur https://console.firebase.google.com/project/taskip-1
- Cliquer sur "Firestore Database" dans le menu de gauche

### 2. Mettre à jour les règles de sécurité
- Cliquer sur l'onglet "Règles" (Rules)
- Remplacer le contenu actuel par :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règles pour la collection todos (structure plate)
    match /todos/{todoId} {
      // Permettre la lecture et l'écriture seulement si l'utilisateur est authentifié
      // et si le todo appartient à l'utilisateur connecté
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      
      // Permettre la création si l'utilisateur est authentifié
      // et si le userId dans le document correspond à l'utilisateur connecté
      allow create: if request.auth != null 
        && request.resource.data.userId == request.auth.uid;
    }
    
    // Règle pour les métadonnées utilisateur (optionnel)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Publier les règles
- Cliquer sur "Publier" pour appliquer les nouvelles règles

## 🔍 Vérifications après application :

1. **Tester l'ajout de todo** : Essayer d'ajouter une tâche depuis l'app
2. **Vérifier dans la console** : Aller dans "Data" pour voir si les todos apparaissent
3. **Consulter les logs** : Dans l'onglet "Usage" pour voir les erreurs potentielles

## 🐛 Si les todos n'apparaissent toujours pas :

1. Vérifier que l'utilisateur est bien connecté
2. Regarder la console du navigateur (F12) pour les erreurs
3. Vérifier que la collection "todos" existe dans Firestore
4. S'assurer que les règles sont bien publiées
