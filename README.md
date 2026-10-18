# ↗ RoadQuest

A mobile-first road trip scavenger hunt built with Next.js App Router, React, TypeScript, Tailwind CSS, and Supabase PostgreSQL / Realtime. Deployment target: Vercel.

## Phase 1 implemented

- Anonymous Supabase guest sessions; no user account registration.
- Private six-character rooms, lobby, 2–12 players, host-only start and rematch.
- Points Frenzy: six active discoveries per player, replacement on claim, first to 500.
- Board Blitz: individual shuffled 4×4 boards with the same balanced discovery set for fair competition; all 16 wins.
- 278 categorized discoveries with points, rarity, region, season, road environment, and light eligibility.
- PostgreSQL-controlled scores, room locking to serialize claims and wins, stale card rejection, RLS, no direct client writes.
- Live room / score subscriptions and five-second recovery polling; session and room persistence.
- Golden Sightings can appear as replacements; golden styling and claim notification.
- Responsive UI, web manifest, service worker, and dedicated offline fallback. Claims require connectivity and are never queued offline.

## Local setup

Use Node 22 or newer.

```sh
npm ci
cp .env.example .env.local
```

Create a **new, dedicated Supabase project**. Run `supabase/migrations/001_game.sql` followed by `002_discoveries.sql` in its SQL editor (or use the Supabase CLI migration workflow). These are initial migrations, not rerunnable scripts. They alter public-schema function privileges; do not run them against an unrelated existing application database.

Enable **Anonymous Sign-Ins** under Supabase Authentication. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.local`. The anon / publishable key is designed to be public; access is constrained by guest JWTs, row-level security, and RPC permissions. No service-role key is used or required by this app.

```sh
npm run dev
npm run typecheck
npm test
npm run build
```

## Deploy to Vercel

1. Import `casey301762/Travel-game` into Vercel as a Next.js project (repository root).
2. Set the two environment variables from `.env.example` for the relevant Vercel environments.
3. Ensure the Supabase migrations and anonymous authentication setup above are complete.
4. Deploy. Use the resulting HTTPS URL on passenger devices. Each browser profile/device gets a separate guest identity.
5. Follow the live acceptance checklist in `STATUS.md` before calling it release-verified.

No paid plan or custom domain is required by the source. Review the providers' plan limits before enabling a paid plan.

## Testing boundaries

`npm test` executes the actual SQL migrations and RPCs in local PostgreSQL via PGlite, with a local auth.uid() shim, two guest identities and role switching. The harness substitutes pgcrypto byte generation only for local compatibility and omits the Supabase publication statement. It does **not** simulate Supabase Auth, Realtime transport, independent browser connections, production concurrency, or actual internet loss.

Scores and winner transitions are protected by the room's PostgreSQL row lock; client code never sends point values. A stale / duplicate card cannot score twice. Cross-player writes and outsider room reads are denied. These statements are backed by local tests; hosted acceptance remains outstanding.

## Product boundaries and next phases

Honor-system claims are immediate and final. Witness verification is not implemented. Host transfer, kicking, reconnecting from a different browser after guest storage loss, and mid-game joins are not supported. Back to home preserves room membership. Games do not automatically expire yet; schedule cleanup before broader public use. No location tracking is used. Filters are selected manually by the host and remain fixed for the round.

Phase 2: Road Trip Royale, Highway Bingo, Adventure, achievements, optional power-ups and witness verification. Phase 3: route intelligence, richer Adventure progression and app-store readiness.

Drivers must not play while driving.
