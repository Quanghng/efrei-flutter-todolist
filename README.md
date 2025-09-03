# Guide de collaboration Git

## 🚨 Règle importante
**La branche `main` est protégée - ne jamais travailler directement dessus !**

## 📋 Étapes pour contribuer

### 1. Récupérer les dernières modifications
```bash
git checkout main
git pull origin main
```

### 2. Créer votre branche de travail
```bash
git branch nom-de-votre-branche
git checkout nom-de-votre-branche
```
💡 **Astuce :** Utilisez un nom descriptif (ex: `feature/ajout-todo`, `fix/bug-suppression`)

### 3. Travailler sur vos modifications
- Faites vos changements
- Testez votre code
- Commitez régulièrement :
```bash
git add .
git commit -m "Description claire de vos changements"
git push origin nom-de-votre-branche
```

### 4. Intégrer vos modifications
Une fois votre travail terminé :
```bash
git checkout main
git pull origin main
git merge nom-de-votre-branche
```

### 5. Nettoyer (optionnel)
```bash
git branch -d nom-de-votre-branche
```

## ⚠️ En cas de conflits
1. Résolvez les conflits dans votre éditeur / voir avec autre membre du groupe
2. Ajoutez les fichiers résolus : `git add .`
3. Finalisez le merge : `git commit`

---------------------------------------------------------------------------------------------------------------------