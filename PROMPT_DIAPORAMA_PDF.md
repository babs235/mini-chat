# PROMPT PDF — Support de Présentation (Diaporama)
## Mini-Chat — Administrateur Système DevOps — Niveau 6

---

> **Instructions pour l'IA (ChatGPT / Gemini / Claude / Gamma) :**
>
> Style Apple / CEO — chaque slide = UNE seule idée.
> Le texte est minimal — c'est le candidat qui parle, le slide ancre l'attention.
>
> **Mise en page générale :**
> - Format A4 paysage
> - Fond bleu nuit très foncé (#0A1628) avec texte blanc — style Apple Keynote
> - Police : SF Pro, Inter, ou Roboto — propre, sans serif
> - Couleur d'accent : bleu électrique (#0080FF)
> - Couleur secondaire : blanc cassé (#F5F5F7)
>
> **Règles de style strictes :**
> - Maximum 1 idée par slide
> - Le titre principal du slide = TRÈS grand (60-80pt), centré ou aligné à gauche
> - Sous-titre ou détail = petit (18-22pt), discret
> - Les **mots en gras** = à afficher encore plus grand ou dans la couleur d'accent
> - Jamais plus de 6 mots de contenu visible (hors schémas et tableaux)
> - Schémas en ASCII ou texte = encadrés, fond légèrement plus clair, police monospace
> - Pied de page minimaliste : "Babikir Ibrahim · ASD Niveau 6 · Juin 2026" + numéro — petit, discret
>
> **Timing : 30 minutes**
> Slides 1-4 : contexte (~5 min) · Slides 5-13 : technique (~16 min) · Slides 14-17 : difficultés (~5 min) · Slides 18-20 : bilan (~4 min)
>
> Chaque "## SLIDE N" = une page distincte. Ne pas fusionner.

---

---

## SLIDE 1 — Titre

# Mini-Chat

### Application de messagerie sur Google Cloud Platform

`Babikir Ibrahim` · Administrateur Système DevOps · Niveau 6 · Juin 2026

---

## SLIDE 2 — L'objectif

# L'app est simple.
## Ce qui compte, c'est ce qu'il y a autour.

*conteneuriser · automatiser · sécuriser · surveiller*

---

## SLIDE 3 — Les 3 blocs

# 3 blocs.
## 1 projet. Tout couvert.

**Bloc 1** → Infrastructure cloud (Terraform + GCP)
**Bloc 2** → Déploiement continu (Pipeline + Docker)
**Bloc 3** → Supervision (Monitoring + Logging)

---

## SLIDE 4 — Les phases

# Mars → Juin 2026

**Mars** · Local — Node.js · Docker Compose · MySQL
**Avril** · Cloud — Terraform · Cloud Run · Pipeline
**Mai–Juin** · Prod — Secrets · Monitoring · Smoke tests

---

## SLIDE 5 — Architecture

# Un `git push`.
## C'est tout.

```
git push
   ↓
tests → build → smoke tests → deploy
                                 ↓
                    Cloud Run · Cloud SQL · Secret Manager
                    HTTPS automatique · Rolling update
```

---

## SLIDE 6 — Terraform

# Rien créé à la main.

*`terraform apply` → toute l'infrastructure*

`cloudrun.tf` · `main.tf` · `monitoring.tf` · `provider.tf`

> "Si je supprime tout et relance apply, je retrouve exactement la même chose."

---

## SLIDE 7 — Sécurité

# 2 comptes. 2 rôles.
## Zéro SSH.

**terraform-deployer** → crée l'infra
**mini-chat-cloudrun** → fait tourner l'app (2 droits seulement)

*Si l'app est compromise → l'infra reste intacte.*

---

## SLIDE 8 — Pipeline

# 4 jobs.
## Rien ne passe si quelque chose casse.

```
Job 1  tests Jest ×10     ⛔ si KO = stop
Job 2  docker build        tag = hash commit
Job 3  smoke tests         image RÉELLE
Job 4  terraform apply     rolling update
```

*L'image testée = l'image déployée. Même SHA.*

---

## SLIDE 9 — Docker

# 180 MB
## au lieu de 950 MB

*Multi-stage Alpine · npm absent de l'image finale*
*Surface d'attaque minimale · Pull plus rapide*

---

## SLIDE 10 — Tests

# 10 tests Jest.
## 0 déploiement si KO.

*Validation · Authentification · Protection JWT*
*mysql2 mocké → rapides · déterministes*

**+ 3 smoke tests** sur l'image réelle avant chaque mise en prod

---

## SLIDE 11 — Secrets

# Le secret ne sort jamais en clair.

```
GitHub → Secret Manager → Cloud Run
                              ↓
               injecté au démarrage · valeur invisible
```

*Pas dans le code · pas dans les logs · pas dans la console GCP*

---

## SLIDE 12 — HTTPS

# HTTPS.
## Automatique.

*Cloud Run gère le certificat SSL tout seul.*
*Pas de load balancer · pas de renouvellement manuel.*

```javascript
return ''; // URL relative → fonctionne partout
```

---

## SLIDE 13 — Supervision

# 0 alerte déclenchée.

**Uptime check** → email si l'URL ne répond plus
**Erreurs 5xx** → email si trop d'erreurs serveur

*Cloud Logging → logs en temps réel · diagnostic immédiat*

---

## SLIDE 14 — Difficulté 1

# ECONNREFUSED

*IP publique activée. Identifiants corrects. App qui tombe.*

**Cause** → Cloud Run n'a pas d'IP fixe
**Solution** → Cloud SQL Auth Proxy · socket Unix · auth IAM

> "Ce n'était pas un bug de code. C'était GCP qui fonctionne différemment."

---

## SLIDE 15 — Difficulté 2

# Mixed Content

*Page HTTPS. Impossible de se connecter.*

```
"http://hostname:3000/auth/register" → BLOQUÉ
```

**Cause** → protocole hardcodé dans config.js
**Fix** → `return ''` · URL relative · navigateur gère le protocole

---

## SLIDE 16 — Difficulté 3

# Auth GitHub → GCP

*Décodage base64 échouait · caractères Windows · shell*

**Fix** → Python lit la variable directement · contourne le shell

> "Ce genre de bug n'existe pas en local. Il faut lire les logs ligne par ligne."

---

## SLIDE 17 — 3 leçons

# 3 problèmes.
## 3 leçons.

| Problème | Leçon |
|---|---|
| Cloud SQL refusé | IAM > IP publique |
| Mixed Content | URLs relatives = compatibles partout |
| Auth pipeline | Python > shell pour les secrets |

---

## SLIDE 18 — Limites

# Des choix.
## Pas des oublis.

- **Pas de WebSocket** → polling 3s · suffisant · moins de complexité
- **Scale to zero** → cold start 1-2s · `min_instance = 1` en prod réelle
- **60 % coverage** → chemins critiques OK
- **Pas de staging** → en équipe il faudrait 2 env

---

## SLIDE 19 — Ce que je referais

# Plus tôt.

**Tests** → dès le premier jour, pas après l'app
**Terraform distant** → GCS dès le début, pas en migration
**Ce que j'ai appris** → les vrais problèmes n'existent qu'en cloud réel

---

## SLIDE 20 — Conclusion

# git push → production.
## Automatiquement.

```
tests ✓ · build ✓ · smoke tests ✓ · deploy ✓
HTTPS ✓ · secrets ✓ · monitoring ✓
```

**Zéro intervention manuelle. Zéro downtime. Zéro secret en clair.**

---

*Merci. Je suis disponible pour vos questions.*

`github.com/babs235/mini-chat` · `https://mini-chat-backend-py4vurg4oq-ew.a.run.app`
