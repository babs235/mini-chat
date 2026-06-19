const mysql = require("mysql2");

// Pool de connexions — MySQL réutilise les connexions plutôt que d'en créer une par requête
// DB_SOCKET_PATH : connexion via socket Unix (Cloud Run + Cloud SQL Auth Proxy)
// DB_HOST        : connexion TCP classique (développement local avec Docker Compose)
const poolConfig = {
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

if (process.env.DB_SOCKET_PATH) {
  poolConfig.socketPath = process.env.DB_SOCKET_PATH;
} else {
  poolConfig.host = process.env.DB_HOST || "db";
}

const pool = mysql.createPool(poolConfig);

// Gestion silencieuse des déconnexions — le pool se reconnecte automatiquement
pool.on("error", (err) => {
  if (err.code === "PROTOCOL_CONNECTION_LOST" || err.code === 4031) {
    console.log("MySQL disconnected - pool will reconnect automatically");
    return;
  }
  console.error("MySQL pool error:", err.message);
});

const db = pool.promise();

// Crée les tables si elles n'existent pas — lancé une fois au démarrage
async function initSchema() {
  await db.execute(`
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      username VARCHAR(50) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await db.execute(`
    CREATE TABLE IF NOT EXISTS messages (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT,
      message TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  `);
  console.log("Schema initialized");
}

initSchema().catch((err) => console.error("Schema init failed:", err.message));

module.exports = db;
