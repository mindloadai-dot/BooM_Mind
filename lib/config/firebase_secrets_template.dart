// Firebase Secret Manager configuration template for Mindload
// This file serves as a template for the actual secrets stored in Firebase Secret Manager
// DO NOT store actual secret values in this file - use Firebase Secret Manager instead

class FirebaseSecretsTemplate {
  // ========================================
  // APPLE APP STORE CONNECT SECRETS
  // ========================================
  
  // Apple Issuer ID from App Store Connect API
  // Location: App Store Connect > Users and Roles > Keys > Issuer ID
  static const String appleIssuerIdKey = 'APPLE_ISSUER_ID';
  // Example value (stored in Secret Manager): '69a6de80-cfbd-47ef-9fba-59b5b9338e5a'
  
  // Apple Key ID from App Store Connect API  
  // Location: App Store Connect > Users and Roles > Keys > Key ID
  static const String appleKeyIdKey = 'APPLE_KEY_ID';
  // Example value (stored in Secret Manager): 'ABC123DEF4'
  
  // Apple Private Key from App Store Connect API (.p8 file content)
  // Location: Downloaded .p8 file from App Store Connect
  static const String applePrivateKeyKey = 'APPLE_PRIVATE_KEY';
  // Example value (stored in Secret Manager): '-----BEGIN PRIVATE KEY-----\nMIGTAg...'
  
  // Apple Bundle ID (from app configuration)
  static const String appleBundleIdKey = 'APPLE_BUNDLE_ID';
  // Example value (stored in Secret Manager): 'com.MindLoad.ios'

  // ========================================
  // GOOGLE PLAY CONSOLE SECRETS  
  // ========================================
  
  // Google Service Account JSON (full JSON as string)
  // Location: Google Cloud Console > IAM & Admin > Service Accounts > Create Key
  static const String googleServiceAccountJsonKey = 'GOOGLE_SERVICE_ACCOUNT_JSON';
  // Example value (stored in Secret Manager): '{"type": "service_account", "project_id": "..."}'
  
  // Google Package Name (from app configuration)
  static const String googlePackageNameKey = 'GOOGLE_PACKAGE_NAME';
  // Example value (stored in Secret Manager): 'com.MindLoad.android'
  
  // Google Play Pub/Sub Topic for Real-time Developer Notifications
  // Location: Google Cloud Console > Pub/Sub > Topics
  static const String playPubsubTopicKey = 'PLAY_PUBSUB_TOPIC';
  // Example value (stored in Secret Manager): 'projects/mindload-firebase/topics/rtdn-play-billing'

  // ========================================
  // OPENAI API CONFIGURATION
  // ========================================
  
  // OpenAI API Key for AI-powered content generation
  // Location: OpenAI Platform > API Keys > Create new secret key
  static const String openaiApiKeyKey = 'OPENAI_API_KEY';
  // Example value (stored in Secret Manager): 'YOUR_OPENAI_API_KEY_HERE'
  
  // OpenAI API Endpoint (optional, defaults to official OpenAI endpoint)
  // Location: Custom proxy endpoint if using one, otherwise leave empty
  static const String openaiEndpointKey = 'OPENAI_API_ENDPOINT';
  // Example value (stored in Secret Manager): 'https://api.openai.com/v1' or custom proxy URL
  
  // OpenAI API Organization ID (optional, for enterprise accounts)
  // Location: OpenAI Platform > Settings > Organization
  static const String openaiOrgIdKey = 'OPENAI_ORG_ID';
  // Example value (stored in Secret Manager): 'org-1234567890abcdef'

  // ========================================
  // SECRET CONFIGURATION MAP
  // ========================================
  
  // All required secrets for international IAP compliance
  static const Map<String, String> requiredSecrets = {
    // Apple secrets
    appleIssuerIdKey: 'Required for Apple App Store receipt verification',
    appleKeyIdKey: 'Required for Apple App Store API authentication', 
    applePrivateKeyKey: 'Required for Apple App Store API signing',
    appleBundleIdKey: 'Required for Apple App Store product verification',
    
    // Google secrets
    googleServiceAccountJsonKey: 'Required for Google Play API authentication',
    googlePackageNameKey: 'Required for Google Play product verification',
    playPubsubTopicKey: 'Required for Google Play webhook notifications',
    
    // OpenAI secrets
    openaiApiKeyKey: 'Required for AI-powered content generation (flashcards, quizzes, study tips)',
  };

  // ========================================
  // SETUP INSTRUCTIONS
  // ========================================
  
