# PROMPT PDF — Dossier de Projet
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA (ChatGPT / Gemini / Claude) :**
>
> Génère un document PDF professionnel de type "dossier de projet" à partir du contenu ci-dessous.
>
> **Mise en page :**
> - Format A4, marges 2,5 cm, police Calibri ou Arial taille 11, interligne 1,3
> - Page de garde : titre centré, nom du candidat, formation, date — sobre et professionnel
> - Table des matières avec numéros de page en début de document
> - En-tête de chaque page : "Dossier de Projet — Mini-Chat — Babikir Ibrahim"
> - Pied de page : numéro de page centré, format "Page X / N"
> - Chaque section principale commence sur une nouvelle page
>
> **Style visuel :**
> - Titres ## : gras, taille 14, couleur bleu foncé (#003366)
> - Titres ### : gras, taille 12, couleur bleu (#0055AA)
> - Tableaux : bordures fines, alternance blanc / gris très clair sur les lignes
> - Blocs de code : fond gris clair, police monospace taille 9, bordure gauche bleue
> - Document technique professionnel — pas de couleurs vives inutiles
>
> **Important :** Respecte le plan ci-dessous à la lettre. C'est le plan type officiel ASD Niveau 6 (RE TP-01414-01).

---

---

# DOSSIER DE PROJET

## Mini-Chat — Application de messagerie cloud-native déployée sur Google Cloud Platform

---

**Candidat :** Babikir Ibrahim
**Formation :** Titre Professionnel Administrateur Système DevOps — Niveau 6
**Référentiel :** RE TP-01414-01
**Réalisation :** Centre de formation — Mars à Juin 2026
**Application en production :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app
**Dépôt de code :** https://github.com/babs235/mini-chat
**Date de rédaction :** Juin 2026

---

---

## SECTION 1 — Compétences du référentiel couvertes par le projet

Ce projet couvre les compétences des trois blocs du titre ASD.

### Bloc 1 — Automatiser le déploiement d'une infrastructure dans le cloud

| Compétence ASD | Mise en œuvre |
|----------------|---------------|
| Automatiser la création de serveurs à l'aide de scripts | Infrastructure entièrement définie en code avec Terraform : Artifact Registry, Cloud SQL, Secret Manager, Cloud Run, Cloud Monitoring. Aucune ressource créée manuellement via la console GCP. |
| Automatiser le déploiement d'une infrastructure | Pipeline GitHub Actions — Job 4 : `terraform apply -auto-approve` déclenché automatiquement à chaque `git push main`. |
| Sécuriser l'infrastructure | Comptes de service GCP à droits minimaux, secrets via Secret Manager (chiffrés AES-256), HTTPS automatique sur Cloud Run, connexion Cloud SQL via socket Unix authentifié, aucun port SSH. |
| Mettre l'infrastructure en production dans le cloud | Application déployée sur Google Cloud Run, accessible publiquement sur https://mini-chat-backend-py4vurg4oq-ew.a.run.app — région europe-west1 (Belgique). |

### Bloc 2 — Déployer en continu une application

| Compétence ASD | Mise en œuvre |
|----------------|---------------|
| Préparer un environnement de test | 10 tests unitaires Jest (validation, authentification, protection JWT) + 3 smoke tests HTTP pré-production sur l'image Docker Artifact Registry dans le pipeline CI/CD. |
| Gérer le stockage des données | Base de données MySQL 8.0 sur Google Cloud SQL (db-f1-micro), connexion via socket Unix (Cloud SQL Auth Proxy), backup automatique activé, schéma initialisé au démarrage du backend. |
| Gérer des containers | Dockerfile multi-stage Alpine (~180 MB), registre Artifact Registry, orchestration Cloud Run (serverless, scale to zero), rolling update sans interruption de service. |
| Automatiser la mise en production d'une application avec une plateforme | Pipeline GitHub Actions 4 jobs : tests → build Artifact Registry → smoke tests → `terraform apply`. Chaque image taguée avec le hash SHA du commit Git. |

