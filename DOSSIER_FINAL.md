# PROMPT — Dossier de Projet Final
## Mini-Chat — Administrateur Système DevOps — ASD Niveau 6

---

> **Instructions pour l'IA :**
> Génère un dossier de projet professionnel en français, format PDF ou Word.
> Police Arial ou Calibri 11pt. Titres numérotés. Tableaux propres. Blocs de code en monospace avec fond grisé.
> Le document suit le plan type ASD RE TP-01414-01 MAIS l'axe principal est chronologique :
> le jury doit comprendre comment le projet a évolué commit par commit, décision par décision.
> Longueur cible : 30 à 40 pages.
> Rédigé à la première personne, ton professionnel mais accessible — c'est un étudiant qui raconte ce qu'il a vraiment fait.
> Reproduis fidèlement tous les extraits de code. Ne résume pas les blocs de code — garde-les entiers.
> À chaque étape, explique LE POURQUOI du choix technique.

---

## INFORMATIONS DU DOCUMENT

| Champ | Valeur |
|-------|--------|
| Titre | Mini-Chat — Application de messagerie cloud-native sur AWS |
| Candidat | Babikir Ibrahim |
| Formation | Administrateur Système DevOps — Titre RNCP Niveau 6 |
| Référentiel | RE TP-01414-01 |
| Période | Mars → Mai 2026 |
| Dépôt GitHub | github.com/babs235/mini-chat |
| Production | https://chat.ibrahimbabikir.fr |

---

---

# INTRODUCTION

Ce projet couvre l'ensemble du cycle de vie d'une application cloud-native : développement, conteneurisation, déploiement automatisé, sécurisation et supervision. Il a été réalisé seul, en centre de formation, sans entreprise.

L'idée est simple : une application de messagerie où des utilisateurs peuvent s'inscrire, se connecter et échanger des messages en temps réel. Ce qui fait la valeur du projet, ce n'est pas l'application elle-même — c'est tout ce qui l'entoure : l'infrastructure AWS entièrement automatisée, le pipeline CI/CD qui déploie sans intervention humaine, et la supervision qui alerte en cas de problème.

Le projet a évolué en trois phases réelles, chacune apportant une correction des limites de la phase précédente :
- **Phase 0 (Mars)** : application fonctionnelle en local
- **Phase 1 (Avril)** : premier déploiement AWS sur EC2, avec ses problèmes
- **Phase 2 (Mai)** : migration ECS Fargate, pipeline fiable, HTTPS, supervision complète

Ce document retrace chaque étape dans l'ordre où elle s'est produite, avec les commandes utilisées, les erreurs rencontrées et les raisons des choix faits.

---

---

# SECTION 1 — COMPÉTENCES ASD COUVERTES

| Compétence | Comment ce projet la couvre |
|-----------|----------------------------|
| Automatiser la création de serveurs | Terraform crée toute l'infrastructure AWS (VPC, ECS, RDS, ALB) en une commande |
| Automatiser le déploiement d'une infrastructure | Un `git push` déclenche le pipeline GitHub Actions qui applique `terraform apply` |
| Sécuriser l'infrastructure | Pas de SSH, Security Groups en moindre privilège, HTTPS TLS 1.3, secrets chiffrés SSM |
| Mettre l'infrastructure en production dans le cloud | Application déployée sur AWS ECS Fargate eu-west-3 (Paris), HTTPS, domaine propre |
| Préparer un environnement de test | 9 tests Jest automatisés + smoke tests Docker qui testent l'image ECR avant déploiement |
| Gérer le stockage des données | RDS MySQL en subnet privé, backup 1 jour, accès restreint aux seuls containers ECS |
| Gérer des containers | Dockerfile multi-stage Alpine, ECR, ECS Fargate, rolling update, Task Definition |
| Automatiser la mise en production | Pipeline 4 jobs séquentiels : tests → build ECR → smoke tests → terraform deploy |
| Définir des statistiques de services | KPI et SLA définis, 4 alarmes CloudWatch avec seuils alignés sur les objectifs |
| Exploiter une solution de supervision | CloudWatch Logs + Métriques, incident réel résolu via les logs, notifications SNS email |

---

---

# SECTION 2 — CAHIER DES CHARGES

## Contexte

Projet réalisé en formation ASD Niveau 6. L'objectif : démontrer la maîtrise complète du cycle DevOps — de l'écriture du code jusqu'à la supervision du service en production.

## Ce qui est inclus

- Backend API REST (Node.js/Express)
- Frontend web (HTML/CSS/JS, glassmorphism, responsive)
- Base de données MySQL managée (AWS RDS)
- Conteneurisation Docker multi-stage
- Infrastructure AWS entièrement en Terraform
- Pipeline CI/CD automatisé 4 jobs (GitHub Actions)
- Secrets chiffrés (AWS SSM Parameter Store)
- HTTPS sur domaine propre (AWS ACM + IONOS DNS)
- Supervision (CloudWatch + 4 alarmes + notifications email SNS)
- Tests automatisés (Jest + smoke tests)

## Ce qui n'est pas inclus

- WebSocket temps réel → polling HTTP toutes les 3 secondes (simplification assumée)
- Auto-scaling ECS → désactivé (Free Tier, évolution planifiée)
- Authentification OAuth → JWT maison suffisant pour ce projet

## Contraintes

