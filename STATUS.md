# RoadQuest delivery record

## Completed

- Phase 1 source implementation and 278-discovery dataset.
- Production Next.js build and strict TypeScript validation passed during development.
- Four PostgreSQL integration tests passed: all 120 filter combinations (5 regions × 4 seasons × 3 road types × 2 light settings); two guest identities and duplicate/unauthorized claims; Board Blitz and rematch isolation; RLS read/write restrictions.
- GitHub repository authorized by Casey: casey301762/Travel-game.

## Not verified / blocked

- Supabase RoadQuest project created: tzxsndrmuhwnsatoeeow (us-east-2), quoted $0/month. Both migrations applied; verified 278 discoveries and all three Realtime publication tables.
- Security advisor reports five authenticated SECURITY DEFINER endpoints. These are intentional for authoritative gameplay and membership lookup; direct writes are denied and ownership checks are enforced. No anon function execution is granted.
- Vercel RoadQuest project created: prj_yNXgoGYNZVYncBQYwvjjvSgAUUAx, account team_Gsw7x3l0m7VdKm6QKAx4iMAt (wardcasey-9003). No deployment exists.
- Vercel Git linking failed: account needs a GitHub login connection.
- Vercel environment configuration blocked by HTTP 403 for wardcasey-9003 scope; authenticated integration cannot currently access this project scope. No Vercel CLI is available as a fallback.
- Supabase integration has no authentication-settings mutation operation. Anonymous sign-ins must be enabled in the dashboard before guest play can be tested.
- No real independent-browser multiplayer or Supabase Realtime test has been performed.
- No visual mobile browser QA has been performed. Responsive styles compile; actual viewport review remains required.
- The shared design conversation URL could not be retrieved; implementation follows the explicit product brief.

## Release acceptance checklist

1. Configure a dedicated Supabase project and anonymous sign-ins; apply both migrations.
2. Deploy repository to Vercel with the two public Supabase environment variables.
3. Open separate normal/incognito browser profiles (or two phones). Create a room on one; join by code on the other.
4. Verify only the host can start; both players see the same live scores and a different board layout.
5. Claim discoveries simultaneously and rapidly double-tap one card; assert one award per card and no post-win score changes.
6. Reach 500 in Frenzy, clear all 16 in Blitz, and verify exactly one winner. Rematch and reject old-card replays.
7. Disconnect one device; confirm disabled claims. Reconnect and refresh; verify guest identity, board and scores restore.
8. Test iOS Safari and Android Chrome at narrow viewports, keyboard navigation, installability, and offline fallback.
9. Confirm an outsider cannot query room data and authenticated users cannot directly update score tables in deployed Supabase.

## Known limitations

- Witness verification, power-ups, achievements and the three remaining modes are not yet implemented.
- Guest identity cannot be recovered if browser storage is cleared; host departure has no succession flow.
- Fixed filters may become unsuitable if the route changes mid-round. Host cannot edit them after creation.
- No stale-room cleanup job, abuse-resistant CAPTCHA, or room-code join throttling yet. Enable anti-abuse protections before broad public distribution.
- Discovery feasibility is metadata-based and still needs family playtesting; color/vehicle combinations are intentional distinct tasks.
- Offline fallback is implemented; offline multiplayer is not.
