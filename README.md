# Mini-Chat ASD - Application de Messagerie Temps Réel

**Projet de certification RNCP 36061 - Administrateur Système DevOps**

[![CI/CD](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml)

## Contexte

Ce projet est réalisé dans le cadre de la préparation au titre RNCP 36061 **Administrateur Système DevOps** (Niveau 6). Il démontre la maîtrise des compétences requises pour automatiser le déploiement d'infrastructures cloud, déployer en continu des applications et superviser les services déployés.

## Architecture du Projet

```
┌─────────────────────────────────────────────────────────────────┐
│                        UTILISATEUR                               │
└──────────────────────┬──────────────────────────────────────────┘
                       │ HTTPS (443)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   INSTANCE EC2 (AWS)                           │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    DOCKER ENGINE                         │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │   BACKEND    │  │  PROMETHEUS  │  │   GRAFANA    │   │  │
│  │  │   Node.js    │  │  Monitoring  │  │ Dashboards   │   │  │
│  │  │   Port 3000  │  │   Port 9090  │  │   Port 3001  │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────────────────────────┬────────────────────────────────────┘
                           │
                           │ MySQL (3306)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                 RDS MYSQL (AWS)                                │
│                    Base de données                             │
└─────────────────────────────────────────────────────────────────┘
```

## Blocs de Compétences Couverts (RNCP 36061)

### BC01 - Automatiser le déploiement d'une infrastructure dans le cloud

| Compétence | Justification | Fichier(s) |
|------------|---------------|------------|
| **CP1** - Scripts d'automatisation | Création de serveurs via scripts shell et Python | `scripts/start.sh`, `scripts/start.bat` |
| **CP2** - Infrastructure as Code | Déploiement automatisé avec Ansible | `ansible/playbook.yml`, `ansible/inventory` |
| **CP3** - Sécurisation | Hardening, gestion des accès, pare-feu | `ansible/playbook.yml` (configuration Docker) |
| **CP4** - Mise en production cloud | Déploiement AWS avec Terraform (en cours) | `terraform/` (à compléter) |

### BC02 - Déployer en continu une application

| Compétence | Justification | Fichier(s) |
|------------|---------------|------------|
| **CP5** - Environnement de test | Docker Compose avec isolation des services | `docker/docker-compose.yml` |
| **CP6** - Stockage des données | Volumes persistants MySQL, backups | `docker/docker-compose.yml` (volumes) |
| **CP7** - Conteneurs | Docker, Docker Compose, images optimisées | `backend/dockerfile.backend` |
| **CP8** - CI/CD | Pipeline GitHub Actions automatique | `.github/workflows/ci-cd.yml` |

### BC03 - Superviser les services déployés

| Compétence | Justification | Fichier(s) |
|------------|---------------|------------|
| **CP9** - Statistiques de services | Métriques Prometheus, KPI personnalisés | `backend/src/middleware/metrics.js` |
| **CP10** - Solution de supervision | Stack Prometheus + Grafana complète | `docker/prometheus.yml`, `docker/docker-compose.yml` |
| **CP11** - Communication professionnelle | Documentation technique, veille | Ce README |

## Stack Technique

### Infrastructure & DevOps
- **Conteneurisation** : Docker, Docker Compose
- **Automatisation** : Ansible
- **CI/CD** : GitHub Actions
- **Cloud** : AWS (EC2, RDS, VPC) - *via Terraform*
- **IaC** : Terraform

### Monitoring & Supervision
- **Métriques** : Prometheus
- **Visualisation** : Grafana
- **Métriques applicatives** : Middleware Node.js personnalisé

### Application
- **Backend** : Node.js, Express
- **Frontend** : HTML5, CSS3, JavaScript vanilla
- **Base de données** : MySQL 8
- **Authentification** : JWT (JSON Web Tokens)
- **Sécurité** : Bcrypt, middleware d'authentification

## Structure du Projet

```
mini-chat/
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # Pipeline CI/CD GitHub Actions
├── ansible/
│   ├── inventory                  # Inventaire des serveurs
│   └── playbook.yml               # Playbook de déploiement
├── backend/
│   ├── frontend/                  # Interface utilisateur (HTML/JS)
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js        # Configuration MySQL
│   │   ├── controllers/
│   │   │   └── authController.js  # Logique d'authentification
│   │   ├── middleware/
│   │   │   ├── auth.js            # Middleware JWT
│   │   │   └── metrics.js         # Middleware métriques Prometheus
│   │   └── routes/
│   │       ├── auth.js            # Routes auth (login/register)
│   │       └── messages.js        # Routes messages
│   ├── dockerfile.backend         # Dockerfile optimisé
│   ├── package.json
│   └── server.js                  # Point d'entrée Express
├── database/
│   └── init.sql                   # Schéma et données initiales
├── docker/
│   ├── docker-compose.yml         # Orchestration multi-services
│   └── prometheus.yml             # Configuration Prometheus
├── docs/
│   └── architecture.png           # Schéma d'architecture
├── scripts/
│   ├── start.bat                  # Script Windows
│   └── start.sh                   # Script Linux/Mac
├── terraform/                     # Infrastructure as Code (AWS)
├── .gitignore
└── README.md                      # Ce fichier
```

## Fonctionnalités

- **Authentification sécurisée** : Inscription/connexion avec JWT
- **Messagerie temps réel** : Envoi et affichage des messages
- **Monitoring complet** : Métriques applicatives et système
- **Déploiement automatisé** : Ansible + CI/CD
- **Architecture cloud-ready** : Prêt pour AWS avec Terraform

## Installation et Déploiement

### Prérequis

- Docker Engine 20.10+
- Docker Compose 2.0+
- Ansible 2.12+ (pour déploiement automatisé)
- AWS CLI (pour déploiement cloud)

### 1. Démarrage Rapide (Local)

```bash
# Cloner le repository
git clone https://github.com/babs235/mini-chat.git
cd mini-chat

# Lancer l'application avec Docker Compose
cd docker
docker compose up -d

# Accéder à l'application
# - Application : http://localhost:3000
# - Prometheus : http://localhost:9090
# - Grafana : http://localhost:3001
```

### 2. Déploiement avec Ansible

```bash
# Depuis la racine du projet
cd ansible

# Vérifier la syntaxe
ansible-playbook -i inventory playbook.yml --syntax-check

# Exécuter le déploiement (local)
ansible-playbook -i inventory playbook.yml

# Exécuter le déploiement (distant)
ansible-playbook -i inventory playbook.yml --ask-become-pass
```

### 3. Déploiement Cloud (AWS)

*À compléter avec Terraform*

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Monitoring et Supervision

### Métriques Disponibles

| Métrique | Type | Description |
|----------|------|-------------|
| `http_requests_total` | Compteur | Nombre total de requêtes HTTP |
| `http_request_duration_seconds` | Histogramme | Durée des requêtes |
| `nodejs_memory_usage` | Jauge | Utilisation mémoire Node.js |
| `mysql_connections` | Jauge | Connexions actives MySQL |

### Accès aux Dashboards

- **Prometheus** : http://localhost:9090
  - Requêtes PromQL pour analyse des métriques
  
- **Grafana** : http://localhost:3001
  - Login : `admin` / `admin`
  - Dashboards préconfigurés pour l'application

## CI/CD Pipeline

Le pipeline GitHub Actions comprend :

1. **Tests et Lint** : Vérification du code Node.js
2. **Build Docker** : Construction et test des images
3. **Validation Ansible** : Vérification syntaxique des playbooks

**Statut** : ![CI/CD](https://github.com/babs235/mini-chat/actions/workflows/ci-cd.yml/badge.svg)

## Sécurité

- **Authentification JWT** : Tokens signés avec expiration
- **Hashage des mots de passe** : Bcrypt avec salt
- **Protection des routes** : Middleware d'authentification
- **Injection SQL** : Requêtes paramétrées avec mysql2
- **CORS** : Configuration restrictive

## Roadmap et Points d'Attention pour le Jury

### ✅ Complété

- [x] Architecture 3 tiers (frontend, backend, database)
- [x] Conteneurisation Docker complète
- [x] CI/CD avec GitHub Actions
- [x] Monitoring Prometheus + Grafana
- [x] Automatisation Ansible (installation Docker, déploiement)
- [x] Documentation technique

### 🔄 En Cours

- [ ] Infrastructure Terraform AWS (EC2 + RDS)
- [ ] Dashboards Grafana avancés avec alerting
- [ ] Tests automatisés complémentaires

### 📋 À Venir

- [ ] Déploiement Kubernetes (EKS)
- [ ] Pipeline GitOps avec ArgoCD
- [ ] Sécurisation avancée (Vault, certificats SSL)

## Commandes Utiles

```bash
# Voir les logs
docker logs docker-backend-1 -f

# Redémarrer un service
docker compose restart backend

# Entrer dans un conteneur
docker exec -it docker-backend-1 /bin/bash

# Sauvegarder la base de données
docker exec docker-db-1 mysqldump -u root -p123456 mini_chat > backup.sql

# Exécuter Ansible en mode check (simulation)
ansible-playbook -i inventory playbook.yml --check
```

## Auteur

**Babikir IBRAHIM AL KHALIL**

Formation : Préparation titre RNCP 36061 - Administrateur Système DevOps  
Période : Février - Juin 2026  

---

## Ressources et Références

- [Documentation RNCP 36061](https://www.francecompetences.fr/recherche/rncp/36061/)
- [Docker Documentation](https://docs.docker.com/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**⚠️ Note pour le jury :** Ce projet est en cours d'évolution. Les éléments marqués "En Cours" ou "À Venir" font l'objet de développements en parallèle pour le passage devant jury de juillet 2026.
