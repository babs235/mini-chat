const mysql = require("mysql2");

// POOL de connexions - évite les déconnexions par inactivité
const pool = mysql.createPool({
  host: "db",
  user: "root",
  password: "123456",
  database: "mini_chat",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// 🔥 FIX CRITIQUE: Gestion des erreurs sans crash
pool.on('error', (err) => {
  if (err.code === 'PROTOCOL_CONNECTION_LOST' || err.code === 4031) {
    console.log('🔄 MySQL déconnecté par inactivité - le pool va recréer une connexion');
    // Le pool recrée automatiquement une nouvelle connexion pour la prochaine requête
    return;
  }
  console.error('💥 Erreur MySQL Pool:', err.message);
});

// Test initial
pool.getConnection((err, conn) => {
  if (err) {
    console.error("❌ Erreur initiale:", err.message);
    return;
  }
  console.log("✅ Pool MySQL prêt");
  conn.release();
});

module.exports = pool.promise();