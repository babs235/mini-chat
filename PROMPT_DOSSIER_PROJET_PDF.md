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

Ce projet couvre les trois blocs de compétences du titre ASD. Je liste ci-dessous chaque compétence avec ce que j'ai mis en place concrètement.

**Bloc 1 — Automatiser le déploiement d'une infrastructure dans le cloud**

Pour la création automatisée de l'infrastructure, j'ai tout écrit en Terraform : Cloud Run, Cloud SQL, Secret Manager, Artifact Registry, les comptes de service. Rien n'est créé à la main dans la console GCP — si je supprime tout et que je relance `terraform apply`, je retrouve exactement la même infrastructure. Pour le déploiement automatisé, le Job 4 de mon pipeline GitHub Actions lance `terraform apply` sans aucune intervention manuelle à chaque fois que je pousse du code sur la branche main. Pour la sécurité, les secrets ne sont jamais dans le code — ils sont dans Google Secret Manager, la base de données n'est accessible que via un socket authentifié par le compte de service, et il n'y a aucun accès SSH possible (Cloud Run est serverless). L'application est accessible en production à l'adresse https://mini-chat-backend-py4vurg4oq-ew.a.run.app, déployée sur Google Cloud Platform en région europe-west1.

**Bloc 2 — Déployer en continu une application**

Pour les tests, j'ai écrit 10 tests unitaires Jest qui couvrent les validations d'entrée, l'authentification et la protection JWT. J'ai aussi 3 smoke tests dans le pipeline qui vérifient que l'image Docker répond correctement avant d'être déployée. La couverture globale est à 60% de lignes — pas parfait, mais les chemins critiques (validation, auth, protection des routes) sont tous testés. Pour le stockage, la base MySQL tourne sur Cloud SQL, le schéma des tables est créé automatiquement au démarrage de l'application (je n'ai pas besoin de me connecter manuellement à la base). Les containers sont gérés avec Docker multi-stage Alpine (~180 MB) stockés dans Artifact Registry, déployés sur Cloud Run avec rolling update. Le pipeline complet (tests → build → smoke tests → déploiement) tourne automatiquement à chaque `git push main`.

**Bloc 3 — Superviser les services déployés**

J'ai mis en place 2 alertes dans Cloud Monitoring : un uptime check qui vérifie que l'URL répond toutes les 5 minutes, et une alerte sur les erreurs HTTP 5xx. Si le service tombe ou commence à rendre des erreurs, je reçois un email. J'utilise Cloud Logging pour voir les logs du container en temps réel — c'est d'ailleurs grâce aux logs que j'ai résolu un bug Mixed Content HTTPS (détaillé en section 6).

---

---

## 2. Cahier des charges

### Qu'est-ce que ce projet ?

Mini-Chat est une application de messagerie accessible depuis un navigateur. Les utilisateurs s'inscrivent, se connectent, et peuvent envoyer et lire des messages. L'application en elle-même est volontairement simple — deux tables en base de données, quelques routes d'API, une interface HTML basique. Ce n'est pas l'objectif. L'objectif, c'est tout ce qu'il y a autour : conteneuriser l'application, automatiser son déploiement, sécuriser les accès, surveiller que ça fonctionne, et faire en sorte qu'un simple `git push` suffise à mettre à jour la production sans toucher à rien manuellement.

### Comment le projet a évolué

Je n'ai pas tout construit d'un coup. Le projet a évolué par étapes, chaque étape corrigeant les problèmes de la précédente.

En mars 2026, j'ai développé l'application en local : backend Node.js/Express avec les routes d'authentification et de messagerie, frontend en HTML/CSS/JavaScript, Docker Compose pour tout faire tourner ensemble sur mon poste avec MySQL.

En avril, j'ai fait le premier déploiement cloud sur AWS. J'ai écrit l'infrastructure Terraform pour EC2 + RDS MySQL et mis en place le pipeline GitHub Actions.

