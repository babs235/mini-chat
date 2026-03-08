const bcrypt = require("bcrypt");
const db = require("../config/database"); // Importation de la connexion à MySQL

// --- FONCTION D'INSCRIPTION (REGISTER) ---
exports.register = async (req, res) => {
    // 1. On récupère les infos envoyées par l'utilisateur
    const { username, password } = req.body;

    try {
        // 2. Sécurité : On hache le mot de passe avant de l'enregistrer
        const hashedPassword = await bcrypt.hash(password, 10);

        // 3. Préparation de la requête SQL (les "?" évitent les injections SQL)
        const query = "INSERT INTO users (username, password) VALUES (?, ?)";

        // 4. Exécution de la requête dans la base de données
        db.query(query, [username, hashedPassword], (err, result) => {
            if (err) {
                // Si une erreur survient (ex: pseudo déjà pris), on renvoie une erreur 500
                return res.status(500).json({ error: "Erreur lors de l'insertion", details: err });
            }

            // 5. Succès : On renvoie l'ID que MySQL a généré pour cet utilisateur
            res.json({
                message: "Utilisateur créé avec succès",
                userId: result.insertId
            });
        });
    } catch (error) {
        res.status(500).json({ error: "Erreur serveur lors du hachage" });
    }
};

// --- FONCTION DE CONNEXION (LOGIN) ---
exports.login = (req, res) => {
    // 1. On récupère les identifiants saisis
    const { username, password } = req.body;

    // 2. On cherche si cet utilisateur existe dans la table 'users'
    const query = "SELECT * FROM users WHERE username = ?";

    db.query(query, [username], async (err, results) => {
        if (err) {
            return res.status(500).json({ error: "Erreur base de données" });
        }

        // 3. Vérification : Si le tableau results est vide, l'utilisateur n'existe pas
        if (results.length === 0) {
            return res.status(401).json({ message: "Utilisateur non trouvé" });
        }

        // 4. On récupère l'utilisateur trouvé
        const user = results[0];

        // 5. Comparaison : On compare le mot de passe saisi avec le hash stocké en base
        const match = await bcrypt.compare(password, user.password);

        if (!match) {
            // Si ça ne correspond pas, on refuse la connexion
            return res.status(401).json({ message: "Mot de passe incorrect" });
        }

        // 6. Succès : L'utilisateur est authentifié
        res.json({
            message: "Connexion réussie",
            userId: user.id,
            username: user.username
        });
    });
};