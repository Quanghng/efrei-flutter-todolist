# Configuration des Index Firestore

## 🎯 Problème rencontré

L'erreur `The query requires an index` indique que Firestore nécessite un index composite pour optimiser votre requête qui combine :
- `userId` (filtre WHERE)  
- `createdAt` (tri ORDER BY)

## ✅ Solutions appliquées

### Solution temporaire (en cours)
- Requête sans `orderBy`
- Tri côté client avec `sort()`
- Permet à l'app de fonctionner immédiatement

### Solution définitive (à faire)

#### 1. Créer l'index automatiquement
Cliquer sur ce lien (généré par Firebase) :
```
https://console.firebase.google.com/v1/r/project/taskip-1/firestore/indexes?create_composite=CkZwcm9qZWN0cy90YXNraXAtMS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdG9kb3MvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

#### 2. Ou créer manuellement dans la Console Firebase
1. Aller sur https://console.firebase.google.com/project/taskip-1/firestore
2. Cliquer sur "Index" dans le menu de gauche
3. Cliquer "Créer un index"
4. Configuration :
   - **Collection** : `todos`
   - **Champs** :
     - `userId` : Ascending
     - `createdAt` : Descending
   - **Statut de la requête** : Enabled
5. Cliquer "Créer"

## ⏱️ Temps de création
- L'index prend **2-5 minutes** à se créer
- Statut visible dans la console : "Building" → "Enabled"

## 🔄 Après création de l'index

Remettre la requête optimale dans `todo_provider.dart` :

```dart
_firestore
    .collection('todos')
    .where('userId', isEqualTo: user.uid)
    .orderBy('createdAt', descending: true) // ← Remettre cette ligne
    .snapshots()
```

## 📊 Index recommandés pour l'app

```javascript
// Index composite pour la requête principale
Collection: todos
Fields: userId (Ascending), createdAt (Descending)

// Index simple pour les filtres (automatiques)
Collection: todos  
Field: userId (Ascending)
Field: createdAt (Descending)
Field: isCompleted (Ascending)
```

## 🐛 Dépannage

Si l'index ne fonctionne pas :
1. Vérifier le statut dans la console (Building/Enabled)  
2. Attendre quelques minutes supplémentaires
3. Redémarrer l'application Flutter
4. Vérifier les règles de sécurité Firestore
