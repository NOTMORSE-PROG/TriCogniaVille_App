# TriCognia Ville monorepo

This branch keeps the Godot game at `/` and imports the latest committed tree
of the Next.js backend under `backend/` as a clean synchronization snapshot.
The original backend repository remains the authoritative history and rollback
source.

- Canonical GitHub URL:
  https://github.com/NOTMORSE-PROG/TriCogniaVille_App
- Backend history and rollback source:
  https://github.com/NOTMORSE-PROG/TriCogniaVille_Backend

The audit did not find a connected Vercel project for this pair. Existing
deployment projects and public URLs must remain unchanged; a backend service
should use `backend/` as its root only during a verified source cutover.