En mai, j'ai eu mon premier gros problème : le pipeline GitHub Actions passait en vert, mais l'application ne répondait pas en production. Après avoir cherché, j'ai compris que le script `user_data` de l'EC2 — qui installait Docker et lançait le container — s'exécutait de manière asynchrone après le déploiement Terraform. Terraform considérait le déploiement terminé, mais en réalité Docker n'était pas encore lancé. J'ai migré vers AWS ECS Fargate pour résoudre ce problème : avec Fargate, le container démarre directement depuis l'image Docker sans script d'initialisation, et ECS s'assure lui-même que le container est en vie via le health check. J'ai aussi ajouté les secrets SSM, le HTTPS avec ACM, les smoke tests et les alarmes CloudWatch.

En juin, mes crédits AWS se sont épuisés. J'ai dû migrer vers Google Cloud Platform. C'est là que j'ai vraiment vu l'intérêt de Terraform : j'ai réécrit les fichiers HCL pour le provider GCP, et le pipeline, le Dockerfile et le code applicatif n'ont presque pas eu à changer. La migration d'un cloud à l'autre m'a pris quelques jours, pas des semaines — parce que l'infrastructure était en code, pas configurée à la main.

### Ce que j'avais à réaliser

Au départ, j'avais défini ces objectifs pour le projet :

- Une application de messagerie fonctionnelle avec authentification JWT ✓
- Une image Docker légère construite en multi-stage ✓
- Une infrastructure cloud entièrement en code avec Terraform ✓
- Un déploiement automatique déclenché par un simple `git push` ✓
- Des secrets jamais écrits en clair dans le code ou les logs ✓
- Le HTTPS en production ✓
- Une supervision avec alertes ✓
- Des tests qui bloquent le déploiement si quelque chose ne va pas ✓

### Contraintes

**Budget.** Je travaille sur les niveaux gratuits. Sur GCP, Cloud Run coûte zéro quand il n'y a pas de trafic (le container s'éteint). Cloud SQL db-f1-micro est la plus petite instance disponible — suffisant pour un projet de formation.

**Pas de WebSocket.** L'interface actualise les messages toutes les 3 secondes avec une requête HTTP classique. Ce n'est pas du temps réel au sens strict, mais ça suffit pour l'usage prévu et ça évite de configurer les WebSockets avec Cloud Run.

**Connexion Cloud SQL.** Sans VPC Connector (qui coûte environ 30€/mois), Cloud Run se connecte à Cloud SQL via le Cloud SQL Auth Proxy intégré — un socket Unix local dans le container. Ça m'a demandé de modifier légèrement le code de connexion, mais c'est plus sécurisé qu'un port réseau ouvert.

**Scale to zero.** Cloud Run peut éteindre le container quand personne n'utilise l'application. Le premier accès après une période d'inactivité peut prendre 1 à 2 secondes — c'est ce qu'on appelle le "cold start". Acceptable pour un projet de formation.

---

---

## 3. Spécifications techniques

### Ce que j'utilise et pourquoi

Pour le backend, j'ai choisi Node.js 20 avec Express parce que c'est léger, rapide à mettre en place, et le driver mysql2 fonctionne très bien avec. Pour l'authentification, j'utilise JWT pour les tokens (ça évite de stocker des sessions en base) et bcrypt pour hacher les mots de passe avec 10 rounds — chaque vérification prend environ 100ms, ce qui rend les attaques par dictionnaire très lentes. Le frontend est en HTML/CSS/JavaScript vanilla parce qu'un framework (React, Vue...) aurait été surdimensionné pour une interface aussi simple.

Pour la conteneurisation, j'utilise un Dockerfile multi-stage avec Alpine. L'idée du multi-stage, c'est d'avoir une première étape qui installe toutes les dépendances, et une deuxième étape qui copie seulement ce qui est nécessaire pour faire tourner l'application — sans npm, sans les dépendances de développement. Résultat : l'image fait environ 180 MB au lieu de 950 MB avec une image Node.js standard.

Pour le cloud, j'ai choisi Cloud Run plutôt que Kubernetes parce que Kubernetes aurait été beaucoup plus complexe à mettre en place pour une seule application. Cloud Run gère lui-même le scaling, le HTTPS et les certificats SSL — je n'ai pas besoin de configurer tout ça. Pour l'Infrastructure as Code, j'ai utilisé Terraform parce que c'est l'outil standard du secteur et qu'il supporte à la fois AWS et GCP — ce qui m'a directement prouvé sa valeur lors de la migration.

