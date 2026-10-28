# EXUN Investigator Portal Backend

Backend and data-access layer for the Wenoti Arcade Anomaly investigation. The
project uses Supabase for authentication, storage, case data, and the evidence
board.

## Getting started

```sh
npm install
npm run seed:build
npm run typecheck
npm test
```

The seed builder reads the source evidence in `prompt/` and updates
`supabase/seed.sql`. To run the complete backend locally, install the Supabase
CLI and use:

```sh
supabase start
supabase db reset
```

Copy `.env.example` to `.env.local` before connecting an application client.
The answer key stays server-side; evidence-board connections are validated by
the `create_connection` RPC.

## Frontend integration

The typed client helpers live in `lib/data`. See [API.md](API.md) for setup,
authentication, payloads, response types, and the underlying Supabase calls.
