# Firebase IAP Backend Deployment Guide

This guide covers deploying the complete Firebase IAP verification and entitlements system for Mindload.

## 🎯 Overview

The Firebase IAP backend provides:
- **Server-side purchase verification** with Apple/Google stores
- **Idempotent entitlement management** with webhook handling
- **Global credit quota enforcement** and audit trails
- **Automated reconciliation** and payout readiness
- **Real-time developer notifications** processing

## 📋 Prerequisites

1. **Firebase Project Setup**
   - Firebase project: `lca5kr3efmasxydmsi1rvyjoizifj4`
   - Firestore database enabled
   - Cloud Functions enabled
   - App Check configured

2. **Apple Store Connect Setup**
   - App Store Connect API key created
   - Issuer ID, Key ID, and Private Key obtained
   - Server-to-Server Notifications V2 configured

3. **Google Play Console Setup**
   - Service account created with necessary permissions
   - Real-time Developer Notifications enabled
   - Pub/Sub topic configured

## 🔧 Deployment Steps

### 1. Secret Manager Configuration

Store sensitive credentials in Firebase Secret Manager:

```bash
# Apple Store Connect API credentials
firebase functions:secrets:set APPLE_ISSUER_ID
firebase functions:secrets:set APPLE_KEY_ID
firebase functions:secrets:set APPLE_PRIVATE_KEY

# Google Play service account
firebase functions:secrets:set GOOGLE_SERVICE_ACCOUNT_JSON

# Set project region
firebase functions:config:set project.region=us-central1
```

### 2. Pub/Sub Topics Setup

Create required Pub/Sub topics:

```bash
# Create topic for IAP event processing
gcloud pubsub topics create iap-event-processing

# Create topic for Google RTDN (if not exists)
gcloud pubsub topics create rtdn-play-billing

# Create subscription for Google RTDN
gcloud pubsub subscriptions create rtdn-play-billing-sub \
  --topic=rtdn-play-billing
```

### 3. Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:iapAppleNotifyV2,functions:iapGoogleRtdnSub,functions:iapVerifyPurchase,functions:iapRestoreEntitlements,functions:processIapEvent,functions:iapReconcileSample
```

### 4. Deploy Firestore Rules and Indexes

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 5. Configure Webhooks

#### Apple Server Notifications V2
- **Endpoint**: `https://us-central1-lca5kr3efmasxydmsi1rvyjoizifj4.cloudfunctions.net/iapAppleNotifyV2`
- **Version**: V2
- **Bundle ID**: `com.MindLoad.ios`

#### Google Real-time Developer Notifications
- **Topic**: `projects/lca5kr3efmasxydmsi1rvyjoizifj4/topics/rtdn-play-billing`
- **Package**: `com.MindLoad.android`

## 🗃️ Firestore Collections Structure

The backend automatically manages these collections:

### `users/{uid}`
```javascript
{
  tier: "free|pro_monthly|pro_annual",
  credits: 60,
  renewalDate: Timestamp,
  platform: "ios|android|unknown",
  introUsed: false,
  countryCode: "US", // ISO-3166
  languageCode: "en", // BCP-47
  timezone: "America/Chicago", // IANA
  updatedAt: Timestamp
}
```

### `entitlements/{uid}`
```javascript
{
  status: "none|active|grace|on_hold|paused|expired",
  productId: "mindload_pro_monthly",
  platform: "ios|android",
  startAt: Timestamp,
  endAt: Timestamp,
  autoRenew: true,
  latestTransactionId: "transaction_id",
  lastVerifiedAt: Timestamp,
  updatedAt: Timestamp
}
```

### `iapEvents/{eventId}`
```javascript
{
  platform: "ios|android",
  type: "subscribed|did_renew|expired|refund",
  transactionId: "transaction_id",
  purchaseToken: "purchase_token", // Android only
  uid: "user_id",
  processedAt: Timestamp,
  status: "pending|processed|skipped",
  raw: {}, // Original webhook payload
  createdAt: Timestamp
}
```

### `creditLedger/{uid}/entries/{entryId}`
```javascript
{
  delta: 60,
  reason: "Monthly renewal: 60 base + 0 rollover",
  sourceEventId: "event_id",
  createdAt: Timestamp
}
```

