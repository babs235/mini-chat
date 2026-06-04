# Mini-Chat — Application de Messagerie Cloud-Native

**Projet de certification RNCP 36061 — Administrateur Système DevOps — Niveau 6**

[![CI/CD](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml)

**Production :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app

---

## Architecture

```
Développeur
    │  git push main
    ▼
GitHub Actions (4 jobs séquentiels)
    ├── Job 1 : Tests Jest (10 tests unitaires)
    ├── Job 2 : docker build → push Artifact Registry :sha-commit
    ├── Job 3 : Smoke tests HTTP sur image réelle
    └── Job 4 : terraform apply → Cloud Run déploie la nouvelle version
                    │
                    ▼
        Google Cloud Platform — europe-west1 (Belgique)
        ┌──────────────────────────────────────────────────┐
        │                                                  │
        │  Internet ──HTTPS──► [Cloud Run :3000]           │
        │                           │                      │
        │                  port 3306 (socket Unix)         │
        │                           ▼                      │
        │              [Cloud SQL MySQL 8.0]               │
        │                                                  │
        │  [Cloud Logging + 2 Alertes] ──► [Email]         │
        └──────────────────────────────────────────────────┘
```

---

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| Backend | Node.js 20 + Express 5 |
| Frontend | HTML5 / CSS3 / JavaScript vanilla |
| Base de données | MySQL 8.0 (Google Cloud SQL) |
| Authentification | JWT + bcrypt |
| Conteneurisation | Docker multi-stage Alpine |
| Registre d'images | Google Artifact Registry |
| Orchestration | Google Cloud Run (serverless) |
| Infrastructure as Code | Terraform 1.5+ (provider GCP) |
| Pipeline CI/CD | GitHub Actions (4 jobs) |
| Secrets | Google Secret Manager |
| Supervision | Google Cloud Monitoring + alertes email |
| État Terraform | Google Cloud Storage (`mini-chat-asd-tfstate`) |

---

## Compétences ASD couvertes (RE TP-01414-01)

| Bloc | Compétence | Mise en œuvre |
|------|-----------|---------------|
| BC01 | Automatiser la création de serveurs | Terraform IaC — 5 fichiers HCL |
| BC01 | Automatiser le déploiement d'une infrastructure | GitHub Actions Job 4 — `terraform apply` |
| BC01 | Sécuriser l'infrastructure | Secret Manager, IAM, HTTPS, pas de SSH |
| BC01 | Mettre en production dans le cloud | Cloud Run GCP europe-west1 |
| BC02 | Préparer un environnement de test | Jest 10 tests + smoke tests CI/CD |
| BC02 | Gérer le stockage des données | Cloud SQL MySQL, socket Unix, backup |
| BC02 | Gérer des containers | Docker multi-stage, Artifact Registry, Cloud Run |
| BC02 | Automatiser la mise en production | Pipeline 4 jobs — push = déploiement complet |
| BC03 | Définir des statistiques de services | 2 alarmes Cloud Monitoring (uptime + 5xx) |
| BC03 | Exploiter une solution de supervision | Cloud Logging + alertes email |

---

## Démarrage local

```bash
git clone https://github.com/babs235/mini-chat.git
cd mini-chat

# Créer le fichier de config local
cat > backend/.env << EOF
DB_HOST=db
DB_USER=root
DB_PASSWORD=local_password
DB_NAME=mini_chat
JWT_SECRET=local_secret
NODE_ENV=development
EOF

# Lancer avec Docker Compose
cd docker && docker compose up --build

# Application disponible sur http://localhost:3000
```

---

## Tests

```bash
cd backend
npm install
npm test              # 10 tests unitaires Jest
npm test -- --coverage  # avec rapport de couverture (~60% lignes)
```

---

## Déploiement production

Le déploiement est **entièrement automatisé** via GitHub Actions.

**Secrets GitHub requis :**

| Secret | Description |
|--------|-------------|
| `GCP_SA_KEY` | Clé JSON du compte de service GCP (base64) |
| `DB_PASSWORD` | Mot de passe Cloud SQL MySQL |
| `JWT_SECRET` | Clé de signature JWT |

**Déclencher un déploiement :**
```bash
git push origin main
# → Tests → Build Artifact Registry → Smoke tests → terraform apply → Cloud Run
```

---

## Structure du projet

```
mini-chat/
├── .github/workflows/
│   └── ci-cd.yml              # Pipeline CI/CD 4 jobs
├── backend/
│   ├── src/
│   │   ├── config/database.js # Pool MySQL (TCP ou socket Unix)
│   │   ├── middleware/auth.js  # Vérification JWT
│   │   └── routes/            # auth.js + messages.js
│   ├── frontend/              # HTML/CSS/JS
│   ├── tests/app.test.js      # Tests Jest
│   └── dockerfile.backend     # Multi-stage Alpine
├── docker/
│   └── docker-compose.yml     # Env local
├── terraform/
│   ├── provider.tf            # GCP + backend GCS
│   ├── main.tf                # Artifact Registry + Cloud SQL + Secret Manager
│   ├── cloudrun.tf            # Cloud Run service
│   ├── monitoring.tf          # Alertes Cloud Monitoring
│   ├── variables.tf
│   └── outputs.tf
└── README.md
```

---

**Babikir Ibrahim — Formation ASD Niveau 6 — 2026**
