# 🔧 Firebase Cloud Functions Fix Guide

## 🚨 **CRITICAL ISSUES IDENTIFIED**

1. **Missing OpenAI API Key** - AI generation completely broken
2. **Missing YouTube API Key** - YouTube processing completely broken  
3. **Authentication Issues** - Functions returning 403/401 errors

## 🎯 **IMMEDIATE FIX REQUIRED**

### **Step 1: Get Your API Keys**

#### **OpenAI API Key**
1. Go to: https://platform.openai.com/api-keys
2. Sign in or create account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)
5. **IMPORTANT**: Save this key securely - you won't see it again!

#### **YouTube API Key**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Select your project: `lca5kr3efmasxydmsi1rvyjoizifj4`
3. Click "Create Credentials" → "API Key"
4. Copy the API key
5. Enable YouTube Data API v3 for this key

### **Step 2: Configure Firebase Secrets**

#### **Option A: Firebase Console (Recommended)**
1. Go to: https://console.firebase.google.com/project/lca5kr3efmasxydmsi1rvyjoizifj4/functions/secrets
2. Click "Add Secret"
3. Add these secrets:

```
Name: OPENAI_API_KEY
Value: sk-your_actual_openai_key_here

Name: YOUTUBE_API_KEY  
Value: your_actual_youtube_api_key_here
```

#### **Option B: Firebase CLI**
```bash
# Set OpenAI API key
echo "sk-your_actual_openai_key_here" | firebase functions:secrets:set OPENAI_API_KEY

# Set YouTube API key
echo "your_actual_youtube_api_key_here" | firebase functions:secrets:set YOUTUBE_API_KEY
```

### **Step 3: Redeploy Functions**
```bash
firebase deploy --only functions
```

### **Step 4: Test Functions**
```bash
# Install dependencies
cd functions
npm install

# Run test script
node test_functions.js
```

## 🔍 **What This Will Fix**

### **✅ AI Generation Functions**
- `generateFlashcards` - Create study flashcards from content
- `generateQuiz` - Generate quiz questions from content  
- `processWithAI` - Comprehensive AI content processing

### **✅ YouTube Processing Functions**
- `youtubePreview` - Get video metadata and transcript info
- `youtubeIngest` - Process video transcripts for study materials
- `cleanupYouTubeRateLimit` - Manage rate limiting
- `cleanupYouTubeCache` - Manage caching

### **✅ All Other Functions**
- Notifications, user management, ledger system, etc.

## 🧪 **Testing Your Fix**

After configuring API keys and redeploying:

1. **Test from Flutter App**:
   - Upload a PDF document
   - Try to generate flashcards/quiz questions
   - Check if AI generation works

2. **Test YouTube Integration**:
   - Paste a YouTube URL
   - Check if preview loads
   - Try to ingest transcript

3. **Check Function Logs**:
   ```bash
   firebase functions:log
   ```

## 🚀 **Expected Results**

- ✅ AI generation working (flashcards, quizzes)
- ✅ YouTube preview and ingest working
- ✅ No more "not authorized" errors
- ✅ Functions returning proper data instead of errors

## 🔒 **Security Notes**

- ✅ API keys are stored securely in Firebase Secrets
- ✅ Functions require authentication + App Check
- ✅ No hardcoded secrets in code
- ✅ Proper rate limiting and abuse prevention

## 📞 **If Still Having Issues**

1. **Check Firebase Console** for function logs
2. **Verify API keys** are properly set in Secrets
3. **Check function deployment** status
4. **Test with simple content** first
5. **Verify App Check** is working in Flutter app

## 🎉 **Success Indicators**

- AI generation creates actual flashcards/quiz questions
- YouTube URLs process successfully
- No more authentication errors in logs
- Functions return proper JSON responses
- Flutter app can successfully call all functions

---

**⚠️ IMPORTANT**: This fix is required for your app to function properly. Without these API keys, the AI generation and YouTube processing features will continue to fail.
