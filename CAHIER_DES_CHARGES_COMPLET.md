# CAHIER DES CHARGES COMPLET

## Mini-Chat Application - Projet DevOps Full Stack

---

## TABLE DES MATIÈRES

1. [Présentation du Projet](#1-présentation-du-projet)
2. [Fonctionnalités Détaillées](#2-fonctionnalités-détaillées)
3. [Architecture Technique Complète](#3-architecture-technique-complète)
4. [Stack Technique Détaillée](#4-stack-technique-détaillée)
5. [Structure du Code](#5-structure-du-code)
6. [Exigences Non-Fonctionnelles](#6-exigences-non-fonctionnelles)
7. [Sécurité](#7-sécurité)
8. [Monitoring et Observabilité](#8-monitoring-et-observabilité)
9. [Scripts de Provisionnement et Backup](#9-scripts-de-provisionnement-et-backup)
10. [Planning et Livrables](#10-planning-et-livrables)
11. [Contraintes et Risques](#11-contraintes-et-risques)

---

## 1. PRÉSENTATION DU PROJET

### 1.1 Contexte du Projet

Dans le cadre de la formation **Administrateur DevOps**, ce projet vise à démontrer la maîtrise complète du cycle de développement et déploiement d'une application moderne, de la conception à la mise en production sur infrastructure cloud.

### 1.2 Objectifs Principaux

| ID | Objectif | Priorité |
|----|----------|----------|
| O1 | Développer une application de messagerie fonctionnelle | Haute |
| O2 | Conteneuriser l'application avec Docker | Haute |
| O3 | Orchestrer avec Docker Compose | Haute |
| O4 | Déployer sur AWS avec Terraform (IaC) | Haute |
| O5 | Implémenter CI/CD avec GitHub Actions | Moyenne |
| O6 | Mettre en place le monitoring Prometheus/Grafana | Haute |
| O7 | Sécuriser l'application (JWT, XSS, bcrypt) | Haute |

### 1.3 Périmètre du Projet

**Inclus :**
- Backend API REST (Node.js/Express)
- Frontend web (HTML/CSS/JS)
- Base de données MySQL
- Conteneurisation Docker
- Infrastructure AWS (EC2, RDS optionnel)
- Monitoring et alerting

**Non inclus (hors scope) :**
- Application mobile native
- WebSocket temps réel (polling utilisé)
- Système de fichier multimédia
- Authentification OAuth externe

---

## 2. FONCTIONNALITÉS DÉTAILLÉES

### 2.1 Fonctionnalités Backend

#### Module Authentification (`backend/src/routes/auth.js`)

| Fonction | Route | Méthode | Description |
|----------|-------|---------|-------------|
| Inscription | `/auth/register` | POST | Création utilisateur avec validation |
| Connexion | `/auth/login` | POST | Authentification JWT |

**Spécifications techniques :**
- Validation des entrées : username 3-20 caractères, password min 6 caractères
- Hachage bcrypt avec salt rounds 10
- Génération JWT avec secret statique (correction du bug Date.now())
- Requêtes SQL préparées (prévention injection SQL)

#### Module Messages (`backend/src/routes/messages.js`)

| Fonction | Route | Méthode | Auth | Description |
|----------|-------|---------|------|-------------|
| Liste messages | `/messages` | GET | JWT | Récupération historique |
| Envoi message | `/messages` | POST | JWT | Création message |

**Spécifications techniques :**
- Protection XSS avec échappement HTML
- Validation : message non vide, max 1000 caractères
- Filtrage des caractères spéciaux `<script>` etc.
- Clé étrangère `user_id` vers table `users`

### 2.2 Fonctionnalités Frontend

#### Page d'Authentification (`index.html`)

| Élément | Description |
|---------|-------------|
| Formulaire connexion | Username + Password |
| Formulaire inscription | Toggle login/register |
| Validation client | Champs requis, longueur min |
| UX | Messages d'erreur, transitions fluides |

#### Page de Chat (`messages.html`)

| Élément | Description |
|---------|-------------|
| Header | Logo, nom utilisateur, bouton déconnexion |
| Zone messages | Affichage bulles style Discord |
| Input message | Champ texte + bouton envoi |
| Auto-scroll | Scroll vers dernier message |
| Refresh auto | Polling toutes les 3 secondes |

### 2.3 Fonctionnalités Transversales

| Fonction | Implémentation |
|----------|----------------|
| Responsive design | CSS Grid/Flexbox, mobile-first |
| Glassmorphism UI | Transparence + blur + gradients |
| Avatars dynamiques | Initiales + couleurs par utilisateur |
| Animations | Fade in, slide, hover effects |

---

## 3. ARCHITECTURE TECHNIQUE COMPLÈTE

### 3.1 Architecture High-Level

```
┌─────────────────────────────────────────────────────────────────┐
│                           CLIENT                                │
│                      (Navigateur Web)                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTP/JSON
┌───────────────────────────▼─────────────────────────────────────┐
│                          AWS EC2                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    DOCKER ENGINE                        │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │              DOCKER COMPOSE STACK                   │ │   │
│  │  │                                                     │ │   │
│  │  │   ┌─────────────┐     ┌─────────────────────────┐  │ │   │
│  │  │   │   NGINX     │────►│      BACKEND          │  │ │   │
│  │  │   │   (option)  │     │   Node.js + Express   │  │ │   │
│  │  │   └─────────────┘     │   Port 3000           │  │ │   │
│  │  │                       └──────────┬────────────┘  │ │   │
│  │  │                                  │                 │ │   │
│  │  │   ┌─────────────┐              │                 │ │   │
│  │  │   │   MySQL     │◄─────────────┘                 │ │   │
│  │  │   │   Port 3306 │    (mysql2 driver)             │ │   │
│  │  │   └─────────────┘                              │ │   │
│  │  │                                               │ │   │
│  │  │   ┌─────────────┐     ┌─────────────────────┐ │ │   │
│  │  │   │ Prometheus  │────►│      Grafana        │ │ │   │
│  │  │   │  Port 9090  │     │    Port 3001        │ │ │   │
│  │  │   └─────────────┘     └─────────────────────┘ │ │   │
│  │  │                                               │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  AWS RDS       │ (Optionnel - pour prod)
                    │  MySQL         │
                    └────────────────┘
```

### 3.2 Architecture Détaillée des Conteneurs

| Conteneur | Base Image | Ports exposés | Rôle |
|-----------|------------|---------------|------|
| **backend** | `node:20-alpine` | 3000 | API REST + serveur frontend |
| **db** | `mysql:8.0` | 3306 (interne) | Persistance données |
| **prometheus** | `prom/prometheus:latest` | 9090 | Collecte métriques |
| **grafana** | `grafana/grafana:latest` | 3001 | Visualisation dashboards |

### 3.3 Flux de Données

#### Inscription (Register Flow)
```
1. Client → POST /auth/register {username, password}
2. Backend → Validation entrées (regex, longueur)
3. Backend → bcrypt.hash(password, 10)
4. Backend → INSERT INTO users (prepared statement)
5. MySQL → Confirmation insertion
6. Backend → Response 201 {message: "User created"}
```

#### Authentification (Login Flow)
```
1. Client → POST /auth/login {username, password}
2. Backend → SELECT * FROM users WHERE username = ?
3. Backend → bcrypt.compare(password, hash)
4. Backend → jwt.sign({userId}, SECRET, {expiresIn: "1h"})
5. Backend → Response 200 {token, username}
6. Client → localStorage.setItem("token", token)
```

#### Envoi Message (Message Flow)
```
1. Client → POST /messages {message} + Header Authorization: token
2. Middleware → jwt.verify(token, SECRET)
3. Middleware → req.user = decoded
4. Backend → Validation XSS (escapeHtml)
5. Backend → INSERT INTO messages (user_id, message)
6. MySQL → Confirmation
7. Backend → Response 201
```

---

## 4. STACK TECHNIQUE DÉTAILLÉE

### 4.1 Backend

| Technologie | Version | Usage | Justification |
|-------------|---------|-------|---------------|
| **Node.js** | 20 LTS | Runtime | Performance, async I/O, ecosystem |
| **Express.js** | ^4.18 | Framework API | Minimaliste, middleware-rich |
| **mysql2** | ^3.9 | Driver DB | Promises, prepared statements |
| **bcrypt** | ^5.1 | Hashing | Industry standard, salt auto |
| **jsonwebtoken** | ^9.0 | Auth JWT | Stateless, scalable |
| **cors** | ^2.8 | Cross-origin | Sécurité requêtes cross-domain |
| **prom-client** | ^15.0 | Métriques | Native Prometheus support |

### 4.2 Frontend

| Technologie | Version | Usage | Justification |
|-------------|---------|-------|---------------|
| **HTML5** | - | Structure | Sémantique, accessible |
| **CSS3** | - | Styling | Grid, Flexbox, Variables |
| **JavaScript ES6+** | - | Logic | Async/await, modules |
| **Font Awesome** | 6.4 | Icônes | Consistent, scalable icons |

### 4.3 DevOps / Infrastructure

| Technologie | Version | Usage | Justification |
|-------------|---------|-------|---------------|
| **Docker** | Latest | Conteneurisation | Isolation, portabilité |
| **Docker Compose** | v2 | Orchestration | Multi-container local |
| **Terraform** | ~> 5.0 | IaC AWS | Infra as code, reproductible |
| **AWS EC2** | t3.micro | Compute | Free Tier, scalable |
| **AWS RDS** | t3.micro | DB Managed | (Optionnel) Backup auto |
| **GitHub Actions** | - | CI/CD | Intégration native Git |
| **Prometheus** | Latest | Monitoring | Time-series metrics |
| **Grafana** | Latest | Dashboards | Visualization pro |

---

## 5. STRUCTURE DU CODE

### 5.1 Arborescence Complète

```
mini-chat/
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # Pipeline CI/CD
│
├── backend/
│   ├── frontend/
│   │   ├── css/
│   │   │   └── styles.css         # Design system complet
│   │   ├── js/
│   │   │   ├── auth.js            # Logique auth (sans IP hardcodée)
│   │   │   ├── chat.js            # Logique chat (sans IP hardcodée)
│   │   │   └── config.js          # Détection dynamique IP
│   │   ├── index.html             # Page login/register
│   │   └── messages.html          # Page chat
│   │
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js        # Config MySQL
│   │   ├── middleware/
│   │   │   └── auth.js            # JWT middleware (SECRET fixe)
│   │   ├── routes/
│   │   │   ├── auth.js            # Routes auth (SECRET fixe)
│   │   │   └── messages.js        # Routes messages + XSS protection
│   │   └── utils/
│   │       └── validators.js      # (optionnel) Validation helpers
│   │
│   ├── dockerfile.backend          # Image Node.js optimisée
│   ├── package.json              # Dépendances Node
│   └── server.js                 # Point d'entrée Express
│
├── database/
│   └── init.sql                  # Schema DB + tables
│
├── docker/
│   ├── docker-compose.yml        # Stack 4 services
│   └── prometheus.yml            # Config monitoring
│
├── docs/
│   └── architecture.png          # (optionnel) Diagramme
│
├── scripts/
│   ├── backup-mysql.sh          # Backup de la base de données MySQL
│   ├── deploy-with-backup.sh    # Déploiement avec backup automatique
│   ├── deploy.sh                # Script déploiement rapide
│   └── aws-deploy.sh            # Déploiement Terraform + Docker
│
├── terraform/
│   ├── main.tf                   # Resources AWS (EC2, RDS, VPC)
│   ├── variables.tf              # Variables Terraform
│   ├── outputs.tf                # IPs en sortie
│   ├── provider.tf               # Config AWS provider
│   └── user-data.sh              # Script init EC2
│
├── .gitignore                 # Exclusions (node_modules, .env, clés SSH)
├── CAHIER_DES_CHARGES.md      # Ce document
├── GUIDE_DEPLOIEMENT.md       # Procédures ops
├── PROMPT_CANVA.md            # Support présentation
└── README.md                  # Vue d'ensemble projet
```

### 5.2 Description des Fichiers Clés

#### Backend

| Fichier | Lignes | Description technique |
|---------|--------|----------------------|
| `server.js` | ~50 | Setup Express, middlewares CORS, routes, démarrage serveur 0.0.0.0:3000 |
| `src/routes/auth.js` | ~100 | Register/login, bcrypt, JWT sign avec SECRET statique, validation entrées |
| `src/routes/messages.js` | ~80 | GET/POST messages, middleware verifyToken, escapeHtml XSS protection |
| `src/middleware/auth.js` | ~30 | JWT verify, SECRET identique à auth.js, req.user attachment |
| `src/config/database.js` | ~20 | Pool MySQL, host: 'db' (Docker network), credentials |

#### Frontend

| Fichier | Lignes | Description technique |
|---------|--------|----------------------|
| `js/config.js` | ~15 | Détection dynamique IP (localhost vs production) |
| `js/auth.js` | ~70 | Fetch API register/login, localStorage token, redirections |
| `js/chat.js` | ~170 | Load messages, send message, polling 3s, animations, avatars |
| `css/styles.css` | ~500 | Variables CSS, glassmorphism, responsive, animations keyframes |

#### Infrastructure

| Fichier | Lignes | Description technique |
|---------|--------|----------------------|
| `dockerfile.backend` | ~25 | Multi-stage build possible, nodemon dev, expose 3000 |
| `docker-compose.yml` | ~80 | 4 services, networks, volumes, healthchecks, depends_on conditionnel |
| `terraform/main.tf` | ~200 | VPC, subnets, security groups, EC2 t3.micro, RDS optionnel, user-data |
| `terraform/outputs.tf` | ~30 | ec2_public_ip, rds_endpoint, urls |

---

## 6. EXIGENCES NON-FONCTIONNELLES

### 6.1 Performance

| Métrique | Objectif | Mesure |
|----------|----------|--------|
| Temps réponse API | < 200ms | moyenne sur 100 requêtes |
| Temps chargement page | < 2s | Lighthouse performance |
| Capacité simultanée | 100 users | load test (artillery/jmeter) |
| Uptime | 99.9% | monitoring sur 30 jours |

### 6.2 Scalabilité

| Aspect | Stratégie |
|--------|-----------|
| Horizontal | Docker Compose → Kubernetes (futur) |
| Vertical | t3.micro → t3.small → t3.medium |
| DB | RDS read replicas (si charge élevée) |
| Cache | Redis (futur) pour sessions/messages |

### 6.3 Disponibilité

| Composant | Stratégie haute dispo |
|-----------|----------------------|
| EC2 | Auto Scaling Group (min 1, max 2) |
| RDS | Multi-AZ deployment |
| Données | Backup automatique quotidien |

---

## 7. SÉCURITÉ

### 7.1 Authentification et Autorisation

| Couche | Implémentation |
|--------|----------------|
| Hashing mots de passe | bcrypt avec salt 10 rounds |
| Session | JWT stateless, expiration 1h |
| Transmission | HTTPS (à implémenter avec certbot/Let's Encrypt) |
| Storage client | localStorage (token), httpOnly cookie recommandé futur |

### 7.2 Protection Contre les Attaques Courantes

| Attaque | Protection | Fichier concerné |
|---------|-----------|------------------|
| **SQL Injection** | Requêtes préparées mysql2 | `auth.js`, `messages.js` |
| **XSS** | Échappement HTML + validation entrée | `messages.js` (escapeHtml) |
| **JWT Forging** | Secret complexe statique, pas de Date.now() | `auth.js`, `middleware/auth.js` |
| **Brute Force** | (À implémenter) Rate limiting | Futur: middleware rate-limit |
| **CSRF** | CORS configuré, tokens JWT | `server.js` |

### 7.3 Échappement XSS (Implémentation)

```javascript
// backend/src/routes/messages.js
function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
```

### 7.4 Gestion des Secrets

| Secret | Localisation | Méthode |
|--------|--------------|---------|
| JWT_SECRET | `auth.js`, `middleware/auth.js` | Variable d'environnement (process.env.JWT_SECRET) |
| MySQL password | `docker-compose.yml`, `database.js` | Variables d'environnement (process.env.DB_PASSWORD) |
| DB_HOST, DB_USER, DB_NAME | `database.js` | Variables d'environnement avec valeurs par défaut |
| AWS credentials | - | ~/.aws/credentials (local), IAM roles (EC2) |
| SSH keys | ~/.ssh/ | Jamais dans Git (.gitignore) |

**Fichier .env** (non versionné) :
```
MYSQL_ROOT_PASSWORD=votre_mot_de_passe
JWT_SECRET=votre_secret_jwt
```

**docker-compose.yml** injecte ces variables dans les containers via `${MYSQL_ROOT_PASSWORD}` et `${JWT_SECRET}`.

---

## 8. MONITORING ET OBSERVABILITÉ

### 8.1 Métriques Collectées (Prometheus)

| Métrique | Type | Source |
|----------|------|--------|
| `http_requests_total` | Counter | Backend Express |
| `http_request_duration_seconds` | Histogram | Backend Express |
| `container_cpu_usage` | Gauge | cAdvisor (optionnel) |
| `container_memory_usage` | Gauge | cAdvisor (optionnel) |
| `mysql_connections` | Gauge | MySQL exporter (optionnel) |

### 8.2 Dashboards Grafana

| Dashboard | Panels | Description |
|-----------|--------|-------------|
| **Overview** | Requests/sec, Error rate, Latency | Santé générale application |
| **Containers** | CPU, Memory, Network | Ressources Docker |
| **Database** | Connections, Queries, Slow queries | Performance MySQL |

### 8.3 Alertes (À configurer)

| Condition | Seuil | Action |
|-----------|-------|--------|
| Error rate > 5% | 5 minutes | Email/Slack |
| Response time > 500ms | 10 minutes | Email/Slack |
| Container down | Immediate | PagerDuty (futur) |

---

## 9. SCRIPTS DE BACKUP

### 9.1 Script de Backup MySQL

**Fichier** : `scripts/backup-mysql.sh`

**Objectif** : Sauvegarder la base de données MySQL de manière automatisée.

**Usage** :
```bash
./scripts/backup-mysql.sh <IP_AWS> <CHEF_CLE_SSH>
```

**Fonctionnalités** :
- Exécution de `mysqldump` via Docker
- Compression du backup (gzip)
- Téléchargement du backup localement
- Nettoyage des vieux backups (garde les 7 derniers)

**Restauration** :
```bash
# Décompresser et restaurer
gunzip mini_chat_backup_20260423_120000.sql.gz
docker exec -i docker_db_1 mysql -u root -p$(grep MYSQL_ROOT_PASSWORD /home/ubuntu/mini-chat/docker/.env | cut -d'=' -f2) mini_chat < mini_chat_backup_20260423_120000.sql
```

### 9.2 Script de Déploiement avec Backup

**Fichier** : `scripts/deploy-with-backup.sh`

**Objectif** : Déployer l'application avec un backup automatique avant chaque déploiement.

**Usage** :
```bash
./scripts/deploy-with-backup.sh <IP_AWS> <CHEF_CLE_SSH>
```

**Fonctionnalités** :
- Backup automatique de la base de données
- Git pull pour récupérer les dernières modifications
- Redémarrage des containers Docker
- Vérification du statut des containers

---

## 10. PLANNING ET LIVRABLES

### 10.1 Planning Détaillé

| Phase | Dates | Durée | Activités | Livrables | Statut |
|-------|-------|-------|-----------|-----------|--------|
| **P1** | 01-07 Avril | 1 semaine | Développement backend/frontend | Code fonctionnel | ✅ |
| **P2** | 08-10 Avril | 3 jours | Docker + Docker Compose | Dockerfile, docker-compose.yml | ✅ |
| **P3** | 11-12 Avril | 2 jours | Terraform AWS | Infra as Code déployable | ✅ |
| **P4** | 13-14 Avril | 2 jours | CI/CD GitHub Actions | Pipeline (tentatives SSH) | ✅ |
| **P5** | 15 Avril | 1 jour | Monitoring Prometheus/Grafana | Métriques + dashboards | ✅ |
| **P6** | 16 Avril | 1 jour | Documentation + Corrections | CDC, Guide déploiement | ✅ |

### 10.2 Livrables Finaux

| Livrable | Format | Localisation | Statut |
|----------|--------|--------------|--------|
| **Code source** | Git | GitHub (babs235/mini-chat) | ✅ Public |
| **Cahier des charges** | Markdown | `CAHIER_DES_CHARGES.md` | ✅ Complet |
| **Guide de déploiement** | Markdown | `GUIDE_DEPLOIEMENT.md` | ✅ Complet |
| **Documentation technique** | Markdown | `README.md` + ce CDC | ✅ |
| **Infrastructure as Code** | Terraform | `terraform/` | ✅ |
| **Conteneurisation** | Docker | `docker/`, `dockerfile.backend` | ✅ |
| **CI/CD Pipeline** | YAML | `.github/workflows/ci-cd.yml` | ✅ (SSH à debug) |
| **Application déployée** | URL | http://13.38.35.35:3000 | ✅ Online |
| **Monitoring** | URL | http://13.38.35.35:9090, :3001 | ✅ Online |

### 10.3 Présentation Jury

| Support | Format | Description |
|---------|--------|-------------|
| **PowerPoint** | .pptx | 15 slides, parcours d'apprentissage |
| **Démo live** | URL | Connexion à l'app, envoi message |
| **Code review** | VS Code | Explication architecture, sécurité |

---

## 11. CONTRAINTES ET RISQUES

### 11.1 Contraintes Techniques

| Contrainte | Impact | Mitigation |
|------------|--------|------------|
| AWS Free Tier | Limites CPU/mémoire | t3.micro, monitoring usage |
| Pas de HTTPS | Sécurité réduite | Let's Encrypt (futur) |
| Polling 3s | Charge réseau | WebSocket (futur v2) |
| Single EC2 | Point unique de panne | Auto Scaling Group (futur) |

### 11.2 Contraintes Organisationnelles

| Contrainte | Description |
|------------|-------------|
| Solo développeur | Toutes les compétences sur 1 personne |
| Deadline fixe | 16 Avril 2026, pas de report possible |
| Budget nul | AWS Free Tier uniquement |
| Formation en parallèle | D'autres blocs REAC simultanés |

### 11.3 Risques Identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Dépassement Free Tier | Moyenne | Élevé | Monitoring billing AWS |
| Perte clé SSH | Faible | Critique | Backup clé, user-data script |
| Corruption DB | Faible | Élevé | Volumes Docker persistants |
| Indisponibilité jury | Faible | Élevé | Screenshot backup, README détaillé |

### 11.4 Leçons Apprises (Retour d'expérience)

| Problème | Cause racine | Solution | Prévention future |
|----------|--------------|----------|-------------------|
| `401 Unauthorized` | JWT secret différent auth.js vs middleware | Unification SECRET statique | Checklist pre-commit |
| `undefined` sur register | Response parsing avant check status | Vérification res.ok avant .json() | Tests automatisés API |
| Container unhealthy | MySQL pas prêt, pas de wait | Healthcheck + depends_on conditionnel | docker-compose config validation |
| IP hardcodée | Changement IP AWS au reboot | config.js détection dynamique | Variable d'environnement REACT_APP_API_URL |
| SSH timeout GitHub Actions | Secrets mal configurés | Déploiement manuel documenté | Tests CI/CD sur branche dev d'abord |

---

## ANNEXES

### A. Commandes de Développement Rapide

```bash
# Local development
npm install
npm start

# Docker local
cd docker
docker-compose up -d --build

# AWS deployment
cd terraform
terraform apply -auto-approve
ssh -i ~/.ssh/mini-chat-key.pem ubuntu@$(terraform output -raw ec2_public_ip)

# Logs monitoring
docker-compose logs -f backend
docker-compose logs -f db
```

### B. URLs de l'Application (16 Avril 2026)

| Service | URL | Identifiants |
|---------|-----|--------------|
| Application | http://13.38.35.35:3000 | Créer compte test |
| Prometheus | http://13.38.35.35:9090 | - |
| Grafana | http://13.38.35.35:3001 | admin/admin |

### C. Checklist de Validation Présentation

- [ ] Application accessible (http://13.38.35.35:3000)
- [ ] Inscription fonctionnelle
- [ ] Connexion fonctionnelle
- [ ] Envoi message fonctionnel
- [ ] Refresh auto messages (3s)
- [ ] Prometheus accessible
- [ ] Grafana accessible
- [ ] Code review JWT (secret statique)
- [ ] Code review XSS (escapeHtml)
- [ ] Terraform plan sans erreur
- [ ] Docker-compose ps tous containers UP

---

## VALIDATION

**Document rédigé par** : Babikir Ibrahim  
**Formation** : Administrateur DevOps  
**Date** : 16 Avril 2026  
**Version** : 2.0 - Complet  
**Review** : Conforme aux attentes REAC Bloc 2

---

*Ce cahier des charges reflète l'état complet du projet Mini-Chat à la date de rendu, incluant l'architecture technique, le code développé, les problématiques rencontrées et les solutions implémentées.*
