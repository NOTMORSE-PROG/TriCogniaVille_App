# TriCogniaVille

TriCogniaVille is an educational Godot game with a companion Next.js backend for accounts, progress, content, and teacher-facing services. Both components are maintained in the canonical `https://github.com/NOTMORSE-PROG/TriCogniaVille` repository.

## Repository Layout

| Path | Component | Main technology |
|---|---|---|
| `/` | Game client | Godot 4.6 and GDScript |
| `backend/` | Web/API service | Next.js 16, TypeScript, Drizzle ORM, and Neon PostgreSQL |

## Game Setup

1. Install Godot 4.6.
2. Clone the project:

```bash
git clone https://github.com/NOTMORSE-PROG/TriCogniaVille.git
cd TriCogniaVille
```

3. Open `project.godot` in Godot and run the project. The configured main scene is `scenes/SplashScreen.tscn`.
4. For a local backend, update the non-secret URL in `app_config.cfg` to point to the backend instance you are running.

Android export configuration is kept in the project, but signing credentials and local SDK paths must remain outside committed configuration.

## Backend Setup

Prerequisites are Node.js 20+ and a PostgreSQL database.

See the dedicated [`backend/README.md`](backend/README.md) for API areas, environment variables, database cautions, and teacher-dashboard details.

```bash
cd backend
npm install
cp .env.example .env.local
# Fill in the required local configuration without committing secrets
npm run db:migrate
npm run dev
```

The backend starts with Next.js. Other useful commands include:

| Command | Purpose |
|---|---|
| `npm run build` | Create a production build |
| `npm run lint` | Run ESLint |
| `npm test` | Run the gamification tests |
| `npm run db:setup` | Run migrations and seed data |

## Deployment Status

No active production deployment was found for TriCogniaVille during the consolidation audit. Publishing the backend or game is a separate rollout task. A future backend deployment should use `backend/` as its root directory and must use a deliberately configured URL in `app_config.cfg`.

## Project Documents

Research, content guides, and source documents remain at the project root for the team. Treat them as project material; do not publish or redistribute them independently without confirming their ownership and intended audience.
