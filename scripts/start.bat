@echo off 
echo Lancement du Backend...
cd backend
start cmd /k "node server.js"

echo Lancement de la base donnees Mysql (manuelle ou via docker)...
pause