| Contrainte | Impact |
|-----------|--------|
| Free Tier AWS | ECS 0.25 vCPU / 512 MB, RDS db.t3.micro 20 Go — ressources minimales |
| Domaine IONOS | Pas de Route 53 → CNAMEs ajoutés manuellement dans le panel IONOS |
| Projet solo | Pas de DynamoDB lock (aucun accès concurrent au state Terraform possible) |
| IAM quota | 10 politiques managées maximum par utilisateur — gestion rigoureuse |
| Pas de NAT Gateway | 32$/mois → containers ECS avec IP publique (protégés par Security Group) |

## Livrables

| Livrable | État |
|---------|------|
| Code source complet | ✅ github.com/babs235/mini-chat |
| Infrastructure as Code (7 fichiers Terraform) | ✅ Déployée |
| Pipeline CI/CD (4 jobs) | ✅ Opérationnel |
| Application HTTPS en production | ✅ https://chat.ibrahimbabikir.fr |
| Supervision (4 alarmes + SNS) | ✅ Opérationnel |
| Guide de déploiement | ✅ |
| Cahier des charges | ✅ |

---

---

# SECTION 3 — HISTOIRE DU PROJET — CHRONOLOGIE COMPLÈTE

---

## PHASE 0 — MARS 2026 : On commence par le code

---

### 2 mars — Création du dépôt et structure du projet

Premier jour de formation. Le projet est identifié : une application de messagerie, Mini-Chat.

```bash
git init
npm init -y
git add .
git commit -m "Initialisation du projet et structure"
```

**Pourquoi Node.js ?**
Node.js est adapté aux applications avec beaucoup de connexions simultanées — c'est exactement ce qu'est un chat. Express a été choisi pour sa légèreté : une API REST simple n'a pas besoin d'un framework lourd comme NestJS ou Fastify. Le projet se concentre sur l'infrastructure, pas sur le framework applicatif.

**Pourquoi MySQL ?**
Base relationnelle standard, bien connue, facile à conteneuriser avec l'image officielle Docker. La structure des données est simple (users + messages), relationnelle par nature (messages liés à des utilisateurs).

---

### 3 mars — Docker Compose et connexion à MySQL

Mise en place de l'environnement de développement local. Plutôt qu'installer MySQL directement sur la machine, Docker Compose permet de tout lancer en une commande.

```bash
# Lancement de l'environnement complet
docker compose up -d

# Vérification que MySQL est accessible
docker compose logs db
```

```yaml
# docker/docker-compose.yml (version initiale)
services:
  backend:
    build:
      context: ../backend
      dockerfile: dockerfile.backend
    ports:
      - "3000:3000"
    environment:
      DB_HOST: db
      DB_USER: root
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: mini_chat
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
      MYSQL_DATABASE: mini_chat
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      retries: 5
```

**Pourquoi Docker dès le début ?**
Garantit que l'environnement local est identique à la production. Quelqu'un qui clone le repo et lance `docker compose up` obtient exactement le même résultat — pas de "ça marche sur ma machine".

```bash
git commit -m "infrastructure Docker OK et connexion a MYSQL Workbench fonctionnelle"
```

---

### 7 mars — Authentification JWT (register et login)

Implémentation des routes d'authentification avec hachage des mots de passe et tokens JWT.

```bash
npm install bcrypt jsonwebtoken
git commit -m "Mise en place authentification (register et login)"
```

```javascript
// backend/src/routes/auth.js (extrait)
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

router.post("/register", async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: "Champs manquants" });
  }
  const hash = await bcrypt.hash(password, 10);
  await db.execute(
    "INSERT INTO users (username, password) VALUES (?, ?)",
    [username, hash]
  );
  res.status(201).json({ message: "Compte créé" });
});

router.post("/login", async (req, res) => {
  const { username, password } = req.body;
  const [rows] = await db.execute(
    "SELECT * FROM users WHERE username = ?", [username]
  );
  if (!rows.length) return res.status(401).json({ error: "Utilisateur inconnu" });
  const valid = await bcrypt.compare(password, rows[0].password);
  if (!valid) return res.status(401).json({ error: "Mot de passe incorrect" });
  const token = jwt.sign({ userId: rows[0].id }, process.env.JWT_SECRET, { expiresIn: "1h" });
  res.json({ token });
});
```

**Pourquoi bcrypt avec 10 rounds ?**
10 rounds est le standard recommandé. Assez lent pour ralentir une attaque brute force (> 100ms par tentative), assez rapide pour l'utilisateur (< 100ms ressenti). Au-delà de 12 rounds, l'impact sur les performances devient perceptible sans gain de sécurité significatif pour ce type de projet.

**Pourquoi JWT et non des sessions ?**
Une API REST est stateless par définition — le serveur n'a pas à mémoriser les sessions. Le token JWT contient les informations nécessaires, est signé avec un secret, et expire automatiquement après 1 heure. Cela simplifie aussi le déploiement distribué : n'importe quel container peut valider un token sans base de sessions partagée.

---

### 8-9 mars — Table messages et récupération

Ajout de la table `messages` et des routes GET/POST.

```bash
git commit -m "ajout dela gestion des messages creation de la tables messages"
git commit -m "installation de nodemon et ajout pour la recuperation des messages"
```

```javascript
// backend/src/routes/messages.js (extrait)
const { verifyToken } = require("../middleware/auth");

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
  res.status(201).json({ message: "Envoyé" });
});
```

**Pourquoi `escapeHtml()` avant l'insertion ?**
Protège contre les attaques XSS : si un utilisateur envoie `<script>alert('xss')</script>`, le texte est stocké encodé et s'affiche comme du texte brut dans le navigateur, sans jamais être exécuté. La requête préparée (`?` comme marqueur) empêche les injections SQL : les paramètres sont séparés de la requête SQL.

