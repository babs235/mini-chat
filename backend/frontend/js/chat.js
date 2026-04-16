const API = "http://13.38.35.35:3000";

const token = localStorage.getItem("token");
const username = localStorage.getItem("username");

// 🔥 Vérifier connexion
if (!token) {
  window.location.href = "index.html";
}

document.getElementById("welcome").innerText =
  "Connecté en tant que : " + username;

//  Charger messages
async function loadMessages() {
  try {
    const res = await fetch(`${API}/messages`, {
      headers: { "Authorization": token }
    });
    const data = await res.json();

    const list = document.getElementById("messages");
    list.innerHTML = "";

    data.forEach(msg => {
      const li = document.createElement("li");
      li.textContent = `${msg.username} : ${msg.message}`;
      list.appendChild(li);
    });

  } catch (err) {
    console.error(err);
  }
}

// 🔹 Envoyer message
async function sendMessage() {
  const message = document.getElementById("messageInput").value;
  if (!message.trim()) return;

  try {
    await fetch(`${API}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": token
      },
      body: JSON.stringify({ message })
    });
    document.getElementById("messageInput").value = "";
    loadMessages();

  } catch (err) {
    console.error(err);
  }
}

// 🔹 Déconnexion
function logout() {
  localStorage.removeItem("token");
  localStorage.removeItem("username");
  window.location.href = "index.html";
}

// 🔹 Chargement initial
loadMessages();
setInterval(loadMessages, 3000);