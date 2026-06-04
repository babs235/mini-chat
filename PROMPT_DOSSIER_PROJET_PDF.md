# PROMPT PDF — Dossier de Projet
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA générant le PDF :**
> Police Calibri ou Arial 11pt, interligne 1,3, marges 2,5 cm, format A4.
> Page de garde sobre avec titre, candidat, formation, date.
> En-tête : "Dossier de Projet — Mini-Chat — Babikir Ibrahim"
> Pied de page : numéro de page centré.
> Chaque section principale commence sur une nouvelle page.
> Blocs de code : fond gris clair, police monospace taille 9.
> Tableaux avec alternance de couleur sur les lignes.
> Le ton du document est à la première personne — ne pas modifier le style d'écriture.

---

---

# DOSSIER DE PROJET

## Mini-Chat — Application de messagerie déployée sur Google Cloud Platform

---

**Candidat :** Babikir Ibrahim
**Formation :** Titre Professionnel Administrateur Système DevOps — Niveau 6
**Référentiel :** RE TP-01414-01
**Période de réalisation :** Mars – Juin 2026
**Application en production :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app
**Code source :** https://github.com/babs235/mini-chat
**Date de rédaction :** Juin 2026

---

---

## 1. Compétences du référentiel couvertes par le projet

Voici les compétences ASD que ce projet me permet de démontrer, avec ce que j'ai concrètement mis en place pour chacune.

### Bloc 1 — Automatiser le déploiement d'une infrastructure dans le cloud

| Compétence | Ce que j'ai fait |
|------------|-----------------|
| Automatiser la création de serveurs à l'aide de scripts | J'ai écrit toute l'infrastructure en Terraform (5 fichiers HCL). Cloud Run, Cloud SQL, Secret Manager, Artifact Registry — tout est créé automatiquement par `terraform apply`, rien n'est fait à la main dans la console GCP. |
| Automatiser le déploiement d'une infrastructure | Le Job 4 de mon pipeline GitHub Actions lance `terraform apply` automatiquement à chaque `git push main`. Je n'ai rien à faire manuellement pour déployer. |
| Sécuriser l'infrastructure | Les mots de passe et secrets ne sont jamais écrits dans le code. Je les stocke dans Google Secret Manager et ils sont injectés directement dans le container au démarrage. La connexion à la base de données passe par un socket sécurisé, pas par un port TCP ouvert. Il n'y a aucun accès SSH sur aucune ressource. |
| Mettre l'infrastructure en production dans le cloud | L'application tourne sur Google Cloud Run en région europe-west1 (Belgique) et répond en HTTPS à l'adresse https://mini-chat-backend-py4vurg4oq-ew.a.run.app |

### Bloc 2 — Déployer en continu une application

| Compétence | Ce que j'ai fait |
|------------|-----------------|
| Préparer un environnement de test | J'ai écrit 10 tests unitaires avec Jest qui testent les validations, l'authentification et la protection JWT. Le pipeline a aussi 3 smoke tests HTTP qui vérifient que l'image Docker fonctionne avant de la déployer en production. |
| Gérer le stockage des données | La base MySQL tourne sur Google Cloud SQL. J'ai configuré les backups automatiques et le schéma (tables users et messages) est créé automatiquement au premier démarrage du backend, ce qui évite de devoir se connecter manuellement à la base. |
| Gérer des containers | J'utilise Docker avec un Dockerfile multi-stage (image Alpine d'environ 180 MB). Les images sont stockées dans Google Artifact Registry et déployées via Cloud Run avec mise à jour sans coupure de service. |
| Automatiser la mise en production avec une plateforme | Mon pipeline 4 jobs fait tout : tests → construction de l'image → tests de l'image → déploiement. Chaque image est marquée avec le hash exact du commit Git, donc je sais à tout moment quelle version exacte tourne en production. |

### Bloc 3 — Superviser les services déployés

| Compétence | Ce que j'ai fait |
|------------|-----------------|
| Définir et mettre en place des statistiques de services | J'ai configuré 2 alertes Cloud Monitoring : une sur la disponibilité du service (uptime check toutes les 5 minutes) et une sur le taux d'erreurs HTTP 5xx. Ces alertes m'envoient un email automatiquement si quelque chose ne va pas. |
| Exploiter une solution de supervision | J'utilise Cloud Logging pour voir les logs du container en temps réel et Cloud Monitoring pour les métriques. J'ai déjà résolu un bug grâce aux logs (erreur Mixed Content HTTPS) que j'explique dans la section 6. |