### Bloc 3 — Superviser les services déployés

| Compétence ASD | Mise en œuvre |
|----------------|---------------|
| Définir et mettre en place des statistiques de services | 2 alertes Cloud Monitoring sur des KPI métier : disponibilité du service (uptime check) et taux d'erreurs HTTP 5xx. |
| Exploiter une solution de supervision | Cloud Logging (logs temps réel du container Cloud Run), Cloud Monitoring (métriques CPU, requêtes, latence), notifications email sur déclenchement d'alerte. Incident réel résolu grâce aux logs (Mixed Content HTTPS). |

---

---

## SECTION 2 — Cahier des charges

### 2.1. Contexte du projet

Ce projet est réalisé en centre de formation dans le cadre du Titre Professionnel Administrateur Système DevOps. Il couvre l'intégralité du cycle de vie d'une application cloud-native : développement, conteneurisation, infrastructure as code, déploiement continu, sécurisation et supervision.

**Mini-Chat** est une application de messagerie interne accessible via navigateur web. Elle permet à des utilisateurs authentifiés d'échanger des messages avec persistance en base de données relationnelle.

**Évolution du projet :**

| Phase | Période | Réalisations |
|-------|---------|-------------|
| Phase 0 | Mars 2026 | Backend Node.js/Express, authentification JWT, frontend HTML/CSS/JS, Docker Compose local |
| Phase 1 | Avril 2026 | Premier déploiement AWS (EC2 + RDS), pipeline CI/CD initial |
| Phase 2 | Mai 2026 | Migration vers AWS ECS Fargate, secrets SSM, HTTPS/ACM, smoke tests, alarmes CloudWatch |
| Phase 3 | Juin 2026 | Migration vers Google Cloud Platform (Cloud Run + Cloud SQL), Terraform GCP, Secret Manager |

La migration vers GCP en Phase 3 a été motivée par l'expiration des crédits AWS. Grâce à l'Infrastructure as Code (Terraform), la migration a consisté principalement à réécrire les fichiers Terraform pour le provider GCP — le pipeline CI/CD, le Dockerfile et le code applicatif sont restés identiques.

### 2.2. Objectifs

| Objectif | Critère de validation |
|----------|----------------------|
| Application de messagerie fonctionnelle | Inscription, connexion JWT, envoi et lecture de messages via API REST |
| Image Docker optimisée | Multi-stage Alpine, < 200 MB, aucun outil de build en production |
| Infrastructure entièrement en code | Toute l'infra GCP créée via `terraform apply` |
| Pipeline CI/CD automatisé | `git push main` → déploiement complet sans intervention manuelle |
| Zéro secret en clair | Aucun secret dans le code, les logs ou l'image Docker |
| HTTPS automatique | Cloud Run fournit le certificat SSL sans configuration |
| Supervision opérationnelle | 2 alertes Cloud Monitoring actives, notification email |
| Tests bloquants | Déploiement impossible si un test échoue |

### 2.3. Contraintes

| Contrainte | Justification |
|------------|---------------|
| Budget Free Tier GCP | Cloud Run scale-to-zero (coût nul sans trafic), Cloud SQL db-f1-micro |
| Pas de WebSocket | Polling HTTP toutes les 3 secondes — compatible Cloud Run sans configuration supplémentaire |
| Connexion Cloud SQL via socket | Sans VPC connector, la connexion passe par le Cloud SQL Auth Proxy intégré à Cloud Run (socket Unix) |
| Scale to zero | Cloud Run peut mettre le container en veille — démarrage à froid possible (~2s) |

### 2.4. Livrables

