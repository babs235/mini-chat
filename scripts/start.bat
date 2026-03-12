@echo off
REM =========================
REM Script d'automatisation pour mini-chat (Windows natif)
REM =========================
REM Auteur : toi
REM Description :
REM   - Arrête et supprime les conteneurs existants
REM   - Reconstruit les images Docker
REM   - Lance les conteneurs en arrière-plan
REM   - Vérifie rapidement que le backend et l'API messages répondent
REM   - Affiche les logs du backend
REM =========================

cd /d "..\docker"
echo === Arrêt et suppression des conteneurs ===
docker compose down

echo === Lancement des conteneurs en arrière-plan ===
docker compose up --build -d

REM Pause courte pour laisser le backend démarrer
timeout /t 5 >nul

echo === Vérification du backend ===
curl http://localhost:3000/

echo === Vérification de l'API messages ===
curl http://localhost:3000/messages

echo === Affichage des logs backend ===
docker compose logs -f backend

pause