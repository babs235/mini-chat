# PROMPT PDF — Dossier de Projet
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA générant le PDF :**
> Police Calibri ou Arial 11pt, interligne 1,4, marges 2,5 cm, format A4.
> Page de garde : titre, nom, formation, date — sobre, pas de fioritures.
> En-tête discret sur chaque page : "Mini-Chat — Dossier de Projet — Babikir Ibrahim"
> Pied de page : numéro de page centré.
> Nouvelle page à chaque section principale (##).
> Blocs de code : fond gris très clair, police monospace taille 9, bordure gauche bleue fine.
> Tableaux : alternance blanc / gris clair, bordures fines.
> Aux endroits marqués [CAPTURE : description], laisser un espace réservé avec un cadre gris clair et la légende indiquée — le candidat y insèrera la vraie capture d'écran.
> Ne pas modifier le style d'écriture — le document est rédigé à la première personne, conserver tel quel.

---

---

# DOSSIER DE PROJET

## Mini-Chat — Application de messagerie déployée sur Google Cloud Platform

---

**Candidat :** Babikir Ibrahim
**Formation :** Titre Professionnel Administrateur Système DevOps — Niveau 6
**Référentiel :** RE TP-01414-01
**Période :** Mars – Juin 2026
**En production :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app
**Code source :** https://github.com/babs235/mini-chat

---

---

## 1. Compétences du référentiel couvertes par le projet

Ce projet couvre les trois blocs de compétences du titre ASD. Voici ce que j'ai mis en place concrètement pour chacune.

**Bloc 1 — Automatiser le déploiement d'une infrastructure dans le cloud**

J'ai écrit toute l'infrastructure en Terraform (5 fichiers HCL) : Cloud Run, Cloud SQL, Secret Manager, Artifact Registry, comptes de service IAM. Rien n'est créé à la main dans la console GCP — si je supprime tout et relance `terraform apply`, je retrouve exactement la même infrastructure. Le Job 4 de mon pipeline GitHub Actions lance ce `terraform apply` automatiquement à chaque `git push main`. Pour la sécurité, les secrets ne sont jamais dans le code — ils sont dans Google Secret Manager, la connexion à la base de données passe par un socket authentifié par le compte de service, et il n'existe aucun accès SSH (Cloud Run est serverless). L'application est accessible en production sur https://mini-chat-backend-py4vurg4oq-ew.a.run.app.

**Bloc 2 — Déployer en continu une application**

J'ai 10 tests unitaires Jest qui couvrent les validations, l'authentification et la protection JWT, plus 3 smoke tests dans le pipeline qui vérifient que l'image Docker répond correctement avant d'être déployée. La couverture est à 60% des lignes — les chemins critiques sont tous couverts. La base MySQL tourne sur Cloud SQL, le schéma se crée automatiquement au démarrage. Les images Docker sont construites en multi-stage Alpine (~180 MB), stockées dans Artifact Registry, et déployées sur Cloud Run avec rolling update. Le pipeline complet (tests → build → smoke tests → déploiement) tourne sans aucune intervention manuelle.

**Bloc 3 — Superviser les services déployés**

J'ai configuré 2 alertes dans Cloud Monitoring : un uptime check qui vérifie que l'URL répond toutes les 5 minutes, et une alerte sur les erreurs HTTP 5xx. Si quelque chose ne va pas, je reçois un email. J'utilise Cloud Logging pour voir les logs du container en temps réel. C'est grâce aux logs que j'ai résolu un bug Mixed Content HTTPS (détaillé en section 6).

---

---

## 2. Cahier des charges

### Le projet

Mini-Chat est une application de messagerie accessible depuis un navigateur. Les utilisateurs s'inscrivent, se connectent, et peuvent envoyer et lire des messages. L'application elle-même est volontairement simple — deux tables en base de données, quelques routes d'API, une interface HTML. Ce n'est pas l'objectif. L'objectif, c'est tout ce qu'il y a autour : conteneuriser l'application, automatiser son déploiement, sécuriser les accès, surveiller que ça fonctionne.

[CAPTURE : Page de connexion de l'application en production — montrer l'URL https://mini-chat-backend-py4vurg4oq-ew.a.run.app et le cadenas HTTPS dans le navigateur]

### Comment le projet a évolué

J'ai travaillé sur ce projet en plusieurs étapes, chaque étape améliorant la précédente.

**Mars 2026 — Développement local**
J'ai commencé par l'application elle-même : le backend en Node.js/Express avec les routes d'authentification (JWT + bcrypt) et les routes de messagerie, le frontend en HTML/CSS/JavaScript, et Docker Compose pour faire tourner le tout localement avec MySQL. Travailler avec Docker dès le départ m'a forcé à rendre l'application compatible container dès le début — pas juste "ça marche sur ma machine".

**Avril 2026 — Premier déploiement sur GCP**
J'ai écrit les fichiers Terraform pour déployer sur Google Cloud Platform : Cloud Run pour le container, Cloud SQL pour la base de données, Artifact Registry pour stocker les images Docker. J'ai aussi mis en place le pipeline GitHub Actions avec les 4 jobs séquentiels.

**Mai-Juin 2026 — Industrialisation**
J'ai renforcé la sécurité en ajoutant Secret Manager pour ne plus avoir aucun secret en clair. J'ai mis en place la supervision avec Cloud Monitoring et les alertes email. J'ai résolu le problème de connexion Cloud SQL (détaillé en section 6) et ajouté les smoke tests pré-déploiement. Le pipeline est devenu le processus complet que j'utilise aujourd'hui : push → tests → build → smoke tests → déploiement automatique.

### Ce que je m'étais fixé comme objectifs

| Objectif | Résultat |
|----------|---------|
| Application de messagerie fonctionnelle | ✓ Inscription, connexion, messagerie en production |
| Image Docker légère | ✓ Multi-stage Alpine, ~180 MB |
| Infrastructure 100% en code | ✓ Terraform, rien créé à la main |
| Déploiement automatique sur `git push` | ✓ Pipeline 4 jobs |
| Secrets jamais en clair | ✓ Secret Manager, vérifié dans les logs |
| HTTPS en production | ✓ Automatique avec Cloud Run |
| Supervision avec alertes | ✓ 2 alertes Cloud Monitoring |
| Tests bloquant le déploiement | ✓ Jest + smoke tests |

### Contraintes

**Budget.** Je travaille sur les niveaux gratuits de GCP. Cloud Run coûte zéro quand il n'y a pas de trafic (scale to zero). Cloud SQL db-f1-micro est la plus petite instance disponible — suffisant pour ce projet.

**Pas de WebSocket.** L'interface actualise les messages toutes les 3 secondes avec une requête HTTP classique. Ça évite de configurer les WebSockets et c'est suffisant pour l'usage prévu.

**Connexion Cloud SQL.** Sans VPC Connector (~30€/mois), Cloud Run se connecte à Cloud SQL via le Cloud SQL Auth Proxy intégré — un socket Unix local. Ça m'a demandé une petite modification du code de connexion (détaillée en section 5).

**Scale to zero.** Cloud Run peut éteindre le container quand personne ne l'utilise. Le premier accès après inactivité peut prendre 1 à 2 secondes. Acceptable pour ce projet.

---

---

## 3. Spécifications techniques

### Ce que j'utilise et pourquoi

Pour le backend, j'ai choisi Node.js 20 avec Express parce que c'est léger et que le driver mysql2 s'intègre très bien. Pour l'authentification, JWT pour les tokens stateless (pas besoin de stocker des sessions en base) et bcrypt avec 10 rounds pour le hachage des mots de passe. Le frontend est en HTML/CSS/JavaScript vanilla — un framework aurait été surdimensionné pour une interface aussi simple.

Pour la conteneurisation, un Dockerfile multi-stage avec Alpine : la première étape installe les dépendances, la deuxième ne copie que ce qui est nécessaire pour faire tourner l'application — sans npm, sans les dépendances de développement. Résultat : ~180 MB au lieu de ~950 MB.

Pour le cloud, Cloud Run plutôt que Kubernetes parce que Kubernetes aurait été beaucoup trop complexe pour une seule application. Cloud Run gère lui-même le scaling, le HTTPS et les certificats. Pour l'IaC, Terraform parce que c'est le standard du secteur.

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Backend | Node.js + Express | 20 LTS / 5.2 |
| Auth | JWT + bcrypt | 9.0 / 6.0 |
| Base de données | MySQL | 8.0 (Cloud SQL) |
| Frontend | HTML/CSS/JS vanilla | — |
| Conteneurisation | Docker multi-stage Alpine | — |
| Registre d'images | Google Artifact Registry | europe-west1 |
| Orchestration | Google Cloud Run | serverless |
| IaC | Terraform | 1.5+ (provider GCP ~5.0) |
| CI/CD | GitHub Actions | 4 jobs |
| Secrets | Google Secret Manager | — |
| Supervision | Cloud Monitoring + Cloud Logging | — |
| État Terraform | Google Cloud Storage | `mini-chat-asd-tfstate` |

### Architecture

```
Développeur
    │
    │  git push main
    ▼
GitHub Actions
    ├── Job 1 : npm test — 10 tests Jest
    ├── Job 2 : docker build → Artifact Registry :hash-commit
    ├── Job 3 : smoke tests sur l'image réelle
    └── Job 4 : terraform apply → Cloud Run déploie la nouvelle image
                    │
                    ▼
        Google Cloud Platform — europe-west1 (Belgique)
        Projet : mini-chat-asd
        ┌───────────────────────────────────────────────────────────┐
        │                                                           │
        │  Internet ──HTTPS──► [Cloud Run — mini-chat-backend]     │
        │                           │                              │
        │                     socket Unix Cloud SQL Auth Proxy     │
        │                           │                              │
        │              [Cloud SQL MySQL 8.0 — mini-chat-db]        │
        │                                                           │
        │  [Cloud Logging]  [Cloud Monitoring + 2 alertes email]   │
        │  [Artifact Registry]  [Secret Manager]                   │
        │  [Cloud Storage — état Terraform]                        │
        └───────────────────────────────────────────────────────────┘
```

Le HTTPS est géré automatiquement par Cloud Run — pas de certificat SSL à configurer manuellement, pas de load balancer à créer. Cloud Run génère et renouvelle le certificat tout seul.

### Base de données

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
  message    TEXT         NOT NULL,   -- contenu échappé XSS avant insertion
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Le schéma est créé automatiquement au premier démarrage du backend via `CREATE TABLE IF NOT EXISTS`. Je n'ai pas besoin de me connecter manuellement à Cloud SQL pour initialiser la base.

### Routes de l'API

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| `/` | GET | Non | "Backend OK" — Cloud Run vérifie cette route pour savoir si le container est vivant |
| `/auth/register` | POST | Non | Validation du nom (3-20 chars, alphanumérique), hachage bcrypt, insertion |
| `/auth/login` | POST | Non | Vérification bcrypt, retourne un token JWT (1 heure) |
| `/messages` | GET | JWT | Tous les messages avec nom d'utilisateur et date, ordre chronologique |
| `/messages` | POST | JWT | Validation (max 500 chars), échappement HTML, insertion |

---

---

## 4. Démarche et outils

### Comment j'ai construit ce projet

Je n'ai pas tout construit en même temps. J'ai suivi un ordre logique : d'abord faire fonctionner l'application en local, ensuite la conteneuriser, ensuite les tests, ensuite le cloud.

Commencer avec Docker Compose localement m'a forcé à penser "container" dès le départ. Quand j'ai voulu déployer sur GCP, il n'y avait pas de surprise — l'application fonctionnait déjà dans un container propre.

J'ai mis en place les tests Jest avant de déployer sur le cloud. La raison : si les tests sont dans le pipeline et que le pipeline bloque si un test échoue, j'ai une vraie raison de les maintenir. Sans cette contrainte, j'aurais probablement remis les tests à plus tard. J'ai utilisé supertest pour tester les routes HTTP sans base de données — je mocke mysql2 dans les tests, ce qui les rend déterministes et rapides.

Pour Terraform, j'ai écrit les fichiers au fur et à mesure des besoins. Je n'ai pas utilisé de template générique. J'ai commencé par Cloud Run + Cloud SQL minimal, puis ajouté Secret Manager, puis les comptes de service avec droits limités, puis la supervision. Ce processus progressif m'a forcé à comprendre ce que chaque ressource fait réellement plutôt que de copier une configuration existante.

[CAPTURE : Pipeline GitHub Actions avec les 4 jobs en vert — montrer que tous les jobs ont réussi]

### Sécurité

Les secrets (mot de passe de la base, clé JWT) ne sont jamais dans le code source, pas dans les variables d'environnement visibles de Cloud Run, pas dans les logs. Ils sont dans Google Secret Manager et injectés au démarrage du container via le champ `secrets` de la configuration Terraform. Même quelqu'un ayant accès à la console GCP ne voit que le nom du secret — jamais sa valeur.

Pour la connexion à Cloud SQL, j'utilise le Cloud SQL Auth Proxy intégré à Cloud Run. Plutôt qu'un port réseau ouvert, le proxy crée un socket Unix local dans le container, et l'authentification se fait par le compte de service GCP.

J'ai créé un compte de service dédié pour Cloud Run avec exactement deux droits : se connecter à Cloud SQL et lire les secrets dans Secret Manager. Si l'application était compromise, l'attaquant ne pourrait pas modifier l'infrastructure GCP — le compte n'a pas ces droits.

Dans le code, toutes les requêtes SQL utilisent des paramètres préparés (jamais de concaténation de chaînes) et le contenu des messages est échappé avant insertion (protection XSS). Il n'y a aucune clé SSH dans ce projet — Cloud Run ne permet pas de connexion SSH.

### Le pipeline CI/CD — logique des 4 jobs

```
Job 1 — Tests unitaires Jest (10 tests)
    → Si un test échoue, tout s'arrête. Pas question de construire une image cassée.

Job 2 — docker build + push Artifact Registry
    → L'image est taguée avec le hash exact du commit Git.
      Je sais toujours quelle version exacte tourne en production.

Job 3 — Smoke tests sur l'image réelle
    → Je tire l'image depuis Artifact Registry (la même qui partira en prod)
      et je vérifie 3 comportements : health check → 200, validation → 400, JWT → 403.
      Différent des tests Jest : là, j'utilise l'image réelle, pas un mock.

Job 4 — terraform apply
    → Cloud Run déploie avec rolling update : nouveau container démarré,
      health check validé, puis ancien container arrêté.
      Si le health check échoue, le déploiement s'annule automatiquement.
```

[CAPTURE : Console GCP Cloud Run — montrer le service mini-chat-backend actif avec le nombre d'instances et l'URL]

---

---

## 5. Réalisations du candidat

### Configuration Cloud Run et injection des secrets

**Fichier :** `terraform/cloudrun.tf`

Ce fichier est le cœur de mon infrastructure. Il définit le service Cloud Run avec tous ses paramètres : image à utiliser, variables d'environnement, secrets, connexion Cloud SQL.

Le point central est l'injection des secrets. J'aurais pu les passer comme variables d'environnement classiques (`env { name = "DB_PASSWORD", value = "..." }`), mais alors la valeur serait visible dans la console GCP pour quiconque a accès au projet. Avec `value_source.secret_key_ref`, Cloud Run va chercher la valeur dans Secret Manager au démarrage du container — la console ne montre que le nom du secret.

```hcl
resource "google_cloud_run_v2_service" "backend" {
  name     = "mini-chat-backend"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = 0   # éteint quand inactif — coût = 0
      max_instance_count = 3
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/mini-chat/backend:${var.image_tag}"

      ports { container_port = 3000 }

      env { name = "NODE_ENV"      value = "production" }
      env { name = "DB_USER"       value = "root" }
      env { name = "DB_NAME"       value = "mini_chat" }
      env {
        name  = "DB_SOCKET_PATH"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }

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

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

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

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

La variable `var.image_tag` reçoit `${{ github.sha }}` depuis le pipeline. C'est ce qui crée la traçabilité : chaque déploiement pointe vers une image précise, et on sait toujours quel commit exact tourne en production.

[CAPTURE : Google Secret Manager — montrer les deux secrets mini-chat-db-password et mini-chat-jwt-secret dans la console GCP]

---

### Base de données, secrets et comptes de service

**Fichier :** `terraform/main.tf` (extrait)

```hcl
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
      ipv4_enabled = true
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "mini-chat-db-password"
  replication { auto {} }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password  # vient des GitHub Secrets — jamais écrit dans le code
}

resource "google_service_account" "cloudrun" {
  account_id   = "mini-chat-cloudrun"
  display_name = "Mini-Chat Cloud Run"
}

resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}
```

J'ai séparé les droits entre deux comptes de service : `terraform-deployer` qui crée et modifie l'infrastructure, et `mini-chat-cloudrun` qui fait tourner l'application. Ce dernier n'a que deux droits — se connecter à Cloud SQL et lire les secrets. Si l'application était compromise, l'attaquant ne pourrait pas modifier l'infrastructure.

---

### Adaptation de la connexion MySQL pour Cloud SQL

**Fichier :** `backend/src/config/database.js`

C'est la seule modification de code que j'ai dû faire pour supporter Cloud SQL. Le driver mysql2 se connecte normalement via `host` (adresse IP). Mais avec Cloud SQL Auth Proxy sur Cloud Run, la connexion passe par un socket Unix local — il faut utiliser `socketPath`.

J'ai ajouté une détection automatique : si `DB_SOCKET_PATH` existe (en production), on utilise le socket. Sinon, on utilise `DB_HOST` (en local avec Docker Compose). L'environnement local continue de fonctionner exactement comme avant sans aucun changement de configuration.

```javascript
const poolConfig = {
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

// Production (Cloud Run) : socket Unix via Cloud SQL Auth Proxy
// Local (Docker Compose) : connexion TCP classique vers le container MySQL
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}

