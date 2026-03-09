const express = require("express");
const router = express.Router();
const db = require("../config/database"); // connexion MySQL

// --- POST /messages : envoyer un message ---
router.post("/", (req, res) => {
  const { user_id, message } = req.body;
  db.query(
    "INSERT INTO messages (user_id, message) VALUES (?, ?)",
    [user_id, message],
    (err, result) => {
      if (err) return res.status(500).json({ error: "Erreur serveur" });
      res.json({ message: "Message envoyé avec succès" });
    }
  );
});

// --- GET /messages : récupérer tous les messages ---
router.get("/", (req, res) => {
  const sql = `
    SELECT messages.id, users.username, messages.message, messages.created_at
    FROM messages
    JOIN users ON messages.user_id = users.id
    ORDER BY messages.created_at ASC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: "Erreur serveur" });
    res.json(results);
  });
});

// --- GET /messages/:userId : récupérer messages d'un utilisateur spécifique ---
router.get("/:userId", (req, res) => {
  const userId = req.params.userId;
  const sql = `
    SELECT messages.id, users.username, messages.message, messages.created_at
    FROM messages
    JOIN users ON messages.user_id = users.id
    WHERE users.id = ?
    ORDER BY messages.created_at ASC
  `;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: "Erreur serveur" });
    res.json(results);
  });
});

module.exports = router;