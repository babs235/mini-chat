const express = require("express");
const router = express.Router();
const db = require("../config/database");


// envoyer un message
router.post("/", (req, res) => {

  const { user_id, message } = req.body;

  const sql = "INSERT INTO messages (user_id, message) VALUES (?, ?)";

  db.query(sql, [user_id, message], (err, result) => {

    if (err) {
      console.error(err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json({ message: "Message envoyé avec succès" });

  });

});


// récupérer tous les messages
router.get("/", (req, res) => {

  const sql = `
  SELECT messages.id, users.username, messages.message, messages.created_at
  FROM messages
  JOIN users ON messages.user_id = users.id
  ORDER BY messages.created_at ASC
  `;

  db.query(sql, (err, results) => {

    if (err) {
      console.error(err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json(results);

  });

});


module.exports = router;