const pool = mysql.createPool(poolConfig);
```

---

### Authentification GCP dans le pipeline

**Fichier :** `.github/workflows/ci-cd.yml` (extrait)

J'ai eu plusieurs tentatives ratées pour authentifier GitHub Actions avec GCP. La première utilisait `echo "$GCP_SA_KEY" | base64 --decode` qui échouait à cause des caractères Windows dans la clé JSON. La solution finale utilise Python, qui lit la variable d'environnement directement sans passer par le shell :

```yaml
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
    with open("/tmp/sa-key.json", "w") as f:
        f.write(raw)
    EOF
    gcloud auth activate-service-account --key-file=/tmp/sa-key.json
    gcloud config set project $PROJECT_ID
    echo "GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json" >> $GITHUB_ENV
```

Le `GOOGLE_APPLICATION_CREDENTIALS` exporté dans `$GITHUB_ENV` permet aux steps suivants (terraform init, validate, apply) de trouver les credentials sans ré-authentification.

[CAPTURE : Cloud Monitoring — montrer les 2 alertes actives et l'uptime check en état OK]

---

---

## 6. Situation de travail ayant nécessité une recherche

### Cloud Run ne pouvait pas se connecter à Cloud SQL

**Le problème**

Lors du premier déploiement, j'avais configuré `DB_HOST` avec l'adresse IP publique de Cloud SQL. Le container démarrait, mais l'application tombait immédiatement. Dans Cloud Logging, je voyais :

```
Error: connect ECONNREFUSED 104.155.21.110:3306
```

L'IP publique était bien activée sur Cloud SQL. Les identifiants étaient bons. Mais rien.

**Ce que j'ai cherché**

J'ai cherché "Cloud Run connect Cloud SQL" dans la documentation officielle Google. Je suis tombé sur la page "Connect from Cloud Run to Cloud SQL" qui présente deux options :
- VPC Serverless Connector : connexion réseau privé, environ 30€/mois
- Cloud SQL Auth Proxy intégré : socket Unix local, gratuit, géré par GCP

**Ce que j'ai compris**

Sur GCP, même avec une IP publique sur Cloud SQL, les connexions TCP directes depuis Cloud Run ne fonctionnent pas sans ouvrir des plages d'IP autorisées — et Cloud Run n'a pas d'IP fixe. La vraie solution est le Cloud SQL Auth Proxy. Quand on déclare un `volume` de type `cloud_sql_instance` dans Terraform, Cloud Run déploie automatiquement le proxy comme processus secondaire dans le container. Le proxy crée un socket Unix à `/cloudsql/[connection-name]`. La connexion est authentifiée par le compte de service GCP — aucun port réseau à ouvrir.

**Ce que j'ai changé**

Dans `cloudrun.tf` :
```hcl
env {
  name  = "DB_SOCKET_PATH"
  value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
}

