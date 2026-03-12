#!/bin/bash
# =========================
# Script d'automatisation pour serveur mini-chat
# =========================
# Description :
#   - Arrête et supprime les conteneurs existants
#   - Reconstruit les images Docker
#   - Lance les conteneurs en arrière-plan
#   - Affiche les logs du backend
#   - Vérifie rapidement que le backend et l'API messages répondent
# =========================
cd /docker
echo "=== Arrêt et suppression des conteneurs existants ==="
docker compose down

echo "=== Construction et lancement des conteneurs ==="
docker compose up --build -d

# Pause courte pour laisser le backend démarrer
sleep 5

echo "=== Vérification du backend ==="
curl http://localhost:3000/

echo "=== Vérification de l'API messages ==="
curl http://localhost:3000/messages

echo "=== Affichage des logs du backend (CTRL+C pour quitter) ==="
docker compose logs -f backend