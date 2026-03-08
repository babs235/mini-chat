const express = require("express");
const router = express.Router();
const db = require("../config/database");

router.post("/messages", (req, res) => {
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

router.get("/messages", (req, res) => {
  const sql = "SELECT * FROM messages ORDER BY created_at ASC";

  db.query(sql, (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json(results);
  });
});

module.exports = router;