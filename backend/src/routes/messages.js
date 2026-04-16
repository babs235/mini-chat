const express = require("express");
const router = express.Router();
const db = require("../config/database");
const verifyToken = require("../middleware/auth");

// 🔒 Fonction d'échappement XSS
function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");

}

// envoyer message sécurisé
router.post("/", verifyToken, (req, res) => {

  const message = req.body.message;

  // Validation : message requis et taille limitée
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: "Message invalide" });
  }

  if (message.length > 500) {
    return res.status(400).json({ error: "Message trop long (max 500 caractères)" });
  }

  // Échappement XSS
  const safeMessage = escapeHtml(message.trim());

  //  récupéré depuis le token
  const user_id = req.user.userId;

  const sql = "INSERT INTO messages (user_id, message) VALUES (?, ?)";

  db.query(sql, [user_id, safeMessage], (err) => {

    if (err) {
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json({ message: "Message envoyé" });

  });

});


// récupérer messages sécurisé
router.get("/", verifyToken, (req, res) => {

  const sql = `
    SELECT messages.id, users.username, messages.message
    FROM messages
    JOIN users ON messages.user_id = users.id
    ORDER BY messages.id ASC
  `;

  db.query(sql, (err, results) => {

    if (err) {
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json(results);

  });

});

module.exports = router;