# GUIDE DE DEPLOIEMENT — Mini-Chat

**Auteur** : Babikir Ibrahim  
**Version** : 2.0 — Architecture ECS Fargate  
**Derniere mise a jour** : Mai 2026

---

## TABLE DES MATIERES

1. [Architecture](#1-architecture)
2. [Prerequis](#2-prerequis)
3. [Secrets GitHub](#3-secrets-github)
4. [Pipeline CI/CD](#4-pipeline-cicd)
5. [Infrastructure Terraform](#5-infrastructure-terraform)
6. [Monitoring](#6-monitoring)
7. [Depannage](#7-depannage)
8. [Commandes utiles](#8-commandes-utiles)

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