---

---

## 2. Cahier des charges

### 2.1. Présentation du projet

Mini-Chat est une application de messagerie interne accessible depuis un navigateur. Les utilisateurs peuvent créer un compte, se connecter et échanger des messages qui sont sauvegardés en base de données. L'objectif du projet n'est pas l'application en elle-même, mais tout ce qui l'entoure : comment je la conteneurise, comment je déploie automatiquement la moindre modification, comment je sécurise les accès, et comment je surveille qu'elle fonctionne correctement.

### 2.2. Comment le projet a évolué

J'ai travaillé sur ce projet en plusieurs étapes, et chaque étape m'a amené à améliorer ce que j'avais fait avant.

**Mars 2026 — Développement local**
J'ai commencé par créer l'application : le backend en Node.js/Express avec les routes d'authentification (JWT + bcrypt) et les routes de messagerie, le frontend en HTML/CSS/JavaScript, et Docker Compose pour faire tourner l'application et la base MySQL ensemble sur mon poste.

**Avril 2026 — Premier déploiement cloud (AWS)**
J'ai écrit la première version de l'infrastructure Terraform pour déployer sur AWS (EC2 + RDS MySQL) et j'ai mis en place le pipeline CI/CD avec GitHub Actions.

**Mai 2026 — Industrialisation sur AWS**
J'ai migré d'EC2 vers AWS ECS Fargate parce que j'avais un problème : le pipeline passait en vert mais l'application ne répondait pas. En utilisant Fargate, le container démarre directement depuis l'image Docker sans passer par un script d'initialisation qui s'exécutait de manière asynchrone. J'ai aussi mis en place les secrets SSM, le HTTPS avec ACM, les smoke tests et les alarmes CloudWatch.

**Juin 2026 — Migration vers Google Cloud Platform**
Mes crédits AWS se sont épuisés. J'ai dû migrer vers GCP. La bonne nouvelle, c'est que grâce à Terraform, j'ai surtout eu à réécrire les fichiers HCL pour le provider GCP. Le pipeline, le Dockerfile et le code Node.js n'ont presque pas changé. Cette migration m'a d'ailleurs montré concrètement l'avantage de l'Infrastructure as Code : l'infrastructure n'est pas liée à un provider spécifique.

### 2.3. Ce que le projet devait faire

| Objectif | Comment je l'ai validé |
|----------|----------------------|
| Application fonctionnelle (auth + messagerie) | Testée manuellement en production — inscription, connexion, envoi/lecture de messages |
| Image Docker légère et sécurisée | Multi-stage Alpine, ~180 MB, aucun outil de build dans l'image finale |
| Infrastructure 100% en code | Toutes les ressources GCP créées par `terraform apply`, aucune ressource créée à la main |
| Déploiement automatique | Un `git push main` déclenche le pipeline et déploie en production |
| Secrets jamais en clair | Vérifiable dans les logs Cloud Logging — DB_PASSWORD et JWT_SECRET n'apparaissent jamais |
| HTTPS fonctionnel | Cloud Run fournit le certificat SSL automatiquement |
| Supervision active | 2 alertes Cloud Monitoring, email reçu si le service tombe |
| Tests bloquants | Si un test Jest échoue, le déploiement s'arrête au Job 1 |

### 2.4. Contraintes

**Budget :** J'ai travaillé sur les niveaux gratuits des deux clouds. Sur GCP, Cloud Run ne coûte rien quand il n'y a pas de trafic (scale to zero). Cloud SQL db-f1-micro est la plus petite instance disponible.

**Pas de WebSocket :** L'interface rafraîchit les messages toutes les 3 secondes via une requête HTTP classique. Cloud Run ne nécessite pas de configuration spéciale pour ça, contrairement à WebSocket.

**Connexion Cloud SQL :** Sans VPC connector (qui coûte environ 30€/mois), la connexion entre Cloud Run et Cloud SQL passe par le Cloud SQL Auth Proxy intégré. Cela nécessite d'utiliser un socket Unix au lieu d'une connexion TCP classique, ce qui m'a demandé une petite modification dans le code.

---

---

## 3. Spécifications techniques

### 3.1. Ce que j'utilise et pourquoi

