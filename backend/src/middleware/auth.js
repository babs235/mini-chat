const jwt = require("jsonwebtoken");

const SECRET = process.env.JWT_SECRET;

// Middleware JWT : bloque les routes si le token est absent ou invalide
function verifyToken(req, res, next) {
  const token = req.headers["authorization"];

  if (!token) {
    return res.status(403).json({ error: "Token manquant" });
  }

  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded; // userId et username disponibles dans les routes suivantes
    next();
  } catch (err) {
    return res.status(401).json({ error: "Token invalide" });
  }
}

module.exports = verifyToken;
