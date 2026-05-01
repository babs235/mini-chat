# GUIDE DE DÉPLOIEMENT

## Mini-Chat - Processus Complet Documenté

---

## TABLE DES MATIÈRES

1. [Prérequis](#1-prérequis)
2. [Infrastructure AWS (Terraform)](#2-infrastructure-aws-terraform)
3. [Déploiement Application](#3-déploiement-application)
4. [Monitoring & Alertes](#4-monitoring--alertes)
5. [Dépannage](#5-dépannage)
6. [Commandes Rapides](#6-commandes-rapides)

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

### 2.1 Architecture Sécurisée (Nouvelle Version 2026)

L'infrastructure a été complètement reconçue avec les meilleures pratiques de sécurité :

| Composant | Configuration | Pourquoi ? |
|-----------|---------------|------------|
| **VPC** | `10.0.0.0/16` avec 3 subnets | Réseau isolé et haute disponibilité |
| **Subnet Public** | `10.0.1.0/24` (eu-west-3a) | Pour EC2 (application) |
| **Subnets Privés** | `10.0.2.0/24` (eu-west-3a) + `10.0.3.0/24` (eu-west-3c) | Pour RDS (base de données) |
| **Security Groups** | Ports 22, 9090, 3001 fermés | Sécurité maximale |
| **SSM Session Manager** | Remplace SSH | Connexion sécurisée sans port ouvert |
| **RDS Backup** | Automatique 7 jours | Protection des données |
| **CloudWatch** | Alertes CPU/Disque/RDS | Monitoring proactif |

### 2.2 Déploiement via CI/CD (Recommandé)

```bash
# 1. Mettre à jour les secrets GitHub
# - AWS_ACCESS_KEY_ID: nouvelle clé
# - AWS_SECRET_ACCESS_KEY: nouvelle clé secrète  
# - db_password: "123456"
# - key_name: "mini-chat-key"

# 2. Commit et push
git add .
git commit -m "feat: infrastructure sécurisée complète"
git push origin main

# 3. GitHub Actions déploie automatiquement
# - Tests → Build → Terraform deploy
# - Durée: 5-10 minutes
```

### 2.3 Déploiement Manuel (Alternative)

```bash
# 1. Se placer dans le dossier terraform
cd terraform/

# 2. Initialiser Terraform
terraform init

# 3. Vérifier le plan
terraform plan

# 4. Déployer (prend ~5 minutes)
terraform apply -auto-approve

# 5. Récupérer l'ID de l'instance pour SSM
terraform output ec2_instance_id
# Exemple: i-0123456789abcdef0
```

### 2.4 Sorties Terraform

| Output | Description | Exemple |
|--------|-------------|---------|
| `ec2_instance_id` | ID instance EC2 (pour SSM) | i-0123456789abcdef0 |
| `ec2_public_ip` | IP serveur EC2 | 13.38.35.35 |
| `rds_endpoint` | Endpoint base de données | mini-chat-db.xxx.eu-west-3.rds.amazonaws.com |
| `app_url` | URL complète application | http://13.38.35.35:3000 |

### 2.5 Connexion Sécurisée avec SSM Session Manager

```bash
# Se connecter au serveur (depuis n'importe où)
aws ssm start-session --target i-0123456789abcdef0

# Accès à Prometheus via SSH tunnel
aws ssm start-session --target i-0123456789abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["9090"],"localPortNumber":["9090"]}'
# Puis ouvrir http://localhost:9090
```

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

## 4. MONITORING & ALERTES

### 4.1 Architecture CloudWatch (Nouvelle Version 2026)

```
┌─────────────────┐      ┌─────────────┐      ┌─────────────┐
│  TON APP       │ ───▶ │CLOUDWATCH  │ ───▶ │    SNS      │
│  (métriques)   │      │  (monitor)  │      │  (emails)   │
└─────────────────┘      └─────────────┘      └─────────────┘
       ↑                        │                     │
       │                        │                     ▼
  Logs applicatifs       Alertes auto        Email/SMS toi
  + métriques système    CPU/Disque/RDS       (instantané)
```

**Pourquoi CloudWatch au lieu de Prometheus/Grafana ?**
- ✅ **Sécurité** : Pas de ports à ouvrir (Prometheus/Grafana étaient publics)
- ✅ **Intégré** : Nativement AWS, pas de maintenance
- ✅ **Alertes email** : Directement dans ta boîte mail
- ✅ **Free tier** : Inclus dans le plan gratuit AWS

### 4.2 Alertes CloudWatch Configurées

| Alerte | Se déclenche quand | Action |
|--------|------------------|--------|
| **CPU EC2 élevé** | CPU > 80% pendant 10 min | Email d'alerte |
| **Disque EC2 plein** | Disque > 85% utilisé | Email d'alerte |
| **CPU RDS élevé** | CPU BDD > 75% pendant 10 min | Email d'alerte |
| **Logs applicatifs** | Tous les logs centralisés | Consultation CloudWatch |

### 4.3 Configuration des Alertes Email

**Après déploiement :**
1. **Email de confirmation** AWS arrive dans ta boîte mail
2. **Clique "Confirm subscription"** (vérifie les spams)
3. **Alertes actives** pour toujours

**Exemple d'email d'alerte :**
```
Sujet: ALARM: mini-chat-cpu-high in EU (Paris)
Corps: AWS Notification - CPU > 80% pendant 10 minutes sur l'instance mini-chat-server
```

### 4.4 Métriques Applicatives (Prometheus toujours disponible)

| Métrique | Description | Fichier source |
|----------|-------------|----------------|
| `http_requests_total` | Nombre total de requêtes HTTP | `backend/src/middleware/metrics.js` |
| `active_users` | Utilisateurs connectés (avec token valide) | `backend/src/middleware/metrics.js` |
| `messages_created_total` | Nombre total de messages créés | `backend/src/middleware/metrics.js` |
| `process_cpu_user_seconds_total` | CPU utilisé par le processus | `collectDefaultMetrics()` |
| `process_resident_memory_bytes` | RAM utilisée par le processus | `collectDefaultMetrics()` |

**Accès aux métriques applicatives :**
```bash
# Via SSH tunnel SSM
aws ssm start-session --target i-0123456789abcdef0 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["9090"],"localPortNumber":["9090"]}'
# Puis http://localhost:9090/metrics
```

### 4.5 Ajouter une Nouvelle Métrique

**Étape 1 : Créer le compteur dans `metrics.js`**
```javascript
const newMetric = new client.Counter({
  name: "new_metric_total",
  help: "Description de la métrique"
});
register.registerMetric(newMetric);
module.exports = { ..., newMetric };
```

**Étape 2 : Importer et incrémenter dans le contrôleur**
```javascript
const { newMetric } = require("../middleware/metrics");

// Dans la fonction où l'action se produit
newMetric.inc(); // +1
```

**Étape 3 : Redémarrer le backend**
```bash
# Via SSM Session Manager
aws ssm start-session --target i-0123456789abcdef0
cd /home/ubuntu/mini-chat/docker
docker-compose restart backend
```

### 4.6 Backup Automatique AWS RDS

**Plus besoin de script manuel !** AWS RDS Backup gère tout automatiquement :

| Caractéristique | Configuration |
|----------------|---------------|
| **Fréquence** | Tous les jours à 3h du matin |
| **Rétention** | 7 jours de backups |
| **Type** | Snapshot automatique |
| **Restauration** | 1-click dans console AWS |

**Restauration manuelle si besoin :**
1. Console AWS → RDS → Databases
2. Sélectionner `mini-chat-db`
3. Actions → Restore to point in time

### 4.7 Mise à jour sur AWS

Après avoir modifié le code :
```bash
# 1. Commit et push
git add backend/src/middleware/metrics.js
git commit -m "feat: add new metric"
git push

# 2. GitHub Actions déploie automatiquement
# Ou manuellement via SSM :
aws ssm start-session --target $(terraform output -raw ec2_instance_id)
cd /home/ubuntu/mini-chat
git pull
cd docker
docker-compose restart backend

# 3. Vérifier la métrique
# Via SSH tunnel vers Prometheus
curl http://localhost:9090/metrics | grep messages_created_total
```

---

## 5. DÉPANNAGE

### 5.1 Problèmes Courants et Solutions

| Problème | Symptôme | Solution |
|----------|----------|----------|
| **Container unhealthy** | `docker ps` montre `unhealthy` | Vérifier MySQL: `docker-compose logs db` |
| **Permission denied** | Docker commands échouent | `sudo usermod -aG docker $USER` puis reconnexion |
| **Backend unreachable** | Cannot connect to server | Vérifier security group AWS (port 3000) |
| **Token invalide** | Déconnexion immédiate | Vérifier JWT_SECRET identique dans auth.js et middleware |
| **IP changée** | App ne répond plus | Mettre à jour l'IP dans les fichiers frontend ou utiliser config.js dynamique |

### 5.2 Commandes de Debug

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

### 5.3 Erreurs CI/CD et Terraform

#### Erreur 1: SignatureDoesNotMatch (AWS Credentials)

**Symptôme:**
```
Error: validating provider credentials: retrieving caller identity from STS:
api error SignatureDoesNotMatch: The request signature we calculated does not match
```

**Cause:** AWS Secret Access Key incorrecte dans les secrets GitHub

**Solution:**
1. Vérifier les secrets GitHub: `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`
2. S'assurer qu'il n'y a pas d'espaces avant/après les clés
3. Régénérer les clés AWS si nécessaire (IAM → Security credentials)

---

#### Erreur 2: DBSubnetGroupAlreadyExists

**Symptôme:**
```
Error: creating RDS DB Subnet Group: DBSubnetGroupAlreadyExists:
The DB subnet group 'mini-chat-db-subnet-group' already exists.
```

**Cause:** Le subnet group existe déjà sur AWS (créé manuellement ou par un déploiement précédent)

**Solution:**
1. Supprimer l'instance RDS d'abord (RDS → Databases → Delete)
2. Puis supprimer le subnet group (RDS → Subnet groups → Delete)
3. Relancer le pipeline

**Important:** L'ordre est crucial - RDS d'abord, puis subnet group

---

#### Erreur 3: Subnets not in same VPC

**Symptôme:**
```
Error: updating RDS DB Subnet Group: InvalidParameterValue:
The new Subnets are not in the same Vpc as the existing subnet group
```

**Cause:** Conflit entre ressources existantes et nouvelle configuration Terraform

**Solution:** Nettoyage complet AWS:
1. Supprimer l'instance RDS
2. Supprimer le DB Subnet Group
3. Supprimer les autres ressources (EC2, VPC) si besoin
4. Relancer le pipeline avec un state Terraform propre

---

#### Erreur 4: VpcLimitExceeded

**Symptôme:**
```
Error: creating EC2 VPC: VpcLimitExceeded: The maximum number of VPCs has been reached.
```

**Cause:** Limite de 5 VPCs par région atteinte sur AWS

**Solution:**
1. Aller sur AWS Console → VPC → Your VPCs
2. Identifier les VPCs inutilisés (sans instances actives)
3. Supprimer les VPCs inutilisés
4. Alternative: Demander une augmentation de limite (Service Quotas)

---

#### Erreur 5: terraform.tfvars manquant

**Symptôme:**
```
Error: Failed to read variables file: Given variables file terraform.tfvars does not exist.
```

**Cause:** Le fichier `terraform.tfvars` est dans `.gitignore` et n'est pas envoyé sur GitHub

**Solution CI/CD:**
```yaml
# Créer un fichier .env.example avec les variables par défaut
# Dans le pipeline:
- name: Test des conteneurs Docker
  run: |
    cd docker
    cp .env.example .env  # Copier le fichier exemple
    docker compose up --build backend db -d
```

---

#### Erreur 6: Variables Terraform non définies

**Symptôme:**
```
var.db_password
  Mot de passe RDS MySQL
# Terraform attend une valeur pour db_password
```

**Cause:** Les variables Terraform n'ont pas de valeur par défaut

**Solution CI/CD:**
```yaml
env:
  TF_VAR_db_password: ${{ secrets.db_password }}
  TF_VAR_key_name: ${{ secrets.key_name }}
```

**Important:** Utiliser le préfixe `TF_VAR_` pour que Terraform reconnaisse les variables d'environnement

---

#### Erreur 7: Terraform fmt -check échoue

**Symptôme:**
```
main.tf
variables.tf
Error: Terraform exited with code 3.
```

**Cause:** Les fichiers Terraform ne sont pas correctement formatés

**Solution:**
```bash
cd terraform
terraform fmt  # Formater automatiquement
git add .
git commit -m "Formatage Terraform"
git push
```

---

#### Erreur 8: Container MySQL échoue dans le CI/CD

**Symptôme:**
```
dependency failed to start: container docker-db-1 exited (1)
```

**Cause:** Le fichier `.env` n'existe pas dans le CI/CD (il est dans `.gitignore`)

**Solution:**
1. Créer un fichier `docker/.env.example` avec les valeurs de test:
   ```
   MYSQL_ROOT_PASSWORD=mysecretpassword
   JWT_SECRET=your_jwt_secret_key_here
   ```
2. Dans le CI/CD, copier le fichier:
   ```yaml
   - name: Test des conteneurs Docker
     run: |
       cd docker
       cp .env.example .env
       docker compose up --build backend db -d
   ```

---

#### Erreur 9: Timeout du déploiement Grafana

**Symptôme:** Le job CI/CD s'arrête pendant le démarrage des containers

**Cause:** Grafana installe plusieurs plugins et prend beaucoup de temps

**Solution CI/CD:**
```yaml
- name: Test des conteneurs Docker
  run: |
    cd docker
    cp .env.example .env
    docker compose up --build backend db -d  # Seulement backend et db, pas Grafana
    sleep 20
    docker ps
    curl -f http://localhost:3000 || exit 1
    docker compose down
```

**Astuce:** Ne pas lancer Grafana dans le CI/CD si non nécessaire pour les tests

---

### 5.4 Checklist CI/CD avant déploiement

- [ ] Secrets GitHub configurés: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- [ ] Variables Terraform dans secrets: `db_password`, `key_name`
- [ ] Fichier `docker/.env.example` créé avec les variables de test
- [ ] Fichiers Terraform formatés (`terraform fmt`)
- [ ] Pas de ressources AWS conflictuelles (mêmes noms existants)
- [ ] Limite de VPCs non atteinte (moins de 5 VPCs sur AWS)

### 5.5 Backup de la Base de Données

Pour effectuer un backup de la base de données MySQL :

```bash
# 1. Creer le repertoire de backups local
mkdir -p backups

# 2. Executer le script de backup
./scripts/backup-mysql.sh 13.38.35.35 ~/.ssh/mini-chat-key.pem

# Le backup sera sauvegarde dans ./backups/mini_chat_backup_<date>.sql.gz
```

**Restauration d'un backup :**
```bash
# 1. Telecharger le backup sur le serveur
scp -i ~/.ssh/mini-chat-key.pem ./backups/mini_chat_backup_20260423_120000.sql.gz ubuntu@13.38.35.35:/home/ubuntu/backups/

# 2. Decompresser et restaurer
ssh -i ~/.ssh/mini-chat-key.pem ubuntu@13.38.35.35
cd /home/ubuntu/backups
gunzip mini_chat_backup_20260423_120000.sql.gz
docker exec -i docker_db_1 mysql -u root -p$(grep MYSQL_ROOT_PASSWORD /home/ubuntu/mini-chat/docker/.env | cut -d'=' -f2) mini_chat < mini_chat_backup_20260423_120000.sql
```

### 5.5 Historique des Problèmes Résolus

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

## 6. COMMANDES RAPIDES

### 6.1 Cheat Sheet

```bash
# DEVELOPPEMENT LOCAL
npm install          # Installer dépendances
npm start            # Lancer en local

# DOCKER
./scripts/deploy.sh  # Script de déploiement complet

# AWS
./scripts/aws-deploy.sh  # Déploiement Terraform + Docker

# MONITORING
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

## ANNEXES

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

## JOURNAL DES CORRECTIONS ET AMÉLIORATIONS

### 17 Avril 2026 - Correction Bug Déconnexion + Design Amélioré

#### Problème identifié ce matin
J'ai remarqué que quand je me connectais, j'étais automatiquement déconnecté après quelques instants. En regardant le code dans `chat.js`, j'ai compris que le token JWT était récupéré **une seule fois** au chargement de la page :

```javascript
// AVANT - Bug
const token = localStorage.getItem("token");  // Lu une fois au chargement
```

Si le token changeait ou s'il y avait un problème de synchronisation, le frontend utilisait un token obsolète.

#### Solution appliquée
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

#### Améliorations design ajoutées
J'ai enrichi le CSS avec de nouvelles animations et effets :

1. **Nouvelles animations** : `slideUp`, `scaleIn`, `pulse`, `shake`
2. **Effet hover shine** sur les boutons (dégradé qui glisse)
3. **Notifications toast** stylisées pour remplacer les alert()
4. **Indicateur de connexion** avec point vert pulsant
5. **Loading overlay** avec spinner
6. **Effet glassmorphism** amélioré sur les messages

**Fichier modifié** : `backend/frontend/css/styles.css`

#### IP déjà dynamique (config.js)
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

### 17 Avril 2026 (après-midi) - Métrique : Utilisateurs Actifs

#### Objectif
Ajouter une métrique Prometheus pour suivre le nombre d'utilisateurs connectés en temps réel.

#### Implémentation
J'ai modifié `backend/src/middleware/metrics.js` pour ajouter :

```javascript
// Gauge pour utilisateurs actifs
const activeUsersGauge = new client.Gauge({
  name: "active_users",
  help: "Nombre d'utilisateurs actuellement connectés"
});

// Middleware qui track les users par token
const trackActiveUsers = (req, res, next) => {
  const token = req.headers["authorization"];
  if (token) {
    activeUsersSet.add(token);
    activeUsersGauge.set(activeUsersSet.size);
    // Auto-expire après 5 minutes
    setTimeout(() => {
      activeUsersSet.delete(token);
      activeUsersGauge.set(activeUsersSet.size);
    }, 5 * 60 * 1000);
  }
  next();
};
```

Dans `server.js` :
```javascript
const { trackActiveUsers } = require("./src/middleware/metrics");
app.use(trackActiveUsers); // Avant les routes protégées
```

#### Utilisation dans Grafana
**Query PromQL :**
```promql
active_users
```

**Type de panel :** `Stat` (affiche un grand nombre)

**Résultat :** Nombre d'utilisateurs avec token valide actuellement connectés.

#### Test
```bash
curl http://13.XX.XX.XX:3000/metrics | grep active_users
```

**Commit :** "feat: Métrique active_users pour monitoring temps réel"

---

### 23 Avril 2026 - Monitoring Complet : Métriques + Alertes + Discord

#### Objectif
Mettre en place un système de monitoring complet avec Prometheus, Grafana et des alertes Discord.

#### Ajout de la métrique messages_created_total

**Fichier modifié** : `backend/src/middleware/metrics.js`
```javascript
// Counter pour messages créés
const messagesCreated = new client.Counter({
  name: "messages_created_total",
  help: "Nombre total de messages créés"
});
register.registerMetric(messagesCreated);
module.exports = { ..., messagesCreated };
```

**Fichier modifié** : `backend/src/routes/messages.js`
```javascript
const { messagesCreated } = require("../middleware/metrics");

// Après insertion réussie du message
messagesCreated.inc();
```

#### Configuration Grafana

**Source de données Prometheus** :
- URL : `http://prometheus:9090`
- Configurée dans l'interface Grafana

**Dashboard créé** :
- Panel 1 : Requêtes HTTP totales (`http_requests_total`)
- Panel 2 : Utilisateurs actifs (`active_users`)
- Panel 3 : Requêtes par seconde (`rate(http_requests_total[5m])`)

#### Configuration des Alertes

**Contact Point Discord** :
- Type : Webhook
- URL : Webhook Discord configuré
- Message personnalisé :
```json
{
  "content": "**{{ .Labels.alertname }}**\n\n{{ .Annotations.summary }}\n\nValeur : {{ .Value }}"
}
```

**Notification Policy** :
- Toutes les alertes → Discord Mini-Chat

**Alert Rules créées** :
1. `beacoup de users` : `active_users > 2` (se déclenche à 2+ users)
2. Autres exemples documentés : Backend Down, CPU élevé, RAM élevée, Trop de messages

#### Nettoyage des fichiers d'alertes

**Fichier modifié** : `docker/prometheus/alerts/minichat.yml`
- Suppression de `TestAlert` (alerte de test toujours active)
- Suppression de `MiniChatHighTraffic` (trop de requêtes)
- Correction de l'alerte CPU : `rate(process_cpu_user_seconds_total[5m]) * 100 > 80`

#### Documentation ajoutée

**Section ajoutée au GUIDE_DEPLOIEMENT.md** :
- Architecture de monitoring
- Métriques disponibles
- Comment ajouter une nouvelle métrique
- Configuration Grafana (data source, dashboard, requêtes PromQL)
- Configuration des alertes (contact point, notification policy, alert rules)
- Exemples d'alertes
- Fichiers de configuration
- Mise à jour sur AWS

#### Mise à jour sur AWS

Après modifications :
```bash
git add backend/src/middleware/metrics.js backend/src/routes/messages.js docker/prometheus/alerts/minichat.yml
git commit -m "feat: add messages_created metric and clean alerts"
git push

# Sur AWS
ssh -i ~/.ssh/mini-chat-key.pem ubuntu@13.38.35.35
cd /home/ubuntu/mini-chat
git pull
cd docker
docker-compose restart backend
```

#### Concepts appris

- **Flux de données** : App → Prometheus → Grafana → Discord
- **Métriques** : Counter (incrémente), Gauge (monte/descend), Histogram (temps)
- **PromQL** : Langage de requête Prometheus (`rate()`, `sum()`, etc.)
- **Alertes Grafana** : Indépendantes des dashboards, créées via interface
- **Contact Points** : Créés une seule fois, réutilisés par toutes les alertes
- **Notification Policies** : Règles de routage des alertes

**Commit** : "feat: add messages_created metric and clean alerts"

---

**Date de création** : 16 avril 2026  
**Version** : 1.3 - Monitoring complet avec alertes Discord  
**Auteur** : Babikir Ibrahim
