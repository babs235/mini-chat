const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, () => {
  console.log("Serveur lance sur le port 3000");
});