| Livrable | Localisation |
|----------|-------------|
| Code source complet (backend, frontend, tests) | `backend/` |
| Dockerfile multi-stage | `backend/dockerfile.backend` |
| Docker Compose (environnement local) | `docker/docker-compose.yml` |
| Infrastructure as Code Terraform (5 fichiers) | `terraform/` |
| Pipeline CI/CD GitHub Actions (4 jobs) | `.github/workflows/ci-cd.yml` |
| Application HTTPS en production | https://mini-chat-backend-py4vurg4oq-ew.a.run.app |
| Supervision (Cloud Monitoring + alertes) | `terraform/monitoring.tf` / GCP Console |

---

---

## SECTION 3 — Spécifications techniques du projet

### 3.1. Stack technologique

| Couche | Technologie | Version |
|--------|-------------|---------|
| Backend | Node.js + Express | 20 LTS / 5.2.1 |
| Authentification | JSON Web Tokens + bcrypt | JWT 9.0.3 / bcrypt 6.0.0 |
| Base de données | MySQL | 8.0 (Google Cloud SQL) |
| Frontend | HTML5 / CSS3 / JavaScript vanilla | — |
| Conteneurisation | Docker (image Alpine) | multi-stage |
| Registre d'images | Google Artifact Registry | europe-west1 |
| Orchestration containers | Google Cloud Run | serverless |
| Infrastructure as Code | Terraform | 1.5+ (provider google ~5.0) |
| Pipeline CI/CD | GitHub Actions | 4 jobs séquentiels |
| Supervision | Google Cloud Monitoring + Cloud Logging | — |
| Secrets | Google Secret Manager | AES-256 |
| État Terraform | Google Cloud Storage | bucket `mini-chat-asd-tfstate` |
| Cloud | GCP (région europe-west1 — Belgique) | projet `mini-chat-asd` |

### 3.2. Schéma de l'infrastructure déployée

```
┌─────────────────────────────────────────────────────────────────────┐
│                  Google Cloud Platform — europe-west1               │
│                        Projet : mini-chat-asd                       │
│                                                                     │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐  │
│  │   Artifact Registry   │    │   Secret Manager                 │  │
│  │   mini-chat/backend   │    │   mini-chat-db-password          │  │
│  │   :sha-commit         │    │   mini-chat-jwt-secret           │  │
│  └──────────────────────┘    └──────────────────────────────────┘  │
│                                          │ injection au démarrage   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Cloud Run — mini-chat-backend                   │   │
│  │  Node.js :3000 — scale to zero — HTTPS automatique          │   │
│  │  Service Account : mini-chat-cloudrun@                       │   │
│  │  Socket Unix : /cloudsql/mini-chat-asd:europe-west1:mini-chat-db│
│  └──────────────────────┬──────────────────────────────────────┘   │
│                         │ socket Unix (Cloud SQL Auth Proxy)        │
│  ┌──────────────────────▼──────────────────────────────────────┐   │
│  │              Cloud SQL MySQL 8.0                             │   │
│  │  Instance : mini-chat-db — db-f1-micro                       │   │
│  │  Base : mini_chat — backup automatique                        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Cloud Monitoring : 2 alertes + uptime check + Cloud Logging  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Cloud Storage : mini-chat-asd-tfstate (état Terraform)       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

Flux utilisateur :
Internet ──HTTPS──► [Cloud Run :3000] ──socket Unix──► [Cloud SQL :3306]
          (certificat automatique Cloud Run)
```

### 3.3. Schéma de base de données

