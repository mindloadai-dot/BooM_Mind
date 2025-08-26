# Product & Plans Wording Implementation Summary

## ✅ IMPLEMENTED: Centralized Product Constants

### 1. Single Source of Truth Created
- **File**: `lib/constants/product_constants.dart`
- **Purpose**: Centralized constants for all product naming, pricing, and token terminology
- **Usage**: Used across paywall, settings, receipts, FAQs, empty states, dialogs, emails/notifications

### 2. Subscription Plan Implementation
- **Axon Monthly**: $4.99/month (price fetched from stores)
- **Name**: "Axon Monthly" (never "Pro")
- **Tokens**: 120 MindLoad Tokens/month
- **Features**: Ultra Mode access, priority processing

### 3. Logic Packs (One-time top-ups) - DO NOT RENAME
- **Spark Pack**: $2.99 → +50 MindLoad Tokens
- **Neuro Pack**: $4.99 → +100 MindLoad Tokens  
- **Cortex Pack**: $9.99 → +250 MindLoad Tokens
- **Synapse Pack**: $19.99 → +500 MindLoad Tokens
- **Quantum Pack**: $49.99 → +1500 MindLoad Tokens

### 4. Token Unit Standardization
- **Unit Name**: "MindLoad Tokens" (NEVER "credits")
- **Short Form**: "ML Tokens" (acceptable abbreviation)
- **Free Monthly Allowance**: "Every new user gets 20 MindLoad Tokens each month."

### 5. Consumption Order Implementation
- **Order**: 20-Token monthly allowance first, then Logic Pack balances, then subscription bonuses
- **Copy**: "Tokens are consumed in this order: 20-Token monthly allowance first, then Logic Pack balances, then any subscription bonuses."

### 6. Rollover Policy Implementation
- **Monthly Allowance**: Does not roll over
- **Logic Pack Balances**: Persist month-to-month
- **Copy**: "Monthly allowance does not roll over; Logic Pack balances persist month-to-month."

## 🔄 UPDATED FILES

### Core Constants
- ✅ `lib/constants/product_constants.dart` - NEW FILE - Single source of truth

### Models
- ✅ `lib/models/pricing_models.dart` - Updated to use centralized constants
- ✅ `lib/models/subscription_models.dart` - Updated to use centralized constants

### Services  
- ✅ `lib/services/credit_service.dart` - Updated to use centralized constants
- ✅ `lib/services/enhanced_subscription_service.dart` - Updated to use centralized constants

### UI Screens
- ✅ `lib/screens/paywall_screen.dart` - Updated to use centralized constants
- ✅ `lib/screens/enhanced_subscription_screen.dart` - Updated to use centralized constants

### Localization
- ✅ `lib/l10n/app_localizations.dart` - Updated English and Spanish strings

## 📱 USER-FACING CHANGES

### Paywall Updates
- **Header**: "Unlock Axon Monthly for Focused Wins"
- **Monthly Plan**: "$4.99/month • 120 MindLoad Tokens/month"
- **Logic Packs**: "MindLoad Logic Packs" with proper naming

### Settings Screen Updates
- **Subscription Management**: "Upgrade to Axon Monthly"
- **Token Display**: "Remaining MindLoad Tokens"
- **Help Section**: "How MindLoad Tokens Work"

### Localization Updates
- **English**: Updated to use "Axon Monthly" and "MindLoad Tokens"
- **Spanish**: Updated to use "Axon Mensual" and "MindLoad Tokens"

## 🎯 NEXT STEPS FOR COMPLETE IMPLEMENTATION

### 1. Update Remaining Localization Files
- Portuguese, French, German, Italian, Japanese, Korean, Chinese, Arabic, Hindi
- Replace all instances of "Pro" with "Axon Monthly"
- Replace all instances of "credits" with "MindLoad Tokens"

### 2. Update Remaining UI Components
- Empty state messages
- Dialog confirmations
- Error messages
- Success messages
- Notification content

### 3. Update Documentation
- FAQ sections
- Help guides
- Terms of service
- Privacy policy

### 4. Update Email Templates
- Welcome emails
- Purchase confirmations
- Subscription reminders
- Low token notifications

## 🔍 SEARCH & REPLACE PATTERNS

### Critical Replacements
- `"Pro"` → `ProductConstants.axonMonthlyName`
- `"credits"` → `ProductConstants.tokenUnitName`
- `"ML Tokens"` → `ProductConstants.tokenUnitNameShort` (when space is limited)

### File Patterns to Search
- `*.dart` - All Dart files
- `*.md` - Documentation files
- `*.json` - Configuration files
- `*.yaml` - Configuration files

### Common Phrases to Update
- "Upgrade to Pro" → "Upgrade to Axon Monthly"
- "Pro subscription" → "Axon Monthly subscription"
- "Pro features" → "Axon Monthly features"
- "Pro access" → "Axon Monthly access"

## ✅ VERIFICATION CHECKLIST

- [x] Centralized constants file created
- [x] Core models updated
- [x] Core services updated  
- [x] Main paywall screen updated
- [x] Main subscription screen updated
- [x] English localization updated
- [x] Spanish localization updated
- [ ] Remaining localizations updated
- [ ] Empty state messages updated
- [ ] Dialog messages updated
- [ ] Error messages updated
- [ ] Success messages updated
- [ ] Notification content updated
- [ ] Email templates updated
- [ ] Documentation updated
- [ ] FAQ content updated

## 🚀 BENEFITS OF IMPLEMENTATION

1. **Single Source of Truth**: All product naming comes from one file
2. **Easy Updates**: Change pricing/names without touching multiple files
3. **Consistency**: Guaranteed consistent terminology across the app
4. **Localization Ready**: Easy to translate and maintain
5. **Brand Compliance**: Ensures "MindLoad Tokens" branding everywhere
6. **Maintenance**: Simple to update when products change

## 📞 SUPPORT NOTES

- **Never use "credits"** - Always use "MindLoad Tokens"
- **Never use "Pro"** - Always use "Axon Monthly" 
- **Logic Pack names are fixed** - Do not rename these products
- **Consumption order is fixed** - Monthly allowance → Logic Packs → Subscription bonuses
- **Rollover policy is fixed** - Monthly allowance doesn't roll over, Logic Packs persist
