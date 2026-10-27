import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const root = resolve(import.meta.dirname, '..');

describe('case seed invariants', () => {
  it('contains the complete official corpus and anomaly markers', async () => {
    const seed = await readFile(resolve(root, 'supabase/seed.sql'), 'utf8');
    for (const slug of ['case-debrief', 'transcript-a', 'energy-usage-dossier', 'asset-integrity-report', 'progress-assessment-log', 'original-code-reckoning', 'altered-code-reckoning']) {
      expect(seed).toContain(`'${slug}'`);
    }
    expect(seed).toContain('2,684 kWh 503.2 kWh');
    expect(seed).toContain("'2026-10-23',2984.00,2684.00");
    expect(seed).toContain("'2026-10-24',3014.70,503.20");
  });
});
