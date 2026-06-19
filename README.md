# Mini-Chat 💬

> Application de messagerie temps réel déployée sur Google Cloud Platform avec un pipeline CI/CD complet.

[![CI/CD Pipeline](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml)
[![Node.js](https://img.shields.io/badge/Node.js-20_LTS-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform&logoColor=white)](https://terraform.io)
[![GCP](https://img.shields.io/badge/Google_Cloud-Cloud_Run-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/run)

**🚀 Live :** https://mini-chat-backend-py4vurg4oq-ew.a.run.app

---

## À propos

Mini-Chat permet à des utilisateurs de s'inscrire, se connecter, et s'envoyer des messages depuis un navigateur. L'application est intentionnellement simple — l'objectif réel est l'infrastructure : un pipeline CI/CD qui déploie automatiquement à chaque `git push`, une infrastructure 100% en code avec Terraform, des secrets sécurisés via Secret Manager, et une supervision avec alertes email.

**Un `git push` = tests → build → validation → déploiement en production. Automatiquement.**

---

## Stack

| | |
|---|---|
| **Backend** | Node.js 20 + Express 5 |
| **Base de données** | MySQL 8.0 sur Google Cloud SQL |
| **Auth** | JWT + bcrypt |
| **Container** | Docker multi-stage Alpine (~180 MB) |
| **Registry** | Google Artifact Registry |
| **Hosting** | Google Cloud Run (serverless) |
| **IaC** | Terraform — 6 fichiers HCL |
| **CI/CD** | GitHub Actions — 4 jobs |
| **Secrets** | Google Secret Manager |
| **Monitoring** | Cloud Monitoring + Cloud Logging |

---

## Pipeline CI/CD

```
git push main
      ↓
 ┌─ Job 1 ──────────────────────────────────┐
 │  npm test  →  10 tests Jest + Supertest  │
 │  ⛔ si KO : tout s'arrête                 │
 └──────────────────────────────────────────┘
      ↓
 ┌─ Job 2 ──────────────────────────────────┐
 │  docker build (multi-stage Alpine)       │
 │  push → Artifact Registry :SHA-commit   │
 └──────────────────────────────────────────┘
      ↓
 ┌─ Job 3 ──────────────────────────────────┐
 │  pull image réelle depuis Artifact Reg. │
 │  smoke tests : GET / → 200              │
 │               POST /register → 400      │
 │               GET /messages → 403       │
 └──────────────────────────────────────────┘
      ↓
 ┌─ Job 4 ──────────────────────────────────┐
 │  terraform apply                         │
 │  Cloud Run rolling update                │
 │  health check → si KO : rollback auto   │
 └──────────────────────────────────────────┘
```

---

## Architecture GCP

```
Internet ──HTTPS──► Cloud Run :3000
                         │
              socket Unix (Cloud SQL Auth Proxy)
                         │
                   Cloud SQL MySQL 8.0

Cloud Monitoring  →  2 alertes email
Cloud Logging     →  logs container temps réel
Secret Manager    →  DB_PASSWORD + JWT_SECRET
Artifact Registry →  images Docker
Cloud Storage     →  état Terraform
```

Le HTTPS est géré automatiquement par Cloud Run. La connexion Cloud SQL passe par un socket Unix authentifié par IAM — zéro port réseau exposé, zéro SSH.

---

## Lancer en local

```bash
git clone https://github.com/babs235/mini-chat.git
cd mini-chat

# Config
cp backend/.env.example backend/.env   # ou crée le .env manuellement

# Lancer
cd docker && docker compose up --build

# → http://localhost:3000
```

**Variables requises dans `backend/.env` :**
```env
DB_HOST=db
DB_USER=root
DB_PASSWORD=local_password
DB_NAME=mini_chat
JWT_SECRET=local_secret
NODE_ENV=development
```

---

## Tests

```bash
cd backend && npm test               # 10 tests Jest
npm test -- --coverage               # ~60% coverage
```

---

## Déploiement

**Secrets GitHub à configurer :**

| Secret | Valeur |
|---|---|
| `GCP_SA_KEY` | Clé JSON du compte de service (raw ou base64) |
| `DB_PASSWORD` | Mot de passe Cloud SQL |
| `JWT_SECRET` | Clé JWT |

```bash
git push origin main  # déclenche le pipeline complet (~8 min)
```

---

## Structure

```
mini-chat/
├── .github/workflows/ci-cd.yml     # Pipeline 4 jobs
├── backend/
│   ├── src/
│   │   ├── config/database.js      # Pool MySQL (socket ou TCP)
│   │   ├── middleware/auth.js      # Middleware JWT
│   │   └── routes/                 # auth.js · messages.js
│   ├── frontend/                   # HTML · CSS · JS
│   ├── tests/app.test.js           # Jest + Supertest
│   └── dockerfile.backend          # Multi-stage Alpine
├── docker/docker-compose.yml       # Dev local
└── terraform/
    ├── provider.tf                  # GCP + état GCS
    ├── main.tf                      # Cloud SQL · Secret Manager · IAM
    ├── cloudrun.tf                  # Cloud Run + injection secrets
    ├── monitoring.tf                # 2 alertes Cloud Monitoring
    ├── variables.tf
    └── outputs.tf
```

---

## Sécurité

- Secrets injectés depuis Secret Manager au démarrage — jamais dans le code ni dans les logs
- 2 comptes de service IAM séparés (infra vs application) — moindre privilège
- Requêtes SQL préparées partout — zéro concaténation
- Échappement HTML avant insertion en base — protection XSS
- Zéro SSH — Cloud Run est serverless

---

*Projet réalisé dans le cadre du Titre Professionnel Administrateur Système DevOps — Niveau 6 (RNCP 36061) — Ecole-IT d'Orléans — 2026*
