// On importe la bibliothèque de sécurité pour le hachage
const bcrypt = require("bcrypt");

/**
 * LOGIQUE D'INSCRIPTION
 */
exports.register = async (req, res) => {
    // 1. On récupère les données envoyées dans le corps (body) de la requête
    const { username, password } = req.body;

    // 2. On "hache" le mot de passe (on le rend illisible)
    // Le chiffre 10 est le "salt round" : plus il est haut, plus c'est sécurisé mais lent
    const hashedPassword = await bcrypt.hash(password, 10);

    // 3. (Etape future) Ici on ajoutera la ligne pour sauvegarder dans MySQL
    console.log("Utilisateur à créer :", username);
    console.log("Mot de passe sécurisé :", hashedPassword);

    // 4. On répond au client pour dire que tout s'est bien passé
    res.json({
        message: "Utilisateur créé avec succès (simulation)",
        username: username,
        hash: hashedPassword // On l'affiche juste pour voir le résultat du hachage
    });
};

/**
 * LOGIQUE DE CONNEXION
 */
exports.login = async (req, res) => {
    // 1. On récupère ce que l'utilisateur a tapé dans le formulaire
    const { username, password } = req.body;

    // 2. (Etape future) On ira vérifier dans la base de données si le username existe
    
    // 3. On répond au client
    res.json({
        message: "Connexion réussie (simulation)",
        username: username
    });
};