| Composant | Technologie | Pourquoi ce choix |
|-----------|-------------|------------------|
| Backend | Node.js 20 + Express 5 | Léger, rapide à mettre en place, bonne compatibilité avec mysql2 |
| Authentification | JWT + bcrypt | JWT pour les tokens stateless, bcrypt pour ne jamais stocker les mots de passe en clair |
| Base de données | MySQL 8 sur Google Cloud SQL | Relationnel, adapté à des données structurées, managé par GCP (pas de gestion du serveur) |
| Frontend | HTML/CSS/JS vanilla | Pas de framework nécessaire pour une interface aussi simple |
| Conteneurisation | Docker multi-stage Alpine | Alpine = image légère, multi-stage = outils de build exclus de l'image finale |
| Registre | Google Artifact Registry | Intégration native avec Cloud Run et le compte de service GCP |
| Orchestration | Google Cloud Run | Serverless, scale to zero, HTTPS automatique, pas de serveur à gérer |
| IaC | Terraform | Standard du secteur, supporte AWS et GCP — ce qui m'a permis de migrer |
| CI/CD | GitHub Actions | Gratuit, intégré à GitHub, simple à configurer |
| Secrets | Google Secret Manager | Chiffrement AES-256, injection directe dans Cloud Run sans passer par les variables d'environnement visibles |
| Supervision | Cloud Monitoring + Cloud Logging | Intégré à GCP, pas de configuration supplémentaire pour Cloud Run |

### 3.2. Architecture de l'infrastructure

```
Développeur
    │
    │  git push main
    ▼
GitHub Actions
    ├── Job 1 : npm test (10 tests Jest)
    ├── Job 2 : docker build → push Artifact Registry :hash-commit
    ├── Job 3 : smoke tests sur l'image (GET / → 200, POST register {} → 400, GET messages → 403)
    └── Job 4 : terraform apply → Cloud Run déploie la nouvelle image
                    │
                    ▼
        Google Cloud Platform — europe-west1 (Belgique)
        Projet : mini-chat-asd
        ┌──────────────────────────────────────────────────────────────┐
        │                                                              │
        │  Internet ──HTTPS──► [Cloud Run — mini-chat-backend :3000]  │
        │                           │                                  │
        │                     socket Unix                              │
        │                     /cloudsql/...                            │
        │                           │                                  │
        │              [Cloud SQL MySQL 8.0 — mini-chat-db]           │
        │                                                              │
        │  [Cloud Logging]  [Cloud Monitoring]  [Secret Manager]      │
        │  [Artifact Registry]  [Cloud Storage — état Terraform]      │
        └──────────────────────────────────────────────────────────────┘
```

### 3.3. Schéma de la base de données

