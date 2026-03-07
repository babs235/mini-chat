const express = require("express"); // On importe le framework Express
const router = express.Router();    // On crée un mini-système de routage spécifique à l'auth
const authController = require("../controllers/authController"); // On importe la logique de calcul

// Route pour l'inscription : quand on envoie des données à /auth/register
// On utilise .post car on envoie des informations sensibles (mot de passe)
router.post("/register", authController.register);

// Route pour la connexion : quand on envoie des données à /auth/login
router.post("/login", authController.login);

// On exporte ce "pack" de routes pour que server.js puisse l'utiliser
module.exports = router;