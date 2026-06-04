# PROMPT POWERPOINT — Soutenance ASD Niveau 6
## Mini-Chat — Administrateur Système DevOps

---

> **Instructions pour l'IA (Gamma / Skywork / ChatGPT / tout outil de présentation) :**
> Crée une présentation PowerPoint professionnelle de soutenance sur ce projet DevOps.
> Thème sombre (bleu marine ou noir), style technique, icônes GCP et DevOps.
> Police moderne (Inter ou Roboto). Couleur d'accent : orange ou bleu électrique.
> Chaque slide a un titre clair et du contenu structuré (bullets, tableaux ou schémas).
> Le plan suit EXACTEMENT le canevas officiel du référentiel ASD Niveau 6.
>
> IMPORTANT : Les lignes ═══ sont des SÉPARATEURS DE STRUCTURE — ce ne sont PAS des slides.
> Seules les lignes "## SLIDE N" sont des slides à créer.
>
> TIMING : la présentation dure exactement 30 minutes.
> Slides 1-5 : ~6 min — Slides 6-15 : ~16 min — Slides 16-17 : ~4 min — Slides 18-20 : ~4 min

---

## ═══════════════════════════════════════════
## SECTION 1 — PRÉSENTATION DE L'ENTREPRISE ET DU SERVICE
## (Référentiel ASD — canevas diaporama point 1)
## ═══════════════════════════════════════════

---

## SLIDE 1 — Page de titre

**Titre principal :** Mini-Chat — Application de messagerie cloud-native

**Sous-titre :** Déploiement automatisé sur Google Cloud Run avec pipeline CI/CD 4 jobs et HTTPS

**Informations :**
- Candidat : Babikir Ibrahim
- Formation : Administrateur Système DevOps — Titre RNCP Niveau 6
- Date : Mai 2026
- Technologies : Node.js · Docker · Terraform · GitHub Actions · Google Cloud Run · ACM · SNS

**Visuel :** fond sombre avec les logos GCP, Docker, GitHub Actions, Terraform

---

## SLIDE 2 — Présentation du service

**Titre :** Le service — Mini-Chat

**Contexte du service :**
Mini-Chat est une application de messagerie interne développée dans le cadre de la formation Administrateur Système DevOps. Elle permet à des équipes d'échanger des messages via une interface web, avec authentification sécurisée, stockage persistant et HTTPS sur domaine propre.

**Le service en chiffres :**
- 2 routes d'authentification (inscription / connexion)
- 2 routes de messagerie (lecture / envoi)
- 1 base de données relationnelle MySQL managée (Google Cloud SQL)
- 1 pipeline CI/CD automatisé en 4 étapes
- 1 infrastructure cloud entièrement en code (Terraform)
- HTTPS sur https://mini-chat-backend-py4vurg4oq-ew.a.run.app

**Utilisateurs cibles :**
Équipes internes — accès via navigateur web sans installation, depuis n'importe quel appareil connecté à Internet.

**Périmètre du projet :**
Projet réalisé en formation, de la conception à la mise en production sur GCP, couvrant l'ensemble des compétences ASD : infrastructure, conteneurisation, déploiement continu, sécurité et supervision.

**Visuel :** insérer `app-connexion-https.png` (page de connexion avec cadenas SSL) + `app-messagerie.png` (page de messagerie avec message envoyé)

---

## ═══════════════════════════════════════════
## SECTION 2 — CONTEXTE DU PROJET
## (Référentiel ASD — canevas diaporama point 2)
## Inclut : cahier des charges, contraintes, livrables attendus
## ═══════════════════════════════════════════

---

## SLIDE 3 — Contexte et phases du projet

**Titre :** Contexte du projet — 3 phases de réalisation

**3 phases de réalisation (timeline horizontale) :**

| Phase | Période | Ce qui a été fait |
|-------|---------|-------------------|
| Phase 0 | Mars 2026 | Backend Node.js, authentification JWT, frontend HTML/CSS/JS, Docker Compose local |
| Phase 1 | Avril 2026 | Infrastructure AWS EC2 + RDS, pipeline CI/CD initial, Dockerfile multi-stage |
| Phase 2 | Mai 2026 | Migration Cloud Run, suppression SSH, SSM secrets, HTTPS/ACM, smoke tests, alertes SNS |

