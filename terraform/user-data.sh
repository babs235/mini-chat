#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Cloner le repo et lancer l'app
cd /home/ubuntu
git clone https://github.com/babs235/mini-chat.git
cd mini-chat/docker
docker compose up -d