### Architecture de l'infrastructure

Voici comment tout est connecté :

```
Développeur
    │
    │  git push main
    ▼
GitHub Actions
    ├── Job 1 : npm test — 10 tests Jest (si un échoue, tout s'arrête)
    ├── Job 2 : docker build → push Artifact Registry avec le tag :hash-du-commit
    ├── Job 3 : smoke tests sur l'image — 3 vérifications HTTP
    └── Job 4 : terraform apply → Cloud Run déploie la nouvelle image
                    │
                    ▼
        Google Cloud Platform — europe-west1 (Belgique)
        Projet mini-chat-asd
        ┌───────────────────────────────────────────────────────────┐
        │                                                           │
        │  Internet ──HTTPS──► [Cloud Run — mini-chat-backend]     │
        │                           │                              │
        │                     socket Unix                          │
        │                 /cloudsql/mini-chat-asd:...              │
        │                           │                              │
        │              [Cloud SQL MySQL 8.0 — mini-chat-db]        │
        │                                                           │
        │  [Cloud Logging]  [Cloud Monitoring + alertes]           │
        │  [Artifact Registry]  [Secret Manager]                   │
        │  [Cloud Storage — état Terraform]                        │
        └───────────────────────────────────────────────────────────┘
```

Le HTTPS est géré automatiquement par Cloud Run — je n'ai pas eu à configurer de certificat SSL manuellement. Cloud Run génère et renouvelle le certificat tout seul. C'est un avantage concret par rapport à ce que j'avais sur AWS, où je devais créer un certificat ACM, le valider par DNS, configurer l'ALB...

### Base de données

Le schéma est simple : deux tables reliées par une clé étrangère.

