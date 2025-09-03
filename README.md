# 📱 TodoList Flutter - EFREI M2
> **Projet Flutter** - Jérôme Commaret - Septembre 2025

## 🎯 Mission du projet

Créer une **application TodoList complète** avec authentification et base de données Firebase/Firestore.

## 🏆 Barème d'évaluation (20 points)

### 📊 Répartition des points

| **Critère** | **Points** | **Détail** |
|-------------|------------|------------|
| 🔧 **Technique** | **10 pts** |  |
| └ Utilisation professionnelle de Git | 2 | Workflow avec branches (dev/staging/main) |
| └ Propreté du code | 2 | Code clean, bien organisé |
| └ Application fonctionnelle | 4 | Toutes les fonctionnalités opérationnelles |
| └ Esthétique de l'application | 4 | Design soigné, UX/UI réussie |
| └ Fonctionnalités bonus | 2 | Features supplémentaires créatives |
| 🎤 **Présentation** | **6 pts** |  |
| └ Expression orale | 2 | Clarté, maîtrise technique |
| └ Slides de présentation | 2 | Support visuel professionnel |
| └ Démonstration live | 2 | App fonctionnelle en direct |

## ✅ Fonctionnalités obligatoires

### 🔐 **Authentification**
- Inscription utilisateur
- Connexion/Déconnexion
- Gestion des sessions

### 📝 **TodoList**
- Créer des tâches
- Modifier des tâches
- Supprimer des tâches
- Marquer comme terminé/non terminé
- Persistance des données

### 🔥 **Firebase/Firestore**
- Base de données cloud
- Synchronisation temps réel
- Gestion des utilisateurs

## 🛠️ Stack technique imposée

### **Langage & Framework**
- ✅ **Dart** + **Flutter**
- ✅ **Material Design** (interface)

### **Gestion d'état** (au choix)
- 🟢 **Provider** (recommandé - simple)
- 🔶 **BLoC** (complexe mais propre)
- 🔵 **MobX** (réactif)

### **Navigation**
- ✅ Navigation Flutter standard
- 🎯 **GoRouter** (bonus)

### **Backend & Données**
- ✅ **Firebase Core**
- ✅ **Firebase Auth**
- ✅ **Cloud Firestore**

### **Stockage local** (optionnel)
- SharedPreferences (paramètres)
- SQLite/Hive (cache offline)

## 📁 Architecture recommandée

```
lib/
├── main.dart                 # Point d'entrée
├── models/                   # Modèles de données
│   ├── todo.dart
│   └── user.dart
├── providers/                # Gestion d'état
│   ├── auth_provider.dart
│   └── todo_provider.dart
├── screens/                  # Écrans
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home_screen.dart
│   └── todo_screen.dart
├── widgets/                  # Composants réutilisables
├── services/                 # Services Firebase
└── utils/                    # Utilitaires
```

## 🚨 Exigences Git **OBLIGATOIRES**

### **Structure des branches**
```
main (production)    ← NE JAMAIS TRAVAILLER DIRECTEMENT
  ↑
staging (intégration) ← Tests, tout fonctionne
  ↑  
dev (développement)   ← Branche principale de travail
  ↑
feature/xxx          ← Vos branches de fonctionnalités
```

### **Workflow imposé**
1. 🔄 Créer les branches `dev` et `staging`
2. 🌿 Créer vos branches `feature/xxx` depuis `dev`
3. ⬆️ Merger dans `dev` dès que possible
4. 🧪 Tester sur `staging` régulièrement
5. 🚀 Merger sur `main` uniquement quand tout fonctionne

### **⚠️ Contrôles du professeur**
- Le prof peut contrôler **à tout moment**
- `staging` doit **TOUJOURS** fonctionner
- Progression **cohérente et régulière**
- Possible création d'**issues GitHub**

## 👥 Organisation équipe

### **Constitution des groupes**
- 📧 **Max 4 personnes** par groupe
- 📧 Envoyer composition à : `jerome.commaret@intervenants.efrei.net`
- 📧 GitHub du prof : `jcommaret`

### **Livrables attendus**
- Repository GitHub public
- README complet
- Application fonctionnelle
- Présentation (slides)
- Démonstration live

## 🧪 Tests (bonus)

### **Types de tests recommandés**
- **Unit Tests** : logique métier
- **Widget Tests** : interface utilisateur  
- **Integration Tests** : end-to-end

### **Packages utiles**
```yaml
dev_dependencies:
  flutter_test:
  mockito: ^5.4.2
  integration_test:
```

## 🚀 Déploiement (bonus)

### **Plateformes possibles**
- 📱 **Android** (APK/Bundle)
- 🍎 **iOS** (TestFlight/App Store)
- 🌐 **Web** (Firebase Hosting)

## 📚 Ressources clés

### **Documentation officielle**
- [Flutter Docs](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

### **Installation**
- [Guide d'installation Flutter](https://docs.flutter.dev/get-started/install)

## 🎯 Conseils pour réussir

1. **🏃‍♂️ Commencer simple** : TodoList basique puis ajouter les features
2. **🔄 Merger souvent** : Éviter les gros conflits
3. **🎨 Soigner le design** : 4 points sur l'esthétique !
4. **🧪 Tester régulièrement** : Sur `staging` 
5. **📖 Documenter** : README et commentaires
6. **💡 Être créatif** : Fonctionnalités bonus appréciées

---

## 🚀 Getting Started

```bash
# Cloner le projet
git clone https://github.com/Quanghng/efrei-flutter-todolist.git
cd efrei-flutter-todolist

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

**🎓 Bon développement !**
