const express = require("express");
const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

// Middleware JSON
app.use(express.json());

// Routes d'authentification
app.use("/auth", authRoutes);

// Routes pour les messages
// Toutes les routes dans messages.js seront sous "/messages"
app.use("/messages", messagesRoutes);

// Route test
app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lancé sur le port 3000");
});