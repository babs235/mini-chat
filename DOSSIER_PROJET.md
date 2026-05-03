# PROMPT — Dossier de Projet ASD Niveau 6
## Mini-Chat — Administrateur Système DevOps

---

> **Instructions pour l'IA :**
> Génère un dossier de projet professionnel en français, format PDF ou Word.
> Mise en page sobre et professionnelle : police Arial ou Calibri 11pt, titres numérotés,
> tableaux propres, blocs de code en monospace avec fond grisé.
> Le document suit EXACTEMENT le plan type imposé par le référentiel ASD RE TP-01414-01.
> Longueur cible : 25 à 35 pages.
> Ne génère PAS de slides — c'est un document texte structuré, pas une présentation.
> Toutes les sections doivent être rédigées en français professionnel, à la première personne.
> Les extraits de code sont réels — reproduis-les fidèlement avec leur contexte expliqué.

---

## INFORMATIONS DU DOCUMENT

| Champ | Valeur |
|-------|--------|
| Titre du projet | Mini-Chat — Application de messagerie cloud-native |
| Candidat | Babikir Ibrahim |
| Formation | Administrateur Système DevOps — Titre RNCP Niveau 6 |
| Référentiel | RE TP-01414-01 |
| Date | Mai 2026 |
| Dépôt GitHub | github.com/babs235/mini-chat |
| Application en production | https://chat.ibrahimbabikir.fr |

---

---

# SECTION 1 — LISTE DES COMPÉTENCES COUVERTES PAR LE PROJET

Cette section liste les compétences du référentiel ASD RE TP-01414-01 couvertes par ce projet.

**Compétences obligatoires (toutes couvertes) :**
- Automatiser le déploiement d'une infrastructure ✅
- Gérer des containers ✅
- Exploiter une solution de supervision ✅

**Toutes les compétences couvertes :**

| Compétence | Comment elle est couverte |
|-----------|--------------------------|
| Automatiser la création de serveurs à l'aide de scripts | Terraform crée l'intégralité de l'infrastructure AWS. Scripts `start.bat` / `start.sh` automatisent le démarrage local. |
| Automatiser le déploiement d'une infrastructure | Un `git push` déclenche le pipeline GitHub Actions qui provisionne ou met à jour toute l'infrastructure via `terraform apply`. |
| Sécuriser l'infrastructure | Pas de SSH, Security Groups en moindre privilège, HTTPS TLS 1.3, secrets chiffrés SSM, tests bloquant le déploiement. |
| Mettre l'infrastructure en production dans le cloud | Application déployée sur AWS ECS Fargate eu-west-3, accessible publiquement via https://chat.ibrahimbabikir.fr. |
| Préparer un environnement de test | 9 tests Jest automatisés + smoke tests Docker (Job 3) qui testent l'image ECR exacte avant déploiement. |
| Gérer le stockage des données | RDS MySQL en subnet privé, backup quotidien, accès restreint aux seuls containers ECS. |
| Gérer des containers | Docker multi-stage Alpine, ECR, ECS Fargate, rolling update automatique, Task Definition déclarative. |
| Automatiser la mise en production avec une plateforme | Pipeline 4 jobs : tests → build ECR → smoke tests pré-prod → terraform deploy. Zéro intervention manuelle. |
| Définir et mettre en place des statistiques de services | KPI et SLA définis, 4 alarmes CloudWatch configurées en Terraform, seuils alignés sur les objectifs de service. |
| Exploiter une solution de supervision | CloudWatch Logs + Metrics en production, incident réel analysé et résolu via les logs, notifications SNS par email. |

---

---

# SECTION 2 — CAHIER DES CHARGES

## 2.1 Contexte du projet

Ce projet est réalisé dans le cadre de la formation Administrateur Système DevOps. L'objectif est de démontrer la maîtrise complète du cycle de vie d'une application cloud-native : développement, conteneurisation, déploiement automatisé, sécurisation et supervision.

Le projet couvre les trois activités types du titre ASD :
- CCP1 : Automatiser le déploiement d'une infrastructure dans le cloud
- CCP2 : Déployer en continu une application
- CCP3 : Superviser les services déployés

Le projet a été réalisé intégralement en centre de formation, sans entreprise.

## 2.2 Périmètre