volume_mounts {
  name       = "cloudsql"
  mount_path = "/cloudsql"
}

volumes {
  name = "cloudsql"
  cloud_sql_instance {
    instances = [google_sql_database_instance.main.connection_name]
  }
}
```

Dans `database.js`, j'ai ajouté la détection automatique socket/TCP. Après ça, la connexion a fonctionné immédiatement.

**Ce que ça m'a appris**

GCP a ses propres mécanismes pour connecter les services entre eux — ce n'est pas forcément intuitif par rapport à une connexion TCP classique, mais c'est plus sécurisé. L'authentification se fait par IAM avant même d'arriver à la base de données.

---

### Bug HTTPS qui bloquait toute l'interface

**Le problème**

Après avoir activé HTTPS, j'avais accès à l'application mais impossible de s'inscrire ou de se connecter. La console du navigateur montrait :

```
Mixed Content: The page at 'https://...' was loaded over HTTPS,
but requested an insecure XMLHttpRequest endpoint 'http://...:3000/auth/register'.
This request has been blocked.
```

**Ce que j'ai cherché**

En cherchant "Mixed Content HTTPS JavaScript", j'ai compris que le navigateur bloque toute requête HTTP depuis une page chargée en HTTPS — c'est la politique Mixed Content. Le problème venait de `frontend/js/config.js` qui construisait l'URL de l'API avec `"http://" + window.location.hostname + ":3000"`. En HTTPS, cette URL `http://` est automatiquement bloquée.