```sql
CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,   -- toujours un hash bcrypt, jamais le mot de passe en clair
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT          NOT NULL,
  message    TEXT         NOT NULL,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

Je n'utilise pas de fichier SQL d'initialisation séparé. Au démarrage du backend, une fonction `initSchema()` exécute les `CREATE TABLE IF NOT EXISTS`. Ça évite d'avoir à se connecter manuellement à Cloud SQL pour initialiser la base — tout se fait automatiquement au premier démarrage.

### Routes de l'API

| Route | Méthode | Auth | Ce que ça fait |
|-------|---------|------|----------------|
| `/` | GET | Non | Répond "Backend OK" — Cloud Run utilise cette route pour vérifier que le container est en vie |
| `/auth/register` | POST | Non | Valide le nom d'utilisateur (3 à 20 caractères, lettres/chiffres/underscore), hache le mot de passe, insère en base |
| `/auth/login` | POST | Non | Vérifie le mot de passe avec bcrypt, retourne un token JWT valable 1 heure |
| `/messages` | GET | JWT | Retourne tous les messages avec le nom d'utilisateur et la date, triés par ordre chronologique |
| `/messages` | POST | JWT | Valide le message (max 500 caractères), échappe les caractères HTML, enregistre en base |

---

---

## 4. Démarche et outils

### Comment j'ai travaillé

Je n'ai pas tout construit en même temps. J'ai suivi un ordre qui m'a semblé logique : d'abord faire fonctionner l'application localement, ensuite la conteneuriser, ensuite mettre en place les tests, et enfin déployer sur le cloud.

J'ai commencé par l'application et Docker Compose. L'avantage de travailler avec Docker dès le début, c'est qu'on force l'application à fonctionner dans un container propre — pas juste sur "ma machine". Quand j'ai voulu déployer sur le cloud, il n'y avait pas de surprise.

Ensuite j'ai mis en place les tests Jest avant même de déployer sur le cloud. La raison : si les tests sont dans le pipeline et que le pipeline bloque si un test échoue, j'ai une raison de maintenir les tests à jour. Sans cette contrainte, on a tendance à ne jamais écrire de tests. J'ai utilisé supertest pour tester les routes HTTP sans avoir besoin d'une vraie base de données — je mocke mysql2 dans les tests. La couverture atteint 60% des lignes, ce qui correspond au seuil requis. Les parties non couvertes sont principalement les chemins "heureux" (inscription réussie, connexion réussie) qui nécessiteraient une vraie base de données dans les tests.

Pour Terraform, j'ai écrit les fichiers au fur et à mesure. Je ne suis pas parti d'un modèle générique — j'ai commencé par la ressource minimale pour faire tourner l'application, et j'ai ajouté les autres couches progressivement (secrets, supervision, comptes de service). Ce processus m'a forcé à comprendre ce que chaque ressource fait réellement.

### Sécurité — les choix que j'ai faits

La sécurité dans ce projet fonctionne en plusieurs couches.

Les secrets (mot de passe de la base de données, clé de signature JWT) ne sont jamais dans le code source, pas dans les variables d'environnement visibles de Cloud Run, pas dans l'image Docker, et pas dans les logs. Ils sont dans Google Secret Manager et injectés directement dans le container au démarrage via le champ `secrets` de la configuration Terraform. En pratique, même quelqu'un qui aurait accès à la console GCP ne verrait que le nom du secret — jamais sa valeur.

Pour la connexion à Cloud SQL, j'utilise le Cloud SQL Auth Proxy intégré à Cloud Run. Plutôt qu'un port TCP ouvert, le proxy crée un socket Unix local dans le container, et l'authentification se fait par le compte de service GCP. Même avec une IP publique sur Cloud SQL, personne ne peut s'y connecter directement depuis l'extérieur.

J'ai créé un compte de service dédié pour Cloud Run (`mini-chat-cloudrun@`) avec exactement deux droits : se connecter à Cloud SQL et lire les secrets dans Secret Manager. Il n'a pas le droit de créer des ressources GCP, de modifier l'infrastructure, ou d'accéder à quoi que ce soit d'autre. C'est ce qu'on appelle le principe du moindre privilège — en pratique, ça veut dire que même si quelqu'un volait les credentials de l'application, les dégâts seraient limités.

Dans le code, toutes les requêtes SQL utilisent des paramètres préparés (les `?` de mysql2) — jamais de concaténation de chaînes qui permettrait une injection SQL. Le contenu des messages est échappé avec `escapeHtml()` avant d'être enregistré en base pour éviter le XSS.

Cloud Run étant serverless, il n'y a aucun serveur sur lequel se connecter — donc aucune clé SSH dans ce projet.

### Le pipeline CI/CD — pourquoi 4 jobs dans cet ordre

Le pipeline est structuré en 4 jobs séquentiels. Chaque job dépend du précédent : si un job échoue, les suivants ne s'exécutent pas.

```
Job 1 — Tests unitaires
    Si un test échoue → on s'arrête là. Pas question de construire une image cassée.

Job 2 — Construction de l'image et push sur Artifact Registry
    L'image est taguée avec le hash exact du commit Git.
    Je sais à tout moment quelle version exacte tourne en production.

Job 3 — Smoke tests sur l'image
    Je tire l'image depuis Artifact Registry (la même qui partira en prod)
    et je vérifie 3 comportements : health check → 200, validation → 400, protection JWT → 403.
    C'est différent des tests Jest : là j'teste l'image réelle, pas un mock.

Job 4 — terraform apply
    Cloud Run déploie la nouvelle image avec un rolling update :
    le nouveau container démarre, le health check passe, l'ancien s'arrête.
    Si le health check ne passe pas, l'ancien container reste actif.