**Limite connue :** `escapeHtml()` est une implémentation manuelle. Une bibliothèque comme `he` ou `sanitize-html` couvrirait davantage de cas limites. Pour ce projet, les 5 remplacements couvrent les vecteurs XSS les plus courants.

---

### 10-12 mars — Interface frontend

Développement du frontend HTML/CSS/JS servi directement par Express.

```javascript
// backend/server.js
app.use(express.static(path.join(__dirname, "frontend")));
app.get("/", (req, res) => { res.send("Backend OK"); });
```

```bash
git commit -m "creation de l'interface frontend avec envoie et affichage des messages"
git commit -m "ajout des fichiers html et javascript pour l'interface frontent"
```

**Pourquoi un frontend statique et non React/Vue ?**
Le projet est évalué sur l'infrastructure DevOps, pas sur le framework frontend. HTML/CSS/JS natif suffit pour démontrer une application fonctionnelle. Ajouter React aurait introduit une étape de build supplémentaire dans le pipeline sans valeur ajoutée pour les compétences ASD évaluées.

Le rafraîchissement des messages toutes les 3 secondes (polling HTTP) remplace le WebSocket — plus simple à mettre en place, sans dépendance supplémentaire.

---

### 23 mars — Prometheus et Grafana (monitoring local, temporaire)

Ajout d'un stack de monitoring local pour visualiser les performances de l'API en développement.

```bash
git commit -m "installation du monitoring(prometheus et graffana pour voir les performaces"
```

Prometheus avec prom-client exposait une route `/metrics`. Des alertes étaient configurées sur Discord via Alertmanager.

**Pourquoi ce stack a été retiré le 2 mai ?**
Prometheus et Grafana tournaient uniquement sur le PC local — ils ne supervisaient pas le service déployé sur AWS. L'application en production tourne sur ECS Fargate en eu-west-3. Un Prometheus sur le PC local ne voit pas ce container.

Déployer Prometheus sur AWS aurait nécessité une instance EC2 ou un container ECS dédié, un port 9090 ouvert dans le Security Group, une configuration de scraping vers l'endpoint ECS — soit plus de complexité pour un résultat inférieur à CloudWatch qui est déjà intégré nativement à ECS : logs automatiques, métriques CPU/RAM/ALB/RDS sans configuration.

---

## PHASE 1 — AVRIL 2026 : Première infrastructure AWS

---

### 1-4 avril — Ansible et JWT, première CI/CD

Première tentative d'automatisation du déploiement avec Ansible, et ajout du JWT côté production.

```bash
git commit -m "automatisation du deploiement avec ansible et installation de JWT"
git commit -m "amelioration de mon ansible et ajout de CI/CD pipeline"
```

```yaml
# .github/workflows/ci-cd.yml (version initiale — 3 jobs)
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test

  build:
    needs: tests
    steps:
      - name: docker build + push ECR

  deploy:
    needs: build
    steps:
      - uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.EC2_IP }}
          # docker pull + docker-compose up sur l'EC2
```

**Pourquoi Ansible à ce stade ?**
Ansible semblait l'outil naturel pour provisionner un serveur EC2 — c'est un standard en administration système. La limite identifiée plus tard : Ansible suppose que le serveur est déjà accessible en SSH, ce qui crée une dépendance au serveur lui-même. Si l'IP change ou si l'instance redémarre, toute la chaîne est cassée.

---

### 7 avril — Terraform : première infrastructure complète

Écriture de l'infrastructure AWS entièrement en Terraform : VPC, subnets, Internet Gateway, Security Groups, instance EC2, RDS MySQL.

```bash
cd terraform
terraform init
terraform plan    # visualiser avant d'appliquer
terraform apply   # créer l'infrastructure
```

```bash
git commit -m "configuration de terraform"
git commit -m "retrait de la cle ssh committee par erreur dans le repo"
```

**Incident clé ce jour-là :** une clé SSH a été committée par accident dans le dépôt. Elle a été retirée immédiatement avec `git rm --cached` et le fichier ajouté au `.gitignore`. Leçon : ne jamais committer de secrets, même temporairement. Utiliser GitHub Secrets dès le départ.

**Pourquoi Terraform et non la console AWS ?**

| Critère | Console AWS | Terraform |
|---------|-------------|-----------|
| Reproductibilité | Non — config manuelle à chaque fois | Oui — `terraform apply` recrée tout |
| Versionnable | Non | Oui — dans git |
| Audit | Difficile | Chaque changement est un diff dans git |
| Collaboration | Impossible à partager | `terraform plan` montre ce qui change avant |

Ce jour-là aussi : nombreuses corrections du pipeline GitHub Actions (mauvaise action SSH, port SSH absent du Security Group, mauvaise action GitHub).

```bash
git commit -m "premier essai de deploiement automatique via GitHub Actions"
git commit -m "correction du deploiement ssh"
git commit -m "utilisation de appleboy ssh-action pour le deploiement"
```

---

### 10 avril — Connexion RDS depuis EC2

Première connexion réussie entre l'application Node.js sur EC2 et RDS MySQL.

```bash
# Récupérer l'endpoint RDS depuis Terraform
terraform output rds_endpoint

git commit -m "URL API vers IP serveur AWS"
git commit -m "changement de l'IP de la db"
```

**Problème récurrent :** l'IP publique de l'EC2 change à chaque redémarrage de l'instance. Chaque fois, il fallait mettre à jour le secret `EC2_IP` dans GitHub Actions manuellement. Ce problème renforcera la décision de migrer vers ECS (qui utilise un ALB avec DNS fixe).

---

