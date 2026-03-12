const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

app.use(cors());
app.use(express.json());

// API routes
app.use("/auth", authRoutes);
app.use("/messages", messagesRoutes);

// servir le frontend
app.use(express.static(path.join(__dirname, "frontend")));

app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lancé sur le port 3000");
});