  static const String setupInstructions = '''
FIREBASE SECRET MANAGER SETUP INSTRUCTIONS:

1. APPLE APP STORE CONNECT SETUP:
   a) Login to App Store Connect
   b) Go to Users and Roles > Keys
   c) Generate new API key with "Developer" role
   d) Download the .p8 private key file
   e) Note the Key ID and Issuer ID
   f) Store all values in Firebase Secret Manager

2. GOOGLE PLAY CONSOLE SETUP:
   a) Go to Google Cloud Console (same project as Firebase)
   b) Create service account with "Editor" role
   c) Generate JSON key for service account
   d) Enable Google Play Android Developer API
   e) Grant service account access in Play Console
   f) Set up Pub/Sub topic for notifications
   g) Store all values in Firebase Secret Manager

3. FIREBASE SECRET MANAGER:
   a) Go to Google Cloud Console > Security > Secret Manager
   b) Create secrets using the keys from requiredSecrets map
   c) Grant Cloud Functions service account access to secrets
   d) Update Cloud Functions to load secrets at runtime

4. CLOUD FUNCTIONS CONFIGURATION:
   - All secrets are loaded in Cloud Functions
   - Never store secrets in client code
   - Use Firebase Admin SDK for server-side verification
   - Implement idempotent webhook handlers

5. OPENAI API SETUP:
   a) Go to OpenAI Platform > API Keys
   b) Create new secret key (starts with sk-...)
   c) Copy the full API key
   d) Store in Firebase Secret Manager as OPENAI_API_KEY
   e) Optionally set OPENAI_API_ENDPOINT if using custom proxy
   f) Optionally set OPENAI_ORG_ID for enterprise accounts

Example Firebase CLI commands:
gcloud secrets create APPLE_ISSUER_ID --data-file=apple_issuer_id.txt
gcloud secrets create APPLE_KEY_ID --data-file=apple_key_id.txt
gcloud secrets create APPLE_PRIVATE_KEY --data-file=apple_private_key.p8
gcloud secrets create GOOGLE_SERVICE_ACCOUNT_JSON --data-file=service_account.json
gcloud secrets create OPENAI_API_KEY --data-file=openai_api_key.txt

''';

  // ========================================
  // VALIDATION METHODS
  // ========================================
  
  // Check if all required secrets are configured (for Cloud Functions)
  static List<String> validateSecretsConfiguration(Map<String, String> secrets) {
    final List<String> missing = [];
    
    for (final key in requiredSecrets.keys) {
      if (!secrets.containsKey(key) || secrets[key]?.isEmpty == true) {
        missing.add(key);
      }
    }
    
    return missing;
  }
  
  // Get Cloud Functions environment configuration
  static Map<String, String> getCloudFunctionsEnvConfig() {
    return {
      'GOOGLE_CLOUD_PROJECT': 'mindload-firebase', // Replace with actual project ID
      'FIREBASE_CONFIG': 'auto', // Firebase automatically provides this
      'NODE_ENV': 'production',
      'TZ': 'America/Chicago', // Default ops timezone
    };
  }
}

// ========================================
// REMOTE CONFIG DEFAULTS
// ========================================

class RemoteConfigDefaults {
  static const Map<String, dynamic> internationalIapDefaults = {
    // Product availability flags
    'intro_enabled': true,
    'annual_intro_enabled': true, 
    'starter_pack_enabled': true,
    
    // System operation flags
    'iap_only_mode': true,
    'manage_links_enabled': true,
    
    // Territory and compliance
    'supported_territories': 'worldwide',
    'currency_localization': 'store_handled',
    'intro_offer_limit': 'once_per_user',
    
    // Payout readiness indicators
    'apple_payout_ready': false, // Set to true after completing Apple setup
    'google_payout_ready': false, // Set to true after completing Google setup
    'webhook_verification_enabled': true,
  };
  
  static const String remoteConfigSetupInstructions = '''
FIREBASE REMOTE CONFIG SETUP:

1. Go to Firebase Console > Remote Config
2. Add all parameters from internationalIapDefaults
3. Set production values after completing store setup
4. Use Remote Config to control rollout and compliance

Key Remote Config Parameters:
- intro_enabled: Controls monthly subscription intro offer
- annual_intro_enabled: Controls annual subscription intro offer  
- starter_pack_enabled: Controls credit pack availability
- iap_only_mode: Must be true (no external payments)
- manage_links_enabled: Controls subscription management links

Update these flags to true after completing store setup:
- apple_payout_ready: Apple App Store payout profile active
- google_payout_ready: Google Play payout profile active
''';
}