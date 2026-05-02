const mysql = require("mysql2");

// POOL de connexions - évite les déconnexions par inactivité
const pool = mysql.createPool({
  host: process.env.DB_HOST || "db",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// FIX CRITIQUE: Gestion des erreurs sans crash
pool.on('error', (err) => {
  if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 4031) {
    console.log(' MySQL déconnecté par inactivité - le pool va recréer une connexion');
    // Le pool recrée automatiquement une nouvelle connexion pour la prochaine requête
    return;
  }
  console.error('💥 Erreur MySQL Pool:', err.message);
});

const db = pool.promise();

// Crée les tables si elles n'existent pas encore (migration au démarrage)
async function initSchema() {
  await db.execute(`
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      username VARCHAR(50) NOT NULL,
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
  console.log("✅ Schema OK");
}

initSchema().catch((err) => console.error("❌ Schema init:", err.message));

module.exports = db;