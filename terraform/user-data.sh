#!/bin/bash
# ============================================================
# user-data.sh - Script de démarrage du serveur EC2
# ============================================================
# Ce script s'exécute automatiquement au premier démarrage
# Il installe Docker, clone le repo et lance l'application
# ============================================================

# Mettre à jour les paquets
apt-get update

# Installer Docker et Docker Compose
apt-get install -y docker.io docker-compose-plugin

# Ajouter l'utilisateur ubuntu au groupe docker (pas besoin de sudo)
usermod -aG docker ubuntu

# Activer et démarrer Docker
systemctl enable docker
systemctl start docker

# Installer AWS CLI (pour les scripts de backup)
apt-get install -y awscli

# Cloner le repo et lancer l'application
cd /home/ubuntu
git clone https://github.com/babs235/mini-chat.git
cd mini-chat/docker
cp .env.example .env
docker compose up -d
