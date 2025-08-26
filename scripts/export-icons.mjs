// Requires: Node 18+, sharp, svgson (or use inkscape CLI alternative)
// Usage: node scripts/export-icons.mjs
import { readdir, mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import sharp from 'sharp';

const ROOT = path.resolve('icons');
const SIZES = [96, 192, 512];
const SRC_DIRS = ['base', 'tiers', 'states'];

async function ensureDir(p) {
  await mkdir(p, { recursive: true });
}

async function exportAll() {
  for (const dir of SRC_DIRS) {
    const full = path.join(ROOT, dir);
    const files = await readdir(full);
    const svgs = files.filter(f => f.endsWith('.svg'));
    for (const svg of svgs) {
      const svgPath = path.join(full, svg);
      const svgBuf = await readFile(svgPath);
      for (const size of SIZES) {
        const outDir = path.join(ROOT, 'exports', 'png', String(size));
        await ensureDir(outDir);
        const outPath = path.join(outDir, svg.replace('.svg', '.png'));
        await sharp(svgBuf).resize(size, size).png({ compressionLevel: 9 }).toFile(outPath);
      }
    }
  }
  console.log('✅ Icon exports complete');
}

exportAll().catch(err => {
  console.error('❌ Export failed', err);
  process.exit(1);
});


