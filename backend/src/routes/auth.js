const express = require("express");
const router = express.Router();
const db = require("../config/database");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");

const SECRET = process.env.JWT_SECRET;

router.post("/register", async (req, res) => {
  let { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: "Username et password requis" });
  }

  username = username.trim();

  if (username.length < 3 || username.length > 20) {
    return res.status(400).json({ error: "Username: 3-20 caractères" });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: "Mot de passe: min 6 caractères" });
  }

  // Bloque les caractères spéciaux pour éviter les injections XSS
  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return res.status(400).json({ error: "Username: lettres, chiffres, _ uniquement" });
  }

  try {
    // bcrypt avec 10 rounds : bon équilibre sécurité/performance
    const hashedPassword = await bcrypt.hash(password, 10);
    await db.query("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashedPassword]);
    res.json({ message: "Utilisateur créé" });
  } catch (err) {
    console.error("Erreur register:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

router.post("/login", async (req, res) => {
  const { username, password } = req.body;

  try {
    const [results] = await db.query("SELECT * FROM users WHERE username = ?", [username]);

    if (results.length === 0) {
      return res.status(401).json({ error: "Utilisateur introuvable" });
    }

    const user = results[0];
    const valid = await bcrypt.compare(password, user.password);

    if (!valid) {
      return res.status(401).json({ error: "Mot de passe incorrect" });
    }

    // Token valable 1h — contient userId et username pour les routes protégées
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      SECRET,
      { expiresIn: "1h" }
    );

    res.json({ token, username: user.username });
  } catch (err) {
    console.error("Erreur login:", err);
    res.status(500).json({ error: "Erreur serveur" });
  }
});

module.exports = router;