**Décision de migration Phase 1 → Phase 2 :**
Sur EC2, le pipeline passait en vert mais l'application ne répondait pas. Après analyse : `user_data` asynchrone, image Docker buildée sur l'EC2 depuis le code source, aucune tracabilité. Cloud Run résout tous ces problèmes sans gestion de serveur.

**Visuel :** timeline horizontale en 3 étapes colorées (orange → bleu → vert)

---

## SLIDE 4 — Cahier des charges

**Titre :** Cahier des charges — Objectifs

**Tableau des objectifs avec statut :**

| Objectif | Statut |
|----------|--------|
| Application de messagerie fonctionnelle (API REST + Frontend) | ✅ Réalisé |
| Conteneurisation Docker multi-stage Alpine | ✅ Réalisé |
| Infrastructure AWS entièrement en code (Terraform) | ✅ Réalisé |
| Pipeline CI/CD automatisé GitHub Actions | ✅ Réalisé |
| Secrets sécurisés avec Google Secret Manager | ✅ Réalisé |
| Déploiement Cloud Run sans EC2, sans SSH | ✅ Réalisé |
| Tests automatisés bloquant le déploiement (Jest + smoke tests) | ✅ Réalisé |
| HTTPS avec domaine propre (mini-chat-backend-py4vurg4oq-ew.a.run.app) | ✅ Réalisé |
| Supervision Cloud Monitoring avec 4 alarmes + notifications email (SNS) | ✅ Réalisé |
| Auto Scaling Cloud Run (min 1 / max 3 containers) | 🔜 Planifié |

---

## SLIDE 5 — Contraintes et livrables attendus

**Titre :** Contraintes et livrables

**Contraintes du projet :**

| Contrainte | Détail |
|-----------|--------|
| Projet formation | Réalisé en centre de formation, pas en entreprise |
| Budget | Free Tier AWS + ressources minimales (ECS 0.25 vCPU / 512 MB, Cloud SQL db-f1-micro) |
| Pas de WebSocket | Rafraîchissement HTTP toutes les 3 secondes (polling) |
| Domaine IONOS | Pas de Route 53 — CNAMEs gérés manuellement dans le panel IONOS |
| Un seul container | Pas d'auto-scaling — planifié en évolution |
| RDS sans accès direct | Subnet privé → schéma auto-créé au démarrage de l'application |

**Livrables attendus et produits :**

| Livrable | Statut |
|----------|--------|
| Code source complet | ✅ github.com/babs235/mini-chat |
| Cahier des charges | ✅ |
| Guide de déploiement | ✅ |
| Infrastructure as Code | ✅ terraform/ (7 fichiers) |
| Pipeline CI/CD | ✅ .github/workflows/ci-cd.yml (4 jobs) |
| Application HTTPS en production | ✅ https://mini-chat-backend-py4vurg4oq-ew.a.run.app |
| Supervision opérationnelle | ✅ Cloud Monitoring + 4 alarmes + SNS email |

---

## ═══════════════════════════════════════════
## SECTION 3 — PRÉSENTATION DE L'INFRASTRUCTURE ET DE L'APPLICATION
## (Référentiel ASD — canevas diaporama point 3)
## ═══════════════════════════════════════════

---

## SLIDE 6 — Architecture générale

**Titre :** Architecture — Vue d'ensemble

**Schéma du flux complet :**
```
Développeur
    |
    | git push main
    ↓
GitHub Actions (CI/CD)
    ├── Job 1 : npm test (9 tests Jest) ──────── bloque si échec
    ├── Job 2 : docker build → push Artifact Registry :sha-commit
    ├── Job 3 : smoke tests (pull Artifact Registry → HTTP tests) ─ bloque si KO
    └── Job 4 : terraform apply → ECS déploie la nouvelle version
                        ↓
        GCP europe-west1 (Belgique)
        ┌────────────────────────────────────────────────────┐
        │  Utilisateur → HTTPS 443 → [ACM] → [ALB]          │
        │                              ↓ health check GET /  │
        │                 [Cloud Run — Node.js port 3000]  │
        │                              ↓ port 3306           │
        │                 [Cloud SQL MySQL — subnet privé]         │
        │                                                    │
        │  Cloud Logging + 4 Alarmes → [SNS] → Email       │
        └────────────────────────────────────────────────────┘
```

