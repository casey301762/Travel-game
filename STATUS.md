# RoadQuest delivery record

## Current release

- Public production app: https://roadquest-topaz.vercel.app/
- Vercel deployment: dpl_3KCfPkxHMGv4db6fsZDsnjMvEXD4, READY.
- Deployed source commit: 0a38138c04dbf4ed22938d51690d5a35c977f6d9.
- Vercel project: prj_yNXgoGYNZVYncBQYwvjjvSgAUUAx.
- Supabase project: tzxsndrmuhwnsatoeeow (us-east-2), creation quote $0/month.
- Both initial database migrations applied; 278 discoveries and all three Realtime tables verified.
- Anonymous Sign-Ins enabled and tested. Browser receives only the public publishable key; no service-role key is used.

## Implemented Phase 1

Room creation and six-character codes; guest joining; 2–12-player lobby; host-only start; Points Frenzy; Board Blitz; authoritative database scoring; individual boards; live leaderboards; winner detection; rematches; manual region/season/environment/day-night filtering; PWA manifest, service worker and offline fallback.

## Verified

- Production Next.js build and TypeScript checks pass.
- Four local PostgreSQL integration tests pass: all 120 filter combinations; separate guest identities, duplicate/unauthorized claims; Board Blitz and rematch isolation; RLS read/write restrictions.
- Real hosted API multiplayer with two independent Supabase guest sessions passes: room creation/code join, host-only start, simultaneous duplicate submission (exactly one award), cross-player claim denial, cross-session Realtime score events, restored session/persisted score, Frenzy winner/rematch and all 16 Board Blitz discoveries/winner.
- Public alias returns HTTP 200 with the actual app without Vercel authentication.
- Desktop browser verification passes: create room; independent SDK guest joins; browser starts game; guest claim updates browser leaderboard; browser claim replaces card and adds score; browser reload restores room, board and scores.
- Browser screenshot reviewed: readable cards, lobby/game and leaderboard at desktop viewport.

## Verification still required

- iOS Safari and Android Chrome visual/layout and installability checks at narrow mobile viewports.
- Full internet-loss/reconnect browser test and offline service worker acceptance.
- Two physical devices or two isolated browser profiles playing together. Current live tests used independent SDK sessions plus one real browser session.
- Simultaneous near-winning claims from different players. Row locks serialize winners; actual concurrent finish-line acceptance remains untested.

## Known limitations / next work

- Royale, Bingo, Adventure, achievements, power-ups and witness verification are not implemented; claims use the honor system.
- No host succession, kicking, mid-game joining, or recovery after guest browser storage is cleared.
- Filters remain fixed after creation. No stale-room cleanup or room-code join throttling yet.
- Guest creation currently starts on page load. Add abuse controls / CAPTCHA before broader public distribution.
- Discovery feasibility still needs family playtesting; vehicle/color combinations are intentional tasks.
- RLS security advisor flags five intentional authenticated SECURITY DEFINER functions. They enable server-controlled game writes and membership lookup while direct client table writes remain denied. Identity/host/card-ownership checks are tested. See https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable for context.
- This record and reusable live API test are committed after the deployed source; those documentation/test additions do not alter the running app.

## Deployment notes

Explicit Vercel team parameters caused 403 errors; addressing the verified project ID through the connected account worked. Git-source production deployment succeeded after account setup. The native deployment-card endpoint was unavailable.

Automatic approval review rejected a request to disable Vercel login protection. The setting was left unchanged. A subsequent ordinary anonymous request and real browser visit proved the public production alias already works, so no access-control change is needed. The protected-deployment helper separately returned 403 and was not required.

The shared design-chat URL could not be retrieved. Implementation follows Casey's detailed product brief.
