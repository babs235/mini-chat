const express = require("express");
const cors = require("cors");
const path = require("path");

// 🔥 monitoring
const { register, metricsMiddleware } = require("./src/middleware/metrics");

const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

// middlewares
app.use(cors());
app.use(express.json());

// 🔥 compter les requêtes
app.use(metricsMiddleware);

// routes API
app.use("/auth", authRoutes);
app.use("/messages", messagesRoutes);

// servir le frontend
app.use(express.static(path.join(__dirname, "frontend")));

// route test
app.get("/", (req, res) => {
  res.send("Backend OK");
});

// 🔥 route metrics pour Prometheus
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// lancement serveur
app.listen(3000, () => {
  console.log("Serveur lancé sur le port 3000");
});