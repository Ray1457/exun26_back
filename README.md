# EXUN Investigator Portal Backend

Supabase backend foundation for the Wenoti Arcade Anomaly case.

## Local checks

```sh
npm install
npm run typecheck
npm test
npm run seed:build
```

The schema is in `supabase/migrations/0001_core.sql` and the deterministic case seed is in `supabase/seed.sql`. With the Supabase CLI installed, start the local stack and apply both with:

```sh
supabase start
supabase db reset
```

Copy `.env.example` to `.env.local` for an application client. The answer key tables have no authenticated grants; connections are checked by the `create_connection` RPC.
