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

// Enregistrer le compteur
register.registerMetric(httpRequests);

// Middleware qui s'exécute à chaque requête
const metricsMiddleware = (req, res, next) => {
  httpRequests.inc(); // +1 à chaque requête
  next();
};

// Export
module.exports = {
  register,
  metricsMiddleware
};