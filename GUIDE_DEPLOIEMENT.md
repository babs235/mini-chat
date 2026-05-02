# GUIDE DE DEPLOIEMENT — Mini-Chat

**Auteur** : Babikir Ibrahim
**Formation** : Administrateur Systemes DevOps — Titre RNCP Niveau 6
**Depot** : github.com/babs235/mini-chat

| Version | Date | Changement principal |
|---------|------|----------------------|
| v1.0 | Avril 2026 | Architecture EC2 + RDS, pipeline CI/CD initial |
| v2.0 | Mai 2026 | Migration ECS Fargate, suppression SSH et user_data |
| v2.1 | Mai 2026 | Retrait Prometheus/Grafana, adoption CloudWatch |

---

## TABLE DES MATIERES

0. [Journal du projet](#0-journal-du-projet)
1. [Architecture](#1-architecture)
2. [Prerequis](#2-prerequis)
3. [Secrets GitHub](#3-secrets-github)
4. [Pipeline CI/CD](#4-pipeline-cicd)
5. [Infrastructure Terraform](#5-infrastructure-terraform)
6. [Monitoring](#6-monitoring)
7. [Depannage](#7-depannage)
8. [Commandes utiles](#8-commandes-utiles)

---

## 0. JOURNAL DU PROJET

Cette section retrace les grandes etapes du projet, les choix techniques faits a chaque phase, et les raisons qui ont pousse a les changer ou les conserver. L'objectif est d'avoir une traçabilite claire de l'evolution de l'application, dans l'esprit du dossier professionnel ASD.

---

### Mars 2026 — Demarrage du projet (Seance 1, 02/03)

Le programme ASD demarre le 2 mars 2026. Des la premiere seance, le projet est identifie : une application de messagerie interne, mini-chat, qui couvrira les volets automatisation d'infrastructure, deploiement continu et supervision des services.

**Choix technique initial — pourquoi Node.js et MySQL ?**
Node.js est bien adapte aux connexions multiples simultanees, ce qui correspond naturellement a une application de chat. MySQL est une base relationnelle robuste, standard dans les projets web, et facile a conteneuriser. Express a ete choisi pour sa simplicite : c'est le framework minimal, sans surcouche inutile.

**Semaines 1 et 2 — Developpement du backend**

Le backend est construit progressivement :
- Routes `/auth/register` et `/auth/login` avec hachage `bcrypt` et tokens JWT
- Routes `/messages` (GET et POST) protegees par verification du token
- Protection XSS par echappement HTML avant insertion en base
- Requetes SQL preparees pour se proteger des injections

Les routes sont testees avec Thunder Client dans VS Code avant toute conteneurisation.

**Semaine 2 — Frontend**

Interface HTML/CSS/JS simple : une page de connexion, une page de messages avec rafraichissement automatique toutes les 3 secondes. Design glassmorphism, responsive mobile-first. Le frontend est statique, servi directement par Express depuis le dossier `frontend/`.

**Semaine 3 — Conteneurisation et environnement local**

Docker Compose est mis en place pour lancer l'environnement complet en une commande. A ce stade, le `docker-compose.yml` inclut : le backend Node.js, une base MySQL avec healthcheck, Prometheus et Grafana.

Prometheus et Grafana sont ajoutes pour avoir un outil de supervision en local. Le backend expose une route `/metrics` au format Prometheus. Des alertes sont configurees avec envoi sur Discord via webhook Alertmanager — CPU eleve, backend down, nombre d'utilisateurs actifs.

Un script `start.bat` est cree pour lancer l'environnement local en une commande sur Windows.

---

### Avril 2026 — Premiere infrastructure AWS

**Semaine 4 — Terraform v1 : EC2 + RDS**

L'infrastructure est ecrite entierement en Terraform : VPC, subnets publics et prives, internet gateway, security groups, instance EC2, RDS MySQL. Le pipeline GitHub Actions (premiere version) est cree : il installe les dependances, lance les tests, puis deploie via SSH sur l'EC2.

**Dockerfile multi-stage Alpine**

Le Dockerfile est reecrit en multi-stage pour reduire la taille de l'image. Le stage `deps` installe les dependances avec `npm ci --only=production`. Le stage final ne contient que le code et les modules, sans les outils de build. Resultat : environ 180 MB au lieu de 950 MB avec `node:20` standard.

**Probleme rencontre : les containers ne demarraient pas**

Apres plusieurs pushs successifs, le pipeline passait en vert mais l'application ne repondait pas. En inspectant l'EC2, le constat etait clair :
- Le script `user_data` s'executait de facon asynchrone au demarrage de l'instance, soit 8 a 10 minutes apres le deploiement
- Ce script utilisait les valeurs par defaut du `.env.example` au lieu des vraies variables d'environnement
- L'image Docker etait buildee directement sur l'EC2 depuis le code source, au lieu d'etre tiree depuis ECR
- A chaque nouveau commit, rien ne forçait l'EC2 a redemarrer l'application

Ce probleme a rendu EC2 inadapte au deploiement continu tel qu'attendu dans le cadre ASD.

---

### Mai 2026 — Migration vers ECS Fargate

**Decision : abandonner EC2 et passer a ECS Fargate**

ECS Fargate resout tous les problemes identifies avec EC2 :
- Plus de `user_data`, plus de SSH, plus de connexion manuelle a la machine
- Le pipeline fait tout : build de l'image, push dans ECR, mise a jour de la Task Definition ECS
- Si le container crashe, ECS le redemmarre automatiquement
- L'ALB (Application Load Balancer) fait un health check avant de basculer le trafic : si le nouveau container ne repond pas, l'ancien reste actif (rollback automatique)

**Ce qui a ete mis en place :**
- ECR pour stocker les images Docker taguees avec le hash exact du commit (`github.sha`)
- ALB avec deux subnets publics (eu-west-3a et eu-west-3c) pour la haute disponibilite
- Trois security groups avec le principe du moindre privilege : ALB n'accepte que le port 80 depuis Internet, ECS n'accepte que le port 3000 depuis l'ALB, RDS n'accepte que le port 3306 depuis ECS
- SSM Parameter Store pour les secrets : `DB_PASSWORD` et `JWT_SECRET` stockes chiffres, jamais en clair dans le code ni dans les logs
- CloudWatch pour les logs du container : le groupe `/ecs/mini-chat-backend` recoit tous les logs en temps reel, avec retention 7 jours

**Schema de base de donnees automatique**

RDS en subnet prive n'a pas d'acces Query Editor (contrairement a Aurora Serverless). Plutot que de necessiter une intervention manuelle a chaque nouveau deploiement, la fonction `initSchema()` dans `database.js` cree les tables automatiquement au demarrage du container avec `CREATE TABLE IF NOT EXISTS`. C'est idempotent : si les tables existent deja, rien ne se passe.

**Problemes Terraform rencontres et resolus**

Plusieurs erreurs de state Terraform ont ete rencontrees lors de la migration :
- Renommage de ressources → Terraform voulait detruire et recreer → resolution par des blocs `moved` dans `terraform/moved.tf`
- Description d'un security group immuable dans AWS → restauration de la description originale pour que seule la regle d'entree change en place
- Double entree du DB Subnet Group en state → resolution par `terraform state rm` + `terraform import` directement dans le pipeline CI/CD
- Quota IAM de 10 politiques managees depasse → suppression des doublons et politiques inutilisees

---

### Mai 2026 — Retrait de Prometheus et Grafana (v2.1)

**Contexte**

Prometheus et Grafana avaient ete mis en place en local des la semaine 3 pour avoir un outil de supervision pendant le developpement. Le backend exposait ses metriques sur `/metrics` (prom-client). Des alertes etaient configurees avec Discord via webhook.

**Pourquoi ce choix a ete revise**

Prometheus et Grafana tournaient uniquement sur le PC local via Docker Compose. Ils ne supervisaient pas le service deploye sur AWS — ils supervisaient une instance locale qui n'est pas accessible en production et qui ne tourne pas en permanence.

L'objectif est de superviser le service *deploye*, pas une simulation locale. L'application en production tourne sur ECS Fargate en region eu-west-3. Prometheus sur le PC local ne voit pas ce container.

Par ailleurs, deployer Prometheus et Grafana sur AWS aurait necessite :
- Une instance EC2 ou un container ECS dedie a Prometheus
- Un port ouvert supplementaire (9090) sur le security group
- Une configuration de scraping vers l'endpoint `/metrics` du container ECS
- Une gestion de la persistance pour Grafana

CloudWatch est deja integre nativement a ECS : les logs sont envoyes automatiquement sans configuration, les metriques CPU, memoire, ALB 5xx et temps de reponse sont disponibles directement dans la console AWS. Zero port supplementaire, zero infrastructure de monitoring a gerer.

**Ce qui a ete supprime**
- `backend/src/middleware/metrics.js` (prom-client, compteurs Prometheus)
- `docker/prometheus.yml` et `docker/prometheus/alerts/` (configuration Alertmanager)
- Services `prometheus` et `grafana` dans `docker-compose.yml`
- Dependance `prom-client` dans `package.json`
- Route `/metrics` dans `server.js`
- Import de `messagesCreated` dans `messages.js`

**Ce qui remplace**

CloudWatch collecte nativement : logs du container ECS, CPUUtilization, MemoryUtilization, ALB HTTPCode_ELB_5XX_Count, ALB TargetResponseTime, RDS FreeStorageSpace. Ces indicateurs couvrent la disponibilite, la performance, les erreurs, les ressources et le stockage — tout ce qu'on a besoin de superviser sur ce service.

---

## 1. ARCHITECTURE

### Vue d'ensemble

```
GitHub (push) → GitHub Actions → ECR → ECS Fargate → ALB → Utilisateur
                                  └──────────────────────→ RDS MySQL
```

### Composants AWS

| Composant | Nom AWS | Role |
|-----------|---------|------|
| Registry | ECR `mini-chat-backend` | Stocke les images Docker |
| Containers | ECS Fargate `mini-chat-cluster` | Fait tourner l'application |
| Load Balancer | ALB `mini-chat-alb` | Distribue le trafic, zero coupure au deploy |
| Base de donnees | RDS MySQL `mini-chat-db` | Donnees persistantes en subnet prive |
| Secrets | SSM Parameter Store | Stocke DB_PASSWORD et JWT_SECRET chiffres |
| Logs | CloudWatch `/ecs/mini-chat-backend` | Logs des containers en temps reel |

### Reseau

```
Internet
    |
  [ ALB ] — subnet public eu-west-3a + eu-west-3c
    |
  [ ECS Task ] — subnet public (assign_public_ip pour atteindre ECR)
    |
  [ RDS MySQL ] — subnet prive eu-west-3a + eu-west-3c (inaccessible depuis internet)
```

### Security Groups

| SG | Autorise | Depuis |
|----|----------|--------|
| `mini-chat-alb-sg` | Port 80 entrant | Internet (0.0.0.0/0) |
| `mini-chat-ecs-sg` | Port 3000 entrant | ALB uniquement |
| `mini-chat-db-sg` | Port 3306 entrant | ECS uniquement |

---

## 2. PREREQUIS

### Outils locaux (developpement uniquement)

- Git
- Docker Desktop (pour tester en local avec docker-compose)
- Terraform v1.5+ (si modifications d'infrastructure)
- AWS CLI (optionnel, pour consulter les ressources)

### Compte AWS

- Region : `eu-west-3` (Paris)
- Etat Terraform stocke dans S3 : `mini-chat-tfstate-babs235`
- Verrou Terraform dans DynamoDB : `mini-chat-tflock`

### Permissions IAM (user mini-chat-admin)

| Politique | Usage |
|-----------|-------|
| AmazonECS_FullAccess | Gerer ECS cluster, service, task |
| AmazonEC2ContainerRegistryFullAccess | Pousser les images dans ECR |
| AmazonEC2FullAccess | VPC, subnets, security groups |
| AmazonRDSFullAccess | Gerer RDS |
| AmazonS3FullAccess | State Terraform |
| AmazonDynamoDBFullAccess | Verrou Terraform |
| AmazonSSMFullAccess | Secrets chiffres |
| IAMFullAccess | Creer les roles ECS |
| ElasticLoadBalancingFullAccess | Creer et gerer l'ALB |
| CloudWatchLogsFullAccess | Consulter les logs containers |

---

## 3. SECRETS GITHUB

Aller dans GitHub → Settings → Secrets and variables → Actions.

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Cle d'acces AWS |
| `AWS_SECRET_ACCESS_KEY` | Cle secrete AWS |
| `DB_PASSWORD` | Mot de passe MySQL RDS |
| `JWT_SECRET` | Cle de signature des tokens JWT |

Ces valeurs ne sont jamais en clair dans le code. Terraform les injecte dans SSM Parameter Store, et ECS les recupere depuis SSM au demarrage du container.

---

## 4. PIPELINE CI/CD

### Declenchement

Chaque push sur la branche `main` declenche le pipeline automatiquement.

### Etapes

```
Job 1 : Tests et Lint
  └── npm ci
  └── npm run lint
  └── npm test

Job 2 : Build and Push to ECR          (necessite Job 1)
  └── docker build (multi-stage alpine)
  └── push image:<sha-du-commit>
  └── push image:latest

Job 3 : Deploy via Terraform           (necessite Job 2)
  └── terraform init
  └── terraform validate
  └── terraform fmt -check
  └── fix state (import subnet group)
  └── terraform apply -auto-approve
      └── cree/met a jour ECS Task Definition avec la nouvelle image
      └── ECS Service deploie la nouvelle version (rolling update)
      └── ALB verifie que le nouveau container repond avant de basculer le trafic
```

### Duree approximative

| Job | Duree |
|-----|-------|
| Tests | ~30 secondes |
| Build & Push | ~2 minutes |
| Deploy Terraform | ~3-5 minutes |

### Tracer un deploiement

Chaque image est taguee avec le hash du commit Git (`github.sha`). Dans ECS, la Task Definition indique exactement quelle image tourne. On peut donc savoir a tout moment quel commit est en production.

---

## 5. INFRASTRUCTURE TERRAFORM

### Fichiers

| Fichier | Contenu |
|---------|---------|
| `terraform/main.tf` | VPC, subnets, security groups, RDS |
| `terraform/ecs.tf` | IAM, SSM, CloudWatch, ECS, ALB |
| `terraform/variables.tf` | Variables (region, secrets, image_tag) |
| `terraform/outputs.tf` | Outputs apres apply (URL ALB, endpoint RDS) |
| `terraform/moved.tf` | Historique des renommages de ressources |
| `terraform/provider.tf` | Provider AWS + backend S3 |

### Outputs apres deploiement

```
app_url     = "http://mini-chat-alb-xxxxxxxxx.eu-west-3.elb.amazonaws.com"
rds_endpoint = "mini-chat-db.xxxxxxxxx.eu-west-3.rds.amazonaws.com:3306"
ecs_cluster = "mini-chat-cluster"
ecs_service = "mini-chat-backend"
```

### Variables Terraform

| Variable | Source | Description |
|----------|--------|-------------|
| `aws_region` | terraform.tfvars | eu-west-3 |
| `db_password` | GitHub Secret `DB_PASSWORD` | Mot de passe RDS |
| `jwt_secret` | GitHub Secret `JWT_SECRET` | Cle JWT |
| `image_tag` | Pipeline `github.sha` | Tag de l'image ECR a deployer |

### Modifier l'infrastructure

1. Modifier les fichiers `.tf`
2. Commiter et pousser sur `main`
3. Le pipeline applique les changements automatiquement

Pour tester localement avant de pousser :
```bash
cd terraform
terraform init
terraform plan
```

### Rolling update (zero downtime)

Quand un nouveau commit est pousse :
1. Terraform cree une nouvelle revision de Task Definition
2. ECS lance le nouveau container en parallele de l'ancien
3. ALB verifie que le nouveau repond sur `GET /` (health check)
4. Si OK : trafic bascule vers le nouveau, ancien arrete
5. Si KO : ancien reste en place, nouveau est retire — rollback automatique

---

## 6. MONITORING

### Logs en temps reel

**AWS Console → CloudWatch → Journaux → Groupes de journaux → `/ecs/mini-chat-backend`**

Cliquer sur le flux le plus recent pour voir les logs du container.

Logs attendus au demarrage :
```
Schema initialized
Server started on port 3000
```

### Etat du service ECS

**AWS Console → ECS → Clusters → mini-chat-cluster → Services → mini-chat-backend → Taches**

- Statut `EN COURS D'EXECUTION` : tout va bien
- Statut `ARRETE` avec code d'erreur : lire les logs CloudWatch

### Metriques CloudWatch disponibles

| Source | Metrique | Description |
|--------|---------|-------------|
| ECS | CPUUtilization | CPU du container |
| ECS | MemoryUtilization | RAM du container |
| ALB | HTTPCode_ELB_5XX_Count | Erreurs 5xx |
| ALB | TargetResponseTime | Temps de reponse |
| RDS | FreeStorageSpace | Espace disque restant |

### Rollback manuel

Si une version est cassee, forcer le retour a la version precedente :

```bash
# Recuperer le numero de la revision precedente dans ECS
aws ecs describe-task-definition \
  --task-definition mini-chat-backend \
  --region eu-west-3

# Mettre a jour le service avec l'ancienne revision
aws ecs update-service \
  --cluster mini-chat-cluster \
  --service mini-chat-backend \
  --task-definition mini-chat-backend:<numero-revision-precedente> \
  --region eu-west-3
```

---

## 7. DEPANNAGE

### Le container ne demarre pas

**1. Verifier les logs CloudWatch**

CloudWatch → Groupes de journaux → `/ecs/mini-chat-backend` → flux le plus recent.

Erreurs courantes :
- `Schema init failed` : le container ne peut pas joindre RDS
- `Cannot find module` : probleme de build Docker
- `JWT_SECRET not defined` : secret SSM manquant ou mal configure

**2. Verifier l'etat de la Task dans ECS**

ECS → mini-chat-cluster → Taches → cliquer sur la tache arretee → section "Conteneurs" → voir le code de sortie et le message d'arret.

---

### Erreurs Terraform connues

#### `DBSubnetGroupAlreadyExists`

```
Error: creating RDS DB Subnet Group: DBSubnetGroupAlreadyExists
```

Cause : conflit entre l'etat Terraform et ce qui existe sur AWS.

Solution : le pipeline contient une etape "Fix Terraform state" qui resout cela automatiquement.

---

#### `InvalidGroup.Duplicate`

```
Error: creating Security Group: InvalidGroup.Duplicate
```

Cause : le security group existe deja (precedent deploiement echoue a mi-chemin).

Solution :
```bash
cd terraform
terraform import aws_security_group.alb_sg <sg-id>
```

---

#### `AuthFailure` sur DetachNetworkInterface

```
api error AuthFailure: You do not have permission to access the specified resource
```

Cause : permissions IAM insuffisantes pour detacher une ENI (interface reseau RDS).

Solution : verifier que `AmazonEC2FullAccess` est bien attache au user IAM.

---

#### `AccessDeniedException` sur ECS

```
not authorized to perform: ecs:CreateCluster
```

Cause : `AmazonECS_FullAccess` manquant sur le user IAM.

Solution : ajouter la politique dans IAM → Users → mini-chat-admin.

---

#### Pipeline vert mais app ne repond pas

1. Attendre 2-3 minutes — ECS met du temps a demarrer le container et l'ALB a le valider
2. Verifier les logs CloudWatch
3. Verifier l'onglet "Taches" dans ECS (statut RUNNING ?)
4. Verifier que le health check ALB passe : ALB → Target Groups → mini-chat-backend-tg → Targets

---

### Checklist avant de pusher

- [ ] `terraform fmt` passe sans erreur
- [ ] Secrets GitHub configures : `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DB_PASSWORD`, `JWT_SECRET`
- [ ] Pas de mot de passe ou cle en clair dans le code
- [ ] `docker-compose` fonctionne en local (test optionnel)

---

## 8. COMMANDES UTILES

### Developpement local

```bash
# Lancer l'application en local
cd docker
cp .env.example .env   # remplir avec de vraies valeurs locales
docker compose up -d

# Voir les logs en local
docker compose logs -f backend

# Arreter
docker compose down
```

### Consulter l'infrastructure depuis le terminal

```bash
# Afficher les outputs Terraform (URL ALB, endpoint RDS, etc.)
cd terraform
terraform output

# Lister les tasks ECS en cours
aws ecs list-tasks \
  --cluster mini-chat-cluster \
  --region eu-west-3

# Voir les logs recents du container
aws logs tail /ecs/mini-chat-backend \
  --follow \
  --region eu-west-3
```

### Forcer un nouveau deploiement sans changer le code

```bash
aws ecs update-service \
  --cluster mini-chat-cluster \
  --service mini-chat-backend \
  --force-new-deployment \
  --region eu-west-3
```

### Structure du projet

```
mini-chat/
├── .github/workflows/
│   └── ci-cd.yml              # Pipeline : tests → build ECR → deploy Terraform
├── backend/
│   ├── dockerfile.backend     # Multi-stage Alpine (image legere)
│   ├── server.js              # Point d'entree Express
│   └── src/
│       ├── config/database.js # Pool MySQL + migration au demarrage
│       ├── middleware/
│       │   └── auth.js        # Verification token JWT
│       └── routes/
│           ├── auth.js        # Inscription / Connexion
│           └── messages.js    # Envoi / Reception messages
├── database/
│   └── init.sql               # Schema SQL (reference, execute au demarrage de l'app)
├── docker/
│   ├── docker-compose.yml     # Local uniquement (backend + MySQL)
│   └── .env.example           # Template variables locales
└── terraform/
    ├── main.tf                # VPC, subnets, security groups, RDS
    ├── ecs.tf                 # IAM, SSM, CloudWatch, ECS, ALB
    ├── variables.tf           # Variables d'entree
    ├── outputs.tf             # Valeurs de sortie
    ├── moved.tf               # Historique renommages ressources
    └── provider.tf            # Provider AWS + backend S3
```
