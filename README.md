#  Mini Chat App

##  Description

Mini Chat App est une application web permettant aux utilisateurs de s'inscrire, se connecter et échanger des messages en temps réel.
Le projet met en œuvre une architecture client-serveur avec authentification sécurisée via JWT.

---

## 🛠️ Stack Technique

* **Frontend** : HTML, CSS, JavaScript
* **Backend** : Node.js, Express
* **Base de données** : MySQL
* **Authentification** : JWT (JSON Web Token)
* **Temps réel** : Socket.io 
* **Conteneurisation** : Docker
* **Monitoring** : Prometheus, Grafana
* **Automatisation** : Ansible, Terraform


---

##  Fonctionnalités

* Inscription et connexion utilisateur
* Authentification sécurisée avec JWT
*  Envoi et affichage de messages
*  Rafraîchissement automatique des messages
*  Monitoring des requêtes (Prometheus)
* Visualisation des métriques (Grafana)

---

##  Architecture

* Le **frontend** communique avec le backend via API REST
* Le **backend** gère :

  * l'authentification
  * les messages
  * la connexion à la base de données
* Les routes `/messages` sont protégées via un middleware JWT
* Les données sont stockées dans MySQL

---

##  Structure du projet

```
backend/
│
├── server.js
├── src/
│   ├── routes/
│   │   ├── auth.js
│   │   └── messages.js
│   ├── middleware/
│   │   └── auth.js
│   └── config/
│       └── database.js
│
frontend/
│
├── index.html
├── messages.html
└── js/
    ├── auth.js
    └── chat.js
```

---

##  Installation

### 1️⃣ Cloner le projet

```bash
git clone <https://github.com/babs235/mini-chat.git>
cd projet
```

---

### 2️⃣ Installer les dépendances

```bash
cd backend
npm install
```

---

### 3️⃣ Configurer la base de données

Créer une base MySQL :

```sql
CREATE DATABASE chat_db;
```

Tables :

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255),
  password VARCHAR(255)
);

CREATE TABLE messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 4️ Lancer le serveur

```bash
node server.js
```

---

### 5️ Accéder à l'application
 http://localhost:3000

---

##  Sécurité

* Authentification via JWT
* Middleware de protection des routes
* Hashage des mots de passe avec bcrypt
* Protection contre accès non autorisé aux messages

---

##  Monitoring

* Prometheus collecte les métriques :

  * nombre de requêtes HTTP
  * CPU
  * mémoire
* Grafana permet de visualiser les données

---

## Automatisation (Ansible)

Ansible permet :

* d’installer automatiquement Docker
* de déployer l’application
* de lancer les conteneurs

---

##  Améliorations possibles

* WebSocket complet (temps réel sans refresh)
*  statut en ligne/offline
*  notifications en direct
*  protection XSS / SQL Injection
*  interface responsive

---

## Auteur

Projet réalisé dans le cadre de la formation développement web et pour le passage de mon titre RNCP 36061.

#  Project Backlog – Mini Chat App

##  To Do

* [ ] Improve UI design (CSS)
* [ ] Add real-time messaging (Socket.io)
* [ ] Display online users
* [ ] Add notifications system
* [ ] Implement XSS protection
* [ ] Implement CSRF protection
* [ ] Improve Terraform configuration (real cloud deployment)
* [ ] Deploy application online

---

##  In Progress

* [ ] JWT authentication integration
* [ ] Securing API routes
* [ ] Learning Terraform basics

---

## Done

* [x] Project setup (Node.js + Express)
* [x] Database connection (MySQL)
* [x] User registration
* [x] User login
* [x] Message sending
* [x] Message retrieval
* [x] Docker setup
* [x] Monitoring with Prometheus
* [x] Basic frontend pages
* [x] Introduction to Terraform (Infrastructure as Code)
* [x] Basic Ansible setup

---

