"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupActionHistory = exports.consumeTokens = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const crypto = __importStar(require("crypto"));
// Configuration for token consumption
const CONFIG = {
    LIMITS: {
        USER_ACTIONS_PER_HOUR: 12,
        USER_ACTIONS_PER_DAY: 60,
        ENDPOINT_BURST: 4,
        BURST_WINDOW_SECONDS: 10,
    },
    COOLDOWNS: {
        SET_COOLDOWN_SECONDS: 10,
    },
    DEDUPLICATION: {
        WINDOW_SECONDS: 60,
    },
};
// Utility functions
function generateContentHash(payload) {
    const hashInput = JSON.stringify({
        actionType: payload.actionType,
        details: payload.details,
    });
    return crypto.createHash('sha256').update(hashInput).digest('hex');
}
function validateYouTubeUrl(url) {
    const youtubeRegex = /^(https?\:\/\/)?(www\.youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/;
    return youtubeRegex.test(url);
}
// Rate limiting and abuse prevention
async function checkRateLimits(userId, actionType) {
    const db = admin_1.admin.firestore();
    const now = admin_1.admin.firestore.Timestamp.now();
    // Fetch user's action history
    const userActionRef = db.collection('user_action_history').doc(userId);
    const userActionDoc = await userActionRef.get();
    const actionHistory = userActionDoc.data() || { actions: [] };
    // Filter actions within the last hour and day
    const hourAgo = new Date(now.toDate());
    hourAgo.setHours(hourAgo.getHours() - 1);
    const dayAgo = new Date(now.toDate());
    dayAgo.setDate(dayAgo.getDate() - 1);
    const actionsLastHour = actionHistory.actions.filter((action) => action.timestamp.toDate() >= hourAgo);
    const actionsLastDay = actionHistory.actions.filter((action) => action.timestamp.toDate() >= dayAgo);
    // Check rate limits
    if (actionsLastHour.length >= CONFIG.LIMITS.USER_ACTIONS_PER_HOUR) {
        return false;
    }
    if (actionsLastDay.length >= CONFIG.LIMITS.USER_ACTIONS_PER_DAY) {
        return false;
    }
    return true;
}
// Deduplication check
async function checkDeduplication(userId, contentHash) {
    const db = admin_1.admin.firestore();
    const now = admin_1.admin.firestore.Timestamp.now();
    const dedupeRef = db.collection('token_deduplication').doc(userId);
    const dedupeDoc = await dedupeRef.get();
    const dedupeData = dedupeDoc.data() || { recentHashes: [] };
    // Remove old hashes
    const recentHashes = dedupeData.recentHashes.filter((entry) => {
        const entryTime = entry.timestamp.toDate().getTime();
        const nowTime = now.toDate().getTime();
        return nowTime - entryTime < CONFIG.DEDUPLICATION.WINDOW_SECONDS * 1000;
    });
    // Check if hash exists
    const hashExists = recentHashes.some((entry) => entry.hash === contentHash);
    if (hashExists) {
        return false;
    }
    // Add new hash
    recentHashes.push({
        hash: contentHash,
        timestamp: now
    });
    await dedupeRef.set({ recentHashes }, { merge: true });
    return true;
}
// Set cooldown check
async function checkSetCooldown(userId, setId) {
    const db = admin_1.admin.firestore();
    const now = admin_1.admin.firestore.Timestamp.now();
    const cooldownRef = db.collection('set_cooldowns').doc(`${userId}_${setId}`);
    const cooldownDoc = await cooldownRef.get();
    const cooldownData = cooldownDoc.data();
    if (cooldownData) {
        const lastActionTime = cooldownData.lastActionTime;
        const timeSinceLastAction = now.toDate().getTime() - lastActionTime.toDate().getTime();
        if (timeSinceLastAction < CONFIG.COOLDOWNS.SET_COOLDOWN_SECONDS * 1000) {
            return false;
        }
    }
    // Update cooldown
    await cooldownRef.set({
        lastActionTime: now
    }, { merge: true });
    return true;
}
// Token consumption calculation (server-side)
function calculateTokenCost(payload) {
    switch (payload.actionType) {
        case 'text_generation':
            return Math.ceil((payload.details.words || 0) / 1000);
        case 'youtube_ingest':
            return Math.ceil((payload.details.minutes || 0) / 5);
        case 'regenerate':
            const setSize = payload.details.isCards ? 10 : 6;
            return Math.ceil((payload.details.itemCount || 0) / setSize);
        case 'reorganize':
            return 1; // 1 token per set
        default:
            throw new Error('Invalid action type');
    }
}
// Main token consumption cloud function
exports.consumeTokens = functions.https.onCall(async (data, context) => {
    // Validate authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required for token consumption');
    }
    // Validate payload
    if (!data.requestId) {
        throw new functions.https.HttpsError('invalid-argument', 'Request ID is required');
    }
    // Validate YouTube URL if applicable
    if (data.actionType === 'youtube_ingest' &&
        !validateYouTubeUrl(data.details.videoUrl || '')) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid YouTube URL');
    }
    const db = admin_1.admin.firestore();
    const userId = context.auth.uid;
    // Check rate limits
    const withinRateLimits = await checkRateLimits(userId, data.actionType);
    if (!withinRateLimits) {
        throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded', {
            retryAfter: 3600,
            limitType: 'hourly'
        });
    }
    // Generate content hash for deduplication
    const contentHash = generateContentHash(data);
    // Check deduplication
    const isUnique = await checkDeduplication(userId, contentHash);
    if (!isUnique) {
        throw new functions.https.HttpsError('already-exists', 'Duplicate request within 60 seconds');
    }
    // Check set-level cooldown if applicable
    if (data.details.setId) {
        const withinSetCooldown = await checkSetCooldown(userId, data.details.setId);
        if (!withinSetCooldown) {
            throw new functions.https.HttpsError('resource-exhausted', 'Set cooldown not elapsed');
        }
    }
    // Calculate token cost server-side
    const tokenCost = calculateTokenCost(data);
    // Fetch user's token account
    const userTokenRef = db.collection('user_token_accounts').doc(userId);
    const userTokenDoc = await userTokenRef.get();
    const tokenAccount = userTokenDoc.data() || {};
    // Validate sufficient tokens
    if ((tokenAccount.monthlyTokens || 0) < tokenCost) {
        throw new functions.https.HttpsError('resource-exhausted', 'Insufficient tokens');
    }
    // Perform atomic token deduction
    await db.runTransaction(async (transaction) => {
        // Deduct tokens
        transaction.update(userTokenRef, {
            monthlyTokens: admin_1.admin.firestore.FieldValue.increment(-tokenCost)
        });
        // Log token action
        transaction.create(db.collection('token_actions').doc(), {
            userId,
            actionType: data.actionType,
            tokensCost: tokenCost,
            requestId: data.requestId,
            timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            details: data.details
        });
        // Log user action history
        transaction.update(db.collection('user_action_history').doc(userId), {
            actions: admin_1.admin.firestore.FieldValue.arrayUnion({
                actionType: data.actionType,
                timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp()
            })
        });
    });
    // Return successful response
    return {
        success: true,
        tokensCost: tokenCost,
        remainingTokens: (tokenAccount.monthlyTokens || 0) - tokenCost
    };
});
// Periodic cleanup of old action histories and deduplication entries
exports.cleanupActionHistory = functions.pubsub.schedule('every 24 hours').onRun(async () => {
    const db = admin_1.admin.firestore();
    const now = admin_1.admin.firestore.Timestamp.now();
    // Clean up action histories older than 30 days
    const actionHistorySnapshot = await db.collection('user_action_history')
        .where('timestamp', '<', now.toDate().setDate(now.toDate().getDate() - 30))
        .get();
    const batch = db.batch();
    actionHistorySnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });
    // Clean up deduplication entries older than 60 seconds
    const dedupeSnapshot = await db.collection('token_deduplication')
        .where('timestamp', '<', now.toDate().setSeconds(now.toDate().getSeconds() - 60))
        .get();
    dedupeSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });
    await batch.commit();
});
//# sourceMappingURL=token-consumption.js.map