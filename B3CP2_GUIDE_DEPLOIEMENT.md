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
**Application en production :** https://chat.ibrahimbabikir.fr
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
| AWS CLI | 2.x | `aws --version` |
| Terraform | 1.5+ | `terraform --version` |

### Comptes et accès nécessaires

| Ressource | Usage |
|-----------|-------|
| Compte AWS | Déploiement de l'infrastructure (Free Tier suffisant) |
| Clé IAM AWS | Droits requis : ECS, ECR, RDS, VPC, IAM, CloudWatch, SSM, S3, SNS, ACM |
| Compte GitHub | Hébergement du code + exécution du pipeline CI/CD |
| Compte IONOS | Gestion des enregistrements DNS (CNAME vers ALB et validation ACM) |
| Bucket S3 | `mini-chat-tfstate-babs235` — stockage du state Terraform |

### Secrets du projet

Les valeurs confidentielles ne sont jamais écrites dans le code source. Elles sont stockées en deux endroits :

| Variable | Stockage | Usage |
|----------|----------|-------|
| `AWS_ACCESS_KEY_ID` | GitHub Secrets | Authentification AWS dans le pipeline CI/CD |
| `AWS_SECRET_ACCESS_KEY` | GitHub Secrets | Authentification AWS dans le pipeline CI/CD |
| `DB_PASSWORD` | GitHub Secrets + AWS SSM `/mini-chat/db_password` | Mot de passe MySQL injecté dans le container ECS |
| `JWT_SECRET` | GitHub Secrets + AWS SSM `/mini-chat/jwt_secret` | Clé de signature des tokens JWT |

---

---

## 2. Environnements disponibles

| Environnement | Infrastructure | Base de données | Accès |
|---------------|---------------|----------------|-------|
| **Développement local** | Docker Compose | MySQL dans un container local | http://localhost:3000 |
| **Production** | AWS ECS Fargate + ALB | AWS RDS MySQL 8.0 | https://chat.ibrahimbabikir.fr |
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

## 4. Déploiement en production (AWS)

### 4.1. Vue d'ensemble du pipeline

Le déploiement est **entièrement automatisé**. Un `git push main` suffit pour déclencher les 4 jobs séquentiels :

```
git push main
    │
    ├── Job 1 — Tests Jest (10 tests)           → bloque tout si échec
    ├── Job 2 — docker build → push ECR         → image taguée :sha-commit
    ├── Job 3 — Smoke tests sur image ECR        → bloque si KO
    └── Job 4 — terraform apply                  → déploiement complet AWS
```

Durée totale : **5 à 8 minutes**

### 4.2. Configuration initiale (une seule fois)

Ces étapes ont été réalisées une fois avant le premier déploiement du projet.

#### Étape 1 — Créer le bucket S3 pour le state Terraform

```bash
aws s3 mb s3://mini-chat-tfstate-babs235 --region eu-west-3
aws s3api put-bucket-versioning \
  --bucket mini-chat-tfstate-babs235 \
  --versioning-configuration Status=Enabled
```

#### Étape 2 — Créer le registre d'images ECR

```bash
aws ecr create-repository \
  --repository-name mini-chat-backend \
  --region eu-west-3
```

#### Étape 3 — Configurer les secrets dans GitHub

Dans le dépôt GitHub → Settings → Secrets and variables → Actions, les quatre secrets suivants sont configurés : `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DB_PASSWORD`, `JWT_SECRET`. Ces valeurs sont injectées automatiquement dans le pipeline sans jamais apparaître dans les logs ou le code.

#### Étape 4 — Configurer le DNS IONOS

Après le premier `terraform apply`, deux enregistrements CNAME ont été ajoutés dans le panel IONOS :

| Sous-domaine | Type | Valeur |
|-------------|------|--------|
| `chat` | CNAME | URL ALB obtenue via `terraform output app_url` |
| `_acme-[hash]` | CNAME | Valeur de validation ACM visible dans AWS Console → Certificate Manager |

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
├── provider.tf      → Provider AWS + backend state S3 (mini-chat-tfstate-babs235)
├── main.tf          → VPC, sous-réseaux, Security Groups, RDS MySQL, ALB
├── ecs.tf           → IAM, SSM secrets, CloudWatch logs, ECS, ACM
├── monitoring.tf    → 4 alarmes CloudWatch + topic SNS
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
| `DB_PASSWORD` | AWS SSM `/mini-chat/db_password` | Injecté chiffré au démarrage — jamais visible en clair dans les logs |
| `JWT_SECRET` | AWS SSM `/mini-chat/jwt_secret` | Injecté chiffré au démarrage — jamais visible en clair dans les logs |