```sql
CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,   -- hash bcrypt, jamais le mot de passe en clair
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT          NOT NULL,
  message    TEXT         NOT NULL,   -- contenu échappé contre les injections XSS
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 3.4. Routes de l'API

| Route | Méthode | Authentification | Ce que ça fait |
|-------|---------|-----------------|----------------|
| `/` | GET | Non | Retourne "Backend OK" — utilisé par Cloud Run pour vérifier que le container est en vie |
| `/auth/register` | POST | Non | Création d'un compte : validation du nom d'utilisateur, hachage du mot de passe avec bcrypt, insertion en base |
| `/auth/login` | POST | Non | Vérification du mot de passe, retourne un token JWT valable 1 heure |
| `/messages` | GET | JWT requis | Retourne tous les messages avec le nom d'utilisateur et la date |
| `/messages` | POST | JWT requis | Enregistre un message après échappement HTML pour éviter le XSS |

---

---

## 4. Démarche et outils

### 4.1. Comment j'ai travaillé

J'ai construit ce projet progressivement, en ajoutant une couche à la fois. Je ne suis pas parti directement sur le cloud — j'ai d'abord fait fonctionner l'application en local, puis j'ai conteneurisé, puis j'ai déployé sur le cloud.

**Phase locale :** J'ai commencé par écrire le backend Node.js avec les routes d'authentification et de messagerie, et j'ai tout testé en local avec Docker Compose. Avoir Docker Compose dès le départ m'a facilité la transition vers le cloud : je savais déjà que mon application fonctionnait dans un container.

**Phase CI/CD :** Avant même de déployer sur le cloud, j'ai mis en place le pipeline GitHub Actions. Ça m'a forcé à écrire des tests — parce que le pipeline s'arrête si les tests échouent. J'ai utilisé Jest avec supertest pour tester les routes HTTP sans avoir besoin d'une vraie base de données (je mocke mysql2 dans les tests).

**Phase infrastructure :** J'ai écrit Terraform au fur et à mesure des besoins. J'ai commencé par ce qui est nécessaire pour faire tourner l'application (Cloud Run + Cloud SQL), puis j'ai ajouté la sécurité (Secret Manager, comptes de service) et enfin la supervision (Cloud Monitoring).

**Problèmes rencontrés :** J'ai eu plusieurs problèmes réels que j'ai dû résoudre : un pipeline qui passait en vert mais l'application qui ne répondait pas (problème de user_data asynchrone sur EC2), une erreur Mixed Content HTTPS qui bloquait toute l'interface, et lors de la migration GCP, une erreur de connexion Cloud SQL que j'ai résolue en utilisant le socket Unix plutôt qu'une connexion TCP. Ces problèmes et leurs solutions sont détaillés dans la section 6.

### 4.2. Sécurité — ce que j'ai mis en place et pourquoi

**Secrets :** Mes mots de passe (base de données et clé JWT) ne sont jamais écrits dans le code, pas même dans les variables d'environnement de la définition Cloud Run. Ils sont stockés dans Google Secret Manager et injectés au démarrage du container via le champ `secrets` de la configuration Terraform. En pratique, même si quelqu'un accède à la définition du service dans la console GCP, il ne voit que le nom du secret — pas sa valeur.

**Connexion base de données :** Cloud SQL est configuré sans réseau privé (pour éviter le coût du VPC Connector). À la place, j'utilise le Cloud SQL Auth Proxy intégré à Cloud Run, qui crée un socket local dans le container. La connexion est authentifiée par le compte de service GCP — pas par un mot de passe de connexion réseau.

**Compte de service dédié :** J'ai créé un compte de service spécifique pour Cloud Run (`mini-chat-cloudrun@mini-chat-asd.iam.gserviceaccount.com`) qui a uniquement deux droits : se connecter à Cloud SQL et lire les secrets dans Secret Manager. Il ne peut pas créer de ressources GCP, modifier l'infrastructure, ou accéder à d'autres données.

**Protection applicative :** Dans le code, j'utilise des requêtes préparées pour toutes les interactions avec MySQL (protection contre l'injection SQL) et j'échappe le contenu des messages avant de les enregistrer (protection contre le XSS).

**Pas de SSH :** Cloud Run est serverless — il n'y a aucun serveur sur lequel se connecter. Il n'existe pas de clé SSH pour ce projet.

### 4.3. Pipeline CI/CD — pourquoi 4 jobs

J'ai structuré le pipeline en 4 jobs séquentiels pour une raison simple : chaque job est une porte. Si une porte ne s'ouvre pas, les suivantes restent fermées.

```
Job 1 — Tests unitaires Jest
    ↓ (bloqué si un test échoue)
Job 2 — Construction de l'image Docker et push sur Artifact Registry
    ↓ (bloqué si le build échoue)
Job 3 — Smoke tests : je tire l'image du registre et je teste 3 comportements HTTP
    ↓ (bloqué si l'image ne répond pas correctement)
Job 4 — terraform apply : Cloud Run déploie la nouvelle version
```

L'intérêt des smoke tests (Job 3) est de tester **la même image** qui va partir en production — pas une image locale ou un mock. Si l'image est cassée à cause d'une dépendance manquante, le problème est détecté avant le déploiement.

---

---

## 5. Réalisations du candidat

### 5.1. Configuration Cloud Run avec injection des secrets Secret Manager

**Fichier :** `terraform/cloudrun.tf`

C'est le fichier le plus important de mon infrastructure. Il décrit le service Cloud Run : quelle image utiliser, quels secrets injecter, comment se connecter à Cloud SQL.

```hcl
resource "google_cloud_run_v2_service" "backend" {
  name     = "mini-chat-backend"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = 0   # éteint quand personne n'utilise l'app — coût = 0
      max_instance_count = 3
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/mini-chat/backend:${var.image_tag}"

      ports { container_port = 3000 }

      # Variables non-sensibles
      env { name = "NODE_ENV"       value = "production" }
      env { name = "DB_USER"        value = "root" }
      env { name = "DB_NAME"        value = "mini_chat" }

      # Chemin du socket Unix créé par le Cloud SQL Auth Proxy
      env {
        name  = "DB_SOCKET_PATH"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

      # Secrets injectés depuis Secret Manager — pas dans les variables d'environnement classiques
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

      # Le volume_mounts doit être dans le bloc containers
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # Le volume est au niveau template — il crée le socket Unix Cloud SQL
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }
  }
}

# Rend le service accessible publiquement (sans authentification GCP)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

