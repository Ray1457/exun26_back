# Frontend API

This repository exposes a small, typed data-access layer over Supabase. It is not a standalone HTTP server. A frontend creates a browser Supabase client and passes it to the helpers in `lib/data`.

## Setup

Install dependencies and configure the public Supabase variables:

```sh
npm install
cp .env.example .env.local
```

Set these values in `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<publishable-anon-key>
```

Only the publishable/anon key belongs in a browser application. Never expose `SUPABASE_SERVICE_ROLE_KEY` in frontend code.

## Client and result handling

```ts
import { createClient } from './lib/data/client.js';
import { getCase } from './lib/data/cases.js';

const client = createClient();
const result = await getCase(client, 'wenoti-arcade-anomaly');

if (result.error) {
  console.error(result.error.code, result.error.message);
} else {
  console.log(result.data.title);
}
```

Every helper returns `Result<T>`:

```ts
type Result<T> =
  | { data: T; error: null }
  | { data: null; error: DataError };

type DataError = {
  code: string;
  message: string;
  retryable: boolean;
};
```

Check `result.error` before reading `result.data`. Network and fetch failures are marked `retryable`; validation, authentication, and permission errors are not automatically retryable.

## Authentication

All authentication helpers are in `lib/data/agents.ts`.

| Helper | Arguments | Returns | Notes |
| --- | --- | --- | --- |
| `signIn(client, email, password)` | `SupabaseClient`, `string`, `string` | `Result<Agent>` | Signs in with email/password, then loads the matching agent row. |
| `signInDemo(client)` | `SupabaseClient` | `Result<Agent>` | Uses `DEMO_EMAIL` and `DEMO_PASSWORD`; intended for local/demo builds. |
| `getMyAgent(client)` | `SupabaseClient` | `Result<Agent>` | Requires an active Supabase session. |
| `signOut(client)` | `SupabaseClient` | `Result<null>` | Ends the current session. |

```ts
const signedIn = await signIn(client, email, password);
if (!signedIn.error) {
  const agent = signedIn.data;
}

await signOut(client);
```

The authenticated user ID must match `agents.id`. Authenticated access is enforced by Supabase RLS and the security-definer RPCs.

## Case and files

Helpers are in `lib/data/cases.ts`.

| Helper | Arguments | Returns | Supabase operation |
| --- | --- | --- | --- |
| `getCase(client, slug)` | `SupabaseClient`, case slug | `Result<Case>` | `cases`, exact slug match |
| `listCaseFiles(client, caseId)` | `SupabaseClient`, UUID | `Result<CaseFile[]>` | `case_files`, ordered by `created_at` |
| `getCaseFileUrl(client, file, expiresIn?)` | `SupabaseClient`, `CaseFile`, seconds | `Result<string>` | Signed URL from `file.bucket` and `file.storage_path`; default expiry is 3600 seconds |

```ts
const caseResult = await getCase(client, 'wenoti-arcade-anomaly');
if (!caseResult.error) {
  const filesResult = await listCaseFiles(client, caseResult.data.id);
  if (!filesResult.error && filesResult.data[0]) {
    const urlResult = await getCaseFileUrl(client, filesResult.data[0]);
    if (!urlResult.error) window.open(urlResult.data, '_blank');
  }
}
```

Signed URLs expire. Request a fresh URL when the previous one is no longer valid.

## Map and energy data

| Helper | Module | Arguments | Returns | Ordering |
| --- | --- | --- | --- | --- |
| `listCabinets` | `lib/data/map.ts` | `client`, `caseId` | `Result<Record<string, unknown>[]>` | `name` |
| `listSightings` | `lib/data/map.ts` | `client`, `caseId` | `Result<Record<string, unknown>[]>` | `seen_at` |
| `getEnergyReadings` | `lib/data/energy.ts` | `client`, `caseId` | `Result<EnergyReading[]>` | `reading_date` |

The map helpers currently return flexible records because their database rows are not represented by exported TypeScript types. `EnergyReading` is typed in `lib/data/types.ts` and includes anomaly fields such as `meter_delta_kwh`, `is_discrepancy`, and `is_spike`.

## Findings

Helpers are in `lib/data/findings.ts`.

| Helper | Arguments | Returns | Behavior |
| --- | --- | --- | --- |
| `listFindings(client, caseId)` | `SupabaseClient`, UUID | `Result<Finding[]>` | Loads findings newest first. |
| `saveFindings(client, caseId, findings)` | `SupabaseClient`, UUID, `unknown[]` | `Result<Finding[]>` | Validates input and saves findings in batches of 200. |

Each finding must have:

```ts
{
  finding_key: string;       // required, non-empty
  kind: string;              // required, non-empty
  title: string;             // required, max 160 characters
  detail?: Record<string, unknown>; // defaults to {}
  confidence?: number;       // 0..1, defaults to 0.8
  severity?: 1 | 2 | 3;      // defaults to 1
  source?: 'lens' | 'manual' | 'seed'; // defaults to 'lens'
}
```

Invalid payloads return `error.code === 'invalid_payload'` without making a database request.

## Investigation board

Helpers are in `lib/data/board.ts`.

| Helper | Arguments | Returns | Supabase operation |
| --- | --- | --- | --- |
| `listPins(client, caseId)` | `SupabaseClient`, UUID | `Result<Pin[]>` | `pins`, ordered by `created_at` |
| `connect(client, fromPin, toPin)` | `SupabaseClient`, two pin UUIDs | `Result<Connection>` | `create_connection(p_from, p_to)` RPC |
| `listConnections(client, caseId)` | `SupabaseClient`, UUID | `Result<Connection[]>` | `connections`, ordered by `created_at` |
| `getProgress(client, caseId)` | `SupabaseClient`, UUID | `Result<Progress>` | `recompute_progress(p_agent, p_case)` RPC using the signed-in user |

```ts
const connection = await connect(client, fromPinId, toPinId);
if (connection.error) {
  // The RPC can reject invalid or unauthorized pin pairs.
  console.error(connection.error.message);
}

const progress = await getProgress(client, caseId);
```

## Direct Supabase names

The helper layer maps to these public database objects:

- Tables/views: `agents`, `cases`, `case_files`, `cabinets`, `sightings`, `energy_readings_analyzed`, `findings`, `pins`, `connections`
- RPCs: `save_findings(uuid, jsonb)`, `create_connection(uuid, uuid)`, `recompute_progress(uuid, uuid)`
- Storage buckets: `case-files`, `agent-uploads`

Prefer the helpers so response normalization, validation, batching, and error mapping remain consistent across frontend screens.

## Types

Import shared row types from `lib/data/types.ts`:

```ts
import type {
  Agent,
  Case,
  CaseFile,
  Connection,
  EnergyReading,
  Finding,
  Pin,
  Progress,
} from './lib/data/types.js';
```

The database schema and seed data live in `supabase/migrations/0001_core.sql` and `supabase/seed.sql`.