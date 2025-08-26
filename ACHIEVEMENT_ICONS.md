## Achievement Icon Assets

This document specifies the icon assets to be used for achievements. Provide the files and I will wire them into the app.

### Directory
Place assets here (preferred):

```
assets/images/achievements/
```

If you prefer a different path, note it and I will update `pubspec.yaml` accordingly.

### File formats
- Preferred: SVG (vector) for crisp rendering across DPIs
- Alternative: PNG @3x (e.g., 96×96 or 120×120) with transparent background
- Color model: sRGB, no color profile embedding

### Naming conventions
- Use lowercase with underscores
- Category base icon: `<category>.png`
- Tier overlay: `tier_<tier>.png`
- State variant (optional): `state_<state>.png`
- Specific achievement: `achievement_<id>.png`

### Category base icons (one per category)
- streaks.png
- study_time.png
- cards_created.png
- cards_reviewed.png
- quiz_mastery.png
- consistency.png
- creation.png
- ultra_exports.png

### Tier overlays (placed above the base)
- tier_bronze.png
- tier_silver.png
- tier_gold.png
- tier_platinum.png
- tier_legendary.png

### State variants (optional)
- state_earned.png
- state_in_progress.png
- state_locked.png

### Specific achievement icons (by ID)
- achievement_focused_five.png
- achievement_steady_ten.png
- achievement_relentless_thirty.png
- achievement_quarter_brain.png
- achievement_year_of_cortex.png
- achievement_warm_up.png
- achievement_deep_diver.png
- achievement_grinder.png
- achievement_scholar.png
- achievement_marathon_mind.png
- achievement_forge_250.png
- achievement_forge_1k.png
- achievement_forge_5k.png
- achievement_forge_10k.png
- achievement_forge_25k.png
- achievement_review_1k.png
- achievement_review_5k.png
- achievement_review_10k.png
- achievement_review_25k.png
- achievement_review_50k.png
- achievement_ace_10.png
- achievement_ace_25.png
- achievement_ace_50.png
- achievement_ace_100.png
- achievement_ace_250.png
- achievement_five_a_week.png
- achievement_distraction_free.png
- achievement_five_per_week.png
- achievement_efficient_creator.png
- achievement_review_master.png
- achievement_set_builder_20.png
- achievement_set_builder_50.png
- achievement_set_builder_100.png
- achievement_efficiency_sage.png
- achievement_ultra_runs_10.png
- achievement_ultra_runs_30.png
- achievement_ultra_runs_75.png
- achievement_ultra_runs_150.png
- achievement_ship_it_5.png
- achievement_ship_it_20.png
- achievement_ship_it_50.png
- achievement_ship_it_100.png

### Delivery checklist
- [ ] Files placed in `assets/images/achievements/`
- [ ] Transparent background
- [ ] Consistent stroke/line weight and padding (visual balance in a circle ~80×80)
- [ ] Provide a brief palette or brand color reference (optional)

Once assets are added, I will:
1) Update `pubspec.yaml` asset paths (if needed)
2) Map icons in the achievement badge renderer
3) Verify contrast and add fallbacks if a file is missing