**Inclus dans le projet :**
- Application backend API REST (Node.js/Express)
- Frontend web (HTML/CSS/JavaScript)
- Base de données MySQL managée (AWS RDS)
- Conteneurisation Docker multi-stage optimisée
- Infrastructure AWS entièrement en code (Terraform)
- Pipeline CI/CD automatisé de bout en bout (GitHub Actions, 4 jobs)
- Gestion des secrets chiffrés (AWS SSM Parameter Store)
- HTTPS sur domaine propre (AWS ACM + IONOS DNS)
- Supervision production (CloudWatch Logs + 4 alarmes + notifications SNS)
- Tests automatisés (Jest) et smoke tests pré-déploiement

**Non inclus :**
- Application mobile native
- WebSocket temps réel (polling HTTP 3s utilisé)
- Authentification OAuth externe
- Auto-scaling ECS (planifié en évolution)

## 2.3 Objectifs

| ID | Objectif | Statut |
|----|----------|--------|
| O1 | Développer une application de messagerie fonctionnelle | Réalisé |
| O2 | Conteneuriser l'application avec Docker multi-stage | Réalisé |
| O3 | Orchestrer en local avec Docker Compose | Réalisé |
| O4 | Déployer sur AWS avec Terraform (Infrastructure as Code) | Réalisé |
| O5 | Implémenter un pipeline CI/CD complet avec GitHub Actions | Réalisé |
| O6 | Sécuriser les secrets avec AWS SSM Parameter Store | Réalisé |
| O7 | Déployer sur ECS Fargate (sans EC2, sans SSH) | Réalisé |
| O8 | Superviser le service avec CloudWatch et 4 alarmes configurées | Réalisé |
| O9 | Exposer l'application en HTTPS avec nom de domaine propre | Réalisé |
| O10 | Mettre en place des notifications d'alerte par email (SNS) | Réalisé |

## 2.4 Contraintes

| Contrainte | Détail |
|-----------|--------|
| Budget | Free Tier AWS — ressources minimales : ECS 0.25 vCPU / 512 MB, RDS db.t3.micro 20 Go |
| Domaine | Acheté chez IONOS — pas de Route 53 → CNAMEs gérés manuellement |
| Pas de WebSocket | Rafraîchissement HTTP toutes les 3 secondes |
| RDS en subnet privé | Pas d'accès direct à la base → schéma créé automatiquement au démarrage de l'application |
| IAM quota | 10 politiques managées maximum par utilisateur IAM → gestion rigoureuse des permissions |
| Projet solo | Pas d'équipe de développeurs — le pipeline et CloudWatch jouent le rôle de canal de communication |

## 2.5 Livrables

| Livrable | Localisation | Statut |
|---------|-------------|--------|
| Code source complet | github.com/babs235/mini-chat | Disponible |
| Infrastructure as Code | terraform/ (7 fichiers) | Déployé |
| Pipeline CI/CD | .github/workflows/ci-cd.yml | Opérationnel |
| Application HTTPS | https://chat.ibrahimbabikir.fr | En ligne |
| Supervision | CloudWatch + 4 alarmes + SNS | Opérationnel |
| Guide de déploiement | GUIDE_DEPLOIEMENT.md | Complet |
| Dossier de projet | DOSSIER_PROJET.md | Ce document |

---

---

# SECTION 3 — SPÉCIFICATIONS TECHNIQUES

## 3.1 Vue d'ensemble de l'architecture

```
Développeur
    |
    | git push main
    ↓
GitHub Actions (CI/CD — 4 jobs séquentiels)
    |
    ├── Job 1 — Tests Jest (9 tests)         bloque si échec
    ├── Job 2 — Build Docker → push ECR       image :sha-commit
    ├── Job 3 — Smoke Tests pré-prod          même image ECR testée
    └── Job 4 — terraform apply               ECS déploie la nouvelle version
                        |
                        ↓
        AWS eu-west-3 (Paris)
        ┌─────────────────────────────────────────────────┐
        │                                                 │
        │  Utilisateur → HTTPS 443 → [ACM] → [ALB]       │
        │                              |                  │
        │              health check GET / (avant bascule) │
        │                              ↓                  │
        │           [ECS Fargate — Node.js port 3000]     │
        │                  subnets publics eu-west-3a/3c  │
        │                              |                  │
        │                         port 3306               │
        │           [RDS MySQL — subnets privés]          │
        │                  eu-west-3a + eu-west-3c        │
        │                                                 │
        │  CloudWatch Logs (/ecs/mini-chat-backend)       │
        │  4 Alarmes CloudWatch → SNS → Email             │
        └─────────────────────────────────────────────────┘
```

