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
    alert(data.message || data.error);

    if (res.ok) {
      showLogin();
    }
  } catch (err) {
    console.error('Erreur inscription:', err);
    alert("Erreur serveur lors de l'inscription");
  }
}

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
      localStorage.setItem("token", data.token);
      localStorage.setItem("username", data.username);
      window.location.href = "messages.html";
    } else {
      alert(data.error || "Connexion échouée");
    }
  } catch (err) {
    console.error('Erreur connexion:', err);
    alert("Erreur serveur lors de la connexion");
  }
}

function showRegister() {
  document.getElementById("loginSection").style.display = "none";
  document.getElementById("registerSection").style.display = "block";
}

function showLogin() {
  document.getElementById("loginSection").style.display = "block";
  document.getElementById("registerSection").style.display = "none";
}
