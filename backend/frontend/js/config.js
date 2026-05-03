const getApiUrl = () => {
  const hostname = window.location.hostname;

  // En local : le serveur tourne directement sur le port 3000
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:3000';
  }

  // En production : URL relative — le navigateur utilise automatiquement
  // le bon protocole (HTTPS) et le bon host, l'ALB redirige vers le port 3000
  return '';
};

const API = getApiUrl();
