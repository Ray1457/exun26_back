import type { SupabaseClient } from '@supabase/supabase-js';
import type { EnergyReading } from './types.js';
import { fail, ok, type Result } from './result.js';

export async function getEnergyReadings(client: SupabaseClient, caseId: string): Promise<Result<EnergyReading[]>> {
  const { data, error } = await client.from('energy_readings_analyzed').select('*').eq('case_id', caseId).order('reading_date');
  return error ? fail(error) : ok((data ?? []) as EnergyReading[]);
}