### 16-17 avril — Interface Glassmorphism et correction bug JWT critique

Refonte complète de l'interface avec le design glassmorphism final.

```bash
git commit -m "UI/UX: Interface moderne Glassmorphism + avatars colorés + responsive design"
```

**Bug critique découvert ce jour-là :** les utilisateurs étaient déconnectés à chaque redémarrage du serveur. Cause : le secret JWT était généré dynamiquement au démarrage.

```javascript
// AVANT — bug : nouveau secret à chaque démarrage
const JWT_SECRET = crypto.randomBytes(32).toString('hex');
// → tous les tokens existants deviennent invalides

// APRÈS — fix : secret fixe depuis variable d'environnement
const JWT_SECRET = process.env.JWT_SECRET;
```

```bash
git commit -m "correction critique du secret JWT qui deconnectait les utilisateurs a chaque redemarrage"
```

---

### 22-24 avril — Stabilisation MySQL

Remplacement des connexions MySQL individuelles par un pool de connexions.

```javascript
// backend/src/config/database.js
const pool = mysql.createPool({
  host: process.env.DB_HOST || "db",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

pool.on("error", (err) => {
  if (err.code === "PROTOCOL_CONNECTION_LOST" || err.code === 4031) {
    console.log("MySQL disconnected - pool will reconnect automatically");
    return;
  }
  console.error("MySQL pool error:", err.message);
});

const db = pool.promise();
```

```bash
git commit -m "remplacement des connexions MySQL par un pool pour eviter les fuites memoire"
git commit -m "ajout du keepAlive MySQL pour eviter les deconnexions lors des periodes d inactivite"
```

**Pourquoi un pool et non des connexions individuelles ?**
Sans pool, chaque requête HTTP ouvre et ferme une connexion MySQL — coûteux en performance et risque d'épuisement des connexions RDS. Le pool maintient un ensemble de connexions réutilisables (max 10 ici), gère automatiquement les reconnexions, et évite les fuites mémoire.

Intégration des retours du professeur : suppression des emojis dans les logs, credentials déplacés en variables d'environnement.

```bash
git commit -m "corrections feedback prof : suppression emojis, credentials en variables d'env"
```

---

### 27 avril — Pipeline CI/CD avec Terraform

Intégration de `terraform apply` dans le pipeline pour automatiser les mises à jour d'infrastructure.

```bash
git commit -m "ajout de deploiement automatique via pipeline"
git commit -m "formatage de mon main.tf et variables.tf pour que ca soit bien ecrit"
```

Changement d'instance : EC2 `t3.micro` → `t3.small` pour avoir plus de RAM disponible pour Docker.

---

## PHASE 2 — 1er MAI 2026 : La journée de crise EC2

---

### 1er mai — 15+ commits, une seule journée

Cette journée illustre la limite fondamentale de l'architecture EC2 pour un déploiement continu. Voici les problèmes rencontrés dans l'ordre :

**Problème 1 — `user_data` dépasse 255 caractères**
```bash
# Tentatives successives
git commit -m "remplacement du fichier user_data par un heredoc pour contourner la limite de 255 caracteres"
git commit -m "compression du user_data en base64 pour essayer de passer la limite"
git commit -m "utilisation de templatefile pour le user_data"
git commit -m "suppression complete du user_data pour isoler le vrai probleme"
```

**Problème 2 — Ansible ne peut pas se connecter depuis GitHub Actions**
```bash
git commit -m "désactiver SSH host key verification pour Ansible"
git commit -m "correction docker-compose-plugin vers docker-compose pour Ubuntu"
```

**Problème 3 — L'EC2 manque d'espace disque**
```bash
git commit -m "upgrade instance t3.small vers t3.medium pour plus d'espace disque"
git commit -m "revenir a t3.small et optimiser nettoyage docker pour free tier"
```

**Problème 4 — L'IP de l'EC2 change après chaque recréation**
```bash
git commit -m "placeholder pour nouvelle IP EC2 - ancienne instance inaccessible"
```

**Décision finale après cette journée :** l'architecture EC2 + user_data + Ansible + Docker Compose est trop fragile. L'image Docker doit être construite en dehors du serveur. Migration vers ECS Fargate.

```bash
git commit -m "ajout job build-and-push Docker images vers ECR"
git commit -m "retrait de ansible"
```

---

## PHASE 2 — 2 MAI 2026 : Migration complète vers ECS Fargate

---

### 2 mai matin — Réécriture de toute l'infrastructure

Migration de EC2 vers ECS Fargate en une journée. Réécriture des fichiers Terraform.

```bash
git commit -m "migration de EC2 vers ECS Fargate avec ALB et secrets SSM"
```

**Pourquoi ECS Fargate résout tous les problèmes d'EC2 :**

| Problème EC2 | Solution ECS Fargate |
|-------------|---------------------|
| user_data asynchrone et fragile | Plus de user_data — Task Definition déclarative |
| IP qui change | ALB avec DNS fixe (ne change jamais) |
| Build Docker sur le serveur | Image buildée en CI/CD, poussée dans ECR, tirée par ECS |
| SSH requis pour déployer | Zéro SSH — ECS met à jour le container automatiquement |
| Crash non détecté | ECS redémarre automatiquement, ALB retire le container cassé |
| Pas de tracabilité | Chaque image taguée avec le SHA du commit Git |

**`assign_public_ip = true` dans le Service ECS :**
Sans NAT Gateway (32$/mois), les containers ECS ont besoin d'une IP publique pour joindre ECR (pull d'image) et CloudWatch (envoi de logs). L'IP publique sert uniquement au trafic sortant — le Security Group `mini-chat-ecs-sg` bloque tout accès entrant direct depuis Internet. Seul l'ALB peut atteindre le port 3000.