**Points clés :**
- Aucun accès SSH — Cloud Run, zéro gestion de serveur
- Chaque image Docker taguée avec le hash exact du commit Git
- Rolling update : déploiement sans coupure de service
- HTTPS enforced : HTTP port 80 redirige automatiquement vers HTTPS 443

**Visuel :** insérer docs/architecture.png (schéma Mermaid exporté)

---

## SLIDE 7 — Application Mini-Chat

**Titre :** L'application — API REST et frontend

**Backend Node.js/Express — Routes :**

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| /auth/register | POST | Non | Inscription (bcrypt 10 rounds, validation longueur) |
| /auth/login | POST | Non | Connexion — retourne JWT signé (1h) |
| /messages | GET | JWT | Historique complet avec timestamps |
| /messages | POST | JWT | Envoi avec protection XSS (escapeHtml) |
| / | GET | Non | Health check Cloud Run → HTTP 200 |

**Sécurité applicative (3 protections) :**
- SQL Injection → Requêtes préparées mysql2 (jamais de concaténation)
- XSS → `escapeHtml()` avant chaque insertion en base
- JWT → Token signé avec secret depuis Google Secret Manager, expiration 1 heure

**Frontend :**
HTML/CSS/JS — glassmorphism, responsive mobile-first, rafraîchissement automatique 3 secondes.
URL de production en relatif (vide) — pas de hardcoding, compatible HTTPS automatiquement.

---

## SLIDE 8 — Réseau et sécurité

**Titre :** Sécurité réseau — Principe du moindre privilège

