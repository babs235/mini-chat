// API URL détectée dynamiquement (voir config.js)

// 🔹 Vérification API
const checkApi = () => {
  if (!API || API === 'undefined' || API.includes('undefined')) {
    console.error('❌ API URL invalide:', API);
    alert('Erreur: URL du serveur non définie. Vérifiez config.js');
    return false;
  }
  return true;
};

// 🔹 INSCRIPTION
async function register() {
  const username = document.getElementById("registerUsername").value;
  const password = document.getElementById("registerPassword").value;

  if (!checkApi()) return;

  const url = `${API}/auth/register`;
  console.log('📡 Appel API (register):', url);

  try {
    const res = await fetch(url, {
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
    console.error('❌ Erreur inscription:', err);
    alert("Erreur serveur lors de l'inscription");
  }
}

// 🔹 LOGIN
async function login() {
  const username = document.getElementById("loginUsername").value;
  const password = document.getElementById("loginPassword").value;

  if (!checkApi()) return;

  const url = `${API}/auth/login`;
  console.log('📡 Appel API (login):', url);

  try {
    const res = await fetch(url, {
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
    console.error('❌ Erreur connexion:', err);
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