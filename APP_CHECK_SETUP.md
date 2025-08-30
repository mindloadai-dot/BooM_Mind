# 🔐 Firebase App Check Configuration Guide

## Step 1: Enable App Check in Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/project/lca5kr3efmasxydmsi1rvyjoizifj4
2. **Navigate to App Check**: Click "App Check" in the left sidebar
3. **Register your apps**:

### Android App Configuration
- **App ID**: `1:884947669542:android:3a905516036f560ba74ce7`
- **Provider**: Select "Play Integrity API" for production
- **Debug Token**: Create debug tokens for development

### iOS App Configuration (if applicable)
- **App ID**: `1:884947669542:ios:a0f6587d65102118a74ce7`
- **Provider**: Select "DeviceCheck" for production
- **Debug Token**: Create debug tokens for development

### Web App Configuration (if applicable)
- **App ID**: `1:884947669542:web:db39decdf401cc5ba74ce7`
- **Provider**: reCAPTCHA v3
- **Site Key**: `6LfGQoIqAAAAABfRlSGNXKGvlYl0_ZW5Hd6Ys5Bq`

## Step 2: Create Debug Tokens for Development

### For Android Development:
1. In Firebase Console → App Check → Apps tab
2. Click on your Android app
3. Click "Manage debug tokens"
4. Click "Add debug token"
5. **Token name**: "Android Development"
6. Copy the generated token and add it to your app

### Debug Token Integration:
```dart
// In lib/config/app_check_config.dart
const debugToken = 'YOUR_GENERATED_DEBUG_TOKEN_HERE';
```

## Step 3: Configure Cloud Functions for App Check

Your Cloud Functions are already configured with:
```typescript
// functions/src/openai.ts
export const generateFlashcards = onCall({
  enforceAppCheck: false, // Set to true for production
  cors: true,
  secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
  // Function logic
});
```

## Step 4: Test App Check Integration

### Development Testing:
1. Run the Flutter app in debug mode
2. Check logs for App Check initialization
3. Look for: `✅ Firebase App Check activated successfully (debug mode)`

### Production Testing:
1. Build release APK/IPA
2. Test with production providers
3. Monitor Firebase Console → App Check → Metrics

## Step 5: Enable App Check Enforcement (Production)

Once testing is complete:

1. **Update Cloud Functions**:
```typescript
export const generateFlashcards = onCall({
  enforceAppCheck: true, // Enable for production
  cors: true,
  secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
  // Function logic
});
```

2. **Deploy updated functions**:
```bash
firebase deploy --only functions
```

## Current Status

✅ **App Check Code**: Configured in Flutter app
✅ **Cloud Functions**: Ready for App Check (currently lenient)
✅ **Debug Providers**: Configured for development
⚠️ **Debug Tokens**: Need to be created in Firebase Console
⚠️ **Production Providers**: Need to be enabled in Firebase Console

## Troubleshooting

### Common Issues:
1. **"No AppCheckProvider installed"** → Enable debug providers
2. **UNAUTHENTICATED errors** → Create debug tokens
3. **App Check token failed** → Check provider configuration

### Debug Commands:
```dart
// Check App Check status
final debugInfo = await AppCheckConfig.getDebugInfo();
print('App Check Debug Info: $debugInfo');
```

## Next Steps

1. **Manual Setup Required**: Go to Firebase Console and configure App Check
2. **Create Debug Tokens**: For seamless development experience
3. **Test Integration**: Verify OpenAI functions work with App Check
4. **Enable Enforcement**: Once testing is complete

---

**Firebase Console Link**: https://console.firebase.google.com/project/lca5kr3efmasxydmsi1rvyjoizifj4/appcheck
