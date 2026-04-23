#!/bin/bash

# Script de backup de la base de données MySQL
# Usage: ./scripts/backup-mysql.sh <IP_AWS> <CHEF_CLE_SSH> [--setup-cron]

set -e

IP_AWS=$1
SSH_KEY=$2
SETUP_CRON=$3
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mini_chat_backup_$DATE.sql"

if [ -z "$IP_AWS" ] || [ -z "$SSH_KEY" ]; then
    echo "Usage: $0 <IP_AWS> <CHEF_CLE_SSH> [--setup-cron]"
    exit 1
fi

# Configuration automatique de cron si demandé
if [ "$SETUP_CRON" = "--setup-cron" ]; then
    echo "Configuration automatique de cron..."
    CRON_JOB="0 2 * * * /home/ubuntu/mini-chat/scripts/backup-mysql.sh $IP_AWS ~/.ssh/mini-chat-key.pem"
    ssh -i "$SSH_KEY" ubuntu@$IP_AWS "(crontab -l 2>/dev/null | grep -v 'backup-mysql'; echo '$CRON_JOB') | crontab -"
    echo "Cron configure pour un backup quotidien a 2h du matin"
fi

echo "Backup de la base de donnees MySQL sur $IP_AWS"

# Creer le repertoire de backups sur le serveur
echo "Creation du repertoire de backups..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "mkdir -p $BACKUP_DIR"

# Effectuer le backup
echo "Execution du backup..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "docker exec docker_db_1 mysqldump -u root -p\$(grep MYSQL_ROOT_PASSWORD /home/ubuntu/mini-chat/docker/.env | cut -d'=' -f2) mini_chat > $BACKUP_DIR/$BACKUP_FILE"

# Compresser le backup
echo "Compression du backup..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "gzip $BACKUP_DIR/$BACKUP_FILE"

# Telecharger le backup localement
echo "Telechargement du backup..."
mkdir -p backups
scp -i "$SSH_KEY" ubuntu@$IP_AWS:$BACKUP_DIR/${BACKUP_FILE}.gz ./backups/

# Nettoyer les vieux backups (garder les 7 derniers)
echo "Nettoyage des vieux backups..."
ssh -i "$SSH_KEY" ubuntu@$IP_AWS "cd $BACKUP_DIR && ls -t mini_chat_backup_*.sql.gz | tail -n +8 | xargs -r rm"

echo "Backup termine: ./backups/${BACKUP_FILE}.gz"
