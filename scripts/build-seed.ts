import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const seedPath = resolve(root, 'supabase/seed.sql');
const sourceFiles = ['prompt/original-code-reckoning.txt', 'prompt/altered-code-reckoning.txt'];

for (const relativePath of sourceFiles) {
  const source = await readFile(resolve(root, relativePath), 'utf8');
  if (relativePath.includes('original') && (!source.includes('class Character') || !source.includes('std::clamp'))) {
    throw new Error('Original source is missing expected markers.');
  }
  if (relativePath.includes('altered') && (source.includes('class Character') || source.includes('std::clamp'))) {
    throw new Error('Altered source still contains removed markers.');
  }
}

const seed = await readFile(seedPath, 'utf8');
await writeFile(seedPath, seed.endsWith('\n') ? seed : `${seed}\n`);
console.log(`Validated seed against ${sourceFiles.length} source files.`);
