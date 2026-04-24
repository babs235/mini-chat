#!/bin/bash

# Script de déploiement avec backup automatique
# Usage: ./scripts/deploy-with-backup.sh <IP_AWS> <CHEF_CLE_SSH>

set -e

IP_AWS=$1
SSH_KEY=$2

if [ -z "$IP_AWS" ] || [ -z "$SSH_KEY" ]; then
    echo "Usage: $0 <IP_AWS> <CHEF_CLE_SSH>"
    exit 1
fi

echo "Deploiement avec backup automatique sur $IP_AWS"

# 1. Backup de la base de donnees
echo "Step 1: Backup de la base de donnees..."
./scripts/backup-mysql.sh $IP_AWS $SSH_KEY

# 2. Git pull
echo "Step 2: Mise a jour du code..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "cd /home/ubuntu/mini-chat && git pull"

# 3. Redemarrage des containers
echo "Step 3: Redemarrage des containers..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "cd /home/ubuntu/mini-chat/docker && docker-compose down && docker-compose up -d --build"

# 4. Verification du statut
echo "Step 4: Verification du statut..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "cd /home/ubuntu/mini-chat/docker && docker ps"

echo "Deploiement termine avec succes!"
