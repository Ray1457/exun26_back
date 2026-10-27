import type { SupabaseClient } from '@supabase/supabase-js';
import type { Connection, Pin, Progress } from './types.js';
import { fail, ok, type Result } from './result.js';

export async function listPins(client: SupabaseClient, caseId: string): Promise<Result<Pin[]>> {
  const { data, error } = await client.from('pins').select('*').eq('case_id', caseId).order('created_at');
  return error ? fail(error) : ok((data ?? []) as Pin[]);
}

export async function connect(client: SupabaseClient, fromPin: string, toPin: string): Promise<Result<Connection>> {
  const { data, error } = await client.rpc('create_connection', { p_from: fromPin, p_to: toPin });
  return error ? fail(error) : ok(data as Connection);
}

export async function listConnections(client: SupabaseClient, caseId: string): Promise<Result<Connection[]>> {
  const { data, error } = await client.from('connections').select('*').eq('case_id', caseId).order('created_at');
  return error ? fail(error) : ok((data ?? []) as Connection[]);
}

export async function getProgress(client: SupabaseClient, caseId: string): Promise<Result<Progress>> {
  const { data, error } = await client.rpc('recompute_progress', { p_agent: (await client.auth.getUser()).data.user?.id, p_case: caseId });
  return error ? fail(error) : ok(data as Progress);
}
