# CAHIER DES CHARGES — Mini-Chat

## Application de messagerie — Projet ASD DevOps

---

**Auteur** : Babikir Ibrahim
**Formation** : Administrateur Systemes et DevOps (ASD)
**Version** : 4.0 — Architecture ECS Fargate (Mai 2026)
**Depot GitHub** : github.com/babs235/mini-chat

---

## TABLE DES MATIERES

1. [Presentation du projet](#1-presentation-du-projet)
2. [Fonctionnalites de l'application](#2-fonctionnalites-de-lapplication)
3. [Architecture technique](#3-architecture-technique)
4. [Stack technique](#4-stack-technique)
5. [Pipeline CI/CD](#5-pipeline-cicd)
6. [Infrastructure AWS](#6-infrastructure-aws)
7. [Securite](#7-securite)
8. [Statistiques de services — BC03](#8-statistiques-de-services--bc03)
9. [Evolutions prevues](#9-evolutions-prevues)
10. [Planning et livrables](#10-planning-et-livrables)
11. [Retour d'experience](#11-retour-dexperience)

---

## 1. PRESENTATION DU PROJET

### 1.1 Contexte

Dans le cadre de la formation **Administrateur Systemes et DevOps**, ce projet demontre la maitrise complete du cycle de vie d'une application cloud-native : developpement, conteneurisation, deploiement automatise, securite et supervision.

Le projet a evolue en trois phases :
- **Phase 0 (Mars 2026)** : Developpement local, authentification, Docker Compose, Prometheus/Grafana, scripts d'automatisation
- **Phase 1 (Avril 2026)** : Premiere infrastructure AWS (EC2 + RDS), pipeline CI/CD initial
- **Phase 2 (Mai 2026)** : Migration vers ECS Fargate, suppression de tout acces SSH, pipeline entierement automatise

### 1.2 Objectifs

| ID | Objectif | Statut |
|----|----------|--------|
| O1 | Developper une application de messagerie fonctionnelle | Realise |
| O2 | Conteneuriser l'application avec Docker (multi-stage) | Realise |
| O3 | Orchestrer en local avec Docker Compose | Realise |
| O4 | Deployer sur AWS avec Terraform (Infrastructure as Code) | Realise |
| O5 | Implementer un pipeline CI/CD complet avec GitHub Actions | Realise |
| O6 | Securiser les secrets avec AWS SSM Parameter Store | Realise |
| O7 | Deployer sur ECS Fargate (sans EC2, sans SSH) | Realise |
| O8 | Superviser le service avec CloudWatch et metriques Prometheus | Realise |
| O9 | Ajouter HTTPS avec nom de domaine (mini-chat.dev) | Prevu |

### 1.3 Perimetre

**Inclus :**
- Application backend API REST (Node.js/Express)
- Frontend web (HTML/CSS/JavaScript)
- Base de donnees MySQL managee (AWS RDS)
- Conteneurisation Docker optimisee multi-stage
- Infrastructure AWS entierement en code (Terraform)
- Pipeline CI/CD automatise de bout en bout
- Gestion des secrets chiffres (SSM Parameter Store)
- Supervision production (CloudWatch) et local (Prometheus + Grafana + alertes Discord)
- Schema de base de donnees auto-cree au demarrage

**Non inclus :**
- Application mobile native
- WebSocket temps reel (polling HTTP 3s utilise)
- Authentification OAuth externe

---

## 2. FONCTIONNALITES DE L'APPLICATION

### 2.1 API Backend

#### Authentification

| Route | Methode | Description |
|-------|---------|-------------|
| `/auth/register` | POST | Creation compte avec validation et hachage bcrypt |
| `/auth/login` | POST | Connexion avec generation token JWT |

Specifications :
- Validation : username 3-20 caracteres, password minimum 6 caracteres
- Hachage bcrypt avec 10 rounds de salage
- Token JWT signe avec secret injecte par AWS SSM, expiration 1 heure
- Requetes SQL preparees (protection injection SQL)

#### Messages

| Route | Methode | Auth | Description |
|-------|---------|------|-------------|
| `/messages` | GET | JWT | Recuperation de l'historique des messages |
| `/messages` | POST | JWT | Envoi d'un message avec protection XSS |

#### Metriques et disponibilite

| Route | Methode | Description |
|-------|---------|-------------|
| `/metrics` | GET | Metriques applicatives au format Prometheus |
| `/` | GET | Health check ALB (retourne "Backend OK") |

### 2.2 Frontend

| Page | Fonctionnalites |
|------|-----------------|
| `index.html` | Formulaire connexion/inscription, toggle, validation client |
| `messages.html` | Bulles de chat, refresh automatique 3s, avatars dynamiques, deconnexion |

Design : glassmorphism, animations CSS, responsive mobile-first.

### 2.3 Schema de base de donnees

```sql
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Les tables sont creees automatiquement au demarrage du container (`initSchema()` dans `database.js`). Aucune intervention manuelle n'est necessaire.

---

## 3. ARCHITECTURE TECHNIQUE

### 3.1 Vue d'ensemble

```
Developpeur
    |
    | git push main
    v
GitHub Actions (CI/CD)
    |
    |-- Job 1 : Tests et Lint
    |-- Job 2 : Build image Docker -> push ECR
    |-- Job 3 : Terraform apply -> ECS deploie la nouvelle version
    |
    v
AWS Infrastructure
    |
    |-- ALB (Application Load Balancer)
    |       Expose l'application sur Internet
    |       Health check sur GET / avant bascule du trafic
    |       Zero coupure au deploiement (rolling update)
    |
    |-- ECS Fargate
    |       Container Node.js (image depuis ECR)
    |       Redemarre automatiquement si crash
    |       Secrets injectes depuis SSM au demarrage
    |
    |-- RDS MySQL (subnet prive)
    |       Inaccessible depuis Internet
    |       Backup automatique quotidien
    |
    |-- CloudWatch
            Logs du container en temps reel
            Retention 7 jours
```

### 3.2 Architecture reseau

```
Internet
    |
  [ ALB ] ..................... subnet public  eu-west-3a + eu-west-3c
    |
  [ ECS Fargate Task ] ........ subnet public  eu-west-3a + eu-west-3c
    |                           (assign_public_ip pour atteindre ECR)
  [ RDS MySQL ] ............... subnet prive   eu-west-3a + eu-west-3c
                                (aucun acces depuis Internet)
```

### 3.3 Flux de deploiement

```
1. Developpeur push code sur GitHub (branche main)
2. GitHub Actions lance le pipeline automatiquement
3. Job 1 : tests, lint
4. Job 2 : docker build -> image taguee avec le hash du commit
           docker push ECR :sha-commit + :latest
5. Job 3 : terraform apply
           -> cree une nouvelle Task Definition ECS avec la nouvelle image
           -> ECS Service lance le nouveau container
           -> ALB verifie le health check (GET /)
           -> Si OK : trafic bascule vers le nouveau container
           -> Si KO : ancien container reste actif (rollback automatique)
6. Logs visibles dans CloudWatch en temps reel
```

### 3.4 Security Groups (principe du moindre privilege)

| Security Group | Autorise | Source |
|----------------|----------|--------|
| `mini-chat-alb-sg` | Port 80 entrant | 0.0.0.0/0 (Internet) |
| `mini-chat-ecs-sg` | Port 3000 entrant | ALB uniquement |
| `mini-chat-db-sg` | Port 3306 entrant | ECS uniquement |

La base de donnees est inaccessible depuis Internet et depuis l'ALB directement.

---

## 4. STACK TECHNIQUE

### 4.1 Application

| Technologie | Version | Usage |
|-------------|---------|-------|
| Node.js | 20 LTS | Runtime backend |
| Express.js | 4.x | Framework API REST |
| mysql2 | 3.x | Driver MySQL avec Promises et requetes preparees |
| bcrypt | 5.x | Hachage des mots de passe |
| jsonwebtoken | 9.x | Generation et verification tokens JWT |
| cors | 2.x | Gestion des requetes cross-origin |
| prom-client | 15.x | Exposition des metriques Prometheus |

### 4.2 DevOps et Infrastructure

| Technologie | Version | Usage |
|-------------|---------|-------|
| Docker | Latest | Conteneurisation multi-stage (Alpine) |
| Docker Compose | v2 | Orchestration locale (developpement uniquement) |
| Terraform | 1.5 | Infrastructure as Code AWS |
| GitHub Actions | - | Pipeline CI/CD automatise |
| AWS ECR | - | Registre d'images Docker prive |
| AWS ECS Fargate | - | Execution des containers sans gestion de serveur |
| AWS ALB | - | Load balancer applicatif, rolling updates, health checks |
| AWS RDS MySQL | 8.0 | Base de donnees managee en subnet prive |
| AWS SSM Parameter Store | - | Stockage chiffre des secrets |
| AWS CloudWatch | - | Logs et monitoring des containers en production |
| AWS S3 + DynamoDB | - | Backend state Terraform avec verrou |

### 4.3 Dockerfile multi-stage

```dockerfile
# Stage 1 : installation des dependances (image Alpine legere)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2 : image finale sans outils de build
FROM node:20-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

Resultat : image finale ~180 MB au lieu de ~950 MB avec `node:20`.

---

## 5. PIPELINE CI/CD

### 5.1 Declenchement

Chaque push sur la branche `main` declenche le pipeline automatiquement. Aucune action manuelle n'est requise.

### 5.2 Structure du pipeline

```
Job 1 : Tests et Lint
  Duree : ~30 secondes
  - npm ci (installation dependances)
  - npm run lint
  - npm test

Job 2 : Build and Push to ECR
  Duree : ~2 minutes
  Necessite : Job 1 reussi
  - Connexion a AWS ECR
  - docker build (multi-stage Alpine)
  - docker push image:<hash-commit>   <- tracabilite exacte
  - docker push image:latest          <- reference rapide

Job 3 : Deploy via Terraform
  Duree : ~3-5 minutes
  Necessite : Job 2 reussi
  - terraform init (recupere le state depuis S3)
  - terraform validate + fmt -check
  - Nettoyage etat Terraform si necessaire
  - terraform apply -auto-approve
    -> Cree nouvelle Task Definition ECS avec l'image du commit
    -> ECS Service deploie via rolling update
    -> ALB valide le health check avant bascule du trafic
```

### 5.3 Tracabilite

Chaque image Docker est taguee avec le hash exact du commit Git. La Task Definition ECS indique quelle image tourne. On peut identifier a tout moment quel commit est en production.

### 5.4 Secrets du pipeline

| Secret GitHub | Usage dans le pipeline |
|---------------|------------------------|
| `AWS_ACCESS_KEY_ID` | Authentification AWS |
| `AWS_SECRET_ACCESS_KEY` | Authentification AWS |
| `DB_PASSWORD` | Injecte dans SSM -> container ECS |
| `JWT_SECRET` | Injecte dans SSM -> container ECS |

Les secrets ne transitent jamais en clair. Terraform les stocke dans SSM Parameter Store (chiffre AES-256). ECS les recupere depuis SSM au demarrage du container.

---

## 6. INFRASTRUCTURE AWS

### 6.1 Fichiers Terraform

| Fichier | Contenu |
|---------|---------|
| `terraform/main.tf` | VPC, subnets, internet gateway, security groups, RDS |
| `terraform/ecs.tf` | IAM roles, SSM parameters, CloudWatch, ECS cluster/service/task, ALB |
| `terraform/variables.tf` | Variables d'entree (region, secrets, image_tag) |
| `terraform/outputs.tf` | URL ALB, endpoint RDS, noms ECS |
| `terraform/provider.tf` | Provider AWS, backend S3 + DynamoDB |
| `terraform/moved.tf` | Historique des renommages de ressources |

### 6.2 Ressources creees

| Ressource AWS | Nom | Configuration |
|---------------|-----|---------------|
| VPC | mini-chat-vpc | 10.0.0.0/16, DNS enabled |
| Subnet public 1 | mini-chat-public-1 | 10.0.1.0/24, eu-west-3a |
| Subnet public 2 | mini-chat-public-2 | 10.0.4.0/24, eu-west-3c |
| Subnet prive 1 | mini-chat-private-1 | 10.0.2.0/24, eu-west-3a |
| Subnet prive 2 | mini-chat-private-2 | 10.0.3.0/24, eu-west-3c |
| Security Group ALB | mini-chat-alb-sg | Port 80 depuis Internet |
| Security Group ECS | mini-chat-ecs-sg | Port 3000 depuis ALB |
| Security Group RDS | mini-chat-db-sg | Port 3306 depuis ECS |
| ALB | mini-chat-alb | Application, public, multi-AZ |
| Target Group | mini-chat-backend-tg | Port 3000, health check GET / |
| ECS Cluster | mini-chat-cluster | Fargate |
| ECS Task Definition | mini-chat-backend | 0.25 vCPU, 512 MB RAM |
| ECS Service | mini-chat-backend | desired_count = 1, rolling update |
| RDS MySQL | mini-chat-db | db.t3.micro, 20 GB, subnet prive |
| ECR | mini-chat-backend | Images Docker taguees par commit |
| SSM | /mini-chat/db_password | SecureString chiffre |
| SSM | /mini-chat/jwt_secret | SecureString chiffre |
| CloudWatch | /ecs/mini-chat-backend | Logs 7 jours de retention |
| IAM Role | mini-chat-ecs-execution-role | ECR pull + CloudWatch + SSM |
| S3 | mini-chat-tfstate-babs235 | State Terraform chiffre |
| DynamoDB | mini-chat-tflock | Verrou Terraform |

### 6.3 Rolling update sans coupure

1. Nouveau container demarre en parallele de l'ancien
2. ALB envoie une requete `GET /` sur le nouveau container
3. Si reponse 200 : trafic bascule, ancien container arrete
4. Si pas de reponse : ancien container reste actif (rollback automatique)

---

## 7. SECURITE

### 7.1 Gestion des secrets

| Secret | Phase 1 (EC2) | Phase 2 (ECS Fargate) |
|--------|---------------|----------------------|
| DB_PASSWORD | Fichier .env en clair | SSM Parameter Store chiffre AES-256 |
| JWT_SECRET | Fichier .env en clair | SSM Parameter Store chiffre AES-256 |
| AWS credentials | ~/.aws/credentials | GitHub Secrets, jamais en clair |

Les secrets ne sont jamais dans le code source, jamais dans les logs, jamais dans le state Terraform (marques `sensitive = true`).

### 7.2 Protection des acces reseau

- RDS inaccessible depuis Internet (subnet prive)
- Containers ECS accessibles uniquement via ALB (port 3000 ferme depuis Internet)
- Aucun port SSH ouvert (pas d'EC2, pas de SSH)
- Acces IAM au principe du moindre privilege

### 7.3 Protection applicative

| Attaque | Protection | Fichier |
|---------|-----------|---------|
| SQL Injection | Requetes preparees mysql2 | `auth.js`, `messages.js` |
| XSS | Echappement HTML | `messages.js` (escapeHtml) |
| JWT Forging | Secret fort depuis SSM, expiration 1h | `auth.js`, `middleware/auth.js` |
| CSRF | CORS configure, tokens JWT | `server.js` |

---

## 8. STATISTIQUES DE SERVICES — BC03

Cette section repond a la competence BC03 : *Definir et mettre en place des statistiques de services*.

### 8.1 Services surveilles

L'architecture mini-chat est composee de quatre services critiques :

| Service | Description |
|---------|-------------|
| API Node.js (ECS) | Container principal qui traite toutes les requetes |
| ALB | Point d'entree public, verifie la disponibilite du container |
| RDS MySQL | Base de donnees persistante, en subnet prive |
| Pipeline CI/CD | Deploiement automatique — echec = service non mis a jour |

### 8.2 Metriques, indicateurs, KPI — distinctions

| Terme | Definition | Exemple dans ce projet |
|-------|-----------|----------------------|
| **Metrique** | Mesure brute collectee automatiquement | 47 requetes HTTP recues, CPU a 12%, 3 messages envoyes |
| **Indicateur** | Metrique interpretee pour suivre l'etat d'un service | Taux d'erreurs 5xx sur 24h, temps de reponse moyen |
| **KPI** | Indicateur cle relie a un objectif de service | Disponibilite mensuelle 99%, p95 < 500 ms |
| **SLA** | Engagement de niveau de service | Service accessible 99% du temps, restauration < 2h |

### 8.3 Indicateurs retenus avec seuils et actions

| Service | Indicateur | Outil / Source | Seuil | Action en cas d'alerte |
|---------|-----------|---------------|-------|----------------------|
| ALB | Disponibilite (health check `GET /`) | ALB Target Group (CloudWatch) | Indisponible > 1 min | Lire CloudWatch `/ecs/mini-chat-backend`, forcer redeploi ECS |
| API | Taux d'erreurs HTTP 5xx | `/metrics` — `http_requests_total` | > 2% sur 5 min | Analyser les logs, rollback vers la revision precedente |
| ECS | Nombre de redemarrages du container | CloudWatch ECS Logs | > 3 / heure | Identifier la cause (OOM, crash, schema DB) dans les logs |
| API | CPU du container | CloudWatch — ECS CPU Utilization | > 80% pendant 10 min | Analyser la charge, envisager l'auto scaling ECS |
| API | Utilisateurs actifs (fenetre 5 min) | `/metrics` — `active_users` | 0 apres activite connue | Verifier JWT, connexion base de donnees |

### 8.4 KPI et objectifs de service (SLA)

| KPI | Objectif cible | Indicateur associe |
|-----|---------------|--------------------|
| Disponibilite mensuelle | >= 99% | ALB health check + ECS task status |
| Temps de reponse | p95 < 500 ms | ALB access logs + metriques `/metrics` |
| Taux d'erreurs | < 2% HTTP 5xx sur 24h | `http_requests_total` par code HTTP |
| Restauration apres incident | < 2 heures | Rolling update automatique ou redeploi manuel |

Ces seuils sont justifies :
- **99% de disponibilite** : standard minimal pour un service interne accessible 24h/24
- **500 ms p95** : seuil perceptible pour un utilisateur — au-dela, l'experience se degrade
- **2% d'erreurs 5xx** : taux acceptable pour absorber les erreurs transitoires sans impacter les utilisateurs
- **2h de restauration** : correspond a la duree d'un redeploi manuel complet si le pipeline echoue

### 8.5 Outils de supervision

#### Production — AWS CloudWatch

| Avantage | Detail |
|----------|--------|
| Integre nativement | Aucune infrastructure supplementaire a gerer |
| Zero configuration | Les logs ECS sont envoyes automatiquement |
| Securise | Pas de port supplementaire a ouvrir |
| Economique | Inclus dans le free tier AWS |

**Logs accessibles** : AWS Console → CloudWatch → Journaux → `/ecs/mini-chat-backend`

Logs produits au demarrage confirmes :
```
Schema initialized
Server started on port 3000
```

**Metriques CloudWatch disponibles** :
- ECS CPUUtilization et MemoryUtilization (par service et par task)
- ALB RequestCount, HTTPCode_ELB_5XX_Count, TargetResponseTime
- RDS DatabaseConnections, FreeStorageSpace

#### Developpement local — Prometheus + Grafana

Prometheus et Grafana sont configures dans `docker/docker-compose.yml` pour le developpement local uniquement.

Realise en local :
- Dashboard avec requetes HTTP totales, utilisateurs actifs, taux d'erreurs
- Alertes configurees avec envoi sur **Discord via webhook**
- Regles d'alertes : CPU eleve, backend down, nombre d'utilisateurs

**Metriques exposees par le backend sur `/metrics`** :

| Metrique | Type | Description |
|----------|------|-------------|
| `http_requests_total` | Counter | Nombre total de requetes HTTP par code et route |
| `active_users` | Gauge | Utilisateurs avec token JWT actif (fenetre 5 min) |
| `messages_created_total` | Counter | Messages envoyes depuis le demarrage |
| `process_cpu_user_seconds_total` | Counter | CPU consomme par le process Node.js |
| `process_resident_memory_bytes` | Gauge | RAM utilisee par le process Node.js |

### 8.6 Exemple d'incident reel et analyse

**Symptome** : le container ECS demarrait puis s'arretait immediatement. Les logs CloudWatch montraient :

```
Schema init failed: connect ECONNREFUSED
```

**Cause identifiee** : le container tentait de joindre MySQL avant que RDS soit pret a accepter des connexions (demarrage a froid apres un delai).

**Verification** :
1. Logs CloudWatch → flux le plus recent → message `Schema init failed`
2. ECS Console → Taches → code de sortie `1`
3. RDS Console → etat `available` mais connexions initialement refusees

**Correction appliquee** : ajout d'une gestion d'erreur non bloquante dans `initSchema()` — le serveur demarre meme si le schema echoue, et le pool MySQL gere la reconnexion automatiquement.

**Lecon** : une metrique de "container restarts" dans CloudWatch aurait detecte ce comportement immediatement sans inspection manuelle.

### 8.7 Rollback

En cas de deploiement defaillant, le rolling update de l'ALB empeche le trafic de basculer vers le container defectueux (rollback automatique).

Rollback manuel si necessaire :
```bash
aws ecs update-service \
  --cluster mini-chat-cluster \
  --service mini-chat-backend \
  --task-definition mini-chat-backend:<numero-revision-precedente> \
  --region eu-west-3
```

### 8.8 Limites actuelles et ameliorations prevues

| Limite actuelle | Amelioration prevue |
|-----------------|---------------------|
| Pas d'alerte automatique si container tombe | CloudWatch Alarm sur ECS TaskCount = 0 |
| Pas d'alerte sur erreurs 5xx | CloudWatch Alarm sur ALB HTTPCode_ELB_5XX_Count |
| Pas d'alerte CPU | CloudWatch Alarm sur ECS CPUUtilization > 80% |
| Un seul container (SPOF) | Auto Scaling ECS min 1 / max 3 |
| HTTP uniquement | HTTPS avec ACM + domaine mini-chat.dev |

---

## 9. EVOLUTIONS PREVUES

### 9.1 HTTPS avec nom de domaine (priorite haute)

**Objectif** : securiser les communications et donner une URL professionnelle.

**Domaine prevu** : `mini-chat.dev`

**Plan d'implementation** :

```
1. Achat du domaine via Route 53 (ou transfert depuis un autre registrar)
2. Creation certificat SSL dans AWS Certificate Manager (gratuit)
3. Validation du domaine (enregistrement DNS CNAME automatique)
4. Ajout listener HTTPS (port 443) sur l'ALB dans Terraform
5. Redirection HTTP -> HTTPS sur l'ALB (port 80 redirige vers 443)
6. Creation enregistrement DNS Route 53 pointant vers l'ALB
```

Fichiers Terraform a modifier : `terraform/ecs.tf` (ajout listener 443, certificat ACM), `terraform/main.tf` (port 443 dans ALB SG), nouveau `terraform/dns.tf` (Route 53).

**Resultat** : `https://mini-chat.dev` accessible depuis n'importe quel navigateur avec cadenas SSL.

### 9.2 ECR Lifecycle Policy

Supprimer automatiquement les anciennes images Docker dans ECR pour maitriser les couts.

```json
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep last 10 images",
    "selection": { "tagStatus": "any", "countType": "imageCountMoreThan", "countNumber": 10 },
    "action": { "type": "expire" }
  }]
}
```

### 9.3 CloudWatch Alarms

Alertes automatiques par email si :
- CPU ECS > 80% pendant 10 minutes
- Container passe en etat STOPPED (TaskCount = 0)
- Nombre d'erreurs HTTP 5xx > seuil defini

### 9.4 Auto Scaling ECS

Augmenter automatiquement le nombre de containers selon la charge :
- Minimum : 1 container
- Maximum : 3 containers
- Declencheur : CPU > 70% ou memoire > 80%

---

## 10. PLANNING ET LIVRABLES

### 10.1 Phase 0 — Developpement local (Mars 2026)

| Semaine | Travaux realises |
|---------|-----------------|
| Semaine 1 | Cahier des charges initial, architecture, choix techniques |
| Semaine 1 | Developpement backend minimal : Express, route `/`, MySQL |
| Semaine 2 | Authentification : bcrypt, JWT, routes `/auth/register` et `/auth/login` |
| Semaine 2 | Tests API avec Thunder Client (VS Code) |
| Semaine 3 | Docker Compose : backend + MySQL + Prometheus + Grafana |
| Semaine 3 | Script d'automatisation `start.bat` pour lancement local |
| Semaine 3 | Alertes Discord via webhook Prometheus Alertmanager |
| Semaine 3 | Frontend HTML/CSS/JS (connexion, messages, design glassmorphism) |

### 10.2 Phase 1 — Infrastructure AWS EC2 (Avril 2026)

| Semaine | Travaux realises |
|---------|-----------------|
| Semaine 4 | Terraform v1 : VPC + EC2 + RDS + Security Groups |
| Semaine 4 | Pipeline CI/CD GitHub Actions (premiere version) |
| Semaine 4 | Dockerfile multi-stage Alpine (image 6x plus legere) |
| Semaine 4 | Documentation initiale |

### 10.3 Phase 2 — ECS Fargate (Mai 2026)

| Date | Travaux realises |
|------|-----------------|
| Mai 2026 | Migration EC2 -> ECS Fargate (suppression SSH, user_data) |
| Mai 2026 | Ajout ECR avec pipeline build -> push automatise |
| Mai 2026 | ALB avec rolling update et health checks |
| Mai 2026 | SSM Parameter Store pour tous les secrets |
| Mai 2026 | CloudWatch pour les logs de production |
| Mai 2026 | Schema auto-cree au demarrage (plus de setup manuel) |
| Mai 2026 | Resolution des conflits Terraform (moved blocks, state rm + import) |
| Mai 2026 | Mise a jour complete documentation |

### 10.4 Phase 3 — Prevue

| Element | Statut |
|---------|--------|
| HTTPS avec mini-chat.dev | Planifie |
| ECR Lifecycle Policy | Planifie |
| CloudWatch Alarms | Planifie |
| Auto Scaling ECS | Planifie |

### 10.5 Livrables

| Livrable | Localisation | Statut |
|----------|--------------|--------|
| Code source | github.com/babs235/mini-chat | Disponible |
| Cahier des charges | `CAHIER_DES_CHARGES_COMPLET.md` | Complet |
| Guide de deploiement | `GUIDE_DEPLOIEMENT.md` | Complet |
| Infrastructure as Code | `terraform/` | Deploye |
| Pipeline CI/CD | `.github/workflows/ci-cd.yml` | Operationnel |
| Application en production | URL ALB eu-west-3 | En ligne |
| Monitoring production | CloudWatch `/ecs/mini-chat-backend` | Operationnel |
| Monitoring local | Prometheus + Grafana + Discord | Operationnel |

---

## 11. RETOUR D'EXPERIENCE

### 11.1 Problemes rencontres et solutions

| Probleme | Cause | Solution |
|----------|-------|----------|
| Containers ne demarraient pas sur EC2 | user_data asynchrone, .env avec valeurs bidon | Migration vers ECS Fargate |
| Image ECR jamais utilisee | docker-compose.yml buildait depuis le code source | Task Definition ECS pointe directement vers ECR |
| Terraform renommage de ressources | Changement de noms -> destroy + recreate | Blocs `moved` dans Terraform |
| Security group non modifiable | Description immuable dans AWS | Restaurer la description originale |
| DB Subnet Group conflit de state | Double entree en state Terraform | `terraform state rm` + `terraform import` dans le pipeline |
| Quotas IAM depasses | 10 politiques managees maximum par utilisateur | Suppression des doublons et politiques inutiles |
| Schema DB non initialise sur RDS | init.sql monte dans Docker local uniquement | Fonction `initSchema()` au demarrage du backend |
| Secrets en minuscules dans pipeline | GitHub Secrets est sensible a la casse | Corriger `jwt_secret` -> `JWT_SECRET` |

### 11.2 Comparaison architectures Phase 1 vs Phase 2

| Critere | Phase 1 (EC2) | Phase 2 (ECS Fargate) |
|---------|---------------|----------------------|
| Deploiement | SSH + docker compose | Pipeline automatique |
| Mise a jour code | Connexion manuelle | Push Git suffit |
| Secrets | .env en clair | SSM chiffre |
| Redemarrage si crash | Manuel | Automatique (ECS Service) |
| SSH requis | Oui | Non |
| Image Docker en production | Buildee sur EC2 | Depuis ECR (buildee en CI) |
| Rolling update | Non | Oui (ALB + ECS) |
| Coupure au deploiement | Oui (~30s) | Non (zero downtime) |

### 11.3 Competences ASD mobilisees

| Competence ASD | Comment elle est couverte |
|----------------|--------------------------|
| Automatiser le deploiement d'une infrastructure | Terraform + GitHub Actions : push = deploiement complet |
| Gerer des containers | Docker multi-stage, ECR, ECS Fargate, Docker Compose local |
| Exploiter une solution de supervision (BC03) | CloudWatch (prod), Prometheus/Grafana/Discord (local), metriques `/metrics` |
| Securiser l'infrastructure | SSM secrets, pas de SSH, moindre privilege, XSS + SQL Injection |
| Infrastructure as Code | Terraform (modules, state S3, moved blocks, import, variables) |
| CI/CD | GitHub Actions 3 jobs, secrets, tracabilite par hash de commit |
| Repondre a un incident | Rolling update, rollback manuel, analyse CloudWatch |

---

## STRUCTURE DU PROJET

```
mini-chat/
├── .github/workflows/
│   └── ci-cd.yml              # Pipeline : tests -> ECR -> Terraform -> ECS
├── backend/
│   ├── dockerfile.backend     # Multi-stage Alpine
│   ├── server.js              # Entree Express + metriques
│   └── src/
│       ├── config/database.js # Pool MySQL + migration auto au demarrage
│       ├── middleware/
│       │   ├── auth.js        # Verification JWT
│       │   └── metrics.js     # Metriques Prometheus (http, users, messages)
│       └── routes/
│           ├── auth.js        # Register / Login
│           └── messages.js    # GET / POST messages
├── database/
│   └── init.sql               # Schema SQL (reference)
├── docker/
│   ├── docker-compose.yml     # Local uniquement (+ Prometheus + Grafana)
│   └── .env.example           # Template variables locales
└── terraform/
    ├── main.tf                # VPC, subnets, security groups, RDS
    ├── ecs.tf                 # IAM, SSM, CloudWatch, ECS, ALB
    ├── variables.tf           # Variables
    ├── outputs.tf             # Outputs
    ├── moved.tf               # Historique renommages
    └── provider.tf            # Provider AWS + state S3
```

---

**Document redige par** : Babikir Ibrahim
**Formation** : Administrateur Systemes et DevOps (ASD)
**Version** : 4.0 — Architecture ECS Fargate
**Date** : Mai 2026