```sql
CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,            -- hash bcrypt, 10 rounds
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT          NOT NULL,
  message    TEXT         NOT NULL,            -- contenu échappé XSS
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3.4. Routes API

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| `/` | GET | Non | Health check → HTTP 200 |
| `/auth/register` | POST | Non | Inscription — validation + bcrypt 10 rounds |
| `/auth/login` | POST | Non | Connexion → token JWT signé (1 heure) |
| `/messages` | GET | JWT | Historique des messages triés chronologiquement |
| `/messages` | POST | JWT | Envoi d'un message (max 500 chars, protection XSS) |

---

---

## SECTION 4 — Démarche et outils utilisés

### 4.1. Chronologie du projet

| Phase | Période | Travaux réalisés |
|-------|---------|-----------------|
| Phase 0 — Dev local | Mars 2026 | Backend Node.js/Express, routes auth et messages, frontend HTML/CSS/JS, Docker Compose avec MySQL |
| Phase 1 — Cloud AWS | Avril 2026 | Infrastructure EC2+RDS avec Terraform AWS, pipeline CI/CD initial GitHub Actions, Dockerfile multi-stage |
| Phase 2 — AWS industrialisé | Mai 2026 | Migration ECS Fargate, secrets SSM, HTTPS ACM, smoke tests pré-production, alarmes CloudWatch + SNS |
| Phase 3 — Migration GCP | Juin 2026 | Réécriture Terraform GCP, Cloud Run + Cloud SQL, Secret Manager, Cloud Monitoring, modification database.js pour socket Unix |

**Décision clé — Migration AWS → GCP :**
Les crédits AWS étant épuisés, l'infrastructure a été migrée vers Google Cloud Platform. Grâce à Terraform et à l'Infrastructure as Code, la migration a consisté principalement à réécrire les fichiers HCL pour le provider GCP. Le code applicatif (Node.js), le Dockerfile et le pipeline GitHub Actions ont nécessité seulement des ajustements mineurs (authentification gcloud, URL Artifact Registry). La migration démontre un avantage concret de l'IaC : portabilité de l'infrastructure.

### 4.2. Outils utilisés

| Outil | Usage |
|-------|-------|
| Node.js 20 + Express 5 | Backend API REST |
| mysql2 | Connexion MySQL — pool + socket Unix pour Cloud SQL |
| bcrypt | Hachage des mots de passe (10 rounds) |
| jsonwebtoken | Signature et vérification des tokens JWT |
| Jest + supertest | Tests unitaires automatisés (10 tests) |
| Docker | Conteneurisation multi-stage Alpine |
| Docker Compose | Environnement de développement local |
| Google Artifact Registry | Registre d'images Docker privé |
| Google Cloud Run | Orchestration serverless — scale to zero |
| Google Cloud SQL MySQL 8.0 | Base de données managée |
| Google Secret Manager | Stockage chiffré des secrets (AES-256) |
| Google Cloud Monitoring | Métriques, alertes, uptime checks |
| Google Cloud Logging | Logs du container Cloud Run en temps réel |
| Terraform 1.5 | Infrastructure as Code — 5 fichiers HCL |
| GitHub Actions | Pipeline CI/CD 4 jobs séquentiels |
| gcloud CLI | Authentification et gestion des ressources GCP |

### 4.3. Sécurité — principe du moindre privilège

| Couche | Mécanisme | Détail |
|--------|-----------|--------|
| Transport | HTTPS automatique | Cloud Run fournit le certificat SSL sans configuration |
| Secrets | Secret Manager (AES-256) | DB_PASSWORD et JWT_SECRET jamais en clair |
| Authentification app | JWT (1 heure) + bcrypt (10 rounds) | Token signé, mot de passe haché |
| SQL Injection | Requêtes préparées mysql2 | Paramètres `?` — jamais de concaténation |
| XSS | `escapeHtml()` | Appliqué avant chaque insertion en base |
| Accès Cloud SQL | Cloud SQL Auth Proxy | Socket Unix via compte de service — pas d'IP ouverte |
| IAM | Compte de service dédié | `mini-chat-cloudrun@` — droits minimaux (Cloud SQL client + Secret Manager reader) |
| SSH | Aucun | Cloud Run est serverless — pas d'accès SSH possible |

---

---

## SECTION 5 — Réalisations du candidat

### 5.1. Terraform — Cloud Run avec injection des secrets Secret Manager

**Fichier :** `terraform/cloudrun.tf`

**Ce que ça fait :** Définit le service Cloud Run avec connexion Cloud SQL via socket Unix. Les secrets DB_PASSWORD et JWT_SECRET sont injectés depuis Secret Manager au démarrage du container — jamais en clair dans les logs ou la définition du service.

```hcl
resource "google_cloud_run_v2_service" "backend" {
  name     = "mini-chat-backend"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = 0 # scale to zero — coût nul sans trafic
      max_instance_count = 3
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/mini-chat/backend:${var.image_tag}"

      ports { container_port = 3000 }

      env { name = "NODE_ENV"       value = "production" }
      env { name = "DB_USER"        value = "root" }
      env { name = "DB_NAME"        value = "mini_chat" }
      # Connexion via socket Unix — Cloud SQL Auth Proxy intégré
      env {
        name  = "DB_SOCKET_PATH"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      # Secrets injectés depuis Secret Manager — jamais visibles dans les logs
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.jwt_secret.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = { cpu = "1", memory = "512Mi" }
      }

      # volume_mounts doit être dans containers — pas au niveau template
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # volumes au niveau template — crée le socket Unix Cloud SQL Auth Proxy
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_version.jwt_secret,
    google_project_iam_member.cloudrun_sql,
  ]
}

