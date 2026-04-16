const API = "http://13.38.35.35:3000";

const token = localStorage.getItem("token");
const currentUsername = localStorage.getItem("username");

// 🔥 Vérifier connexion
if (!token) {
  window.location.href = "index.html";
}

// Afficher le nom d'utilisateur dans le header
document.getElementById("welcome").innerText = currentUsername;

// 📝 Formater la date/heure
function formatTime(dateString) {
  const date = new Date(dateString);
  return date.toLocaleTimeString('fr-FR', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}

// 👤 Obtenir l'initiale du username
function getInitial(name) {
  return name ? name.charAt(0).toUpperCase() : '?';
}

// 🎨 Générer une couleur basée sur le username (pour les avatars)
function getAvatarColor(name) {
  const colors = [
    '#6366f1', '#8b5cf6', '#ec4899', '#f43f5e',
    '#f97316', '#eab308', '#10b981', '#06b6d4'
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
}

//  Charger messages
async function loadMessages() {
  try {
    const res = await fetch(`${API}/messages`, {
      headers: { "Authorization": token }
    });
    
    // 🔒 Si token invalide, rediriger vers login
    if (res.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("username");
      window.location.href = "index.html";
      return;
    }
    
    const data = await res.json();
    
    // 🔒 Vérifier que data est bien un tableau
    if (!Array.isArray(data)) {
      console.error("Erreur: données invalides", data);
      return;
    }

    const list = document.getElementById("messages");
    const emptyState = document.getElementById("emptyState");
    
    // Gestion de l'état vide
    if (data.length === 0) {
      list.style.display = "none";
      emptyState.style.display = "block";
      return;
    } else {
      list.style.display = "flex";
      emptyState.style.display = "none";
    }
    
    // Ne mettre à jour que si le nombre de messages a changé (évite le flicker)
    if (list.children.length === data.length) {
      return;
    }

    list.innerHTML = "";

    data.forEach(msg => {
      const isOwn = msg.username === currentUsername;
      const li = document.createElement("li");
      li.className = `message-item ${isOwn ? 'own' : ''}`;
      
      const avatarColor = getAvatarColor(msg.username);
      const time = msg.created_at ? formatTime(msg.created_at) : '';
      
      li.innerHTML = `
        <div class="message-avatar" style="background: ${avatarColor}">
          ${getInitial(msg.username)}
        </div>
        <div class="message-content">
          <div class="message-header">
            <span class="message-author">${msg.username}</span>
            <span class="message-time">${time}</span>
          </div>
          <div class="message-text">${msg.message}</div>
        </div>
      `;
      list.appendChild(li);
    });
    
    // Scroll vers le bas
    const chatMessages = document.getElementById("chatMessages");
    chatMessages.scrollTop = chatMessages.scrollHeight;

  } catch (err) {
    console.error(err);
  }
}

// 🔹 Envoyer message
async function sendMessage() {
  const input = document.getElementById("messageInput");
  const message = input.value.trim();
  
  if (!message) return;

  // Désactiver l'input pendant l'envoi
  input.disabled = true;

  try {
    const res = await fetch(`${API}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": token
      },
      body: JSON.stringify({ message })
    });
    
    // 🔒 Si token invalide, rediriger vers login
    if (res.status === 401) {
      localStorage.removeItem("token");
      localStorage.removeItem("username");
      window.location.href = "index.html";
      return;
    }
    
    if (res.ok) {
      input.value = "";
      await loadMessages();
    } else {
      const error = await res.json();
      console.error("Erreur envoi:", error);
    }

  } catch (err) {
    console.error(err);
  } finally {
    input.disabled = false;
    input.focus();
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