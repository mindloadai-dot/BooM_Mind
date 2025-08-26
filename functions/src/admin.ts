import * as admin from 'firebase-admin';

// Initialize Firebase Admin only once
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export { admin };
export const db = admin.firestore();
