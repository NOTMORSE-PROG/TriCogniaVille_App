# TriCogniaVille Backend and Teacher Dashboard

This Next.js service supports the TriCogniaVille Godot game. It provides player authentication, profiles, building and quest data, progress synchronization, badges, speech assessment, certificates, and a teacher dashboard for reviewing students and analytics.

This component is maintained inside the canonical `https://github.com/NOTMORSE-PROG/TriCogniaVille` repository at `backend/`.

## Technology

- Next.js 16 and React 19
- TypeScript
- Drizzle ORM with Neon PostgreSQL
- JWT authentication
- Google OAuth for game accounts
- Cloudinary-backed speech uploads
- Groq-assisted speech assessment

## Local Setup

Prerequisites:

- Node.js 20+
- PostgreSQL or a Neon connection string
- Google OAuth credentials

```bash
git clone https://github.com/NOTMORSE-PROG/TriCogniaVille.git
cd TriCogniaVille/backend
npm install
cp .env.example .env.local
npm run db:migrate
npm run dev
```

Open `http://localhost:3000`. The root route redirects to the teacher sign-in page.

`db:migrate`, `db:seed`, and `db:setup` modify the configured database. Use a development database unless another environment is intentionally in scope.

## Environment Variables

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Signs game and dashboard authentication tokens |
| `GOOGLE_CLIENT_ID` | Google OAuth web client identifier |
| `GOOGLE_CLIENT_SECRET` | Google OAuth web client secret |
| `GOOGLE_ANDROID_CLIENT_ID` | Google OAuth Android client identifier |
| `TEACHER_SEED_EMAIL` | Email for the deliberately seeded teacher account |
| `TEACHER_SEED_PASSWORD` | Password for the deliberately seeded teacher account |
| `NEXT_PUBLIC_APP_URL` | Public base URL used by the web service |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name for speech uploads |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `GROQ_API_KEY` | Primary Groq key for speech assessment features |
| `GROQ_API_KEY_2` | Optional secondary Groq key |

The tracked `.env.example` documents the core settings. Add feature-specific values only to ignored local or provider-managed environment configuration; never commit working credentials.

## Commands

| Command | Purpose |
|---|---|
| `npm run dev` | Start the local Next.js server |
| `npm run build` | Create a production build |
| `npm start` | Start the production build |
| `npm run lint` | Run ESLint |
| `npm test` | Run the gamification test suite |
| `npm run db:migrate` | Apply database migrations |
| `npm run db:seed` | Seed the configured database |
| `npm run db:setup` | Run migrations and then seed data |

## Main Areas

| Path | Responsibility |
|---|---|
| `src/app/api/v1/auth/` | Registration, login, logout, and Google authentication |
| `src/app/api/v1/progress/` | Player progress |
| `src/app/api/v1/sync/` | Game synchronization |
| `src/app/api/v1/speech/` | Speech upload, transcription, assessment, and review |
| `src/app/api/v1/badges/` | Player badges |
| `src/app/api/v1/certificate/` | Certificate generation and download |
| `src/app/api/dashboard/` | Teacher dashboard data |
| `src/app/dashboard/` | Teacher-facing pages |
| `src/lib/db/` | Database schema, migrations, and seed logic |
| `__tests__/` | Backend tests |

## Deployment Status

No active production deployment was found for TriCogniaVille during the consolidation audit. Deployment is a separate rollout task. A future service should use `backend/` as its root directory, and the Godot client's `app_config.cfg` must be updated only after the new URL is verified.

Return to the [project README](../README.md) for Godot setup and the complete repository layout.