---

### 2 mai — Problème Terraform : blocs `moved`

Lors du renommage des Security Groups pour plus de lisibilité, Terraform a voulu les détruire et recréer — ce qui aurait coupé le service.

```
# terraform plan montrait :
# aws_security_group.alb will be destroyed
# aws_security_group.alb_sg will be created
```

**Solution — blocs `moved` dans `terraform/moved.tf` :**

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

```bash
git commit -m "ajout des blocs moved pour eviter la destruction des security groups au renommage"
```

Terraform a mis à jour uniquement le state, sans toucher aux ressources AWS. Aucune coupure.

---

### 2 mai — Problème Terraform : conflit db_subnet_group

`aws_db_subnet_group.mini_chat` était présent deux fois dans le state, bloquant `terraform apply`.

```bash
# Supprimer l'entrée en double
terraform state rm aws_db_subnet_group.mini_chat

# Réimporter la ressource réelle depuis AWS
terraform import aws_db_subnet_group.mini_chat mini-chat-db-subnet-group

# Appliquer — fonctionne maintenant
terraform apply
```

```bash
git commit -m "correction du conflit de state sur le db subnet group en double"
```

Cette séquence a été intégrée dans le Job 4 du pipeline pour éviter toute récurrence lors des déploiements suivants.

---

### 2 mai — Auto-création des tables au démarrage

RDS en subnet privé n'a pas d'accès direct (pas de Query Editor, pas de SSH). La fonction `initSchema()` crée les tables automatiquement au démarrage du container.

```javascript
// backend/src/config/database.js
async function initSchema() {
  await db.execute(`
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      username VARCHAR(50) NOT NULL,
      password VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await db.execute(`
    CREATE TABLE IF NOT EXISTS messages (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT,
      message TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  `);
  console.log("Schema initialized");
}

initSchema().catch((err) => console.error("Schema init failed:", err.message));
```

```bash
git commit -m "creation automatique des tables MySQL au demarrage du container"
```

**Pourquoi `CREATE TABLE IF NOT EXISTS` ?** Idempotent : si les tables existent déjà (redémarrage normal), rien ne se passe. Si c'est un nouveau déploiement sur une base vide, les tables sont créées. Aucune intervention manuelle nécessaire.

**Limite connue :** `initSchema()` est non bloquante — le serveur commence à écouter sur le port 3000 avant que la création des tables soit terminée. Si une requête arrive dans cette fenêtre de ~1 seconde, elle peut échouer. En production, un endpoint `/health` dédié avec `SELECT 1` serait plus fiable.

---

## PHASE 2 — 3 MAI 2026 : Finalisation et déploiement officiel

---

### 3 mai matin — 9 tests Jest automatisés

Ajout des tests unitaires Jest + Supertest et intégration dans le pipeline en Job 1 bloquant.

```bash
npm install --save-dev jest supertest
git commit -m "ajout des tests automatises Jest et integration dans le pipeline en job bloquant"
```

```javascript
// backend/tests/app.test.js (extrait)
const request = require("supertest");
const app = require("../server");