```

L'intérêt des smoke tests en Job 3, c'est de tester exactement le même artefact qui va partir en production. Si une dépendance npm manque dans l'image Docker ou si le Dockerfile est cassé, ça se voit ici — avant de toucher à la production.

---

---

## 5. Réalisations du candidat

### Cloud Run avec injection des secrets depuis Secret Manager

**Fichier :** `terraform/cloudrun.tf`

C'est le fichier central de mon infrastructure GCP. Il décrit tout ce qui concerne le service Cloud Run : l'image à utiliser, les variables d'environnement, les secrets, la connexion à Cloud SQL.

Le point le plus important est la façon dont j'injecte les secrets. J'aurais pu les passer comme variables d'environnement classiques, mais alors n'importe qui avec accès à la console GCP les verrait en clair dans la définition du service. Avec `value_source.secret_key_ref`, Cloud Run va lui-même chercher la valeur dans Secret Manager au démarrage — la console ne montre que le nom du secret, jamais sa valeur.

```hcl
resource "google_cloud_run_v2_service" "backend" {
  name     = "mini-chat-backend"
  location = var.region

  template {
    service_account = google_service_account.cloudrun.email

    scaling {
      min_instance_count = 0   # s'éteint quand personne n'utilise l'app
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

      # volume_mounts doit être dans le bloc containers
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    # volumes se déclare au niveau template (pas dans containers)
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

La variable `var.image_tag` reçoit le hash du commit Git via le pipeline (`TF_VAR_image_tag=${{ github.sha }}`). C'est ce qui crée la traçabilité : chaque déploiement pointe vers une image spécifique, et on peut toujours savoir quel commit exact tourne en production.

---

### Cloud SQL, Secret Manager et comptes de service

**Fichier :** `terraform/main.tf` (extrait)

Ce fichier crée la base de données, les secrets chiffrés, et définit qui a le droit de faire quoi dans GCP.

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
  secret_data = var.db_password  # vient de GitHub Secrets, jamais écrit dans le code
}

# Compte de service dédié à Cloud Run
resource "google_service_account" "cloudrun" {
  account_id   = "mini-chat-cloudrun"
  display_name = "Mini-Chat Cloud Run"
}

# Droit de se connecter à Cloud SQL — rien d'autre
resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Droit de lire le secret DB_PASSWORD — rien d'autre
resource "google_secret_manager_secret_iam_member" "db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}
```

J'ai délibérément séparé les droits entre deux comptes de service : `terraform-deployer` qui crée et modifie l'infrastructure, et `mini-chat-cloudrun` qui fait tourner l'application. Si l'application est compromise, l'attaquant ne peut pas modifier l'infrastructure GCP parce que le compte de service de l'application n'a tout simplement pas ces droits.

---

### Modification de database.js pour le socket Unix Cloud SQL

**Fichier :** `backend/src/config/database.js`

C'est la seule modification de code que j'ai dû faire pour la migration vers GCP. Le driver mysql2 se connecte normalement via `host` (adresse IP ou nom de domaine). Mais avec Cloud SQL Auth Proxy sur Cloud Run, la connexion passe par un socket Unix local — il faut utiliser `socketPath` à la place.

J'ai ajouté une détection automatique : si la variable `DB_SOCKET_PATH` existe (en production sur Cloud Run), on utilise le socket. Sinon, on utilise `DB_HOST` (en local avec Docker Compose). Comme ça, l'environnement local continue de fonctionner exactement comme avant.

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
// Local (Docker Compose) : connexion TCP classique
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}

const pool = mysql.createPool(poolConfig);
```

---

### Authentification GCP dans le pipeline

**Fichier :** `.github/workflows/ci-cd.yml` (extrait du step d'authentification)

J'ai essayé plusieurs méthodes pour authentifier GitHub Actions avec GCP. La première utilisait `echo "$GCP_SA_KEY" | base64 --decode`, qui échouait à cause des caractères CRLF Windows dans la clé JSON. La solution finale utilise Python, qui lit la variable d'environnement directement sans passer par le shell :

```yaml
- name: Auth GCP
  env:
    GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
  run: |
    python3 - <<'EOF'
    import os, base64, json
    raw = os.environ["GCP_SA_KEY"].strip()
    try:
        # Tente le décodage base64 (format alternatif)
        decoded = base64.b64decode(raw).decode("utf-8")
        json.loads(decoded)
        raw = decoded
    except Exception:
        pass  # c'est du JSON brut, on garde tel quel
    with open("/tmp/sa-key.json", "w") as f:
        f.write(raw)
    EOF
    gcloud auth activate-service-account --key-file=/tmp/sa-key.json
    gcloud config set project $PROJECT_ID
    echo "GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json" >> $GITHUB_ENV
```

Le `GOOGLE_APPLICATION_CREDENTIALS` exporté dans `$GITHUB_ENV` permet à Terraform de trouver les credentials dans les steps suivants (terraform init, validate, apply) sans avoir à répéter l'authentification.

---

---

## 6. Situation de travail ayant nécessité une recherche

### Pourquoi Cloud Run ne pouvait pas se connecter à Cloud SQL

Lors de la migration vers GCP, j'ai déployé Cloud Run et configuré `DB_HOST` avec l'adresse IP publique de Cloud SQL. Le container démarrait, mais l'application échouait immédiatement avec cette erreur dans Cloud Logging :

```
Error: connect ECONNREFUSED 104.155.21.110:3306
```

J'avais bien activé l'IP publique sur Cloud SQL. J'avais vérifié les identifiants. Mais rien.

**Ce que j'ai cherché**

J'ai cherché "Cloud Run connect Cloud SQL" dans la documentation officielle Google. Je suis tombé sur la page "Connect from Cloud Run to Cloud SQL" qui explique deux options :
- VPC Serverless Connector : connexion réseau privé, autour de 30€/mois
- Cloud SQL Auth Proxy intégré : socket Unix local, géré par GCP, gratuit

**Ce que j'ai compris**

GCP ne fonctionne pas comme AWS sur ce point. Même avec une IP publique sur Cloud SQL, GCP vérifie l'identité du client qui se connecte via IAM — pas juste l'adresse IP source. Pour une connexion directe TCP depuis Cloud Run, il faudrait configurer des plages d'IP autorisées, mais Cloud Run n'a pas d'IP fixe.

La vraie solution, c'est le Cloud SQL Auth Proxy. Quand on déclare un `volume` de type `cloud_sql_instance` dans Terraform, Cloud Run déploie automatiquement le proxy comme un processus secondaire dans le container. Le proxy crée un socket Unix à `/cloudsql/[connection-name]`. Le container s'y connecte via `socketPath` au lieu de `host`, et l'authentification se fait via le compte de service GCP — aucun port réseau à ouvrir.

**Ce que j'ai changé**

Dans `cloudrun.tf`, j'ai ajouté le volume et défini la variable d'environnement `DB_SOCKET_PATH` :

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

Et dans `database.js`, j'ai ajouté la logique de détection pour utiliser `socketPath` si la variable est présente :

```javascript
if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}
```

Après ça, la connexion a fonctionné immédiatement.

**Ce que ça m'a appris**

GCP a ses propres mécanismes pour connecter les services entre eux. Ce n'est pas toujours intuitif par rapport à ce qu'on ferait sur AWS ou en local, mais c'est en général plus sécurisé. Le Cloud SQL Auth Proxy évite complètement d'ouvrir un port réseau — la connexion est authentifiée par IAM avant même d'arriver à la base de données.

---

### Résoudre un bug HTTPS qui bloquait toute l'interface

Après avoir activé HTTPS sur AWS (en Phase 2), j'avais accès à l'application en HTTPS mais impossible de s'inscrire ou de se connecter. La console du navigateur montrait :

```
Mixed Content: The page at 'https://...' was loaded over HTTPS,
but requested an insecure XMLHttpRequest endpoint 'http://...:3000/auth/register'.
This request has been blocked.
```

Le problème était dans `frontend/js/config.js`. Pour construire l'URL de l'API, le code faisait `"http://" + window.location.hostname + ":3000"`. Sur une page HTTPS, le navigateur bloque automatiquement toute requête HTTP — c'est la politique de "Mixed Content".

La correction était simple une fois le problème identifié : en production, les URLs relatives (chaîne vide) suffisent. Le navigateur construit automatiquement l'URL complète en reprenant le protocole et le domaine de la page courante.

```javascript
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return '';  // URL relative — compatible HTTP local et HTTPS production
};
```

Ce bug m'a appris que le frontend doit être pensé pour plusieurs environnements dès le départ. Hardcoder un protocole ou un port dans le code frontend crée une dépendance fragile à l'environnement.

---

*Babikir Ibrahim — Juin 2026*
*Titre Professionnel Administrateur Système DevOps — Niveau 6 — RE TP-01414-01*
*github.com/babs235/mini-chat — https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
