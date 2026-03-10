const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

// Autoriser les requêtes externes
app.use(cors());

// Lire le JSON des requêtes
app.use(express.json());

// Routes API
app.use("/auth", authRoutes);
app.use("/messages", messagesRoutes);

// Servir le frontend
app.use(express.static(path.join(__dirname, "frontend")));

// Route test
app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lancé sur le port 3000");
});