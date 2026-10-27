import type { SupabaseClient } from '@supabase/supabase-js';
import { fail, ok, type Result } from './result.js';

export async function listCabinets(client: SupabaseClient, caseId: string): Promise<Result<Record<string, unknown>[]>> {
  const { data, error } = await client.from('cabinets').select('*').eq('case_id', caseId).order('name');
  return error ? fail(error) : ok(data ?? []);
}

export async function listSightings(client: SupabaseClient, caseId: string): Promise<Result<Record<string, unknown>[]>> {
  const { data, error } = await client.from('sightings').select('*').eq('case_id', caseId).order('seen_at');
  return error ? fail(error) : ok(data ?? []);
}
