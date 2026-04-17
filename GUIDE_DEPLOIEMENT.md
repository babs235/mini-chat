# 🚀 GUIDE DE DÉPLOIEMENT

## Mini-Chat - Processus Complet Documenté

---

## 📖 TABLE DES MATIÈRES

1. [Prérequis](#1-prérequis)
2. [Infrastructure AWS (Terraform)](#2-infrastructure-aws-terraform)
3. [Déploiement Application](#3-déploiement-application)
4. [Dépannage](#4-dépannage)
5. [Commandes Rapides](#5-commandes-rapides)

---

## 1. PRÉREQUIS

### 1.1 Outils nécessaires
```bash
# Sur votre machine locale
- Git
- Terraform v1.5+
- AWS CLI configuré
- Clé SSH (mini-chat-key.pem)
```

### 1.2 Configuration AWS
```bash
aws configure
# AWS Access Key ID: [votre_access_key]
# AWS Secret Access Key: [votre_secret_key]
# Default region: eu-west-3 (Paris)
# Default output format: json
```

---

## 2. INFRASTRUCTURE AWS (TERRAFORM)

### 2.1 Déploiement Initial

```bash
# 1. Se placer dans le dossier terraform
cd terraform/

# 2. Initialiser Terraform
terraform init

# 3. Vérifier le plan
terraform plan

# 4. Déployer (prend ~5 minutes)
terraform apply -auto-approve

# 5. Récupérer l'IP publique
terraform output ec2_public_ip
# Exemple: 13.38.35.35
```

### 2.2 Sorties Terraform

| Output | Description | Exemple |
|--------|-------------|---------|
| `ec2_public_ip` | IP serveur EC2 | 13.38.35.35 |
| `rds_endpoint` | Endpoint base de données | mini-chat-db.xxx.eu-west-3.rds.amazonaws.com |

---

## 3. DÉPLOIEMENT APPLICATION

### 3.1 Première Installation (User Data)

L'instance EC2 démarre automatiquement avec le script `user-data.sh` qui :
1. Installe Docker et Docker Compose
2. Clone le repository
3. Lance les containers

**Vérification après 3-4 minutes :**

```bash
# Se connecter en SSH
ssh -i ~/.ssh/mini-chat-key.pem ubuntu@13.38.35.35

# Vérifier les containers
docker ps

# Résultat attendu:
# CONTAINER ID   IMAGE       STATUS          PORTS
# xxxxxxxx       backend     Up 2 minutes    0.0.0.0:3000->3000/tcp
# xxxxxxxx       mysql:8     Up 2 minutes    3306/tcp
# xxxxxxxx       prometheus  Up 2 minutes    9090/tcp
# xxxxxxxx       grafana     Up 2 minutes    3000/tcp
```

### 3.2 Mise à jour (Déploiement Continu)

```bash
# 1. Sur votre machine locale - pousser les changements
git add .
git commit -m "Description des changements"
git push origin main

# 2. Se connecter au serveur
ssh -i ~/.ssh/mini-chat-key.pem ubuntu@13.38.35.35

# 3. Mettre à jour l'application
cd /home/ubuntu/mini-chat
git pull origin main
cd docker
docker-compose down
docker-compose up -d --build

# 4. Vérifier le déploiement
docker ps
docker-compose logs -f backend
```

---

## 4. DÉPANNAGE

### 4.1 Problèmes Courants et Solutions

| Problème | Symptôme | Solution |
|----------|----------|----------|
| **Container unhealthy** | `docker ps` montre `unhealthy` | Vérifier MySQL: `docker-compose logs db` |
| **Permission denied** | Docker commands échouent | `sudo usermod -aG docker $USER` puis reconnexion |
| **Backend unreachable** | Cannot connect to server | Vérifier security group AWS (port 3000) |
| **Token invalide** | Déconnexion immédiate | Vérifier JWT_SECRET identique dans auth.js et middleware |
| **IP changée** | App ne répond plus | Mettre à jour l'IP dans les fichiers frontend ou utiliser config.js dynamique |

### 4.2 Commandes de Debug

```bash
# Voir les logs d'un service
docker-compose logs -f [service]
# Ex: docker-compose logs -f backend

# Entrer dans un container
docker exec -it docker_backend_1 /bin/bash

# Vérifier la connexion DB depuis le backend
docker exec docker_backend_1 mysql -h db -u root -p

# Redémarrer un service spécifique
docker-compose restart backend

# Nettoyer tout et recommencer
docker-compose down -v
docker-compose up -d --build
```

### 4.3 Historique des Problèmes Résolus

**Problème 1: Backend container unhealthy**
- **Cause**: MySQL n'était pas prêt quand le backend démarrait
- **Solution**: Ajout de `depends_on` avec `condition: service_healthy` dans docker-compose.yml

**Problème 2: JWT token invalide après connexion**
- **Cause**: SECRET différent entre auth.js et middleware/auth.js
- **Solution**: Unification du secret + retrait de Date.now() qui changeait à chaque redémarrage

**Problème 3: IPs hardcodées dans le frontend**
- **Cause**: Changement d'IP AWS à chaque redémarrage d'instance
- **Solution**: Création de config.js avec détection dynamique de l'IP

**Problème 4: GitHub Actions SSH échoue**
- **Cause**: Clé SSH mal configurée dans les secrets GitHub
- **Solution**: Passage au déploiement manuel documenté

---

## 5. COMMANDES RAPIDES

### 5.1 Cheat Sheet

```bash
# 🔧 DEVELOPPEMENT LOCAL
npm install          # Installer dépendances
npm start            # Lancer en local

# 🐳 DOCKER
./scripts/deploy.sh  # Script de déploiement complet

# ☁️ AWS
./scripts/aws-deploy.sh  # Déploiement Terraform + Docker

# 🔍 MONITORING
curl http://13.38.35.35:9090  # Prometheus
curl http://13.38.35.35:3001  # Grafana (admin/admin)
```

### 5.2 URLs de l'Application

| Service | URL | Identifiants |
|---------|-----|--------------|
| Application | http://13.38.35.35:3000 | - |
| Prometheus | http://13.38.35.35:9090 | - |
| Grafana | http://13.38.35.35:3001 | admin/admin |

---

## 📚 ANNEXES

### A. Structure des Fichiers Importants

```
mini-chat/
├── backend/
│   ├── server.js                 # Point d'entrée
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.js          # JWT SECRET ici
│   │   │   └── messages.js      # Routes protégées
│   │   ├── middleware/
│   │   │   └── auth.js          # JWT SECRET ici (doit matcher)
│   │   └── config/database.js   # Config MySQL
│   └── frontend/
│       └── js/
│           ├── config.js        # Détection dynamique IP
│           ├── auth.js          # Utilise config.js
│           └── chat.js          # Utilise config.js
├── docker/
│   └── docker-compose.yml       # Orchestration
├── terraform/
│   ├── main.tf                  # Infrastructure
│   ├── variables.tf             # Variables
│   └── outputs.tf               # IPs en sortie
└── .github/workflows/
    └── ci-cd.yml                # Pipeline (désactivée)
```

### B. Checklist Pré-Déploiement

- [ ] Terraform plan exécuté sans erreur
- [ ] Secrets AWS configurés
- [ ] Clé SSH disponible (~/.ssh/mini-chat-key.pem)
- [ ] JWT_SECRET identique dans auth.js et middleware
- [ ] IP détectée dynamiquement (pas d'IP en dur)
- [ ] Variables d'environnement MySQL configurées
- [ ] Security Group AWS ouvert sur ports 3000, 9090, 3001

---

## 📝 JOURNAL DES CORRECTIONS ET AMÉLIORATIONS

### 17 Avril 2026 - Correction Bug Déconnexion + Design Amélioré

#### 🔧 Problème identifié ce matin
J'ai remarqué que quand je me connectais, j'étais automatiquement déconnecté après quelques instants. En regardant le code dans `chat.js`, j'ai compris que le token JWT était récupéré **une seule fois** au chargement de la page :

```javascript
// AVANT - Bug
const token = localStorage.getItem("token");  // Lu une fois au chargement
```

Si le token changeait ou s'il y avait un problème de synchronisation, le frontend utilisait un token obsolète.

#### ✅ Solution appliquée
J'ai remplacé par des **fonctions qui récupèrent le token frais à chaque requête** :

```javascript
// APRÈS - Fix
const getToken = () => localStorage.getItem("token");
const getUsername = () => localStorage.getItem("username");

// Utilisation dans chaque fonction
const token = getToken();
```

J'ai aussi ajouté une vérification de sécurité au début de `loadMessages()` et `sendMessage()` :
```javascript
if (!token) {
  window.location.href = "index.html";
  return;
}
```

**Fichiers modifiés** : `backend/frontend/js/chat.js`

#### 🎨 Améliorations design ajoutées
J'ai enrichi le CSS avec de nouvelles animations et effets :

1. **Nouvelles animations** : `slideUp`, `scaleIn`, `pulse`, `shake`
2. **Effet hover shine** sur les boutons (dégradé qui glisse)
3. **Notifications toast** stylisées pour remplacer les alert()
4. **Indicateur de connexion** avec point vert pulsant
5. **Loading overlay** avec spinner
6. **Effet glassmorphism** amélioré sur les messages

**Fichier modifié** : `backend/frontend/css/styles.css`

#### 🌐 IP déjà dynamique (config.js)
J'avais déjà créé `config.js` qui détecte automatiquement l'IP du serveur. Quand je redémarre mon instance AWS et que l'IP change, l'application s'adapte sans que j'aie besoin de modifier le code.

```javascript
const getApiUrl = () => {
  if (window.location.hostname === 'localhost') {
    return 'http://localhost:3000';
  }
  return `http://${window.location.hostname}:3000`;
};
```

**Commit** : "FIX: Token dynamique + Design amélioré + Animations"

---

**Date de création** : 16 avril 2026  
**Version** : 1.1 - Corrections bug déconnexion  
**Auteur** : Babikir Ibrahim