**La correction**

En production, les URLs relatives suffisent — le navigateur construit automatiquement l'URL complète en reprenant le protocole de la page courante :

```javascript
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return '';  // URL relative — fonctionne en HTTP local et en HTTPS production
};
```

**Ce que ça m'a appris**

Dès qu'on touche à HTTPS, le frontend doit être pensé pour plusieurs environnements. Hardcoder un protocole ou un port crée une dépendance fragile. Les URLs relatives évitent ce problème et fonctionnent dans tous les contextes.

[CAPTURE : Cloud Logging — montrer les logs du container Cloud Run avec "Server started on port 3000" et "Schema initialized"]

---

---

## 7. Bilan

### Ce qui fonctionne

L'application est en production et accessible publiquement. Les trois blocs de compétences du référentiel sont couverts : l'infrastructure est entièrement décrite en Terraform, le déploiement est automatisé via un pipeline GitHub Actions en quatre étapes, et la supervision est en place avec des alertes email. Depuis le premier déploiement stable, l'application n'a pas eu de coupure non planifiée.

Ce qui me satisfait le plus, c'est la cohérence de l'ensemble. Un `git push` déclenche les tests, construit l'image Docker, la valide avec des smoke tests, puis déploie — sans aucune intervention manuelle. Si les tests échouent, rien ne part en production. Si le health check échoue après déploiement, Cloud Run annule le rolling update automatiquement. C'est ce que j'avais visé au départ.

