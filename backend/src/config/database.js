const mysql = require("mysql2");

// 🔥 POOL de connexions - évite les déconnexions par inactivité
const pool = mysql.createPool({
  host: "db",
  user: "root",
  password: "123456",
  database: "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // 🔥 Reconnexion auto si déconnecté
  reconnect: true,
  // 🔥 Teste la connexion avant de l'utiliser
  testOnBorrow: true
});

// Test initial de connexion
pool.getConnection((err, conn) => {
  if (err) {
    console.error("❌ Erreur connexion MySQL :", err);
    return;
  }
  console.log("✅ Connexion MySQL Pool réussie");
  conn.release();
});

// Gestion des erreurs du pool
pool.on('error', (err) => {
  console.error('💥 Erreur MySQL Pool:', err.message);
});

module.exports = pool.promise();