Mindload Achievement Icon System

This package provides a cohesive, token-driven icon set for the Achievements experience. All icons are vector (SVG), adaptive to themes via semantic tokens, and exportable to PNG at 96, 192, and 512 px.

Directory layout
- base/: base category icons (no tiers/states)
- tiers/: tier overlays (bronze/silver/gold/platinum/legendary)
- states/: state overlays (earned/in_progress/locked)
- exports/png/96|192|512/: generated bitmap exports (run script below)
- preview/: sprite sheet and mockups
- tokens/icon.tokens.json: icon token mappings (color/gradient/halo)

Design rules
- Artboard 96x96; 8px base grid; 72px circular keyline
- Stroke 2px outer, 1.5px internal; rounded caps/joins
- Flat + subtle depth (optional halo); minimal noise
- No hard-coded hex. All fills/strokes reference tokens via CSS variables
- Accessible: AA contrast at 96px on both light/dark backgrounds

Token integration
Each SVG references CSS variables (e.g., var(--color-icon-primary)). Provide runtime values via your theme system. See tokens/icon.tokens.json for the canonical token keys.

Flutter usage (composition + theming)
```
// Layer base → state (optional) → tier (optional)
Widget buildAchievementIcon(String baseName, {String? stateName, String? tierName, double size = 96}) {
  return SizedBox(
    width: size,
    height: size,
    child: Stack(children: [
      Positioned.fill(child: Image.asset('icons/base/$baseName.svg', package: null)),
      if (stateName != null) Positioned.fill(child: Image.asset('icons/states/$stateName.svg')),
      if (tierName != null) Positioned.fill(child: Image.asset('icons/tiers/$tierName.svg')),
    ]),
  );
}
```

Exports
- Recommend Inkscape or Sharp/Resvg to render to PNG
- Export script provided: scripts/export-icons.ps1 and scripts/export-icons.mjs
- Generated files go to icons/exports/png/<size>/<filename>.png

QA checklist
- Theming: verify light/dark, matrix/cyber neon, minimal
- Contrast: AA at 96px on backgrounds used in app
- Size: legible at 64 and 96
- Consistency: stroke = 2px outer, 1.5px detail; grid-aligned
- No raw hex in SVG; only CSS variables

Accessibility
- Provide labels like "Quiz Mastery (Earned)" in UI semantics

Notes
- Numbers (e.g., 5, 10, 30) use generic text in SVG; UI should provide accessible labels.
- Halos/gradients use token-driven variables and can be globally tuned per theme.

