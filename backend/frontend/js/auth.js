const API = "http://13.38.35.35:3000";

// 🔹 INSCRIPTION
async function register() {
  const username = document.getElementById("registerUsername").value;
  const password = document.getElementById("registerPassword").value;

  try {
    const res = await fetch(`${API}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password })
    });

    const data = await res.json();
    alert(data.message);

    if (res.ok) {
      // revenir au login après inscription réussie
      showLogin();
    }

  } catch (err) {
    console.error(err);
    alert("Erreur serveur lors de l'inscription");
  }
}

// 🔹 LOGIN
async function login() {
  const username = document.getElementById("loginUsername").value;
  const password = document.getElementById("loginPassword").value;

  try {
    const res = await fetch(`${API}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username, password })
    });

    const data = await res.json();

    if (data.token) {
      // 🔑 Stocker le JWT et username
      localStorage.setItem("token", data.token);
      localStorage.setItem("username", data.username);
      window.location.href = "messages.html";
    } else {
      alert(data.error || "Connexion échouée");
    }

  } catch (err) {
    console.error(err);
    alert("Erreur serveur lors de la connexion");
  }
}

// 🔹 Affichage login/inscription
function showRegister() {
  document.getElementById("loginSection").style.display = "none";
  document.getElementById("registerSection").style.display = "block";
}

function showLogin() {
  document.getElementById("loginSection").style.display = "block";
  document.getElementById("registerSection").style.display = "none";
}