**Security Groups (3 niveaux d'isolation) :**

| Security Group | Autorise | Depuis |
|----------------|----------|--------|
| mini-chat-alb-sg | Port 80 + 443 entrants | Internet (0.0.0.0/0) |
| mini-chat-ecs-sg | Port 3000 entrant | ALB uniquement |
| mini-chat-db-sg | Port 3306 entrant | ECS uniquement |

**Résultat :**
```
Internet → [ALB ports 80/443] → [ECS port 3000] → [RDS port 3306]
           ↑ seul accès public   ↑ invisible        ↑ invisible
                                   depuis internet     depuis internet
```

La base de données est inaccessible depuis Internet et depuis l'ALB directement.
Pas de port SSH ouvert — aucune ressource n'a de clé SSH.

**Note sur assign_public_ip = true (ECS) :**
Les containers ECS ont une IP publique assignée — non par choix de sécurité, mais par contrainte de coût :
sans NAT Gateway (32$/mois), les containers doivent avoir une IP publique pour joindre ECR et Cloud Monitoring.
Le Security Group `mini-chat-ecs-sg` bloque tout accès entrant direct depuis Internet : seul l'ALB peut joindre le port 3000.
L'IP publique sert uniquement au trafic sortant (pull image ECR, envoi logs). En production réelle, un NAT Gateway serait la solution préférable.

---

## SLIDE 9 — Terraform — Infrastructure as Code

**Titre :** Terraform — Infrastructure entièrement en code

**7 fichiers Terraform :**

| Fichier | Contenu |
|---------|---------|
| main.tf | VPC, 4 subnets, Internet Gateway, 3 Security Groups, Cloud SQL MySQL |
| ecs.tf | IAM roles, SSM secrets, Cloud Monitoring logs, ECS cluster/task/service, ALB, ACM |
| monitoring.tf | 4 alarmes Cloud Monitoring + topic SNS + abonnement email |
| variables.tf | Variables d'entrée (région, secrets, image_tag) |
| outputs.tf | URL ALB, endpoint RDS, noms ECS après déploiement |
| provider.tf | Provider AWS + backend state S3 (chiffré, sans verrou DynamoDB — projet solo, aucun accès concurrent possible) |
| moved.tf | Historique des renommages de ressources |

**Ce que Terraform crée automatiquement :**
VPC · 4 subnets · Internet Gateway · 3 Security Groups · ALB · Target Group · Listener HTTP (redirect) · Listener HTTPS (TLS 1.3) · ACM Certificate · ECS Cluster · Cloud Run Container Definition · Cloud Run Service · Cloud SQL MySQL · ECR (data) · SSM Parameters · Cloud Logging · 4 Alarmes · canal de notification email + Subscription · IAM Role

Un seul `git push` met à jour toute l'infrastructure — y compris les alarmes, les secrets et les certificats.

---

## SLIDE 10 — Pipeline CI/CD — 4 jobs

**Titre :** Pipeline CI/CD — GitHub Actions

**4 jobs séquentiels :**

```
PUSH sur main
     ↓
┌─────────────────────────┐
│  Job 1 — Tests          │  ~30 secondes
│  npm ci                 │
│  npm test (9 Jest)      │ ← bloque tout si échec
└───────────┬─────────────┘
            ↓ ✅ OK
┌─────────────────────────┐
│  Job 2 — Build ECR      │  ~2 minutes
│  docker build           │
│  push :sha-commit       │ ← tracabilité exacte
│  push :latest           │
└───────────┬─────────────┘
            ↓ ✅ OK
┌─────────────────────────┐
│  Job 3 — Smoke Tests    │  ~1 minute
│  pull image :sha-commit │ ← même artefact qu'en prod
│  docker run (env fictif)│
│  curl GET / → 200       │ ← santé de base
│  curl POST /register → 400 (validation)
│  curl GET /messages → 403 (auth requise)
│  ❌ KO → STOP, pas de déploiement
└───────────┬─────────────┘
            ↓ ✅ OK
┌─────────────────────────┐
│  Job 4 — Deploy         │  ~3-5 minutes
│  terraform init         │
│  terraform apply        │ ← ECS déploie la nouvelle image
└─────────────────────────┘
```

**Conformité pré-prod :** le Job 3 garantit que l'image ECR est fonctionnelle AVANT le déploiement.
On teste le même artefact (hash SHA identique) qui partira en production.

**Limite assumée des smoke tests :** les variables DB sont fictives — la connectivité MySQL réelle n'est pas testée ici.
Ce cas est couvert après déploiement : l'ALB vérifie `GET /` avant de basculer le trafic. Si le container ne peut pas joindre RDS, il échoue au démarrage, le health check Cloud Run ne passe pas, et l'ancien container reste actif (rollback automatique).

**Visuel :** insérer `github-actions-4-jobs-verts.png` (pipeline GitHub Actions — 4 jobs tous verts)

---

## SLIDE 11 — Docker multi-stage

**Titre :** Conteneurisation — Dockerfile multi-stage Alpine

**Dockerfile :**
```
Stage 1 — deps (node:20-alpine)
  WORKDIR /app
  COPY package*.json ./
  npm ci --only=production
  → installe uniquement les dépendances de production

Stage 2 — final (node:20-alpine)
  COPY --from=deps /app/node_modules
  COPY code source
  EXPOSE 3000
  CMD ["node", "server.js"]
```

**Résultat :** image ~180 MB au lieu de ~950 MB — 6x plus légère

**Avantages :**
- Aucun outil de build dans l'image de production
- Surface d'attaque minimale (Alpine Linux)
- Démarrage plus rapide du container
- Coûts de stockage ECR réduits (économie directe)

---

## SLIDE 12 — HTTPS avec ACM

**Titre :** HTTPS — Certificat SSL Cloud Run (certificat automatique)

**Problème initial :** application accessible uniquement en HTTP sur l'URL de l'ALB (adresse peu mémorisable, pas de cadenas SSL).

**Solution mise en place :**

```
1. Achat domaine ibrahimbabikir.fr chez IONOS
2. Création certificat ACM dans Terraform (europe-west1)
   → Validation par DNS — ACM génère un CNAME à ajouter
3. IONOS DNS panel — 2 enregistrements CNAME ajoutés manuellement :
   ├── Validation ACM : _acme-xxxxx.mini-chat-backend-py4vurg4oq-ew.a.run.app → validation.acm.amazonaws.com
   └── Sous-domaine   : mini-chat-backend-py4vurg4oq-ew.a.run.app → mini-chat-alb-xxxxxxxxx.europe-west1.elb.amazonaws.com
4. ALB — 2 listeners configurés dans Terraform :
   ├── Port 80  HTTP  → redirect 301 vers HTTPS
   └── Port 443 HTTPS → forward vers ECS (TLS 1.3, policy ELBSecurityPolicy-TLS13-1-2-2021-06)
5. Frontend — URLs relatives (string vide) en production
   → plus de Mixed Content, compatible HTTP local et HTTPS prod
```

**Résultat :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app — cadenas SSL, TLS 1.3, redirection HTTP automatique.

**Visuel :** insérer `app-connexion-https.png` (navigateur — cadenas vert + "Certificat valide")

---

## SLIDE 13 — Gestion des secrets

**Titre :** Secrets — Google Secret Manager

**Avant (Phase 1 - EC2) :** fichier `.env` en clair sur le serveur

**Après (Phase 2 - Cloud Run) :**

```
GitHub Secrets              GitHub Actions Pipeline
├── DB_PASSWORD    ─────→   TF_VAR_db_password
└── JWT_SECRET     ─────→   TF_VAR_jwt_secret
                                     ↓
                            Terraform stocke dans
                            Secret Manager
                            /mini-chat/db_password  🔒 SecureString AES-256
                            /mini-chat/jwt_secret   🔒 SecureString AES-256
                                     ↓
                            ECS injecte au démarrage
                            du container (champ secrets, jamais en clair)
```

**Garanties :** jamais dans le code source · jamais dans les logs Cloud Monitoring · jamais dans le state Terraform · jamais dans l'image Docker

---

## SLIDE 14 — Supervision Cloud Monitoring + SNS

**Titre :** Supervision — Google Cloud Monitoring + Notifications SNS

**Logs en temps réel :**
Groupe `/ecs/mini-chat-backend` — logs de démarrage, requêtes HTTP, erreurs — rétention 7 jours.

**4 alarmes Cloud Monitoring actives (terraform/monitoring.tf) :**

| Alarme | Métrique | Seuil | Action |
|--------|---------|-------|--------|
| Container stoppé | ECS instance count Cloud Run | < 1 pendant 1 minute | Email SNS |
| Erreurs 5xx élevées | ALB request_count 5xx | > 10 sur 5 minutes | Email SNS |
| CPU ECS élevé | ECS CPUUtilization | > 80% pendant 10 minutes | Email SNS |
| Disque RDS faible | RDS FreeStorageSpace | < 2 Go | Email SNS |

**Notification SNS :**
Un topic Cloud Monitoring email reçoit les alarmes et envoie un email à babikiribrahimalkhalil@gmail.com.
La politique SNS autorise explicitement `cloudwatch.amazonaws.com` à publier dans le topic.

**Visuel :**
- `cloudwatch-alarmes-ok.png` — vue d'ensemble Cloud Monitoring : 4 alarmes actives, En alarme : 0, OK : 4
- `cloudwatch-logs-demarrage.png` — logs /ecs/mini-chat-backend : "Server started on port 3000" + "Schema initialized"
- `ecs-service-actif.png` — service ECS mini-chat-backend : Statut Actif, 1 tâche en cours, 1 Sain
- `ecs-metriques-cpu-ram.png` — métriques Cloud Monitoring : CPU max 16.2%, RAM max 2.27%

---

## SLIDE 15 — SLA et indicateurs de service

**Titre :** Statistiques de services — KPI et SLA (BC03)

**Distinction métrique / indicateur / KPI / SLA :**

| Terme | Exemple dans ce projet |
|-------|----------------------|
| Métrique | 47 requêtes HTTP reçues, CPU à 12%, 3 messages envoyés |
| Indicateur | Taux d'erreurs 5xx sur 24h, temps de réponse moyen |
| KPI | Disponibilité mensuelle 99%, p95 < 500 ms |
| SLA | Service accessible 99% du temps, restauration < 2h |

**SLA définis et couverts par les alarmes :**

| KPI | Objectif SLA | Alarme configurée |
|-----|-------------|------------------|
| Disponibilité mensuelle | ≥ 99% | instance count Cloud Run < 1 → ALARM + email |
| Taux d'erreurs | < 2% HTTP 5xx / 24h | request_count 5xx > 10 → ALARM |
| Ressources CPU | < 80% | CPUUtilization > 80% 10 min → ALARM |
| Stockage données | > 2 Go libres | FreeStorageSpace < 2 Go → ALARM |
| Restauration | < 2 heures | Rolling update automatique ou redeploi |

---

## ═══════════════════════════════════════════
## SECTION 4 — EXEMPLE SIGNIFICATIF DU TRAVAIL RÉALISÉ
## (Référentiel ASD — canevas diaporama point 4)
## ═══════════════════════════════════════════

---

## SLIDE 16 — Exemple significatif : incident réel résolu

**Titre :** Exemple de travail réalisé — Analyse et résolution d'incident

**Incident : Mixed Content bloquant toute l'application**

**Symptôme observé par l'utilisateur :**
Page HTTPS affichée, mais impossible de s'inscrire ou se connecter. Console du navigateur :
```
Mixed Content: The page at 'https://mini-chat-backend-py4vurg4oq-ew.a.run.app' was loaded over HTTPS,
but requested an insecure XMLHttpRequest endpoint 'http://mini-chat-backend-py4vurg4oq-ew.a.run.app:3000/auth/register'
```

**Démarche d'investigation (3 étapes) :**
1. Console navigateur → message Mixed Content → URL construite avec `http://` hardcodé
2. Lecture de `config.js` → `window.location.hostname` → reconstruction `http://hostname:3000`
3. Identification du bug : en HTTPS, le navigateur bloque toute requête HTTP sortante

**Cause identifiée :**
`config.js` construisait l'URL de l'API avec `http://` + nom d'hôte + `:3000` pour tout ce qui n'était pas localhost. Sur HTTPS, cette URL http:// est bloquée par le navigateur (Mixed Content policy).

**Correction appliquée dans `config.js` :**
```javascript
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return ''; // URLs relatives en production — compatibles HTTP et HTTPS
};
```

**Leçon retenue :**
En production derrière un ALB, les URLs relatives suffisent. Hardcoder le protocole ou le port crée une dépendance fragile à l'environnement.

---

## ═══════════════════════════════════════════
## SECTION 5 — EXEMPLE DE RECHERCHE EFFECTUÉE
## (Référentiel ASD — canevas diaporama point 5)
## ═══════════════════════════════════════════

---

## SLIDE 17 — Exemple de recherche : blocs `moved` Terraform

**Titre :** Exemple de recherche — Renommer des ressources Terraform sans les détruire

**Problème constaté (point de départ de la recherche) :**
Lors de la migration vers Cloud Run, les security groups ont été renommés pour plus de lisibilité.
Terraform a voulu détruire et recréer les ressources renommées → coupure de service, perte des configurations.

```
aws_security_group.alb  →  aws_security_group.alb_sg
# Terraform par défaut : destroy alb + create alb_sg → downtime !
```

**Recherche effectuée :**
Documentation Terraform officielle sur la gestion du state → découverte des blocs `moved {}`.

**Découverte — blocs `moved` dans moved.tf :**
```hcl
moved {
  from = aws_security_group.alb
  to   = aws_security_group.alb_sg
}
```

Terraform met à jour uniquement le state — aucune ressource AWS n'est détruite ni recréée.

**Résultat :** renommage propre de 5 ressources sans coupure, sans perte de données.

**Deuxième recherche — `terraform state rm` + `terraform import` :**
Conflict sur `aws_db_subnet_group` présent deux fois dans le state.
Solution : supprimer l'entrée en double du state puis ré-importer la ressource existante en AWS.
Cette commande a été intégrée directement dans le pipeline CI/CD (`ci-cd.yml`) pour éviter la récurrence.

---

## ═══════════════════════════════════════════
## SECTION 6 — SYNTHÈSE ET CONCLUSION
## (Référentiel ASD — canevas diaporama point 6)
## ═══════════════════════════════════════════

---

## SLIDE 18 — Difficultés rencontrées et solutions

**Titre :** Difficultés rencontrées — Problèmes réels résolus

| Difficulté | Cause | Solution |
|------------|-------|----------|
| Containers ne démarraient pas sur EC2 | `user_data` asynchrone — scripts non terminés au moment du déploiement | Migration vers Cloud Run : plus de user_data, container démarre directement depuis Artifact Registry |
| Renommage Terraform → destroy + recreate | Terraform interprète un renommage comme une destruction | Blocs `moved {}` dans moved.tf : state mis à jour sans toucher aux ressources AWS |
| DB Subnet Group conflit dans le state | Double entrée Terraform après migration | `terraform state rm` + `terraform import` intégrés dans le pipeline |
| Schema DB non initialisé sur RDS | init.sql uniquement local, RDS inaccessible directement | `initSchema()` non bloquant au démarrage du backend |
| Mixed Content bloquant toute l'application | config.js construisait `http://hostname:3000` sur une page HTTPS | URLs relatives vides en production — le navigateur gère le protocole |
| ECS service en erreur après ajout HTTPS | ECS démarrait avant que le listener HTTPS soit créé par Terraform | `depends_on = [aws_lb_listener.http, aws_lb_listener.https]` dans ecs.tf |

---

## SLIDE 19 — Comparaison architectures et compétences ASD

**Titre :** Evolution et compétences mobilisées

**Phase 1 → Phase 2 :**

| Critère | Phase 1 — EC2 | Phase 2 — Cloud Run |
|---------|--------------|----------------------|
| Déploiement | SSH + docker compose | git push → automatique |
| Secrets | .env en clair | Secret Manager (chiffré) AES-256 |
| Redémarrage si crash | Manuel | Automatique (Cloud Run Service) |
| SSH requis | Oui | Non |
| Tracabilité | Aucune | Hash commit exact sur chaque image |
| Rolling update | Non — coupure ~30s | Oui — zéro downtime |
| Tests bloquants | Non | Oui — 9 Jest + smoke tests |
| HTTPS | Non | Oui — ACM + TLS 1.3 |
| Alertes | Non | Oui — 4 alarmes Cloud Monitoring + SNS email |

**Compétences ASD couvertes :**

| Compétence ASD | Couverture dans le projet |
|----------------|--------------------------|
| Automatiser la création de serveurs | Terraform IaC — toute l'infra en code |
| Automatiser le déploiement | GitHub Actions 4 jobs — push = déploiement complet |
| Sécuriser l'infrastructure | SSM, pas de SSH, Security Groups, HTTPS, tests CI |
| Mettre en production dans le cloud | Cloud Run GCP europe-west1, ALB, ACM |
| Préparer un environnement de test | Jest 9 tests + smoke tests Docker pre-prod |
| Gérer le stockage des données | Cloud SQL MySQL subnet privé, backup 1 jour, logs Cloud Monitoring 7 jours |
| Gérer des containers | Docker multi-stage, Cloud Run, ECR, rolling update |
| Définir des statistiques de services | BC03 : KPI/SLA + 4 alarmes Cloud Monitoring + SNS |
| Exploiter une solution de supervision | Cloud Monitoring logs + alarmes + incident réel résolu |

---

## SLIDE 20 — Conclusion

**Titre :** Synthèse et conclusion

**Satisfactions :**
- Architecture Cloud Run moderne — zéro gestion de serveur, zéro SSH, zéro downtime
- Un seul `git push` déclenche tests, smoke tests, build et déploiement automatiquement
- Secrets 100% sécurisés : du code source jusqu'au container en production
- HTTPS opérationnel sur un domaine propre (mini-chat-backend-py4vurg4oq-ew.a.run.app) avec TLS 1.3
- Supervision active : 4 alarmes Cloud Monitoring liées aux SLA, notifications email par SNS
- Tracabilité totale : on sait à tout moment quel commit exact tourne en production

**Difficultés principales :**
- Pipeline passait en vert sur EC2 mais l'application ne répondait pas (user_data asynchrone)
- Mixed Content HTTPS bloquait toute l'application à cause d'URLs hardcodées
- Terraform voulait détruire des ressources lors de simples renommages
- Container s'arrêtait immédiatement au démarrage (RDS pas encore prêt)
- Quota IAM de 10 politiques managées atteint en cours de migration

**Ce que j'ai appris :**
Cloud Run résout structurellement les problèmes de déploiement continu sur EC2.
Terraform est puissant mais exige une gestion rigoureuse du state dès qu'on renomme des ressources.
Le frontend doit être pensé pour plusieurs environnements dès le départ (URLs relatives, pas de hardcoding).

**Évolutions prévues :**
- Auto Scaling Cloud Run (min 1 / max 3 containers selon charge CPU)
- Environnement de staging (branche `staging` → ECS service dédié)
- ECR Lifecycle Policy (garder les 10 dernières images, purger le reste)

---

*Présentation Soutenance ASD Niveau 6 — Babikir Ibrahim — Mai 2026*
*Référentiel : RE TP-01414-01 — Canevas diaporama respecté intégralement*
*Projet complet : github.com/babs235/mini-chat — Application : https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
