# PROMPT PDF — Support de Présentation (Diaporama)
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA (ChatGPT / Gemini / Claude / Gamma) :**
>
> Génère un document PDF de présentation à partir du contenu ci-dessous.
> Ce document simule un support de type diaporama — chaque slide est une page A4 distincte.
>
> **Mise en page :**
> - Format A4 paysage de préférence (ou portrait si paysage non disponible)
> - Chaque section "SLIDE N" = une nouvelle page PDF
> - Fond blanc ou bleu très foncé (#0A1628), selon ce qui est plus lisible
> - Police principale : Inter, Roboto, ou Calibri
> - Couleur d'accent principale : bleu électrique (#0080FF) ou orange (#FF6B35)
>
> **Style des slides :**
> - Titre du slide : grand, gras, centré ou aligné à gauche, couleur d'accent
> - Contenu : listes à puces claires, tableaux propres avec bordures, blocs de code en monospace
> - Logos ou icônes GCP, Docker, GitHub Actions, Terraform si l'outil peut en générer
> - Pas de texte trop dense — maximum 6-8 lignes de contenu par slide
> - En pied de slide : "Mini-Chat — ASD Niveau 6 — Babikir Ibrahim" + numéro de slide
>
> **Timing total : 30 minutes de présentation**
> - Slides 1-5 : ~6 minutes (présentation + contexte)
> - Slides 6-14 : ~16 minutes (technique)
> - Slides 15-17 : ~4 minutes (exemple + recherche)
> - Slides 18-20 : ~4 minutes (synthèse + conclusion)
>
> **Important :** Chaque "## SLIDE N" ci-dessous est une page distincte. Ne les fusionne pas.

---

---

## SLIDE 1 — Page de titre

**Titre principal :**
Mini-Chat — Application de messagerie cloud-native

**Sous-titre :**
Déploiement automatisé sur Google Cloud Run
Pipeline CI/CD 4 jobs — HTTPS — Infrastructure as Code

**Informations candidat :**
- Candidat : Babikir Ibrahim
- Formation : Administrateur Système DevOps — Titre RNCP Niveau 6
- Date : Mai 2026

**Technologies (logos ou texte) :**
Node.js · Docker · Terraform · GitHub Actions · Google Cloud Run · ACM · Cloud Monitoring · SNS

---

## SLIDE 2 — Présentation du service

**Titre :** Le service — Mini-Chat

**Qu'est-ce que Mini-Chat ?**
Application de messagerie interne accessible via navigateur web, avec authentification sécurisée, stockage persistant en base de données et HTTPS sur domaine propre.

**Le service en chiffres :**
- 4 routes API REST (inscription, connexion, envoi, lecture)
- 1 base de données MySQL managée sur Google Cloud SQL
- 1 pipeline CI/CD automatisé — 4 étapes
- 1 infrastructure cloud 100 % en code (Terraform)
- HTTPS actif sur https://mini-chat-backend-py4vurg4oq-ew.a.run.app

**Utilisateurs cibles :**
Équipes internes — accès via navigateur, sans installation, depuis n'importe quel appareil connecté.

**Périmètre :**
Projet complet de la conception à la production — couvre les 3 blocs de compétences ASD.

---

## SLIDE 3 — Contexte — 3 phases de réalisation

**Titre :** Contexte du projet — 3 phases

**Timeline (tableau ou frise) :**

| Phase | Période | Réalisations |
|-------|---------|-------------|
| Phase 0 | Mars 2026 | Backend Node.js, JWT, frontend HTML/CSS/JS, Docker Compose local |
| Phase 1 | Avril 2026 | Infrastructure EC2 + RDS, pipeline CI/CD initial, Dockerfile multi-stage |
| Phase 2 | Mai 2026 | Migration Cloud Run, secrets SSM, HTTPS/ACM, smoke tests, alertes SNS |

**Pourquoi la migration Phase 1 → Phase 2 ?**
Pipeline vert sur EC2, mais application silencieuse en production.
Cause : `user_data` asynchrone — le container démarrait après le déploiement Terraform.
Solution : Cloud Run — déploiement direct depuis Artifact Registry, rolling update contrôlé, health check Cloud Run.

---

## SLIDE 4 — Cahier des charges

**Titre :** Cahier des charges — Objectifs du projet

**Tableau des objectifs avec statut :**

| Objectif | Statut |
|----------|--------|
| Application de messagerie fonctionnelle (API REST + Frontend) | Réalisé |
| Conteneurisation Docker multi-stage Alpine | Réalisé |
| Infrastructure AWS entièrement en code (Terraform) | Réalisé |
| Pipeline CI/CD automatisé GitHub Actions — 4 jobs | Réalisé |
| Secrets sécurisés avec Google Secret Manager | Réalisé |
| Déploiement Cloud Run — sans EC2, sans SSH | Réalisé |
| Tests bloquants (Jest + smoke tests pré-production) | Réalisé |
| HTTPS avec domaine propre (mini-chat-backend-py4vurg4oq-ew.a.run.app) | Réalisé |
| Supervision Cloud Monitoring — 4 alarmes + notifications email SNS | Réalisé |
| Auto Scaling Cloud Run (min 1 / max 3 containers) | Planifié |

---

## SLIDE 5 — Contraintes et livrables

**Titre :** Contraintes et livrables attendus

**Contraintes :**

| Contrainte | Détail |
|-----------|--------|
| Budget Free Tier | Cloud Run 0,25 vCPU / 512 Mo — Cloud SQL db-f1-micro — pas de NAT Gateway |
| Domaine IONOS | CNAMEs configurés manuellement (pas de Route 53) |
| Pas de WebSocket | Polling HTTP toutes les 3 secondes |
| RDS inaccessible directement | Sous-réseau privé — schéma initialisé au démarrage du backend |

**Livrables produits :**

| Livrable | Localisation |
|----------|-------------|
| Code source complet | github.com/babs235/mini-chat |
| Infrastructure as Code (7 fichiers Terraform) | terraform/ |
| Pipeline CI/CD (4 jobs) | .github/workflows/ci-cd.yml |
| Application HTTPS en production | https://mini-chat-backend-py4vurg4oq-ew.a.run.app |
| Supervision opérationnelle (4 alarmes) | Google Cloud Monitoring / monitoring.tf |

---

## SLIDE 6 — Architecture générale

**Titre :** Architecture — Vue d'ensemble

**Schéma du flux complet :**

```
Développeur
    │  git push main
    ▼
GitHub Actions
    ├── Job 1 : Tests Jest (9 suites)
    ├── Job 2 : docker build → push Artifact Registry :sha-commit
    ├── Job 3 : smoke tests (pull Artifact Registry → 3 tests HTTP)
    └── Job 4 : terraform apply → ECS déploie la nouvelle version
                    │
                    ▼
        GCP europe-west1 (Belgique)
        Internet ──HTTPS──► [ALB] ──► [Cloud Run :3000] ──► [Cloud SQL MySQL]
        HTTP 80  ──► redirect 301
        [Cloud Logging + 4 Alarmes] ──► [SNS] ──► Email
```

**Points clés :**
- Aucun accès SSH — Cloud Run, zéro gestion de serveur
- Chaque image Docker taguée avec le hash exact du commit Git
- Rolling update : nouveau container démarré avant l'arrêt de l'ancien
- HTTPS forcé : HTTP redirige automatiquement vers HTTPS

---

## SLIDE 7 — Application — API REST et frontend

**Titre :** L'application — API REST et frontend

**Routes API :**

| Route | Méthode | Auth | Description |
|-------|---------|------|-------------|
| / | GET | Non | Health check Cloud Run → HTTP 200 |
| /auth/register | POST | Non | Inscription — validation + bcrypt 10 rounds |
| /auth/login | POST | Non | Connexion → JWT signé (1 heure) |
| /messages | GET | JWT | Historique complet avec timestamps |
| /messages | POST | JWT | Envoi + protection XSS (escapeHtml) |

**3 protections applicatives :**
- Injection SQL → requêtes préparées `(?, ?)` — jamais de concaténation
- XSS → `escapeHtml()` avant chaque insertion en base
- JWT → token signé, expiration 1 heure, secret depuis Google Secret Manager

**Frontend :**
HTML/CSS/JS vanilla — responsive — rafraîchissement auto 3 secondes — URLs relatives en production (pas de hardcoding protocole/port).

---

## SLIDE 8 — Sécurité réseau — Isolation par Security Groups

**Titre :** Sécurité réseau — Principe du moindre privilège

**3 niveaux d'isolation :**

| Security Group | Autorise | Depuis |
|----------------|----------|--------|
| mini-chat-alb-sg | Ports 80 et 443 entrants | Internet (0.0.0.0/0) |
| mini-chat-ecs-sg | Port 3000 entrant | Security Group ALB uniquement |
| mini-chat-db-sg | Port 3306 entrant | Security Group ECS uniquement |

**Résultat :**
```
Internet → [ALB 80/443] → [ECS :3000] → [RDS :3306]
            seul accès      invisible      invisible
            public          depuis         depuis
                            Internet       Internet
```

**Note sur l'IP publique ECS :**
Sans NAT Gateway (~32 $/mois), ECS a une IP publique pour joindre ECR et Cloud Monitoring.
Le Security Group `mini-chat-ecs-sg` bloque tout accès entrant direct.
En production réelle : NAT Gateway préférable.

---

## SLIDE 9 — Infrastructure as Code — Terraform

**Titre :** Terraform — 7 fichiers — Infrastructure complète en code

**Structure Terraform :**

| Fichier | Contenu |
|---------|---------|
| main.tf | VPC, 4 sous-réseaux, Internet Gateway, 3 Security Groups, Cloud SQL MySQL |
| ecs.tf | IAM, SSM secrets, Cloud Monitoring logs, ECS cluster/task/service, ALB, ACM |
| monitoring.tf | 4 alarmes Cloud Monitoring + topic SNS + abonnement email |
| variables.tf | Variables d'entrée (région, secrets, image_tag) |
| outputs.tf | URL ALB, endpoint RDS, noms cluster/service ECS |
| provider.tf | Provider AWS + backend state S3 chiffré |
| moved.tf | Historique des renommages de ressources (évite les destructions) |

**Ce que `terraform apply` crée automatiquement :**
VPC · 4 subnets · IGW · 3 Security Groups · ALB · 2 Listeners (HTTP + HTTPS) · ACM · ECS Cluster · Task Definition · Cloud Run Service · RDS · SSM Secrets · Cloud Logging · 4 Alarmes · SNS · IAM Role

Un seul `git push` met à jour toute l'infrastructure.

---

## SLIDE 10 — Pipeline CI/CD — 4 jobs

**Titre :** Pipeline GitHub Actions — 4 jobs séquentiels

```
PUSH sur main
     │
     ▼
Job 1 — Tests Jest (~30 secondes)
     npm ci  →  npm test (9 suites)
     ⛔ Bloque tout si un test échoue
     │
     ▼
Job 2 — Build ECR (~2 minutes)
     docker build (multi-stage Alpine)
     push :sha-commit  ← traçabilité exacte
     push :latest
     │
     ▼
Job 3 — Smoke Tests (~1 minute)
     pull image :sha-commit ← même artefact qu'en prod
     docker run (variables fictives)
     GET /         → 200  ✓
     POST /register {} → 400  ✓
     GET /messages (no token) → 403  ✓
     ⛔ Bloque si KO
     │
     ▼
Job 4 — Deploy Terraform (~3-5 minutes)
     terraform init + validate + fmt
     terraform apply -auto-approve
     ECS déploie la nouvelle image :sha-commit
```

**Garantie clé :** l'image testée en Job 3 est exactement celle déployée en Job 4 — même hash SHA.

---

## SLIDE 11 — Conteneurisation — Dockerfile multi-stage

**Titre :** Docker multi-stage Alpine — Image optimisée

**Dockerfile :**

```dockerfile
# Stage 1 : Installation des dépendances
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2 : Image finale de production
FROM node:20-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

**Résultat :** ~180 MB au lieu de ~950 MB avec node:20 standard — 6x plus légère

**Avantages :**
- Aucun outil de build (npm, git) dans l'image de production
- Surface d'attaque minimale (Alpine Linux = ~5 MB base)
- Démarrage container plus rapide — pull Artifact Registry plus rapide
- Coûts stockage ECR réduits

---

## SLIDE 12 — HTTPS — Certificat SSL Cloud Run (HTTPS automatique)

**Titre :** HTTPS — Cloud Run (certificat automatique) + ALB

**Mise en place étape par étape :**

1. Achat du domaine ibrahimbabikir.fr chez IONOS
2. Création certificat ACM dans Terraform (europe-west1) — validation par DNS
3. Ajout des enregistrements CNAME dans le panel IONOS :
   - Validation ACM : `_acme-xxxxx.mini-chat-backend-py4vurg4oq-ew.a.run.app`
   - Sous-domaine : `mini-chat-backend-py4vurg4oq-ew.a.run.app → [ALB DNS]`
4. ALB — 2 listeners dans Terraform :
   - Port 80 HTTP → redirect 301 vers HTTPS
   - Port 443 HTTPS → TLS 1.3 → forward vers ECS
5. Frontend — URLs relatives vides en production

**Résultat :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app — cadenas SSL valide — TLS 1.3 — redirection HTTP automatique

---

## SLIDE 13 — Gestion des secrets — Google Secret Manager

**Titre :** Secrets — Google Secret Manager

**Flux de sécurisation :**

```
GitHub Secrets
├── DB_PASSWORD ─► TF_VAR_db_password ─► SSM /mini-chat/db_password
└── JWT_SECRET  ─► TF_VAR_jwt_secret  ─► SSM /mini-chat/jwt_secret
                                               │ (SecureString AES-256)
                                               ▼ injection au démarrage
                                        ECS container
                                        (champ secrets: — jamais en logs)
```

**Garanties :**
- Jamais dans le code source ni l'historique Git
- Jamais dans les logs Cloud Monitoring
- Jamais dans l'image Docker ou le Artifact Registry
- Jamais dans le state Terraform (variable sensible, marquée `sensitive`)
- Jamais dans la console AWS en clair (SecureString = chiffrement KMS)

---

## SLIDE 14 — Supervision — Cloud Monitoring + SNS

**Titre :** Supervision — Google Cloud Monitoring + Notifications email SNS

**Logs en temps réel :**
Groupe `/ecs/mini-chat-backend` — démarrage serveur, schéma initialisé, requêtes HTTP, erreurs — rétention 7 jours.

**4 alarmes Cloud Monitoring actives :**

| Alarme | Métrique | Seuil | SLA |
|--------|---------|-------|-----|
| Container stoppé | ECS instance count Cloud Run | < 1 pendant 1 min | Disponibilité ≥ 99 % |
| Erreurs 5xx | ALB request_count 5xx | > 10 sur 5 min | Taux d'erreur < 2 % |
| CPU élevé | ECS CPUUtilization | > 80 % pendant 10 min | Ressources < 80 % |
| Disque RDS | RDS FreeStorageSpace | < 2 Go | Stockage suffisant |

**Notification SNS :**
Topic `mini-chat-alerts` → email immédiat dès qu'une alarme se déclenche.
Métriques observées en production : CPU max 16,2 % — RAM max 2,27 % — 0 alarme déclenchée.

---

## SLIDE 15 — KPI et SLA

**Titre :** Statistiques de services — KPI définis et mesurés

**Distinction des termes :**

| Terme | Exemple dans ce projet |
|-------|----------------------|
| Métrique brute | CPU à 12 %, 47 requêtes HTTP reçues, 3 messages envoyés |
| Indicateur | Taux d'erreurs 5xx sur 24h, temps de réponse moyen |
| KPI | Disponibilité mensuelle ≥ 99 %, p95 < 500 ms |
| SLA | Service accessible 99 % du temps, restauration < 2 heures |

**SLA couverts par les alarmes :**

| KPI | Objectif SLA | Alarme Cloud Monitoring |
|-----|-------------|-----------------|
| Disponibilité mensuelle | ≥ 99 % | instance count Cloud Run < 1 → ALARM + email |
| Taux d'erreurs HTTP | < 2 % de 5xx / 24h | HTTPCode_5XX > 10 → ALARM |
| Utilisation CPU | < 80 % | CPUUtilization > 80 % 10 min → ALARM |
| Stockage données | > 2 Go libres | FreeStorageSpace < 2 Go → ALARM |

---

## SLIDE 16 — Exemple de travail réalisé — Incident Mixed Content

**Titre :** Exemple significatif — Résolution d'un incident HTTPS

**Symptôme :**
Page HTTPS affichée, mais impossible de s'inscrire ou se connecter.
Console navigateur :
```
Mixed Content: The page at 'https://mini-chat-backend-py4vurg4oq-ew.a.run.app' was loaded over HTTPS,
but requested an insecure XMLHttpRequest endpoint 'http://mini-chat-backend-py4vurg4oq-ew.a.run.app:3000/auth/register'
```

**Démarche d'investigation (3 étapes) :**
1. Console navigateur → message Mixed Content → URL construite avec `http://` hardcodé
2. Lecture de `config.js` → `window.location.hostname` → reconstruction `http://hostname:3000`
3. Cause identifiée : en HTTPS, le navigateur bloque toute requête HTTP sortante

**Correction appliquée dans `config.js` :**
```javascript
const getApiUrl = () => {
  const hostname = window.location.hostname;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  return ''; // URLs relatives — compatibles HTTP local et HTTPS prod
};
```

**Leçon :** En production derrière un ALB, les URLs relatives suffisent. Hardcoder le protocole ou le port crée une dépendance fragile à l'environnement.

---

## SLIDE 17 — Exemple de recherche — Blocs `moved` Terraform

**Titre :** Exemple de recherche — Renommer des ressources Terraform sans les détruire

**Problème de départ :**
Migration Phase 1 → Phase 2 : renommage des Security Groups pour plus de lisibilité.
```
aws_security_group.alb  →  aws_security_group.alb_sg
```
Résultat du `terraform plan` :
```
# aws_security_group.alb will be destroyed   ← coupure de service !
# aws_security_group.alb_sg will be created
```

**Recherche effectuée :**
Documentation officielle Terraform sur la gestion du state.
Mots-clés : "rename resource terraform without destroy".
Découverte : **blocs `moved {}`** — introduits en Terraform 1.1.

**Solution — fichier `terraform/moved.tf` :**
```hcl
moved {
  from = aws_security_group.alb
  to   = aws_security_group.alb_sg
}
```
Terraform met à jour uniquement le state — aucune ressource AWS n'est détruite.

**Résultat :** 5 ressources renommées sans coupure, sans perte de données.

**2ème recherche :** Conflit `aws_db_subnet_group` en double dans le state → `terraform state rm` + `terraform import` intégrés dans le pipeline CI/CD.

---

## SLIDE 18 — Difficultés rencontrées et solutions

**Titre :** Difficultés réelles rencontrées — Comment elles ont été résolues

| Difficulté | Cause | Solution |
|------------|-------|----------|
| Containers EC2 ne démarraient pas | `user_data` asynchrone — scripts non terminés au déploiement | Migration Cloud Run : container démarré directement depuis Artifact Registry, plus de user_data |
| Renommage Terraform → destroy + recreate | Terraform interprète un renommage comme une destruction | Blocs `moved {}` dans moved.tf — state mis à jour sans toucher aux ressources AWS |
| DB Subnet Group en double dans le state | Double entrée Terraform après migration | `terraform state rm` + `terraform import` intégrés dans le pipeline |
| Schéma MySQL non initialisé sur RDS | init.sql uniquement local, RDS inaccessible | `initSchema()` non bloquant au démarrage du backend Node.js |
| Mixed Content bloquant toute l'appli | config.js construisait `http://hostname:3000` sur page HTTPS | URLs relatives vides en production — le navigateur gère le protocole |
| ECS en erreur après ajout HTTPS | ECS démarrait avant la création des listeners ALB | `depends_on = [aws_lb_listener.http, aws_lb_listener.https]` dans ecs.tf |

---

## SLIDE 19 — Évolution architecture et compétences couvertes

**Titre :** Évolution — Phase 1 EC2 vs Phase 2 Cloud Run

**Comparaison :**

| Critère | Phase 1 — EC2 | Phase 2 — Cloud Run |
|---------|--------------|----------------------|
| Déploiement | SSH + docker compose | git push → automatique |
| Secrets | .env en clair | Secret Manager (chiffré) AES-256 |
| Redémarrage si crash | Manuel | Automatique (Cloud Run Service) |
| SSH | Oui | Non — zéro |
| Traçabilité image | Aucune | Hash commit exact |
| Rolling update | Non — coupure | Oui — zéro downtime |
| Tests bloquants | Non | Oui — 9 Jest + 3 smoke tests |
| HTTPS | Non | Oui — ACM + TLS 1.3 |
| Alertes | Non | 4 alarmes Cloud Monitoring + SNS |

**Compétences ASD couvertes :**
Blocs 1, 2 et 3 — Infrastructure, Déploiement continu, Supervision.

---

## SLIDE 20 — Synthèse et conclusion

**Titre :** Synthèse et conclusion

**Satisfactions :**
- Architecture Cloud Run moderne — zéro gestion serveur, zéro SSH, zéro downtime
- Un seul `git push` déclenche tests, smoke tests, build et déploiement automatiquement
- Secrets 100 % sécurisés : du code source jusqu'au container en production
- HTTPS opérationnel sur domaine propre avec TLS 1.3
- Supervision active : 4 alarmes Cloud Monitoring liées aux SLA, notifications email SNS
- Traçabilité totale : on sait à tout moment quel commit exact tourne en production

**Difficultés principales :**
- Pipeline vert sur EC2 mais application silencieuse (user_data asynchrone)
- Mixed Content HTTPS bloquant toute l'application (URLs hardcodées)
- Terraform voulant détruire des ressources lors de simples renommages
- Container s'arrêtant immédiatement (RDS pas encore prêt au démarrage)

**Ce que j'ai appris :**
Cloud Run résout structurellement les problèmes de déploiement continu sur EC2.
Terraform est puissant mais exige une gestion rigoureuse du state dès qu'on refactorise.
Le frontend doit être pensé pour plusieurs environnements dès le départ (URLs relatives).

**Évolutions prévues :**
Auto Scaling Cloud Run (min 1 / max 3) · Environnement staging · ECR Lifecycle Policy

---

*Présentation Soutenance ASD Niveau 6 — Babikir Ibrahim — Mai 2026*
*Référentiel RE TP-01414-01 — Canevas diaporama officiel respecté intégralement*
*github.com/babs235/mini-chat — https://mini-chat-backend-py4vurg4oq-ew.a.run.app*