**Pourquoi j'ai fait ça comme ça :** J'ai choisi d'injecter DB_PASSWORD et JWT_SECRET via `value_source.secret_key_ref` plutôt que comme variables d'environnement classiques. La différence : une variable d'environnement classique est visible dans la console GCP si quelqu'un a accès au projet. Avec Secret Manager, même quelqu'un qui voit la configuration du service ne voit que le nom du secret, jamais sa valeur.

---

### 5.2. Base de données Cloud SQL et gestion des droits IAM

**Fichier :** `terraform/main.tf` (extrait)

Ce fichier crée la base de données, les secrets, et définit qui a le droit de faire quoi.

```hcl
# Base de données MySQL sur Cloud SQL
resource "google_sql_database_instance" "main" {
  name             = "mini-chat-db"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-f1-micro"   # plus petite instance disponible — budget étudiant

    backup_configuration {
      enabled            = true
      binary_log_enabled = true
      start_time         = "03:00"
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  deletion_protection = false
}

# Secrets chiffrés dans Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "mini-chat-db-password"
  replication { auto {} }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password   # valeur vient des GitHub Secrets — jamais écrite dans le code
}

# Compte de service pour Cloud Run
resource "google_service_account" "cloudrun" {
  account_id   = "mini-chat-cloudrun"
  display_name = "Mini-Chat Cloud Run"
}

# Droit de se connecter à Cloud SQL — rien de plus
resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Droit de lire le secret DB_PASSWORD — rien de plus
resource "google_secret_manager_secret_iam_member" "db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}
```

**Pourquoi j'ai créé un compte de service dédié :** Terraform a son propre compte de service (`terraform-deployer`) qui a les droits pour créer des ressources. Cloud Run a son propre compte (`mini-chat-cloudrun`) qui ne peut faire qu'une chose : se connecter à la base et lire les secrets. Si quelqu'un volait les credentials de l'application (ce qui est très difficile avec Cloud Run), il ne pourrait pas modifier l'infrastructure GCP.

---

### 5.3. Modification de database.js pour le socket Unix Cloud SQL

**Fichier :** `backend/src/config/database.js`

C'est la seule modification de code que j'ai dû faire pour la migration vers GCP. Cloud SQL Auth Proxy crée un socket Unix local dans le container, et mysql2 doit utiliser `socketPath` pour s'y connecter — pas `host`.

```javascript
const poolConfig = {
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

// En production (Cloud Run) : connexion via socket Unix — Cloud SQL Auth Proxy
// En local (Docker Compose) : connexion TCP classique — host = "db" (le service Docker)
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}

const pool = mysql.createPool(poolConfig);
```

**Pourquoi ce changement :** Quand j'ai essayé de connecter Cloud Run à Cloud SQL via l'adresse IP publique, la connexion était refusée. En cherchant dans la documentation GCP, j'ai compris que la méthode recommandée est le Cloud SQL Auth Proxy — qui crée un socket Unix local dans le container. mysql2 supporte les sockets Unix avec l'option `socketPath`. J'ai ajouté une détection automatique : si `DB_SOCKET_PATH` est défini (en production), on utilise le socket ; sinon, on utilise `DB_HOST` (en local). Comme ça, le Docker Compose local continue de fonctionner sans changement.

---

### 5.4. Pipeline CI/CD — authentification GCP robuste