## 3.2 Réseau — VPC et subnets

| Ressource | Nom | CIDR / AZ | Rôle |
|---------|-----|-----------|------|
| VPC | mini-chat-vpc | 10.0.0.0/16 | Réseau isolé |
| Subnet public 1 | mini-chat-public-1 | 10.0.1.0/24 / eu-west-3a | ALB + ECS |
| Subnet public 2 | mini-chat-public-2 | 10.0.4.0/24 / eu-west-3c | ALB + ECS (HA) |
| Subnet privé 1 | mini-chat-private-1 | 10.0.2.0/24 / eu-west-3a | RDS |
| Subnet privé 2 | mini-chat-private-2 | 10.0.3.0/24 / eu-west-3c | RDS (HA) |

**Pourquoi 2 AZ :** l'ALB et RDS exigent au minimum 2 zones de disponibilité différentes. ECS est aussi réparti sur 2 AZ pour la haute disponibilité.

## 3.3 Security Groups — principe du moindre privilège

| Security Group | Règle entrante | Source | Règle sortante |
|----------------|---------------|--------|---------------|
| mini-chat-alb-sg | Port 80 (HTTP) | 0.0.0.0/0 | Tout |
| mini-chat-alb-sg | Port 443 (HTTPS) | 0.0.0.0/0 | Tout |
| mini-chat-ecs-sg | Port 3000 | mini-chat-alb-sg uniquement | Tout |
| mini-chat-db-sg | Port 3306 | mini-chat-ecs-sg uniquement | Tout |

**Résultat :** la base de données est inaccessible depuis Internet, depuis l'ALB et depuis toute ressource qui n'est pas un container ECS. Aucun port SSH ouvert sur aucune ressource.

## 3.4 ECS Fargate — Task Definition

| Paramètre | Valeur | Justification |
|---------|-------|--------------|
| CPU | 256 (0.25 vCPU) | Suffisant pour une application Node.js légère |
| Mémoire | 512 MB | Marges confortables pour Express + mysql2 |
| Network mode | awsvpc | Obligatoire avec Fargate |
| Image | ECR :sha-commit | Tracabilité exacte par commit Git |
| assign_public_ip | true | Sans NAT Gateway (32$/mois), le container doit avoir une IP publique pour joindre ECR et CloudWatch. L'accès entrant reste bloqué par le Security Group. |

**Limites assumées et justifiées :**
- `DB_USER = "root"` : en production réelle, un utilisateur MySQL dédié avec uniquement les droits SELECT/INSERT/UPDATE sur la base `mini_chat` serait créé. Pour ce projet formation, le compte root est utilisé par souci de simplicité — aucun autre service ne partage cette base.
- `assign_public_ip = true` : nécessaire sans NAT Gateway. Le Security Group `mini-chat-ecs-sg` garantit qu'aucun trafic entrant direct n'est possible depuis Internet.

**Secrets injectés depuis SSM (jamais en clair) :**
- `DB_PASSWORD` ← `/mini-chat/db_password` (SecureString AES-256)
- `JWT_SECRET` ← `/mini-chat/jwt_secret` (SecureString AES-256)

## 3.5 ALB — Load Balancer et HTTPS

| Listener | Port | Action |
|---------|------|--------|
| HTTP | 80 | Redirect 301 → HTTPS |
| HTTPS | 443 | Forward vers ECS (TLS 1.3, ELBSecurityPolicy-TLS13-1-2-2021-06) |

**Health check :** `GET /` → réponse attendue HTTP 200. L'ALB attend la réponse avant de basculer le trafic vers le nouveau container (rolling update). Si le health check échoue, l'ancien container reste actif.

**Limite connue du health check :** la route `/` retourne 200 même si RDS est temporairement inaccessible, car `initSchema()` est non bloquant. Le health check valide que le processus Node.js répond, pas que la base de données est joignable. En production, un endpoint `/health` dédié qui exécute une requête `SELECT 1` sur MySQL fournirait une vérification plus fiable.

**Certificat ACM :** `chat.ibrahimbabikir.fr`, validation DNS, créé dans Terraform. Deux CNAMEs ajoutés manuellement dans le panel IONOS.

## 3.6 RDS MySQL

