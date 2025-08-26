# Mindload Pricing & ML Tokens Guide

## What changed

- "Credits" are now branded as "MindLoad Tokens" (ML Tokens) in user-facing text.
- Starter Pack: $1.99 → +5 ML Tokens.
- Document uploads consume 1 ML Token per 5 PDF pages (rounded up).
- PDF upload caps per tier increased:
  - Free: 50 pages max per file, 3 uploads/day
  - Pro: 200 pages max per file, 20 uploads/day
  - Annual: 300 pages max per file, 30 uploads/day
- Paywall reads prices dynamically from Remote Config via `PricingService`.

## Core concepts

- **ML Tokens**: The unit your users spend on generation and document uploads.
- **Pricing**: Pro Monthly, Pro Annual, Starter Pack (consumable). Displayed prices come from Remote Config when provided; otherwise app defaults.
- **Document costs**: 1 ML Token per 5 pages (ceil). Example: 1–5 pages → 1 token; 6–10 pages → 2 tokens, etc.

## Where to change pricing at runtime (no app update needed)

Use Remote Config keys (0 means “use defaults”):

- `pricing_pro_monthly_usd` (double)
- `pricing_pro_annual_usd` (double)
- `pricing_starter_pack_usd` (double)
- `tokens_free_monthly` (int)
- `tokens_pro_monthly` (int)
- `tokens_intro_month` (int)
- `tokens_starter_pack_bonus` (int)

When set, the paywall will pick up values after RC fetch/activate (on next app start or RC refresh).

## Programmatic overrides (dev/admin)

`lib/services/pricing_service.dart` centralizes pricing. Initialize it at startup (we already do for paywall) and use overrides to change values on the fly:

```dart
await PricingService.instance.initialize();

await PricingService.instance.applyOverrides({
  'pricing_pro_monthly_usd': 6.49,
  'pricing_pro_annual_usd': 44.99,
  'pricing_starter_pack_usd': 1.99,
  'tokens_pro_monthly': 50,
  'tokens_starter_pack_bonus': 5,
});
```

Overrides persist locally (StorageService). Remove keys or set to 0 in RC to revert to defaults.

## Reading pricing/quotas in UI

- Use `PricingService.instance` getters:
  - Prices: `proMonthlyPrice`, `proAnnualPrice`, `starterPackPrice`
  - Quotas: `proMonthlyTokens`, `freeMonthlyTokens`, `introMonthTokens`, `starterPackTokens`
- Paywall (`lib/screens/paywall_screen.dart`) already uses `PricingService` to display monthly/annual prices.
  - To display quotas on the paywall, read `PricingService.proMonthlyTokens` and add to copy (e.g., "60 ML Tokens/month").

## Token costs & uploads

- Enforcement lives in:
  - `lib/services/document_processor.dart`: `validatePdfPageLimit(bytes)` checks tier caps and token availability.
  - `lib/services/credit_service.dart`: `creditsForPageCount(pageCount)` returns ceil(pageCount/5), `useCreditsForDocumentPages(...)` deducts.
  - `lib/services/firebase_client_service.dart`:
    - `uploadPDF(...)` validates caps and deducts tokens before uploading.
    - `uploadImageAsPdf(imageBytes, ...)` converts an image to 1-page PDF, validates, and deducts 1 token before uploading.

## IAP product IDs & readiness

- Product IDs (unchanged):
  - Monthly: `mindload_pro_monthly`
  - Annual: `mindload_pro_annual`
  - Starter Pack: `mindload_starter_pack_100` (display name/description should say "+5 ML Tokens"; ID remains the same for store continuity)
- Android (Play Console):
  - Enable Google Play Billing; configure 3 products above.
  - Set prices to match Remote Config (RC can differ for A/B tests; ensure store pricing still makes sense vs UI copy).
- iOS (App Store Connect):
  - Configure in-app purchase products with same IDs.
  - Ensure "Sign in with Apple" capability is enabled.

## Recommended defaults (editable)

- Prices (USD):
  - Monthly: $5.99, Annual: $49.99, Starter: $1.99
- Tokens:
  - Free: 5/month, Pro: 60/month, Intro: 30 first month, Starter Pack: +5

## Localized copy (ML Tokens branding)

- User-facing strings have been updated in high-impact places (paywall, exit intent, snackbars). If you see remaining "credits" strings, search and replace in:
  - `lib/screens/`, `lib/widgets/`, `lib/services/remote_config_service.dart`, `lib/l10n/app_localizations.dart`

## QA checklist after changing pricing/quotas

1. RC keys set and published; app relaunched
2. Paywall shows new monthly/annual prices
3. Starter pack shows "+5 ML Tokens"
4. Upload a 12-page PDF → expects 3 ML Tokens
5. Capture an image and upload → 1 ML Token deducted
6. Tier caps enforced: Free 50p, Pro 200p, Annual 300p per PDF
7. Purchases complete successfully and entitlements apply

## Troubleshooting

- Paywall still shows old prices:
  - Ensure RC keys are non-zero; restart app or trigger RC fetch
- "Insufficient tokens" when uploading small files:
  - Check available tokens, and verify `creditsForPageCount` rule (ceil by 5 pages)
- Starter pack still says +100:
  - Update store listing text; product ID stays the same for compatibility


