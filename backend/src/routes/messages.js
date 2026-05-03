const express = require("express");
const router = express.Router();
const db = require("../config/database");
const verifyToken = require("../middleware/auth");

// Neutralise les caractères HTML pour éviter les attaques XSS
function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

router.post("/", verifyToken, async (req, res) => {
  const message = req.body.message;

  if (!message || typeof message !== "string") {
    return res.status(400).json({ error: "Message invalide" });
  }

  if (message.length > 500) {
    return res.status(400).json({ error: "Message trop long (max 500 caracteres)" });
  }

  const safeMessage = escapeHtml(message.trim());
  const user_id = req.user.userId;

  try {
    await db.query("INSERT INTO messages (user_id, message) VALUES (?, ?)", [user_id, safeMessage]);
    res.json({ message: "Message envoye" });
  } catch (err) {
    console.error("Erreur envoi message:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

router.get("/", verifyToken, async (req, res) => {
  try {
    // Jointure pour récupérer le username avec chaque message
    const sql = `
      SELECT messages.id, users.username, messages.message, messages.created_at
      FROM messages
      JOIN users ON messages.user_id = users.id
      ORDER BY messages.id ASC
    `;
    const [results] = await db.query(sql);
    res.json(results);
  } catch (err) {
    console.error("Erreur recuperation messages:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

module.exports = router;