| Paramètre | Valeur |
|---------|-------|
| Engine | MySQL 8.0 |
| Instance class | db.t3.micro |
| Stockage | 20 Go gp2 |
| Subnet group | subnets privés eu-west-3a + eu-west-3c |
| Backup | 1 jour de rétention, fenêtre 03:00-04:00 UTC |
| Accès public | Non |
| skip_final_snapshot | true — pas de snapshot final à la suppression (contrainte Free Tier, projet formation) |

## 3.7 CloudWatch Supervision

| Alarme | Métrique | Seuil | Action |
|-------|---------|-------|--------|
| Container stoppé | ECS RunningTaskCount | < 1 pendant 1 min | Email SNS |
| Erreurs 5xx | ALB HTTPCode_ELB_5XX_Count | > 10 sur 5 min | Email SNS |
| CPU ECS élevé | ECS CPUUtilization | > 80% pendant 10 min | Email SNS |
| Disque RDS faible | RDS FreeStorageSpace | < 2 Go | Email SNS |

**SNS :** topic `mini-chat-alerts`, abonnement email confirmé, politique autorisant `cloudwatch.amazonaws.com` à publier.

**Prérequis Container Insights :** la métrique `RunningTaskCount` utilisée par l'alarme "container stoppé" appartient au namespace `ECS/ContainerInsights`. Elle n'existe que si Container Insights est activé sur le cluster ECS (`containerInsights = "enabled"` dans la ressource `aws_ecs_cluster`). Sans cette activation, l'alarme ne reçoit aucune donnée et reste en état `INSUFFICIENT_DATA`.

## 3.8 Fichiers Terraform

| Fichier | Contenu |
|---------|---------|
| main.tf | VPC, subnets, Internet Gateway, 3 Security Groups, RDS MySQL |
| ecs.tf | IAM roles, SSM secrets, CloudWatch logs, ECS cluster/task/service, ALB, ACM |
| monitoring.tf | 4 alarmes CloudWatch + SNS topic + abonnement email |
| variables.tf | Variables d'entrée (région, secrets, image_tag) |
| outputs.tf | URL ALB, endpoint RDS, noms ECS |
| provider.tf | Provider AWS + backend state S3 (chiffré, sans verrou DynamoDB) |
| moved.tf | Historique des renommages de ressources sans destruction |

## 3.9 Application — Routes API

| Route | Méthode | Auth JWT | Description |
|-------|---------|----------|-------------|
| `/auth/register` | POST | Non | Inscription — validation, bcrypt 10 rounds |
| `/auth/login` | POST | Non | Connexion — retourne token JWT (1h) |
| `/messages` | GET | Oui | Historique des messages avec username et timestamp |
| `/messages` | POST | Oui | Envoi message — validation longueur, protection XSS |
| `/` | GET | Non | Health check ALB — retourne HTTP 200 |

## 3.10 Schéma de base de données