# Accès public — pas d'authentification requise (application publique)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

**Pourquoi ce choix :** Le champ `value_source.secret_key_ref` est la seule façon d'injecter un secret Secret Manager dans un container Cloud Run sans qu'il apparaisse dans les variables d'environnement visibles via la console GCP ou les logs Cloud Logging.

---

### 5.2. Terraform — Cloud SQL et Secret Manager

**Fichier :** `terraform/main.tf` (extrait)

**Ce que ça fait :** Crée la base de données Cloud SQL, les secrets chiffrés, et le compte de service avec droits minimaux.

```hcl
# Base de données Cloud SQL MySQL 8.0
resource "google_sql_database_instance" "main" {
  name             = "mini-chat-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:00"
    }

    ip_configuration {
      ipv4_enabled = true  # IP publique pour Cloud Run sans VPC connector
    }
  }

  deletion_protection = false
}

# Secret Manager — DB_PASSWORD chiffré AES-256
resource "google_secret_manager_secret" "db_password" {
  secret_id = "mini-chat-db-password"
  replication { auto {} }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Compte de service Cloud Run — droits minimaux
resource "google_service_account" "cloudrun" {
  account_id   = "mini-chat-cloudrun"
  display_name = "Mini-Chat Cloud Run"
}

# Droit Cloud SQL client — connexion via Auth Proxy uniquement
resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Droit lecture Secret Manager — DB_PASSWORD et JWT_SECRET uniquement
resource "google_secret_manager_secret_iam_member" "db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}
```

**Pourquoi ce choix :** Le compte de service `mini-chat-cloudrun` a uniquement les droits `cloudsql.client` et `secretmanager.secretAccessor`. Il ne peut ni créer de ressources, ni lire d'autres secrets GCP — principe du moindre privilège appliqué au niveau IAM.

---

### 5.3. Pipeline CI/CD — Authentification GCP et 4 jobs

**Fichier :** `.github/workflows/ci-cd.yml`

**Ce que ça fait :** Pipeline complet de 4 jobs séquentiels avec authentification GCP robuste via Python (détecte automatiquement JSON brut ou base64).