describe("Auth routes", () => {
  test("register sans body → 400", async () => {
    const res = await request(app).post("/auth/register").send({});
    expect(res.statusCode).toBe(400);
  });
  test("login utilisateur inexistant → 401", async () => {
    const res = await request(app).post("/auth/login")
      .send({ username: "inexistant", password: "123" });
    expect(res.statusCode).toBe(401);
  });
  test("GET /messages sans token → 403", async () => {
    const res = await request(app).get("/messages");
    expect(res.statusCode).toBe(403);
  });
});
```

9 tests au total : register (succès, doublon, champs manquants), login (succès, mauvais mdp, utilisateur inexistant), messages (GET sans token, GET avec token valide, POST avec token valide).

---

### 3 mai — Container Insights + 4 alarmes CloudWatch

Activation de Container Insights sur le cluster ECS (prérequis pour `RunningTaskCount`) et création des alarmes dans `terraform/monitoring.tf`.

```hcl
# terraform/ecs.tf — Container Insights activé
resource "aws_ecs_cluster" "mini_chat" {
  name = "mini-chat-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```

```hcl
# terraform/monitoring.tf
resource "aws_sns_topic" "alerts" {
  name = "mini-chat-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "babikiribrahimalkhalil@gmail.com"
}

resource "aws_sns_topic_policy" "alerts_policy" {
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

resource "aws_cloudwatch_metric_alarm" "ecs_task_stopped" {
  alarm_name          = "mini-chat-ecs-task-stopped"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.mini_chat.name
    ServiceName = aws_ecs_service.backend.name
  }
}
```

**Pourquoi la politique SNS est obligatoire ?**
Par défaut, CloudWatch n'a pas le droit de publier dans un topic SNS. Sans cette politique explicite autorisant `cloudwatch.amazonaws.com`, les alarmes changent d'état (OK → ALARM) mais n'envoient aucune notification. Les alertes restent muettes.

**Pourquoi Container Insights est obligatoire pour l'alarme ECS stopped ?**
La métrique `RunningTaskCount` appartient au namespace `ECS/ContainerInsights`. Elle n'existe pas sans activation de Container Insights sur le cluster. Sans activation, l'alarme reste en état `INSUFFICIENT_DATA` — elle ne se déclenche jamais, même si le container s'arrête.

```bash
git commit -m "activation de Container Insights et creation des alarmes CloudWatch et SNS"
```

**4 alarmes configurées :**

| Alarme | Métrique | Seuil | Notification |
|-------|---------|-------|-------------|
| `mini-chat-ecs-task-stopped` | RunningTaskCount | < 1 pendant 1 min | Email SNS |
| `mini-chat-alb-5xx-eleve` | HTTPCode_ELB_5XX_Count | > 10 sur 5 min | Email SNS |
| `mini-chat-ecs-cpu-eleve` | CPUUtilization | > 80% pendant 10 min | Email SNS |
| `mini-chat-rds-espace-disque-faible` | FreeStorageSpace | < 2 Go | Email SNS |

---

### 3 mai — Smoke tests pré-production (Job 3)

Ajout d'un 3ème job dans le pipeline qui teste l'image Docker exacte avant de la déployer.

```yaml
smoke-tests:
  name: Job 3 — Smoke Tests
  needs: build-push
  runs-on: ubuntu-latest
  steps:
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
          -H "Content-Type: application/json" -d '{}')
        [ "$STATUS" = "400" ] || exit 1
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
          http://localhost:3000/messages)
        [ "$STATUS" = "403" ] || exit 1
```

**Pourquoi tester l'image ECR et non juste le code ?**
Les tests Jest (Job 1) testent le code Node.js brut. Le Job 3 teste l'artefact exact qui partira en production — la même image Docker avec le même hash SHA. Si le Dockerfile est cassé, si une dépendance manque dans l'image, si le container ne démarre pas, le Job 3 l'attrape avant le déploiement.

**Limite assumée :** les variables DB sont fictives — la connectivité MySQL réelle n'est pas testée. Ce cas est couvert après déploiement : l'ALB health check (`GET /`) valide que le container répond avant de basculer le trafic. Si le container ne peut pas joindre RDS, il échoue, l'ALB ne valide pas le health check, et l'ancien container reste actif.

```bash
git commit -m "ajout de mon address pour etre informer et ajout d'un envir de test pre prod"
```

---

### 3 mai — HTTPS avec AWS ACM et domaine IONOS

Passage de HTTP à HTTPS avec un certificat SSL géré par AWS Certificate Manager.

```hcl
# terraform/ecs.tf
resource "aws_acm_certificate" "mini_chat" {
  domain_name       = "chat.ibrahimbabikir.fr"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mini_chat.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.mini_chat.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.mini_chat.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
```

**Étapes manuelles nécessaires dans IONOS :**
```
1. Terraform génère un CNAME de validation ACM
2. Dans le panel DNS IONOS — ajouter :
   CNAME validation : _acme-xxxxx.chat.ibrahimbabikir.fr → validation.acm.amazonaws.com
   CNAME sous-domaine : chat.ibrahimbabikir.fr → mini-chat-alb-xxx.eu-west-3.elb.amazonaws.com
3. ACM valide le certificat automatiquement (quelques minutes)
```

**Pourquoi IONOS DNS et non Route 53 ?**
Route 53 coûte 0,50$/mois par zone hébergée. Le domaine `ibrahimbabikir.fr` était déjà enregistré chez IONOS avec le DNS inclus. La validation manuelle n'est faite qu'une fois — ce n'est pas une tâche récurrente.

**Incident rencontré :** lors du premier `terraform apply`, ECS tentait de démarrer le service au même moment que la validation ACM (qui prend quelques minutes). L'ECS service échouait car le listener HTTPS n'existait pas encore.

```bash
git commit -m "ajout d'un fix pour le timing car le ecs a voulu mettre a jour avant que https existe"
```

**Solution :** ajout d'un `depends_on` sur le listener HTTPS dans la ressource ECS Service — ECS attend que les deux listeners existent avant de démarrer.

```hcl
resource "aws_ecs_service" "backend" {
  depends_on = [aws_lb_listener.http, aws_lb_listener.https]
}
```

---

### 3 mai — Le bug du Mixed Content : déploiement officiel

**C'est le dernier bug résolu avant le déploiement stable en production.**

Après passage en HTTPS, l'application était accessible mais impossible de s'inscrire ou se connecter. Le navigateur bloquait toutes les requêtes API.

**Message dans la console du navigateur :**
```
Mixed Content: The page at 'https://chat.ibrahimbabikir.fr' was loaded over HTTPS,
but requested an insecure XMLHttpRequest endpoint 'http://chat.ibrahimbabikir.fr:3000/auth/register'
```

**Cause identifiée dans `backend/frontend/js/config.js` :**
```javascript
// AVANT — bug : construit une URL http:// hardcodée en production
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return `http://${hostname}:3000`; // ← BLOQUÉ par le navigateur sur HTTPS
};
```

**La règle du navigateur :** une page chargée en HTTPS ne peut pas faire de requêtes vers des URLs HTTP. C'est la Mixed Content policy — elle protège l'utilisateur contre une page sécurisée qui ferait des appels non chiffrés en arrière-plan.

**Correction appliquée :**
```javascript
// APRÈS — fix : URLs relatives en production
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return ''; // URLs relatives — le navigateur complète avec le bon protocole
};

const API = getApiUrl();
// En prod : fetch(`${API}/auth/login`) → fetch('/auth/login') → https://chat.ibrahimbabikir.fr/auth/login
// En local : fetch(`${API}/auth/login`) → fetch('http://localhost:3000/auth/login')
```

```bash
git commit -m "correction de la compatibilite HTTPS en production — les URLs deviennent relatives"
```

**Leçon retenue :** en production derrière un ALB, les URLs relatives suffisent. L'ALB reçoit la requête HTTPS et la transmet au container en HTTP interne — pas besoin de spécifier le protocole ni le port dans le frontend.

**C'est ce commit qui marque le déploiement officiel stable de Mini-Chat en production.**

---

### 3 mai — Nettoyage final du projet

Suppression de tout ce qui était inutile ou obsolète.

```bash
git commit -m "suppression complete de Prometheus et Grafana — remplace par CloudWatch"
# → suppression prom-client, /metrics route, prometheus.yml, alertmanager

