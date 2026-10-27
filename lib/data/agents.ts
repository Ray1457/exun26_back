import type { SupabaseClient } from '@supabase/supabase-js';
import type { Agent } from './types.js';
import { fail, ok, type Result } from './result.js';

export async function signIn(client: SupabaseClient, email: string, password: string): Promise<Result<Agent>> {
  const auth = await client.auth.signInWithPassword({ email, password });
  if (auth.error) return fail(auth.error);
  return getMyAgent(client);
}

export async function signInDemo(client: SupabaseClient): Promise<Result<Agent>> {
  const email = process.env.DEMO_EMAIL;
  const password = process.env.DEMO_PASSWORD;
  if (!email || !password) return fail({ code: 'demo_not_configured', message: 'Demo credentials are not configured.' });
  return signIn(client, email, password);
}

export async function getMyAgent(client: SupabaseClient): Promise<Result<Agent>> {
  const { data: user, error: authError } = await client.auth.getUser();
  if (authError || !user.user) return fail(authError ?? { code: 'not_authenticated', message: 'Sign in required.' });
  const { data, error } = await client.from('agents').select('*').eq('id', user.user.id).single();
  return error ? fail(error) : ok(data as Agent);
}

export async function signOut(client: SupabaseClient): Promise<Result<null>> {
  const { error } = await client.auth.signOut();
  return error ? fail(error) : ok(null);
}
