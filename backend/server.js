const express = require("express");
const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

// Middleware pour lire le JSON des requêtes
app.use(express.json());

// Routes d'authentification
app.use("/auth", authRoutes);

// Routes pour les messages
app.use(messagesRoutes);

// Route test
app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lance sur le port 3000");
});