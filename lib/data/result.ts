export type DataError = {
  code: string;
  message: string;
  retryable: boolean;
};

export type Result<T> =
  | { data: T; error: null }
  | { data: null; error: DataError };

export const ok = <T>(data: T): Result<T> => ({ data, error: null });

const retryableCodes = new Set(['PGRST301', 'ECONNRESET', 'fetch_failed']);

export function toDataError(error: unknown): DataError {
  const source = error as { code?: string; message?: string } | null;
  const code = source?.code ?? 'unknown_error';
  return {
    code,
    message: source?.message ?? 'The request could not be completed.',
    retryable: retryableCodes.has(code) || /network|fetch|timeout/i.test(source?.message ?? ''),
  };
}

export function fail<T = never>(error: unknown): Result<T> {
  return { data: null, error: toDataError(error) };
}