```yaml
name: CI/CD Mini-Chat (GCP)

on:
  push:
    branches: [main]

env:
  PROJECT_ID: mini-chat-asd
  REGION: europe-west1
  IMAGE: europe-west1-docker.pkg.dev/mini-chat-asd/mini-chat/backend

jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
        working-directory: ./backend
      - run: npm test
        working-directory: ./backend

  build-push:
    needs: tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Auth GCP
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
        run: |
          python3 - <<'EOF'
          import os, base64, json
          raw = os.environ["GCP_SA_KEY"].strip()
          try:
              decoded = base64.b64decode(raw).decode("utf-8")
              json.loads(decoded)
              raw = decoded
          except Exception:
              pass
          open("/tmp/sa-key.json", "w").write(raw)
          EOF
          gcloud auth activate-service-account --key-file=/tmp/sa-key.json
          gcloud config set project $PROJECT_ID
          gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
      - name: Build and push
        run: |
          docker build -t $IMAGE:${{ github.sha }} -t $IMAGE:latest \
            -f backend/dockerfile.backend backend/
          docker push $IMAGE:${{ github.sha }}
          docker push $IMAGE:latest

  smoke-tests:
    needs: build-push
    runs-on: ubuntu-latest
    steps:
      - name: Auth + Pull + Test
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
        run: |
          # Auth identique au job build-push
          python3 -c "
          import os,base64,json
          raw=os.environ['GCP_SA_KEY'].strip()
          try:
              d=base64.b64decode(raw).decode(); json.loads(d); raw=d
          except: pass
          open('/tmp/sa-key.json','w').write(raw)"
          gcloud auth activate-service-account --key-file=/tmp/sa-key.json
          gcloud config set project $PROJECT_ID
          gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
          docker pull $IMAGE:${{ github.sha }}
          docker run -d --name preprod -p 3000:3000 \
            -e NODE_ENV=test -e DB_HOST=127.0.0.1 \
            -e DB_USER=root -e DB_NAME=mini_chat \
            -e DB_PASSWORD=test -e JWT_SECRET=test \
            $IMAGE:${{ github.sha }}
          for i in $(seq 1 10); do curl -sf http://localhost:3000/ && break; sleep 2; done
          [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/)" = "200" ]
          [ "$(curl -s -o /dev/null -w '%{http_code}' -X POST \
            http://localhost:3000/auth/register -H 'Content-Type: application/json' \
            -d '{}')" = "400" ]
          [ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/messages)" = "403" ]
          docker rm -f preprod

  deploy:
    needs: smoke-tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: '1.5' }
      - name: Auth GCP
        env:
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
        run: |
          python3 -c "
          import os,base64,json
          raw=os.environ['GCP_SA_KEY'].strip()
          try:
              d=base64.b64decode(raw).decode(); json.loads(d); raw=d
          except: pass
          open('/tmp/sa-key.json','w').write(raw)"
          gcloud auth activate-service-account --key-file=/tmp/sa-key.json
          gcloud config set project $PROJECT_ID
          echo "GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json" >> $GITHUB_ENV
      - run: cd terraform && terraform init
      - run: cd terraform && terraform validate
      - run: cd terraform && terraform fmt -check
      - run: cd terraform && terraform apply -auto-approve
        env:
          TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
          TF_VAR_jwt_secret:  ${{ secrets.JWT_SECRET }}
          TF_VAR_image_tag:   ${{ github.sha }}
```

**Pourquoi Python pour l'auth :** La clé GCP est un JSON multilignes. Les shells bash et PowerShell peuvent corrompre les caractères spéciaux lors de l'injection de secrets GitHub. Python lit la valeur via `os.environ` sans aucun traitement shell, puis gère les deux formats (JSON brut et base64) automatiquement.

---

### 5.4. Adaptation database.js — Support du socket Unix Cloud SQL

**Fichier :** `backend/src/config/database.js`

**Ce que ça fait :** Modification minimale pour supporter les deux modes de connexion — TCP classique (développement local Docker Compose) et socket Unix (production Cloud Run + Cloud SQL Auth Proxy).

```javascript
const poolConfig = {
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

// DB_SOCKET_PATH → connexion via socket Unix (Cloud Run + Cloud SQL Auth Proxy)
// DB_HOST        → connexion TCP classique (Docker Compose local)
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}

const pool = mysql.createPool(poolConfig);
```

**Pourquoi ce choix :** Cloud Run + Cloud SQL utilisent le Cloud SQL Auth Proxy, qui crée un socket Unix local au container. MySQL2 supporte `socketPath` pour ce cas. La détection conditionnelle (`if (process.env.DB_SOCKET_PATH)`) maintient la compatibilité avec le Docker Compose local qui utilise TCP classique — aucun changement de configuration locale nécessaire.