git commit -m "suppression des dependances inutilisees socket.io et express-session"
# → ces packages étaient dans package.json mais jamais importés

git commit -m "suppression du script user-data EC2 devenu inutile depuis la migration ECS"
# → terraform/user-data.sh, héritage de la Phase 1

git commit -m "suppression de authController.js inutilise qui etait un doublon de la version 1"
# → doublon de la logique d'auth, jamais appelé
```

---

---

# SECTION 4 — ARCHITECTURE FINALE

## Vue d'ensemble

```
Développeur
    |
    | git push main
    ↓
GitHub Actions (4 jobs séquentiels)
    |
    ├── Job 1 — Tests Jest (9 tests)              ~30s
    │   └── bloque tout si un test échoue
    ├── Job 2 — Build Docker → ECR                ~2 min
    │   └── image taguée :sha-commit (tracabilité exacte)
    ├── Job 3 — Smoke Tests (même image ECR)       ~1 min
    │   └── GET / → 200, POST /register → 400, GET /messages → 403
    └── Job 4 — terraform apply                   ~3-5 min
        └── ECS déploie la nouvelle image (rolling update)
                        |
                        ↓
        AWS eu-west-3 (Paris)
        ┌──────────────────────────────────────────────┐
        │                                              │
        │  Utilisateur → HTTPS 443                     │
        │       ↓                                      │
        │  [ACM — certificat chat.ibrahimbabikir.fr]   │
        │       ↓                                      │
        │  [ALB mini-chat-alb]                         │
        │   port 80 → redirect 301 HTTPS               │
        │   port 443 → forward vers ECS                │
        │   health check GET / avant bascule trafic    │
        │       ↓                                      │
        │  [ECS Fargate — mini-chat-backend]           │
        │   Node.js port 3000                          │
        │   subnets publics eu-west-3a + eu-west-3c    │
        │   0.25 vCPU / 512 MB / image ECR:sha-commit  │
        │       ↓                                      │
        │  [RDS MySQL 8.0 — mini-chat-db]              │
        │   db.t3.micro / 20 Go gp2                    │
        │   subnets PRIVÉS (inaccessible depuis web)   │
        │                                              │
        │  CloudWatch Logs /ecs/mini-chat-backend      │
        │  4 Alarmes → SNS → Email                     │
        └──────────────────────────────────────────────┘
```

## Security Groups — 3 niveaux d'isolation

```
Internet (0.0.0.0/0)
    │ ports 80 + 443
    ▼
[mini-chat-alb-sg]
    │ port 3000 uniquement
    ▼
[mini-chat-ecs-sg]
    │ port 3306 uniquement
    ▼
[mini-chat-db-sg → RDS]
```

La base de données est invisible depuis Internet, depuis l'ALB et depuis toute ressource qui n'est pas un container ECS.

## Stack technique complète

| Technologie | Usage |
|-------------|-------|
| Node.js 20 LTS | Runtime backend |
| Express 5 | Framework API REST |
| mysql2 | Driver MySQL — requêtes préparées, pool de connexions |
| bcrypt | Hachage mots de passe (10 rounds) |
| jsonwebtoken | Tokens JWT signés, expiration 1h |
| Docker multi-stage Alpine | Image ~180 MB (au lieu de ~950 MB) |
| Docker Compose | Environnement local uniquement |
| Terraform 1.5 | Infrastructure as Code AWS |
| GitHub Actions | Pipeline CI/CD 4 jobs |
| AWS ECR | Registre d'images Docker privé |
| AWS ECS Fargate | Containers sans gestion de serveur |
| AWS ALB | Load balancer, health checks, rolling update |
| AWS RDS MySQL 8.0 | Base de données managée, subnet privé |
| AWS SSM Parameter Store | Secrets chiffrés AES-256 |
| AWS ACM | Certificat SSL/TLS HTTPS |
| AWS CloudWatch | Logs + 4 alarmes en production |
| AWS SNS | Notifications email sur alarmes |
| AWS S3 | State Terraform chiffré |
| Jest + Supertest | 9 tests automatisés backend |

---

---

# SECTION 5 — BILAN

## Ce qui fonctionne en production

- Application accessible 24h/24 sur https://chat.ibrahimbabikir.fr
- Déploiement automatique à chaque `git push main` — aucune intervention manuelle
- Rolling update sans coupure de service
- 4 alarmes CloudWatch actives — état OK
- Logs en temps réel dans CloudWatch : "Server started on port 3000" + "Schema initialized"
- 9 tests Jest + smoke tests bloquant tout déploiement d'une image cassée

## Limites assumées et justifiées

| Limite | Justification |
|-------|--------------|
| `DB_USER = root` | Projet formation, base dédiée, aucun autre service. En production : utilisateur MySQL dédié avec droits limités |
| `assign_public_ip = true` | Sans NAT Gateway (32$/mois). Protégé par Security Group |
| `skip_final_snapshot = true` | Free Tier, projet formation. En production : snapshot final obligatoire |
| JWT en `localStorage` | Accessible via JS — un cookie HttpOnly serait plus sûr. Choix de simplicité |
| `escapeHtml()` manuel | Une bibliothèque dédiée (`he`) couvrirait plus de cas limites |
| Pas de `UNIQUE KEY` sur username | Race condition possible — en production : contrainte UNIQUE au niveau MySQL |
| `sleep 5` dans smoke tests | Fragile si cold start > 5s — une boucle de retry serait plus robuste |
| Health check GET / | Répond 200 même si RDS est down — un `/health` avec `SELECT 1` serait plus fiable |

## Évolutions planifiées

- Auto-scaling ECS (min 1 / max 3 containers selon CPU)
- Endpoint `/health` dédié avec vérification MySQL réelle
- Utilisateur MySQL dédié avec droits limités
- ECR Lifecycle Policy (garder les 10 dernières images)
- Environnement de staging (branche `staging` → ECS service dédié)

---

---

# SECTION 6 — SITUATION DE RECHERCHE : TERRAFORM MOVED ET STATE

## Contexte

Lors de la migration vers ECS Fargate, les Security Groups ont été renommés pour plus de cohérence :

```
aws_security_group.alb  →  aws_security_group.alb_sg
aws_security_group.ecs  →  aws_security_group.ecs_sg
aws_security_group.db   →  aws_security_group.db_sg
```

## Problème

`terraform plan` affichait :
```
# aws_security_group.alb will be destroyed
# aws_security_group.alb_sg will be created
```

Terraform interprète un renommage comme une destruction de l'ancienne ressource et une création d'une nouvelle. Ce comportement aurait provoqué une coupure de service complète.

## Recherche effectuée

Consultation de la documentation officielle Terraform sur la gestion du state. Recherche : "terraform rename resource without destroy". Trouvé : la fonctionnalité `moved {}` introduite dans Terraform 1.1.

## Solution — blocs `moved` dans `terraform/moved.tf`

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

**Résultat :** `terraform plan` affichait :
```
# aws_security_group.alb has moved to aws_security_group.alb_sg
```
Aucune ressource détruite. Aucune coupure de service.

## Deuxième situation : conflit de state

`aws_db_subnet_group.mini_chat` était présent deux fois dans le state, bloquant `terraform apply` avec une erreur de conflit.

```bash
# Supprimer l'entrée en double du state
terraform state rm aws_db_subnet_group.mini_chat

