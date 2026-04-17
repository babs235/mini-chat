// ============================================
// CONFIGURATION DYNAMIQUE - Détection auto IP
// ============================================

// Détecte automatiquement l'IP du serveur
const getApiUrl = () => {
  // Si on est sur localhost (développement)
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  
  // Sinon, utilise le même hostname que le frontend (production)
  // Cela fonctionne car backend et frontend sont sur le même serveur
  return `http://${window.location.hostname}:3000`;
};

// Export pour utilisation dans les autres fichiers
const API = getApiUrl();