### 5.2. Configuration du container ECS Fargate

| Paramètre | Valeur |
|-----------|--------|
| CPU | 256 unités (0,25 vCPU) |
| Mémoire | 512 Mo |
| Nombre de containers actifs | 1 |
| Port exposé | 3000 |
| Stratégie de déploiement | Rolling update (zéro downtime) |
| Health check ALB | `GET /` → HTTP 200 |

### 5.3. Configuration RDS MySQL

| Paramètre | Valeur |
|-----------|--------|
| Moteur | MySQL 8.0 |
| Classe d'instance | db.t3.micro |
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
curl https://chat.ibrahimbabikir.fr/
# Attendu : "Backend OK"

# HTTPS actif et redirection HTTP
curl -I http://chat.ibrahimbabikir.fr/
# Attendu : HTTP/1.1 301 Moved Permanently

# Validation active
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://chat.ibrahimbabikir.fr/auth/register \
  -H "Content-Type: application/json" -d '{}'
# Attendu : 400

# Protection JWT active
curl -s -o /dev/null -w "%{http_code}" \
  https://chat.ibrahimbabikir.fr/messages
# Attendu : 403
```

### 6.2. Vérification dans AWS Console

| Élément | Chemin dans AWS Console | État attendu |
|---------|------------------------|--------------|
| ECS Service | ECS → mini-chat-cluster → mini-chat-backend | Running: 1, Health: Healthy |
| RDS | RDS → Databases → mini-chat-db | Status: Available |
| ALB | EC2 → Load Balancers → mini-chat-alb | State: Active |
| Certificat SSL | ACM → chat.ibrahimbabikir.fr | Status: Issued |
| Alarmes | CloudWatch → Alarms | 4 alarmes en état OK |
| Logs | CloudWatch → /ecs/mini-chat-backend | Logs récents présents |

### 6.3. Vérification via Terraform

```bash
cd terraform
terraform output
```

Sortie attendue :
```
app_url     = "https://chat.ibrahimbabikir.fr"
ecs_cluster = "mini-chat-cluster"
ecs_service = "mini-chat-backend"
```

### 6.4. Test fonctionnel complet

1. Ouvrir https://chat.ibrahimbabikir.fr dans un navigateur
2. Créer un compte → vérifier HTTP 201 dans les outils développeur
3. Se connecter → vérifier la réception d'un token JWT
4. Envoyer un message → vérifier l'affichage dans l'interface
5. Ouvrir un second onglet → vérifier que le message apparaît dans les 3 secondes

---

---

## 7. Supervision et maintenance

### 7.1. Consulter les logs en temps réel

```bash
aws logs tail /ecs/mini-chat-backend --follow --region eu-west-3
```

Ou via AWS Console : CloudWatch → Log groups → /ecs/mini-chat-backend

### 7.2. Interpréter les alarmes CloudWatch

| Alarme | Déclencheur | Action corrective |
|--------|-------------|------------------|
| Container stoppé | ECS RunningTaskCount < 1 | Vérifier les logs du container — chercher l'erreur de démarrage |
| Erreurs 5xx élevées | > 10 erreurs HTTP 5xx sur 5 min | Consulter les logs applicatifs — souvent une erreur base de données |
| CPU élevé | CPU > 80 % pendant 10 min | Analyser le nombre de requêtes actives — envisager l'auto-scaling |
| Disque RDS faible | Espace libre < 2 Go | Augmenter le stockage RDS ou purger les données anciennes |

### 7.3. Forcer un redéploiement sans changement de code

```bash
aws ecs update-service \
  --cluster mini-chat-cluster \
  --service mini-chat-backend \
  --force-new-deployment \
  --region eu-west-3
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
| Container ECS s'arrête immédiatement | RDS pas disponible ou variable d'environnement incorrecte | Consulter les logs CloudWatch `/ecs/mini-chat-backend` |
| API inaccessible sur page HTTPS | Mixed Content — URL hardcodée en HTTP dans le frontend | Vérifier `backend/frontend/js/config.js` — les URLs doivent être relatives en production |
| `terraform apply` détruit et recrée des ressources | Renommage Terraform sans bloc `moved {}` | Ajouter le bloc correspondant dans `terraform/moved.tf` avant d'appliquer |
| Alarme "Container stoppé" déclenchée brièvement | ECS a redémarré le container après une erreur transitoire | Consulter les logs pour identifier la cause — généralement résolu sans intervention |

---

*Document rendu dans le cadre de B3-CP2 — Bloc 3 — Guide de déploiement*
*Babikir Ibrahim — 21/05/2026*
