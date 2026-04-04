const mysql = require("mysql2");

const connection = mysql.createConnection({
  host: "db",
  user: "root",
  password: "123456",
  database: "mini_chat"
});

connection.connect((err) => {
  if (err) {
    console.error("Erreur connexion MySQL :", err);
    return;
  }
  console.log("Connexion MySQL réussie");
});

module.exports = connection;