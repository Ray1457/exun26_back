import { z } from 'zod';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Finding } from './types.js';
import { fail, ok, type Result } from './result.js';

const findingSchema = z.object({
  finding_key: z.string().min(1),
  kind: z.string().min(1),
  title: z.string().min(1).max(160),
  detail: z.record(z.string(), z.unknown()).default({}),
  confidence: z.number().min(0).max(1).default(.8),
  severity: z.number().int().min(1).max(3).default(1),
  source: z.enum(['lens', 'manual', 'seed']).default('lens'),
});

export async function saveFindings(client: SupabaseClient, caseId: string, findings: unknown[]): Promise<Result<Finding[]>> {
  const parsed = z.array(findingSchema).min(1).safeParse(findings);
  if (!parsed.success) return fail({ code: 'invalid_payload', message: parsed.error.message });
  const saved: Finding[] = [];
  for (let index = 0; index < parsed.data.length; index += 200) {
    const { data, error } = await client.rpc('save_findings', { p_case: caseId, p_findings: parsed.data.slice(index, index + 200) });
    if (error) return fail({ ...error, message: `Finding batch ${Math.floor(index / 200) + 1} failed: ${error.message}` });
    saved.push(...((data ?? []) as Finding[]));
  }
  return ok(saved);
}

export async function listFindings(client: SupabaseClient, caseId: string): Promise<Result<Finding[]>> {
  const { data, error } = await client.from('findings').select('*').eq('case_id', caseId).order('created_at', { ascending: false });
  return error ? fail(error) : ok((data ?? []) as Finding[]);
}
