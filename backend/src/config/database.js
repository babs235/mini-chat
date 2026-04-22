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
  // FIX: Keep connections alive (ping toutes les 10 sec)
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
  // FIX: Timeout de connexion plus court pour retry rapide
  connectTimeout: 10000,
  // FIX: Idle timeout avant de fermer une connexion (doit être < wait_timeout MySQL)
  idleTimeout: 600000, // 10 minutes (MySQL par défaut est 8h, mais Docker le réduit)
  // Reconnexion auto si déconnecté
  reconnect: true,
  // Teste la connexion avant de l'utiliser
  testOnBorrow: true
});

// FIX: Gestion propre des erreurs de connexion
pool.on('connection', (conn) => {
  console.log('✅ Nouvelle connexion MySQL établie');
});

pool.on('error', (err) => {
  console.error(' Erreur MySQL Pool:', err.message);
  // Ne pas crasher - le pool va retry automatiquement
});

// Test initial de connexion
pool.getConnection((err, conn) => {
  if (err) {
    console.error(" Erreur connexion MySQL initiale:", err.message);
    return;
  }
  console.log(" Connexion MySQL Pool réussie");
  conn.release();
});

module.exports = pool.promise();