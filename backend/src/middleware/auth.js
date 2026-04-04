const jwt = require("jsonwebtoken");

const SECRET = "secretkey";

// 🔥 middleware qui protège les routes
function verifyToken(req, res, next) {

  const token = req.headers["authorization"];

  if (!token) {
    return res.status(403).json({ error: "Token manquant" });
  }

  try {
    const decoded = jwt.verify(token, SECRET);

    // 👉 on récupère userId depuis le token
    req.user = decoded;

    next();
  } catch (err) {
    return res.status(401).json({ error: "Token invalide" });
  }

}

module.exports = verifyToken;