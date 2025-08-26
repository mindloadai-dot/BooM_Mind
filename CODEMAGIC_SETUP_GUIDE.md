# 🚀 Codemagic CI/CD Setup Guide for MindLoad

This guide will help you set up automated builds and deployments for your MindLoad app using Codemagic.

## 📋 Prerequisites

1. **Codemagic Account**: Sign up at [codemagic.io](https://codemagic.io)
2. **Apple Developer Account**: For iOS builds and App Store distribution
3. **Google Play Console**: For Android builds and Play Store distribution
4. **Firebase Project**: For backend functions and configuration

## 🔧 Environment Variables Setup

### 1. **Firebase Configuration**
Set these in Codemagic UI under Environment Variables:

```
FIREBASE_PROJECT_ID = lca5kr3efmasxydmsi1rvyjoizifj4
FIREBASE_API_KEY = AIzaSyBUwmw8qPpAAWTTwNIpFHIwwSioYRX_UMk
```

### 2. **API Keys** (Mark as Encrypted)
```
OPENAI_API_KEY = your_openai_api_key_here
YOUTUBE_API_KEY = AIzaSyBEu3C5389QeqkrIcgUV06MkK4fZHNxP_Q
```

### 3. **Apple Developer Configuration** (Mark as Encrypted)
```
APP_STORE_CONNECT_ISSUER_ID = your_issuer_id
APP_STORE_CONNECT_KEY_IDENTIFIER = your_key_id
APP_STORE_CONNECT_PRIVATE_KEY = your_private_key_content
CERTIFICATE_PRIVATE_KEY = your_certificate_private_key
```

### 4. **Google Play Configuration** (Mark as Encrypted)
```
GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS = your_service_account_json
```

## 🍎 iOS Setup

### 1. **Apple Developer Portal**
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Create App ID: `com.MindLoad.ios`
3. Create Distribution Certificate
4. Create App Store Provisioning Profile

### 2. **App Store Connect**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app with bundle ID: `com.MindLoad.ios`
3. Generate API Key for Codemagic

### 3. **Codemagic iOS Integration**
1. In Codemagic, go to your app settings
2. Navigate to "Code signing identities"
3. Upload your distribution certificate
4. Add your provisioning profile
5. Configure App Store Connect integration

## 🤖 Android Setup

### 1. **Google Play Console**
1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app with package name: `com.MindLoad.android`
3. Generate service account for API access

### 2. **Codemagic Android Integration**
1. In Codemagic, go to your app settings
2. Navigate to "Code signing identities"
3. Upload your keystore file
4. Configure Google Play integration

## 🔥 Firebase Functions Setup

### 1. **Firebase CLI Token**
```bash
firebase login:ci
# Copy the token and add to Codemagic as FIREBASE_TOKEN
```

### 2. **Deploy Functions Manually First**
```bash
cd functions
npm install
firebase deploy --only functions
```

## 📱 Workflow Configuration

### **Main Workflow: `mindload-ios-android`**
- **Purpose**: Production builds for both platforms
- **Triggers**: Push to main branch, manual trigger
- **Outputs**: 
  - iOS IPA for App Store
  - Android AAB for Play Store
- **Publishing**: Automatic upload to TestFlight and Play Console

### **Development Workflow: `mindload-dev-build`**
- **Purpose**: Debug builds for testing
- **Triggers**: Push to develop branch, manual trigger
- **Outputs**: Debug APK and iOS app

### **Firebase Workflow: `mindload-firebase-deploy`**
- **Purpose**: Deploy Firebase Functions
- **Triggers**: Push to main branch, manual trigger
- **Outputs**: Updated Cloud Functions

## 🚀 Getting Started

### 1. **Connect Repository**
1. In Codemagic, click "Add application"
2. Connect your GitHub repository: `mindloadai-dot/BooM_Mind`
3. Select the `codemagic.yaml` file

### 2. **Configure Environment Variables**
1. Go to your app settings in Codemagic
2. Navigate to "Environment variables"
3. Add all the variables listed above
4. Mark sensitive variables as "Encrypted"

### 3. **Set Up Code Signing**
1. **iOS**: Upload certificates and provisioning profiles
2. **Android**: Upload keystore file
3. Configure automatic signing

### 4. **Configure Publishing**
1. **App Store Connect**: Set up API key integration
2. **Google Play**: Set up service account integration
3. **Email/Slack**: Configure notifications

## 🔄 Build Process

### **Automatic Triggers**
- **Main Branch**: Production builds → App Store & Play Store
- **Develop Branch**: Development builds → Internal testing
- **Manual**: Any branch can be built manually

### **Build Steps**
1. **Environment Setup**: Flutter, Xcode, CocoaPods
2. **Dependencies**: Clean pod install, Flutter packages
3. **Analysis**: Flutter analyze, unit tests
4. **Build**: iOS IPA, Android AAB
5. **Publish**: Upload to stores, send notifications

## 🛠️ Troubleshooting

### **Common Issues**

#### **CocoaPods Issues**
```yaml
# The workflow includes automatic pod clean/reinstall
- name: Clean and reinstall CocoaPods (fix build issues)
  script: |
    cd ios
    rm -rf Pods Podfile.lock
    pod cache clean --all
    pod repo update
    pod install --repo-update --verbose
```

#### **Swift Optimization Warnings**
- Fixed in the Podfile configuration
- Codemagic will use the updated settings

#### **Code Signing Issues**
- Ensure certificates are properly uploaded
- Check provisioning profile matches bundle ID
- Verify App Store Connect API key permissions

### **Build Logs**
- Check Codemagic build logs for detailed error messages
- Use verbose logging for debugging
- Contact Codemagic support for platform-specific issues

## 📊 Monitoring

### **Build Status**
- Monitor build success/failure rates
- Set up Slack/email notifications
- Use Codemagic dashboard for insights

### **Performance**
- Track build times
- Optimize dependencies
- Use caching for faster builds

## 🔐 Security Best Practices

1. **Environment Variables**: Always mark sensitive data as encrypted
2. **API Keys**: Store in Codemagic, not in code
3. **Certificates**: Use Codemagic's secure storage
4. **Access Control**: Limit team access to production workflows

## 📞 Support

- **Codemagic Docs**: [docs.codemagic.io](https://docs.codemagic.io)
- **Codemagic Support**: Available in the platform
- **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev)

---

## 🎉 Ready to Deploy!

Once configured, your MindLoad app will automatically:
- ✅ Build on every commit
- ✅ Run tests and analysis
- ✅ Deploy to TestFlight and Play Console
- ✅ Send notifications on success/failure
- ✅ Handle CocoaPods clean/reinstall automatically

Your CI/CD pipeline is now ready for production! 🚀
