import type { SupabaseClient } from '@supabase/supabase-js';
import type { Case, CaseFile } from './types.js';
import { fail, ok, type Result } from './result.js';

export async function getCase(client: SupabaseClient, slug: string): Promise<Result<Case>> {
  const { data, error } = await client.from('cases').select('*').eq('slug', slug).single();
  return error ? fail(error) : ok(data as Case);
}

export async function listCaseFiles(client: SupabaseClient, caseId: string): Promise<Result<CaseFile[]>> {
  const { data, error } = await client.from('case_files').select('*').eq('case_id', caseId).order('created_at');
  return error ? fail(error) : ok((data ?? []) as CaseFile[]);
}

export async function getCaseFileUrl(client: SupabaseClient, file: CaseFile, expiresIn = 3600): Promise<Result<string>> {
  const { data, error } = await client.storage.from(file.bucket).createSignedUrl(file.storage_path, expiresIn);
  return error ? fail(error) : ok(data.signedUrl);
}