# Réimporter la ressource existante dans AWS
terraform import aws_db_subnet_group.mini_chat mini-chat-db-subnet-group

# Appliquer — OK
terraform apply
```

## Leçon retenue

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
│   ├── frontend/              # Servi statiquement par Express
│   │   ├── index.html         # Page connexion / inscription
│   │   ├── messages.html      # Interface de chat
│   │   ├── css/styles.css
│   │   └── js/
│   │       ├── config.js      # URL API selon environnement
│   │       ├── auth.js        # Fonctions login/register
│   │       └── chat.js        # Chargement et envoi messages
│   ├── src/
│   │   ├── config/database.js # Pool MySQL + initSchema()
│   │   ├── middleware/auth.js  # Vérification JWT
│   │   └── routes/
│   │       ├── auth.js        # POST /auth/register, POST /auth/login
│   │       └── messages.js    # GET /messages, POST /messages
│   └── tests/
│       └── app.test.js        # 9 tests Jest + Supertest
├── database/
│   └── init.sql               # Schéma SQL de référence
├── docker/
│   ├── docker-compose.yml     # Local uniquement
│   └── .env.example           # Template variables locales
├── docs/
│   └── architecture.png       # Schéma Mermaid exporté en PNG
├── scripts/
│   ├── start.bat              # Lancement local Windows
│   └── start.sh               # Lancement local Linux/Mac
└── terraform/
    ├── main.tf                # VPC, subnets, SG, RDS
    ├── ecs.tf                 # IAM, SSM, ECS, ALB, ACM
    ├── monitoring.tf          # 4 alarmes CloudWatch + SNS
    ├── variables.tf
    ├── outputs.tf
    ├── moved.tf               # Historique renommages
    └── provider.tf            # Provider AWS + state S3
```

## Annexe B — Secrets GitHub Actions

| Secret | Jobs | Destination finale |
|--------|------|--------------------|
| `AWS_ACCESS_KEY_ID` | 2, 3, 4 | Authentification AWS CLI |
| `AWS_SECRET_ACCESS_KEY` | 2, 3, 4 | Authentification AWS CLI |
| `DB_PASSWORD` | 4 (TF_VAR_db_password) | SSM → container ECS |
| `JWT_SECRET` | 4 (TF_VAR_jwt_secret) | SSM → container ECS |

## Annexe C — Captures d'écran à insérer

> 1. `cloudwatch-logs-demarrage.png` — CloudWatch logs : "Server started on port 3000" puis "Schema initialized"
> 2. `cloudwatch-alarmes-ok.png` — CloudWatch Overview : 4 alarmes, En alarme : 0, OK : 4
> 3. `ecs-service-actif.png` — ECS service : Statut Actif, 1 tâche en cours, 1 Sain
> 4. `ecs-metriques-cpu-ram.png` — Container Insights : CPU max 16.2%, RAM max 2.27%
> 5. `github-actions-4-jobs-verts.png` — GitHub Actions : 4 jobs tous verts
> 6. `app-connexion-https.png` — chat.ibrahimbabikir.fr avec cadenas SSL vert
> 7. `app-messagerie.png` — Interface chat avec message envoyé

---

*Document rédigé par Babikir Ibrahim*
*Formation : Administrateur Système DevOps — Titre RNCP Niveau 6*
*Référentiel : RE TP-01414-01*
*Date : Mai 2026*
