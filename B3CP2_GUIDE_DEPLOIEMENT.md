# PROMPT PDF — B3-CP2 Guide de déploiement
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA (ChatGPT / Gemini / Claude) :**
>
> Génère un document PDF professionnel à partir du contenu ci-dessous.
>
> **Mise en page :**
> - Format A4 portrait, marges 2,5 cm, police Calibri ou Arial taille 11, interligne 1,3
> - Page de garde : titre, nom du candidat, formation, date — sobre et professionnel
> - Table des matières en début de document avec numéros de page
> - En-tête : "B3-CP2 — Guide de déploiement — Mini-Chat — Babikir Ibrahim"
> - Pied de page : numéro de page centré
> - Chaque section principale (##) commence sur une nouvelle page
>
> **Style :**
> - Titres ## : gras taille 14, couleur bleu foncé
> - Titres ### : gras taille 12, couleur bleu
> - Tableaux : bordures fines, alternance blanc / gris clair sur les lignes
> - Blocs de code : fond gris clair, police monospace taille 9, bordure gauche bleue

---

---

# B3-CP2 — Guide de déploiement

## Projet : Mini-Chat — Application de messagerie cloud-native

**Candidat :** Babikir Ibrahim
**Formation :** Titre Professionnel Administrateur Système DevOps — Niveau 6
**Période :** 18/05 – 21/05/2026
**Application en production :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app
**Dépôt de code :** https://github.com/babs235/mini-chat

---

---

## 1. Prérequis

### Outils à installer sur le poste de travail

| Outil | Version minimale | Commande de vérification |
|-------|----------------|--------------------------|
| Node.js | 20 LTS | `node --version` |
| npm | 10+ | `npm --version` |
| Docker Desktop | 24+ | `docker --version` |
| Docker Compose | 2.x (inclus dans Docker Desktop) | `docker compose version` |
| Git | 2.40+ | `git --version` |
| gcloud CLI | 2.x | `gcloud --version` |
| Terraform | 1.5+ | `terraform --version` |

### Comptes et accès nécessaires

| Ressource | Usage |
|-----------|-------|
| Compte GCP | Déploiement de l'infrastructure (Free Tier suffisant) |
| Clé IAM AWS | Droits requis : ECS, ECR, RDS, VPC, IAM, Cloud Monitoring, SSM, S3, SNS, ACM |
| Compte GitHub | Hébergement du code + exécution du pipeline CI/CD |
| Compte IONOS | Gestion des enregistrements DNS (CNAME vers ALB et validation ACM) |
| Bucket GCS | `mini-chat-asd-tfstate` — stockage du state Terraform |

### Secrets du projet

Les valeurs confidentielles ne sont jamais écrites dans le code source. Elles sont stockées en deux endroits :

| Variable | Stockage | Usage |
|----------|----------|-------|
| `GCP_SA_KEY` | GitHub Secrets | Authentification AWS dans le pipeline CI/CD |
| `GCP_SA_KEY` | GitHub Secrets | Authentification AWS dans le pipeline CI/CD |
| `DB_PASSWORD` | GitHub Secrets + Google Secret Manager `/mini-chat/db_password` | Mot de passe MySQL injecté dans le container ECS |
| `JWT_SECRET` | GitHub Secrets + Google Secret Manager `/mini-chat/jwt_secret` | Clé de signature des tokens JWT |

---

---

## 2. Environnements disponibles

| Environnement | Infrastructure | Base de données | Accès |
|---------------|---------------|----------------|-------|
| **Développement local** | Docker Compose | MySQL dans un container local | http://localhost:3000 |
| **Production** | Google Cloud Run | Google Cloud SQL MySQL 8.0 | https://mini-chat-backend-py4vurg4oq-ew.a.run.app |
| **Staging** | Non déployé — prévu en évolution | — | — |

---

---

## 3. Environnement de développement local

### 3.1. Cloner le dépôt

```bash
git clone https://github.com/babs235/mini-chat.git
cd mini-chat
```

### 3.2. Créer le fichier de configuration local

Créer le fichier `backend/.env` avec les variables d'environnement locales.
Les valeurs de `DB_PASSWORD` et `JWT_SECRET` sont définies librement en local — elles ne sont utilisées que sur la machine de développement et ne correspondent pas aux secrets de production.

```env
DB_HOST=db
DB_USER=root
DB_PASSWORD=     # valeur locale définie par le développeur
DB_NAME=mini_chat
JWT_SECRET=      # valeur locale définie par le développeur
NODE_ENV=development
```

> **Important :** Ce fichier est listé dans `.gitignore`. Il ne doit jamais être commité ni partagé.

### 3.3. Démarrer l'environnement complet

```bash
cd docker
docker compose up --build
```

Docker Compose démarre deux services :
- **db** : MySQL 8.0 (port 3307 externe / 3306 interne)
- **backend** : Node.js (port 3000)

Le backend attend automatiquement que MySQL soit prêt (health check `mysqladmin ping`) avant de démarrer.

### 3.4. Vérifier le démarrage

```bash
# Vérifier que les deux containers tournent
docker compose ps

# Tester le health check
curl http://localhost:3000/
# Attendu : "Backend OK"

# Consulter les logs
docker compose logs backend -f
```

Résultat attendu dans les logs :
```
Server started on port 3000
Schema initialized
```

### 3.5. Accéder à l'application

Ouvrir dans un navigateur : **http://localhost:3000**

Créer un compte → se connecter → envoyer des messages.

### 3.6. Arrêter l'environnement

```bash
# Arrêter sans supprimer les données
docker compose stop

# Arrêter et reset complet (supprime les volumes)
docker compose down -v
```

### 3.7. Lancer les tests unitaires

```bash
cd backend
npm install
npm test
```

Résultat attendu :
```
Tests: 10 passed, 10 total
```

---

---

## 4. Déploiement en production (GCP)

### 4.1. Vue d'ensemble du pipeline

Le déploiement est **entièrement automatisé**. Un `git push main` suffit pour déclencher les 4 jobs séquentiels :

```
git push main
    │
    ├── Job 1 — Tests Jest (10 tests)           → bloque tout si échec
    ├── Job 2 — docker build → push Artifact Registry         → image taguée :sha-commit
    ├── Job 3 — Smoke tests sur image ECR        → bloque si KO
    └── Job 4 — terraform apply                  → déploiement complet AWS
```

Durée totale : **5 à 8 minutes**

### 4.2. Configuration initiale (une seule fois)

Ces étapes ont été réalisées une fois avant le premier déploiement du projet.

#### Étape 1 — Créer le bucket S3 pour le state Terraform

```bash
gcloud storage buckets create gs://mini-chat-asd-tfstate --region europe-west1
# versioning active par defaut sur GCS \
  --bucket mini-chat-asd-tfstate \
  --versioning-configuration Status=Enabled
```

#### Étape 2 — Créer le registre d'images ECR

```bash
gcloud artifacts repositories create mini-chat --format=docker \
  --repository-name mini-chat-backend \
  --region europe-west1
```

#### Étape 3 — Configurer les secrets dans GitHub

Dans le dépôt GitHub → Settings → Secrets and variables → Actions, les quatre secrets suivants sont configurés : `GCP_SA_KEY`, `GCP_SA_KEY`, `DB_PASSWORD`, `JWT_SECRET`. Ces valeurs sont injectées automatiquement dans le pipeline sans jamais apparaître dans les logs ou le code.

#### Étape 4 — Configurer le DNS IONOS

Après le premier `terraform apply`, deux enregistrements CNAME ont été ajoutés dans le panel IONOS :

| Sous-domaine | Type | Valeur |
|-------------|------|--------|
| `chat` | CNAME | URL ALB obtenue via `terraform output app_url` |
| `_acme-[hash]` | CNAME | Valeur de validation ACM visible dans GCP Console → Certificate Manager |

### 4.3. Déploiement courant (usage quotidien)

```bash
git add .
git commit -m "description du changement"
git push origin main
```

Le pipeline se déclenche automatiquement. Suivre l'avancement dans l'onglet **Actions** du dépôt GitHub.

### 4.4. Déploiement manuel via Terraform (hors pipeline)

Si besoin d'agir directement sur l'infrastructure sans passer par le pipeline, les secrets sont passés via des variables d'environnement préfixées `TF_VAR_` — jamais en argument direct de la commande :

```bash
cd terraform
terraform init

# Les secrets sont lus depuis les variables d'environnement TF_VAR_*
# définies dans le shell ou dans le fichier .env local (non commité)
terraform plan
terraform apply
```

### 4.5. Structure des fichiers Terraform

```
terraform/
├── provider.tf      → Provider AWS + backend state S3 (mini-chat-asd-tfstate)
├── main.tf          → VPC, sous-réseaux, Security Groups, Cloud SQL MySQL, ALB
├── ecs.tf           → IAM, SSM secrets, Cloud Monitoring logs, ECS, ACM
├── monitoring.tf    → 4 alarmes Cloud Monitoring + topic SNS
├── variables.tf     → Variables d'entrée (région, secrets, image_tag)
├── outputs.tf       → URL ALB, endpoint RDS, noms cluster/service ECS
└── moved.tf         → Historique des renommages de ressources
```

---

---

## 5. Configuration détaillée

### 5.1. Variables d'environnement du container ECS

| Variable | Source | Description |
|----------|--------|-------------|
| `DB_HOST` | Terraform — auto-calculé | Endpoint RDS généré par AWS |
| `DB_USER` | Terraform — valeur fixe | Utilisateur MySQL |
| `DB_NAME` | Terraform — valeur fixe | `mini_chat` |
| `NODE_ENV` | Terraform — valeur fixe | `production` |
| `DB_PASSWORD` | Google Secret Manager `/mini-chat/db_password` | Injecté chiffré au démarrage — jamais visible en clair dans les logs |
| `JWT_SECRET` | Google Secret Manager `/mini-chat/jwt_secret` | Injecté chiffré au démarrage — jamais visible en clair dans les logs |

### 5.2. Configuration du container Cloud Run

| Paramètre | Valeur |
|-----------|--------|
| CPU | 256 unités (0,25 vCPU) |
| Mémoire | 512 Mo |
| Nombre de containers actifs | 1 |
| Port exposé | 3000 |
| Stratégie de déploiement | Rolling update (zéro downtime) |
| Health check Cloud Run | `GET /` → HTTP 200 |

### 5.3. Configuration Cloud SQL MySQL

| Paramètre | Valeur |
|-----------|--------|
| Moteur | MySQL 8.0 |
| Classe d'instance | db-f1-micro |
| Stockage | 20 Go (gp2) |
| Réseau | Sous-réseau privé (inaccessible depuis Internet) |
| Backup | 1 jour de rétention |
| Chiffrement au repos | Activé (KMS) |

### 5.4. Isolation réseau — Security Groups

| Security Group | Trafic entrant autorisé | Depuis |
|----------------|------------------------|--------|
| `mini-chat-alb-sg` | Ports 80 et 443 | Internet (0.0.0.0/0) |
| `mini-chat-ecs-sg` | Port 3000 | Security Group ALB uniquement |
| `mini-chat-db-sg` | Port 3306 | Security Group ECS uniquement |

La base de données est **totalement invisible depuis Internet**. Aucun port SSH n'est ouvert sur aucune ressource.

---

---

## 6. Vérification du déploiement

### 6.1. Vérification via ligne de commande

```bash
# Health check applicatif
curl https://mini-chat-backend-py4vurg4oq-ew.a.run.app/
# Attendu : "Backend OK"

# HTTPS actif et redirection HTTP
curl -I http://mini-chat-backend-py4vurg4oq-ew.a.run.app/
# Attendu : HTTP/1.1 301 Moved Permanently

# Validation active
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://mini-chat-backend-py4vurg4oq-ew.a.run.app/auth/register \
  -H "Content-Type: application/json" -d '{}'
# Attendu : 400

# Protection JWT active
curl -s -o /dev/null -w "%{http_code}" \
  https://mini-chat-backend-py4vurg4oq-ew.a.run.app/messages
# Attendu : 403
```

### 6.2. Vérification dans GCP Console

| Élément | Chemin dans GCP Console | État attendu |
|---------|------------------------|--------------|
| Cloud Run Service | ECS → mini-chat-backend → mini-chat-backend | Running: 1, Health: Healthy |
| RDS | RDS → Databases → mini-chat-db | Status: Available |
| ALB | EC2 → Load Balancers → mini-chat-alb | State: Active |
| Certificat SSL | ACM → mini-chat-backend-py4vurg4oq-ew.a.run.app | Status: Issued |
| Alarmes | Cloud Monitoring → Alarms | 4 alarmes en état OK |
| Logs | Cloud Monitoring → /ecs/mini-chat-backend | Logs récents présents |

### 6.3. Vérification via Terraform

```bash
cd terraform
terraform output
```

Sortie attendue :
```
app_url     = "https://mini-chat-backend-py4vurg4oq-ew.a.run.app"
ecs_cluster = "mini-chat-backend"
ecs_service = "mini-chat-backend"
```

### 6.4. Test fonctionnel complet

1. Ouvrir https://mini-chat-backend-py4vurg4oq-ew.a.run.app dans un navigateur
2. Créer un compte → vérifier HTTP 201 dans les outils développeur
3. Se connecter → vérifier la réception d'un token JWT
4. Envoyer un message → vérifier l'affichage dans l'interface
5. Ouvrir un second onglet → vérifier que le message apparaît dans les 3 secondes

---

---

## 7. Supervision et maintenance

### 7.1. Consulter les logs en temps réel

```bash
gcloud logging read /ecs/mini-chat-backend --follow --region europe-west1
```

Ou via AWS Console : Cloud Monitoring → Log groups → /ecs/mini-chat-backend

### 7.2. Interpréter les alarmes Cloud Monitoring

| Alarme | Déclencheur | Action corrective |
|--------|-------------|------------------|
| Container stoppé | ECS instance count Cloud Run < 1 | Vérifier les logs du container — chercher l'erreur de démarrage |
| Erreurs 5xx élevées | > 10 erreurs HTTP 5xx sur 5 min | Consulter les logs applicatifs — souvent une erreur base de données |
| CPU élevé | CPU > 80 % pendant 10 min | Analyser le nombre de requêtes actives — envisager l'auto-scaling |
| Disque RDS faible | Espace libre < 2 Go | Augmenter le stockage RDS ou purger les données anciennes |

### 7.3. Forcer un redéploiement sans changement de code

```bash
aws ecs update-service \
  --cluster mini-chat-backend \
  --service mini-chat-backend \
  --force-new-deployment \
  --region europe-west1
```

### 7.4. Détruire l'infrastructure (libérer les ressources AWS)

```bash
cd terraform
terraform destroy
```

> **Attention :** Cette commande supprime toutes les ressources AWS du projet, y compris la base de données et ses données. À n'utiliser qu'en fin de projet.

---

---

## 8. Résolution des problèmes courants

| Symptôme | Cause probable | Solution |
|----------|---------------|---------|
| Pipeline Job 4 — "resource already exists in state" | Conflit dans le state Terraform (double entrée) | Le pipeline contient automatiquement `terraform state rm` + `terraform import` pour résoudre ce cas |
| Container ECS s'arrête immédiatement | RDS pas disponible ou variable d'environnement incorrecte | Consulter les logs Cloud Monitoring `/ecs/mini-chat-backend` |
| API inaccessible sur page HTTPS | Mixed Content — URL hardcodée en HTTP dans le frontend | Vérifier `backend/frontend/js/config.js` — les URLs doivent être relatives en production |
| `terraform apply` détruit et recrée des ressources | Renommage Terraform sans bloc `moved {}` | Ajouter le bloc correspondant dans `terraform/moved.tf` avant d'appliquer |
| Alarme "Container stoppé" déclenchée brièvement | ECS a redémarré le container après une erreur transitoire | Consulter les logs pour identifier la cause — généralement résolu sans intervention |

---

*Document rendu dans le cadre de B3-CP2 — Bloc 3 — Guide de déploiement*
*Babikir Ibrahim — 21/05/2026*
