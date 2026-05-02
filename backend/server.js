const express = require("express");
const cors = require("cors");
const path = require("path");

const app = express();

const authRoutes = require("./src/routes/auth");
const messagesRoutes = require("./src/routes/messages");

app.use(cors());
app.use(express.json());

app.use("/auth", authRoutes);
app.use("/messages", messagesRoutes);

app.use(express.static(path.join(__dirname, "frontend")));

app.get("/", (req, res) => {
  res.send("Backend OK");
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Server started on port 3000");
});
