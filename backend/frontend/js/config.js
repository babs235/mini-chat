// ============================================
// CONFIGURATION DYNAMIQUE - Détection auto IP
// ============================================

// Détecte automatiquement l'IP du serveur
const getApiUrl = () => {
  const hostname = window.location.hostname;
  const port = window.location.port;
  
  console.log('🔍 Hostname détecté:', hostname);
  console.log('🔍 Port détecté:', port);
  
  // Si on est sur localhost (développement)
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }
  
  // Si hostname est vide ou undefined, utiliser l'URL actuelle
  if (!hostname || hostname === 'undefined' || hostname === '') {
    console.error('❌ Hostname invalide, utilisation fallback');
    // Essayer de récupérer depuis l'URL
    const urlParts = window.location.href.split('/');
    if (urlParts[2]) {
      return `http://${urlParts[2].split(':')[0]}:3000`;
    }
    return 'http://localhost:3000';
  }
  
  // Sinon, utilise le même hostname que le frontend (production)
  return `http://${hostname}:3000`;
};

// Export pour utilisation dans les autres fichiers
const API = getApiUrl();
console.log('🌐 API URL configurée:', API);
