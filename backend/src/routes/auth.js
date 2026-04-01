const express = require("express");
const router = express.Router();
const db = require("../config/database");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");

const SECRET = "secretkey";

// 🔥 REGISTER
router.post("/register", async (req, res) => {

  const { username, password } = req.body;

  // hash du mot de passe
  const hashedPassword = await bcrypt.hash(password, 10);

  const sql = "INSERT INTO users (username, password) VALUES (?, ?)";

  db.query(sql, [username, hashedPassword], (err) => {

    if (err) {
      return res.status(500).json({ error: "Erreur serveur" });
    }

    res.json({ message: "Utilisateur créé" });

  });

});


// 🔥 LOGIN
router.post("/login", (req, res) => {

  const { username, password } = req.body;

  const sql = "SELECT * FROM users WHERE username = ?";

  db.query(sql, [username], async (err, results) => {

    if (results.length === 0) {
      return res.status(401).json({ error: "Utilisateur introuvable" });
    }

    const user = results[0];

    const valid = await bcrypt.compare(password, user.password);

    if (!valid) {
      return res.status(401).json({ error: "Mot de passe incorrect" });
    }

    // 🔥 création du token
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      SECRET,
      { expiresIn: "1h" }
    );

    res.json({
      token,
      username: user.username
    });

  });

});

module.exports = router;