---

---

## SECTION 6 — Situation de travail ayant nécessité une recherche

### 6.1. Recherche — Connexion Cloud Run vers Cloud SQL sans VPC

**Point de départ :**
Lors de la migration vers GCP, le container Cloud Run démarrait mais ne pouvait pas se connecter à Cloud SQL. Erreur dans les logs Cloud Logging :

```
Error: connect ECONNREFUSED 127.0.0.1:3306
```

Le code utilisait `host: process.env.DB_HOST` avec l'IP publique de Cloud SQL. La connexion TCP directe était refusée malgré l'IP publique activée.

**Recherche effectuée :**
Consultation de la documentation officielle Google Cloud : "Connecting from Cloud Run to Cloud SQL".
Deux options disponibles :
1. **VPC Serverless Connector** (~30€/mois) — connexion via réseau privé VPC
2. **Cloud SQL Auth Proxy intégré** — socket Unix local, gratuit, géré par GCP

**Découverte — le Cloud SQL Auth Proxy intégré à Cloud Run :**
En déclarant un `volume` de type `cloud_sql_instance` dans Terraform, Cloud Run déploie automatiquement le proxy en sidecar et crée un socket Unix à `/cloudsql/[connection-name]`. Le container peut alors se connecter via `socketPath` au lieu de `host`.

**Solution appliquée (Terraform + Node.js) :**

Dans `cloudrun.tf` :
```hcl
volumes {
  name = "cloudsql"
  cloud_sql_instance {
    instances = ["mini-chat-asd:europe-west1:mini-chat-db"]
  }
}
volume_mounts {
  name       = "cloudsql"
  mount_path = "/cloudsql"
}
env {
  name  = "DB_SOCKET_PATH"
  value = "/cloudsql/mini-chat-asd:europe-west1:mini-chat-db"
}
```

Dans `database.js` :
```javascript
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}
```

**Résultat :** Connexion Cloud Run → Cloud SQL opérationnelle, sécurisée par le compte de service GCP (IAM). Économie de ~30€/mois en évitant le VPC Serverless Connector.

### 6.2. Deuxième recherche — volume_mounts au bon niveau dans Cloud Run Terraform

**Problème :**
Le premier `terraform apply` échouait avec une erreur de schéma Terraform :
```
Error: An argument named "volume_mounts" is not expected here.
```

`volume_mounts` avait été placé au niveau du bloc `template`, mais Terraform GCP exige qu'il soit à l'intérieur du bloc `containers`.

**Recherche effectuée :**
Documentation Terraform Registry pour `google_cloud_run_v2_service` — lecture de la hiérarchie exacte des blocs : `template > containers > volume_mounts` (à l'intérieur du container) vs `template > volumes` (au niveau template).

**Correction appliquée :**
```hcl
template {
  containers {
    # volume_mounts DOIT être ici — à l'intérieur de containers
    volume_mounts {
      name       = "cloudsql"
      mount_path = "/cloudsql"
    }
  }
  # volumes est au niveau template — pas dans containers
  volumes {
    name = "cloudsql"
    cloud_sql_instance { instances = [...] }
  }
}
```

**Ce qui a été appris :** La différence entre `volumes` (déclaration, au niveau template) et `volume_mounts` (utilisation, à l'intérieur du container) est identique au concept Docker Compose : volumes définis globalement, montés dans chaque service. Terraform respecte cette séparation rigoureusement.

---

*Dossier de projet réalisé dans le cadre du Titre Professionnel Administrateur Système DevOps — Niveau 6*
*Référentiel d'évaluation RE TP-01414-01 — Plan type dossier de projet respecté intégralement*
*Babikir Ibrahim — Juin 2026 — github.com/babs235/mini-chat*
*Production : https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