**Fichier :** `.github/workflows/ci-cd.yml` (extrait du step d'auth)

J'ai eu plusieurs tentatives ratées pour authentifier GitHub Actions avec GCP. La solution finale utilise Python pour écrire la clé dans un fichier — c'est le seul moyen que j'ai trouvé qui fonctionne de manière fiable avec un JSON multilignes dans un secret GitHub.

```yaml
- name: Auth GCP
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
  run: |
    python3 - <<'EOF'
    import os, base64, json
    raw = os.environ["GCP_SA_KEY"].strip()
    # Tente le décodage base64 — si ça marche, c'est du base64
    # Sinon, c'est du JSON brut — ça marche aussi
    try:
        decoded = base64.b64decode(raw).decode("utf-8")
        json.loads(decoded)
        raw = decoded
    except Exception:
        pass
    with open("/tmp/sa-key.json", "w") as f:
        f.write(raw)
    EOF
    gcloud auth activate-service-account --key-file=/tmp/sa-key.json
    gcloud config set project $PROJECT_ID
    echo "GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json" >> $GITHUB_ENV
```

**Pourquoi j'ai utilisé Python :** Au début j'utilisais `echo "$GCP_SA_KEY" | base64 --decode`. Ça échouait à cause des caractères CRLF Windows dans la clé. Python lit la variable d'environnement directement (sans passer par le shell) et gère l'encodage proprement. J'ai aussi ajouté la détection automatique base64/JSON brut parce que selon comment on colle la clé dans GitHub Secrets, le format peut varier.

---

---

## 6. Situation de travail ayant nécessité une recherche

### 6.1. Problème : Cloud Run ne pouvait pas se connecter à Cloud SQL

**Contexte :**
Lors de la migration vers GCP, j'ai déployé Cloud Run et configuré `DB_HOST` avec l'adresse IP publique de Cloud SQL. Le container démarrait, mais impossible de se connecter à la base. Dans Cloud Logging, je voyais :

```
Error: connect ECONNREFUSED 104.155.21.110:3306
```

Cloud SQL avait bien une IP publique activée. J'avais ouvert la connexion. Mais ça ne marchait pas.

**Recherche effectuée :**
J'ai cherché "Cloud Run connect Cloud SQL" dans la documentation officielle GCP. J'ai trouvé deux options :
- Option 1 : VPC Serverless Connector — connexion réseau privé, environ 30€/mois
- Option 2 : Cloud SQL Auth Proxy intégré à Cloud Run — socket Unix local, gratuit

**Ce que j'ai compris :**
Même avec une IP publique sur Cloud SQL, GCP bloque les connexions TCP directes depuis Cloud Run par défaut sauf si on autorise des plages d'IP spécifiques. Mais les IPs de Cloud Run changent à chaque déploiement. Le Cloud SQL Auth Proxy résout ce problème différemment : au lieu d'une connexion TCP, le proxy crée un socket Unix local dans le container, et s'authentifie avec le compte de service GCP. Pas besoin d'ouvrir de port réseau.

**Ce que j'ai fait :**
J'ai ajouté le volume Cloud SQL dans Terraform (ce qui active le proxy automatiquement), défini la variable `DB_SOCKET_PATH` avec le chemin du socket, et modifié `database.js` pour utiliser `socketPath` au lieu de `host`. Après ça, la connexion a fonctionné immédiatement.

```hcl
# Dans cloudrun.tf — active le Cloud SQL Auth Proxy
volumes {
  name = "cloudsql"
  cloud_sql_instance {
    instances = ["mini-chat-asd:europe-west1:mini-chat-db"]
  }
}
```

```javascript
// Dans database.js — utilise le socket si disponible
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}
```

**Ce que ça m'a appris :**
La connexion entre services GCP ne fonctionne pas forcément comme une connexion réseau classique. GCP a ses propres mécanismes d'authentification entre services (IAM, Auth Proxy) qui sont plus sécurisés qu'un simple port ouvert. Il vaut mieux utiliser ces mécanismes plutôt que d'essayer de répliquer une connexion TCP classique.

---

### 6.2. Problème : `volume_mounts` au mauvais endroit dans Terraform

**Contexte :**
Après avoir ajouté la configuration du volume Cloud SQL, `terraform apply` échouait avec :

```
Error: An argument named "volume_mounts" is not expected here.
```

J'avais placé `volume_mounts` au niveau du bloc `template`, comme ça :

```hcl
template {
  containers { ... }
  volumes { ... }
  volume_mounts { ... }   # MAUVAIS — placé au niveau template
}
```

**Recherche effectuée :**
J'ai consulté la documentation Terraform Registry pour `google_cloud_run_v2_service` et lu la hiérarchie des blocs. La documentation montre que `volume_mounts` doit être à l'intérieur du bloc `containers`, pas au même niveau que `volumes`.

```hcl
template {
  containers {
    ...
    volume_mounts {   # CORRECT — dans containers
      name       = "cloudsql"
      mount_path = "/cloudsql"
    }
  }
  volumes {          # CORRECT — au niveau template
    name = "cloudsql"
    cloud_sql_instance { ... }
  }
}
```

**Ce que ça m'a appris :**
La différence entre déclarer un volume (`volumes`) et l'utiliser (`volume_mounts`) correspond à la logique Docker Compose : on déclare les volumes globalement et on les monte dans chaque service. Terraform Cloud Run applique exactement la même séparation. Une fois que j'ai compris ce parallèle avec Docker Compose, la structure est devenue logique.

---

*Dossier de projet — Titre Professionnel Administrateur Système DevOps — Niveau 6*
*Babikir Ibrahim — Juin 2026*
*github.com/babs235/mini-chat — https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
