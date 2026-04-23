const express = require("express");
const router = express.Router();
const db = require("../config/database");
const verifyToken = require("../middleware/auth");
const { messagesCreated } = require("../middleware/metrics");

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
router.post("/", verifyToken, async (req, res) => {

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

  try {
    const sql = "INSERT INTO messages (user_id, message) VALUES (?, ?)";
    
    // FIX P0: Pool promise - async/await
    await db.query(sql, [user_id, safeMessage]);

    // 🔥 Incrémenter le compteur de messages
    messagesCreated.inc();

    res.json({ message: "Message envoyé" });

  } catch (err) {
    console.error("Erreur envoi message:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }

});

// récupérer messages sécurisé
router.get("/", verifyToken, async (req, res) => {

  try {
    const sql = `
      SELECT messages.id, users.username, messages.message
      FROM messages
      JOIN users ON messages.user_id = users.id
      ORDER BY messages.id ASC
    `;

    // FIX P0: Pool promise - async/await
    const [results] = await db.query(sql);

    res.json(results);

  } catch (err) {
    console.error("Erreur récupération messages:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }

});

module.exports = router;