### `receipts/{uid}/{platform}_{transactionId}`
```javascript
{
  status: "active|expired|refunded",
  lastVerifiedAt: Timestamp,
  raw: {}, // Store verification response
  updatedAt: Timestamp
}
```

## ⚙️ Cloud Functions

### Core Functions

1. **`iapAppleNotifyV2`** (HTTPS Trigger)
   - Handles Apple Server Notifications V2
   - Validates JWT signatures
   - Creates IAP events for processing

2. **`iapGoogleRtdnSub`** (Pub/Sub Trigger)
   - Processes Google RTDN messages
   - Creates IAP events for processing

3. **`iapVerifyPurchase`** (Callable)
   - Client-callable purchase verification
   - Requires Firebase Auth + App Check
   - Immediate processing for user purchases

4. **`iapRestoreEntitlements`** (Callable)
   - Rebuilds user entitlements from store
   - Queries active subscriptions
   - Updates local entitlement status

5. **`processIapEvent`** (Pub/Sub Background)
   - Background worker for IAP event processing
   - Handles idempotency checks
   - Updates user credits and entitlements

6. **`iapReconcileSample`** (Scheduled)
   - Daily reconciliation (2 AM Chicago time)
   - Processes 5% random user sample
   - Corrects entitlement mismatches

## 🔒 Security Features

- **App Check Integration**: Protects callable functions
- **Idempotent Processing**: Prevents duplicate credits
- **Server-side Verification**: All store API calls server-side
- **Audit Trail**: Complete credit ledger history
- **Firestore Security Rules**: User-scoped data access

## 📊 Credit Quotas (Server-Enforced)

- **Free Tier**: 3 credits/month
- **Pro Monthly**: 60 credits/month + up to 30 rollover
- **Intro Month**: 30 credits (first $2.99 month only)
- **Starter Pack**: +100 credits immediately

## 🔄 Reconciliation

- **Daily Sample**: 5% of Pro users verified nightly
- **Manual Trigger**: `iapReconcileUser` callable function
- **Automatic Correction**: Mismatches corrected server-side
- **Audit Logging**: All changes logged to credit ledger

## 🌍 Global Compliance

- **Territory Coverage**: Worldwide via App Store/Play Store
- **Currency Handling**: Local pricing by platform stores
- **Timezone Management**: America/Chicago (ops) + user display
- **GDPR/Privacy**: No PII in telemetry, user-scoped data

## 🚀 Testing

### Test Purchase Flow
1. Make test purchase in app
2. Verify `iapEvents` collection receives event
3. Check `processIapEvent` processes correctly
4. Confirm user credits updated in `users` collection
5. Validate audit trail in `creditLedger`

### Test Webhooks
1. Trigger test notification from store console
2. Verify webhook function receives and processes
3. Check event created in `iapEvents`
4. Confirm background processing completes

### Test Reconciliation
1. Call `iapReconcileUser` function manually
2. Verify store status query
3. Check entitlement correction if needed

## 🔍 Monitoring

- **Cloud Functions Logs**: Monitor function execution
- **Firestore Usage**: Track read/write operations
- **Error Alerts**: Set up alerting for function failures
- **Reconciliation Reports**: Monitor nightly reconciliation

## 📝 Maintenance

### Regular Tasks
- Review error logs weekly
- Monitor credit quota usage
- Check reconciliation success rates
- Update store API credentials as needed

### Updates
- Update Apple/Google API integrations
- Refresh webhook endpoints if needed
- Update Firestore indexes for new queries
- Review and update security rules

## 🆘 Troubleshooting

### Common Issues
1. **Webhook Not Working**: Check endpoint URLs and authentication
2. **Credits Not Updating**: Verify `processIapEvent` function logs
3. **Verification Failing**: Check Apple/Google API credentials
4. **Reconciliation Errors**: Review store API responses

### Debug Tools
- Firebase Functions logs
- Firestore data explorer  
- IAP telemetry data
- Manual reconciliation function

---

This deployment creates a production-ready IAP backend with global compliance, idempotent processing, and automated reconciliation for the Mindload app.