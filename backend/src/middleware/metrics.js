// Import prom-client
const client = require("prom-client");

// Création du registre
const register = new client.Registry();

// Ajouter métriques système (CPU, RAM…)
client.collectDefaultMetrics({ register });

// Compteur de requêtes HTTP
const httpRequests = new client.Counter({
  name: "http_requests_total",
  help: "Nombre total de requêtes HTTP"
});

// 🔥 NOUVEAU : Gauge pour utilisateurs actifs
const activeUsersGauge = new client.Gauge({
  name: "active_users",
  help: "Nombre d'utilisateurs actuellement connectés (avec token valide)"
});

// 🔥 NOUVEAU : Counter pour messages créés
const messagesCreated = new client.Counter({
  name: "messages_created_total",
  help: "Nombre total de messages créés"
});

// Enregistrer les métriques
register.registerMetric(httpRequests);
register.registerMetric(activeUsersGauge);
register.registerMetric(messagesCreated);

// 🔥 FIX P0: Map avec timestamp pour éviter fuites mémoire
const activeUsersMap = new Map();

// Nettoyage périodique des users inactifs (toutes les 30 sec)
setInterval(() => {
  const now = Date.now();
  const TIMEOUT = 5 * 60 * 1000; // 5 minutes
  let changed = false;
  
  for (const [token, timestamp] of activeUsersMap.entries()) {
    if (now - timestamp > TIMEOUT) {
      activeUsersMap.delete(token);
      changed = true;
    }
  }
  
  if (changed) {
    activeUsersGauge.set(activeUsersMap.size);
    console.log(`🧹 Nettoyage users: ${activeUsersMap.size} actifs`);
  }
}, 30000); // 30 secondes

// Middleware qui s'exécute à chaque requête
const metricsMiddleware = (req, res, next) => {
  httpRequests.inc(); // +1 à chaque requête
  next();
};

// 🔥 FIX P0 : Middleware pour tracker les users actifs (sans fuite mémoire)
const trackActiveUsers = (req, res, next) => {
  const token = req.headers["authorization"];
  
  if (token) {
    // Mettre à jour le timestamp (refresh l'activité)
    activeUsersMap.set(token, Date.now());
    
    // Mettre à jour la métrique Prometheus
    activeUsersGauge.set(activeUsersMap.size);
  }
  
  next();
};

// Export
module.exports = {
  register,
  metricsMiddleware,
  trackActiveUsers,
  messagesCreated  // 🔥 Exporté pour l'utiliser dans messages.js
};