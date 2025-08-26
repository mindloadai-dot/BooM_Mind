# Firebase Deployment Troubleshooting Guide

## 🚀 Quick Fix Commands

### 1. Reset and Deploy from Scratch
```bash
# 1. Clean everything
rm -rf functions/lib functions/node_modules
cd functions && npm install && cd ..

# 2. Build functions
cd functions && npm run build && cd ..

# 3. Deploy step by step
firebase deploy --only firestore
firebase deploy --only storage  
firebase deploy --only functions
firebase deploy --only hosting
```

### 2. Common Error Fixes

#### "Process Exception" Errors
```bash
# Kill any hanging processes
pkill -f firebase
pkill -f node

# Clear Firebase cache
firebase logout
firebase login
```

#### "Build Failed" Errors
```bash
# Reset functions completely
cd functions
rm -rf lib node_modules package-lock.json
npm cache clean --force
npm install
npm run build
```

#### "Rules Invalid" Errors
```bash
# Test rules locally
firebase emulators:start --only firestore
# Check rules syntax in firebase.json
```

## 🔍 Deployment Order

**Always deploy in this order:**
1. Firestore Rules (`firebase deploy --only firestore`)
2. Storage Rules (`firebase deploy --only storage`)
3. Functions (`firebase deploy --only functions`)
4. Hosting (`firebase deploy --only hosting`)

## 📋 Pre-Deployment Checklist

- [ ] Firebase CLI installed and updated (`npm install -g firebase-tools`)
- [ ] Logged into Firebase (`firebase login`)
- [ ] Project selected (`firebase use --add`)
- [ ] Functions dependencies installed (`cd functions && npm install`)
- [ ] Functions build successful (`cd functions && npm run build`)
- [ ] No TypeScript errors
- [ ] firebase.json is valid JSON
- [ ] All rule files exist (firestore.rules, storage.rules)

## 🛠️ Debug Commands

```bash
# Check project status
firebase projects:list

# Test functions locally
cd functions && npm run serve

# Check for syntax errors
cd functions && npm run lint

# View deployment logs
firebase functions:log

# Test rules
firebase emulators:start --only firestore,storage
```

## 🆘 Emergency Reset

If deployment continues to fail:

```bash
# 1. Complete reset
rm -rf functions/lib functions/node_modules
firebase logout
firebase login

# 2. Reinstall everything
cd functions
npm cache clean --force
npm install
npm run build
cd ..

# 3. Deploy minimal first
firebase deploy --only firestore
```

## 📞 Still Having Issues?

1. Check Firebase Console for error details
2. Run `firebase debug` for detailed logs
3. Check that your project ID matches in `.firebaserc`
4. Ensure billing is enabled for Cloud Functions
5. Verify project permissions in Firebase Console