```sql
CREATE TABLE IF NOT EXISTS users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL,
  password   VARCHAR(255) NOT NULL,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT,
  message    TEXT         NOT NULL,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Les tables sont créées automatiquement au démarrage du container via `initSchema()` dans `database.js`. Aucune intervention manuelle sur RDS n'est nécessaire.

**Limite connue :** la colonne `username` n'a pas de contrainte `UNIQUE` au niveau base de données. Le code applicatif vérifie l'existence d'un username avant inscription, mais deux requêtes simultanées pourraient contourner cette vérification (race condition). En production, `UNIQUE KEY (username)` serait ajouté pour garantir l'unicité au niveau du moteur MySQL.

---

---

# SECTION 4 — DÉMARCHE ET OUTILS UTILISÉS

## 4.1 Phases de réalisation

### Phase 0 — Développement local (Mars 2026)

Objectif : valider les fonctionnalités avant tout déploiement cloud.

- Développement du backend Node.js/Express (routes auth + messages)
- Authentification JWT avec hachage bcrypt
- Frontend HTML/CSS/JS (glassmorphism, responsive)
- Docker Compose pour orchestrer backend + MySQL localement
- Script `start.bat` (Windows) pour lancer l'environnement en une commande

**Outils utilisés :** Node.js 20, Express 4, mysql2, bcrypt, jsonwebtoken, Docker Desktop, VS Code

### Phase 1 — Infrastructure AWS EC2 (Avril 2026)

Objectif : premier déploiement cloud, première pipeline CI/CD.

- Terraform v1 : VPC + EC2 + RDS + Security Groups
- Pipeline GitHub Actions initial (3 jobs : tests → build → deploy SSH)
- Dockerfile multi-stage Alpine (image 6x plus légère)

**Problème identifié :** le pipeline passait en vert mais l'application ne répondait pas. Cause : `user_data` EC2 asynchrone — les scripts d'installation n'étaient pas terminés quand GitHub Actions considérait le déploiement comme réussi. L'image Docker était buildée sur l'EC2 depuis le code source, sans tracabilité.

**Décision :** migrer vers ECS Fargate.

### Phase 2 — ECS Fargate (Mai 2026)

Objectif : architecture sans serveur, pipeline entièrement automatisée, zero SSH.

- Migration EC2 → ECS Fargate (suppression de tout `user_data`, clé SSH, `docker-compose` en prod)
- ECR pour stocker les images Docker taguées par hash de commit
- ALB avec health checks et rolling update
- SSM Parameter Store pour les secrets (plus de `.env` en clair)
- CloudWatch pour les logs de production
- Smoke tests (Job 3) : test de l'image ECR avant déploiement
- HTTPS avec ACM et domaine `chat.ibrahimbabikir.fr`
- 4 alarmes CloudWatch + notifications email SNS

**Outils utilisés :** Terraform 1.5, GitHub Actions, AWS ECS Fargate, AWS ECR, AWS ALB, AWS RDS, AWS SSM, AWS CloudWatch, AWS SNS, AWS ACM, IONOS DNS

## 4.2 Stack technique complète

| Technologie | Usage |
|-------------|-------|
| Node.js 20 LTS | Runtime backend |
| Express 4 | Framework API REST |
| mysql2 | Driver MySQL, requêtes préparées, Promises |
| bcrypt | Hachage des mots de passe (10 rounds) |
| jsonwebtoken | Génération et vérification tokens JWT |
| Docker (multi-stage Alpine) | Conteneurisation — image ~180 MB |
| Docker Compose | Orchestration locale (développement uniquement) |
| Terraform 1.5 | Infrastructure as Code AWS |
| GitHub Actions | Pipeline CI/CD automatisé |
| AWS ECR | Registre d'images Docker privé |
| AWS ECS Fargate | Exécution containers sans gestion de serveur |
| AWS ALB | Load balancer, rolling updates, health checks |
| AWS RDS MySQL 8.0 | Base de données managée en subnet privé |
| AWS SSM Parameter Store | Stockage chiffré des secrets |
| AWS ACM | Certificat SSL/TLS pour HTTPS |
| AWS CloudWatch | Logs et monitoring de production |
| AWS SNS | Notifications email sur alarmes |
| AWS S3 | Backend state Terraform (chiffré) |
| Jest + Supertest | Tests automatisés backend (9 tests) |

## 4.3 Collaborations

Projet réalisé en solo en centre de formation. Les échanges entre rôles (développeur / ops) sont simulés par le pipeline lui-même : si Job 1 (tests) échoue, le déploiement est bloqué et l'erreur est visible dans GitHub Actions. Si une alarme CloudWatch se déclenche, la notification email SNS joue le rôle d'alerte vers l'équipe.

---

---

# SECTION 5 — RÉALISATIONS DU CANDIDAT

Cette section présente les scripts et configurations les plus significatifs, avec leur justification.

## 5.1 Terraform — main.tf (extrait Security Groups)

```hcl
# Security Group ALB : seul point d'entrée public
resource "aws_security_group" "alb_sg" {
  name   = "mini-chat-alb-sg"
  vpc_id = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group ECS : port 3000 uniquement depuis l'ALB
resource "aws_security_group" "ecs_sg" {
  name   = "mini-chat-ecs-sg"
  vpc_id = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group RDS : port 3306 uniquement depuis ECS
resource "aws_security_group" "db_sg" {
  name   = "mini-chat-db-sg"
  vpc_id = aws_vpc.mini_chat_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

**Justification :** Trois niveaux d'isolation en cascade. Internet ne peut atteindre que l'ALB. L'ALB ne peut atteindre que le container ECS. Le container ECS ne peut atteindre que RDS. La base de données est totalement invisible depuis Internet.

---

## 5.2 Terraform — ecs.tf (extrait secrets SSM + Task Definition)

```hcl
# Secrets chiffrés AES-256 dans SSM Parameter Store
resource "aws_ssm_parameter" "db_password" {
  name  = "/mini-chat/db_password"
  type  = "SecureString"
  value = var.db_password
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/mini-chat/jwt_secret"
  type  = "SecureString"
  value = var.jwt_secret
}

# Task Definition : recette du container
resource "aws_ecs_task_definition" "backend" {
  family                   = "mini-chat-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mini-chat-backend"
    image = "${data.aws_ecr_repository.backend.repository_url}:${var.image_tag}"

    portMappings = [{ containerPort = 3000, protocol = "tcp" }]

    environment = [
      { name = "DB_HOST", value = aws_db_instance.mini_chat_db.address },
      { name = "DB_USER", value = "root" },
      { name = "DB_NAME", value = "mini_chat" },
      { name = "NODE_ENV", value = "production" }
    ]

    secrets = [
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "JWT_SECRET",  valueFrom = aws_ssm_parameter.jwt_secret.arn }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/mini-chat-backend"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}
```

**Justification :** Les secrets ne sont jamais en clair. Ils sont stockés chiffrés AES-256 dans SSM, et ECS les injecte comme variables d'environnement au démarrage du container. Ils n'apparaissent ni dans les logs CloudWatch, ni dans le state Terraform, ni dans l'image Docker.

---

## 5.3 Pipeline CI/CD — ci-cd.yml (4 jobs)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  tests:
    name: Job 1 — Tests
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm test

  build-push:
    name: Job 2 — Build & Push ECR
    needs: tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-3
      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      - name: Build and push
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -f backend/dockerfile.backend -t $ECR_REGISTRY/mini-chat-backend:$IMAGE_TAG backend/
          docker push $ECR_REGISTRY/mini-chat-backend:$IMAGE_TAG
          docker tag $ECR_REGISTRY/mini-chat-backend:$IMAGE_TAG $ECR_REGISTRY/mini-chat-backend:latest
          docker push $ECR_REGISTRY/mini-chat-backend:latest

  smoke-tests:
    name: Job 3 — Smoke Tests
    needs: build-push
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-3
      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      - name: Pull and run image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker pull $ECR_REGISTRY/mini-chat-backend:$IMAGE_TAG
          docker run -d --name smoke \
            -p 3000:3000 \
            -e DB_HOST=localhost \
            -e DB_USER=root \
            -e DB_PASSWORD=fake \
            -e DB_NAME=mini_chat \
            -e JWT_SECRET=fakesecret \
            -e NODE_ENV=production \
            $ECR_REGISTRY/mini-chat-backend:$IMAGE_TAG
          sleep 5
      - name: HTTP Tests
        run: |
          curl -sf http://localhost:3000/ || exit 1
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST http://localhost:3000/auth/register \
            -H "Content-Type: application/json" \
            -d '{}')
          [ "$STATUS" = "400" ] || exit 1
          STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
            http://localhost:3000/messages)
          [ "$STATUS" = "403" ] || exit 1

  deploy:
    name: Job 4 — Deploy
    needs: smoke-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-3
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      - name: Terraform apply
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
          TF_VAR_jwt_secret: ${{ secrets.JWT_SECRET }}
          TF_VAR_image_tag: ${{ github.sha }}
        working-directory: terraform
        run: |
          terraform init
          terraform apply -auto-approve
```

**Limite connue — `sleep 5` :** le délai de 5 secondes avant les tests curl est une approximation. Si le container met plus de 5 secondes à démarrer (cold start, connexion DB lente), les tests échouent avec `connection refused`. Une approche plus robuste utiliserait une boucle de retry. Pour ce projet, le `sleep 5` s'est avéré suffisant en pratique.

**Justification du Job 3 (smoke tests) :** avant de déployer, on teste l'image ECR exacte qui partira en production. Le même SHA de commit est utilisé dans le Job 2 (build), le Job 3 (test) et le Job 4 (deploy). C'est la garantie que l'environnement pré-prod est conforme à l'environnement de production. Si le container ne démarre pas, ou si les endpoints répondent incorrectement, le déploiement est bloqué.

---

## 5.4 Dockerfile multi-stage

```dockerfile
# Stage 1 : installation des dépendances de production uniquement
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

**Justification :** le build en deux étapes garantit que l'image finale ne contient pas npm, les outils de build ni les dépendances de développement. Résultat : ~180 MB au lieu de ~950 MB. Surface d'attaque réduite, démarrage plus rapide, coûts ECR inférieurs.

---

## 5.5 Protection XSS et SQL Injection — messages.js

```javascript
function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

router.post("/", verifyToken, async (req, res) => {
  const message = req.body.message;

  if (!message || typeof message !== "string") {
    return res.status(400).json({ error: "Message invalide" });
  }

  if (message.length > 500) {
    return res.status(400).json({ error: "Message trop long (max 500 caracteres)" });
  }

  const safeMessage = escapeHtml(message.trim());
  const user_id = req.user.userId;

  await db.query(
    "INSERT INTO messages (user_id, message) VALUES (?, ?)",
    [user_id, safeMessage]
  );
});
```

**Justification :** deux protections cumulées. `escapeHtml()` neutralise les balises HTML avant insertion — si un utilisateur envoie `<script>alert('xss')</script>`, le texte est stocké encodé et s'affiche comme du texte brut, jamais exécuté. La requête préparée avec `?` comme marqueur empêche toute injection SQL : les paramètres sont séparés de la requête SQL, jamais concaténés.

**Limites de sécurité assumées :**
- `escapeHtml()` est une implémentation manuelle — une bibliothèque dédiée (`he`, `sanitize-html`) offrirait une couverture plus exhaustive des cas limites (encodage Unicode, attributs HTML). Pour ce projet, les 5 remplacements couvrent les vecteurs XSS les plus courants.
- Le token JWT est stocké dans `localStorage`. C'est accessible via JavaScript — une attaque XSS réussie pourrait le lire. La solution plus sûre serait un cookie `HttpOnly` (inaccessible au JS). Choix assumé pour la simplicité du frontend sans backend de session.

---

## 5.6 Config.js — URLs relatives en production

```javascript
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return '';
};

const API = getApiUrl();
```

**Justification :** en production derrière l'ALB, les appels fetch utilisent des chemins relatifs (`/auth/login`, `/messages`). Le navigateur construit automatiquement l'URL complète avec le bon protocole (HTTPS) et le bon domaine. Avant cette correction, `config.js` construisait `http://chat.ibrahimbabikir.fr:3000` — une URL HTTP bloquée par le navigateur sur une page HTTPS (Mixed Content policy).

---

## 5.7 Terraform — monitoring.tf (alarmes CloudWatch + SNS)

```hcl
resource "aws_sns_topic" "alerts" {
  name = "mini-chat-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "babikiribrahimalkhalil@gmail.com"
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.alerts.arn
    }]
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_stopped" {
  alarm_name          = "mini-chat-ecs-stopped"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  dimensions          = { ClusterName = "mini-chat-cluster", ServiceName = "mini-chat-backend" }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

**Justification :** les alarmes sont définies en Terraform — elles se créent et se mettent à jour automatiquement avec le reste de l'infrastructure. La politique SNS doit explicitement autoriser CloudWatch à publier dans le topic, sinon les alarmes ne peuvent pas déclencher les notifications. Sans cette politique, les alertes restent muettes.

---

---

# SECTION 6 — SITUATION DE TRAVAIL AYANT NÉCESSITÉ UNE RECHERCHE

## Sujet de la recherche : renommer des ressources Terraform sans les détruire

### Contexte

Lors de la migration vers ECS Fargate, j'ai renommé plusieurs ressources Terraform pour plus de cohérence et de lisibilité :

```
aws_security_group.alb   →  aws_security_group.alb_sg
aws_security_group.ecs   →  aws_security_group.ecs_sg
aws_security_group.db    →  aws_security_group.db_sg
```

### Problème rencontré

Au lancement de `terraform plan`, Terraform a affiché :

```
# aws_security_group.alb will be destroyed
# aws_security_group.alb_sg will be created
```

Terraform interprétait les renommages comme une destruction de l'ancienne ressource et une création d'une nouvelle. Ce comportement aurait provoqué :
- La destruction des security groups utilisés par ECS et RDS
- Une coupure de service complète pendant la recréation
- La possible destruction de l'ECS service qui en dépendait

### Recherche effectuée

J'ai consulté la documentation officielle Terraform sur la gestion du state. En cherchant "terraform rename resource without destroy", j'ai trouvé la fonctionnalité `moved {}` introduite dans Terraform 1.1.

### Solution — blocs `moved` dans moved.tf

```hcl
moved {
  from = aws_security_group.alb
  to   = aws_security_group.alb_sg
}

moved {
  from = aws_security_group.ecs
  to   = aws_security_group.ecs_sg
}

moved {
  from = aws_security_group.db
  to   = aws_security_group.db_sg
}
```

**Résultat :** Terraform met à jour uniquement le state, sans toucher aux ressources AWS réelles. Le `terraform plan` suivant affichait :

```
# aws_security_group.alb has moved to aws_security_group.alb_sg
```

Aucune ressource détruite, aucune coupure de service.

### Deuxième situation de recherche : résoudre un conflit de state Terraform

Un autre problème est apparu : `aws_db_subnet_group.mini_chat` était présent deux fois dans le state Terraform, ce qui bloquait `terraform apply` avec une erreur de conflit.

Après recherche dans la documentation Terraform sur la gestion du state, j'ai trouvé la séquence `state rm` + `import` :

```bash
# Supprimer l'entrée en double du state
terraform state rm aws_db_subnet_group.mini_chat

# Réimporter la ressource existante en AWS
terraform import aws_db_subnet_group.mini_chat mini-chat-db-subnet-group
```

Cette séquence a été intégrée directement dans le Job 4 du pipeline pour éviter toute récurrence lors des déploiements suivants.

### Leçon retenue

Terraform gère un state qui représente la correspondance entre le code HCL et les ressources AWS réelles. Toute modification structurelle (renommage, déplacement) doit être accompagnée d'une instruction explicite au state manager. Les blocs `moved {}` et les commandes `state rm` + `import` sont les outils appropriés pour ces opérations sans risque de perte de données.

---

---

# ANNEXES

## Annexe A — Structure du dépôt

```
mini-chat/
├── .github/workflows/
│   └── ci-cd.yml              # Pipeline 4 jobs
├── backend/
│   ├── dockerfile.backend     # Multi-stage Alpine
│   ├── server.js              # Point d'entrée Express
│   ├── package.json
│   ├── frontend/              # HTML/CSS/JS servi statiquement
│   │   ├── index.html         # Page connexion / inscription
│   │   ├── messages.html      # Interface de chat
│   │   └── js/
│   │       ├── config.js      # URL API selon environnement
│   │       ├── auth.js        # Fonctions login/register
│   │       └── messages.js    # Chargement et envoi messages
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js    # Pool MySQL + initSchema()
│   │   ├── middleware/
│   │   │   └── auth.js        # Vérification JWT
│   │   └── routes/
│   │       ├── auth.js        # POST /auth/register, POST /auth/login
│   │       └── messages.js    # GET /messages, POST /messages
│   └── tests/                 # 9 tests Jest + Supertest
├── docs/
│   └── architecture.mmd       # Schéma Mermaid de l'architecture
├── terraform/
│   ├── main.tf                # VPC, subnets, SG, RDS
│   ├── ecs.tf                 # IAM, SSM, ECS, ALB, ACM
│   ├── monitoring.tf          # Alarmes CloudWatch + SNS
│   ├── variables.tf
│   ├── outputs.tf
│   ├── moved.tf               # Historique renommages
│   └── provider.tf            # AWS provider + state S3
├── GUIDE_DEPLOIEMENT.md       # Guide complet de déploiement
└── CAHIER_DES_CHARGES_COMPLET.md  # Support diaporama (prompt IA)
```

## Annexe B — Secrets GitHub Actions

| Secret | Utilisé dans | Destination finale |
|--------|-------------|-------------------|
| `AWS_ACCESS_KEY_ID` | Jobs 2, 3, 4 | Authentification AWS CLI |
| `AWS_SECRET_ACCESS_KEY` | Jobs 2, 3, 4 | Authentification AWS CLI |
| `DB_PASSWORD` | Job 4 (TF_VAR_db_password) | SSM → container ECS |
| `JWT_SECRET` | Job 4 (TF_VAR_jwt_secret) | SSM → container ECS |

## Annexe C — Captures d'écran à insérer

> **Note pour la mise en page :** insérer ici les captures d'écran suivantes :
> 1. AWS CloudWatch → groupe `/ecs/mini-chat-backend` avec les logs de démarrage
> 2. AWS CloudWatch → liste des 4 alarmes (état OK)
> 3. AWS ECS → cluster mini-chat-cluster → service mini-chat-backend (RUNNING)
> 4. GitHub Actions → pipeline complet avec les 4 jobs en vert
> 5. Navigateur → https://chat.ibrahimbabikir.fr avec le cadenas SSL visible
> 6. Interface Mini-Chat → page de connexion et page de messagerie

---

*Document rédigé par Babikir Ibrahim*
*Formation : Administrateur Système DevOps — Titre RNCP Niveau 6*
*Référentiel : RE TP-01414-01 — Plan type du dossier de projet respecté intégralement*
*Date : Mai 2026*