### Les limites que j'assume

**Pas de WebSocket.** L'interface actualise les messages toutes les 3 secondes via polling HTTP. C'est une contrainte que j'ai choisie consciemment pour ne pas complexifier l'infrastructure. Cloud Run supporte les WebSockets, mais ça aurait demandé plus de configuration et détourné l'attention de l'objectif principal.

**Scale to zero.** Le premier accès après une période d'inactivité prend 1 à 2 secondes de cold start. C'est acceptable pour un projet de formation, mais pas pour une application en production réelle avec des utilisateurs actifs — là, il faudrait `min_instance_count = 1`.

**Couverture de tests à 60%.** Les chemins critiques — authentification, validation, protection JWT — sont couverts. Ce qui ne l'est pas, ce sont les cas d'erreur de base de données et certaines routes secondaires. Pour un projet en production réelle, je viserais 80%.

**Un seul environnement.** Je n'ai pas de staging séparé de la production. Tout passe directement sur le projet GCP `mini-chat-asd`. C'est suffisant pour ce projet, mais en équipe il faudrait deux environnements distincts avec des variables Terraform différentes.

### Ce que je ferais différemment

Je mettrais en place les tests Jest dès le premier jour, avant même d'écrire le code de l'application. J'ai commencé par l'application, puis les tests, puis le pipeline — ce qui m'a obligé à revenir en arrière pour rendre certaines parties testables. Dans l'ordre inverse, le code aurait été mieux structuré dès le départ.

Je configurerais aussi le backend Terraform distant (Cloud Storage) dès le début du projet. J'ai commencé avec un état local, puis migré vers le bucket GCS — cette migration aurait pu causer des problèmes si l'état local avait été corrompu entre-temps.

### Ce que ce projet m'a apporté

Avant ce projet, je comprenais Docker et le principe du cloud. Ce projet m'a forcé à aller beaucoup plus loin : écrire de l'IaC avec Terraform, comprendre comment les services GCP s'authentifient entre eux via IAM, construire un pipeline CI/CD qui bloque réellement sur les erreurs, et superviser une application en conditions réelles.

Les deux situations techniques de la section 6 résument bien cette progression. Le problème Cloud SQL n'était pas un bug dans mon code — c'était une incompréhension de comment GCP gère les connexions entre services. Comprendre pourquoi TCP ne fonctionne pas et pourquoi le socket Unix via le proxy est la bonne solution, c'est le genre de connaissance qu'on n'acquiert qu'en se confrontant à un vrai environnement cloud.

---

*Babikir Ibrahim — Juin 2026*
*Titre Professionnel Administrateur Système DevOps — Niveau 6 — RE TP-01414-01*
*github.com/babs235/mini-chat — https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
