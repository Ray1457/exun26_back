import { describe, expect, it } from 'vitest';
import { fail, ok, toDataError } from '../lib/data/result.js';

describe('data result contract', () => {
  it('wraps successful values', () => {
    expect(ok({ ready: true })).toEqual({ data: { ready: true }, error: null });
  });

  it('maps network failures as retryable', () => {
    expect(toDataError({ code: 'fetch_failed', message: 'network unavailable' })).toMatchObject({
      code: 'fetch_failed',
      retryable: true,
    });
  });

  it('never throws from fail', () => {
    expect(fail({ code: 'forbidden', message: 'denied' })).toEqual({
      data: null,
      error: { code: 'forbidden', message: 'denied', retryable: false },
    });
  });
});
