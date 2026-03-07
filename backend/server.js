const express = require("express");
const app = express();
const authRoutes = require("./src/routes/auth");

// Middleware pour lire le JSON des requêtes
app.use(express.json());

// Routes d'authentification
app.use("/auth", authRoutes);

// Route test
app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lance sur le port 3000");
});