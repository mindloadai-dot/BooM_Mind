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
exports.generateStudyMaterial = exports.generateFlashcards = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin_1 = require("./admin");
const logger = __importStar(require("firebase-functions/logger"));
// Define secrets for secure API key management
const openaiApiKey = (0, params_1.defineSecret)('OPENAI_API_KEY');
const openaiOrgId = (0, params_1.defineSecret)('OPENAI_ORGANIZATION_ID');
// Configuration for OpenAI processing
const CONFIG = {
    MAX_REQUESTS_PER_MINUTE: 20,
    MAX_TOKENS_PER_REQUEST: 4000,
    MAX_TOKENS_PER_RESPONSE: 2000,
    REQUEST_TIMEOUT_SECONDS: 30,
    DEFAULT_TEMPERATURE: 0.7,
    DEFAULT_MODEL: 'gpt-4o-mini',
};
// Rate limiting cache
const rateLimitCache = new Map();
/**
 * Validate App Check token properly
 */
async function validateAppCheck(appCheckToken) {
    try {
        if (!appCheckToken || appCheckToken.length === 0) {
            return false;
        }
        // In production, verify the App Check token with Firebase Admin SDK
        try {
            const appCheckClaims = await admin_1.admin.appCheck().verifyToken(appCheckToken);
            // Verify the token is for the correct app
            if (appCheckClaims.appId !== process.env.FIREBASE_PROJECT_ID) {
                logger.warn('App Check token app ID mismatch');
                return false;
            }
            // Note: App Check token expiration is handled automatically by Firebase
            // No need to manually check expiration
            return true;
        }
        catch (verifyError) {
            logger.error('App Check token verification failed:', verifyError);
            return false;
        }
    }
    catch (error) {
        logger.error('App Check validation failed:', error);
        return false;
    }
}
/**
 * Check rate limits for OpenAI requests
 */
function checkRateLimits(userId) {
    const now = Date.now();
    const userLimit = rateLimitCache.get(userId);
    if (userLimit) {
        if (now < userLimit.resetTime) {
            if (userLimit.count >= CONFIG.MAX_REQUESTS_PER_MINUTE) {
                return { allowed: false, error: 'Rate limit exceeded' };
            }
        }
        else {
            // Reset the counter
            rateLimitCache.set(userId, { count: 0, resetTime: now + 60000 });
        }
    }
    else {
        rateLimitCache.set(userId, { count: 0, resetTime: now + 60000 });
    }
    return { allowed: true };
}
/**
 * Make OpenAI API call
 */
async function makeOpenAICall(messages, responseFormat, model = CONFIG.DEFAULT_MODEL) {
    const requestBody = {
        model,
        messages,
        max_tokens: CONFIG.MAX_TOKENS_PER_REQUEST,
        temperature: CONFIG.DEFAULT_TEMPERATURE,
    };
    if (responseFormat) {
        requestBody.response_format = responseFormat;
    }
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey.value()}`,
    };
    if (openaiOrgId.value()) {
        headers['OpenAI-Organization'] = openaiOrgId.value();
    }
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers,
        body: JSON.stringify(requestBody),
    });
    if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
    }
    return await response.json();
}
/**
 * Generate flashcards from content
 */
exports.generateFlashcards = (0, https_1.onCall)({
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
    secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
    const { data, auth } = request;
    // Validate authentication
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = auth.uid;
    // Validate App Check token
    const isValidAppCheck = await validateAppCheck(data.appCheckToken);
    if (!isValidAppCheck) {
        throw new https_1.HttpsError('permission-denied', 'Invalid App Check token');
    }
    // Check rate limits
    const rateLimitCheck = checkRateLimits(userId);
    if (!rateLimitCheck.allowed) {
        throw new https_1.HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
    }
    const { content, count, difficulty } = data;
    if (!content || !count || !difficulty) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters');
    }
    try {
        const prompt = `
Generate ${count} flashcards from the following content. 
Difficulty level: ${difficulty}

Content:
${content}

Generate flashcards in this exact JSON format:
{
  "flashcards": [
    {
      "question": "Question text here",
      "answer": "Answer text here",
      "difficulty": "${difficulty}"
    }
  ]
}

Make sure the questions are clear, educational, and cover key concepts from the content.
`;
        const response = await makeOpenAICall([
            {
                role: 'system',
                content: 'You are an expert educator creating flashcards.'
            },
            {
                role: 'user',
                content: prompt
            }
        ], { type: 'json_object' });
        // Update rate limit counter
        const userLimit = rateLimitCache.get(userId);
        if (userLimit) {
            userLimit.count++;
        }
        return {
            flashcards: JSON.parse(response.choices[0].message.content).flashcards,
            usage: response.usage
        };
    }
    catch (error) {
        logger.error('OpenAI API call failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to generate flashcards');
    }
});
/**
 * Generate study material from content
 */
exports.generateStudyMaterial = (0, https_1.onCall)({
    region: 'us-central1',
    timeoutSeconds: 60,
    memory: '512MiB',
    secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
    const { data, auth } = request;
    // Validate authentication
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = auth.uid;
    // Validate App Check token
    const isValidAppCheck = await validateAppCheck(data.appCheckToken);
    if (!isValidAppCheck) {
        throw new https_1.HttpsError('permission-denied', 'Invalid App Check token');
    }
    // Check rate limits
    const rateLimitCheck = checkRateLimits(userId);
    if (!rateLimitCheck.allowed) {
        throw new https_1.HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
    }
    const { content, materialType, difficulty } = data;
    if (!content || !materialType || !difficulty) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required parameters');
    }
    try {
        const prompt = `
Generate ${materialType} study material from the following content.
Difficulty level: ${difficulty}

Content:
${content}

Create comprehensive study material that covers the key concepts and helps with learning.
`;
        const response = await makeOpenAICall([
            {
                role: 'system',
                content: 'You are an expert educator creating study materials.'
            },
            {
                role: 'user',
                content: prompt
            }
        ]);
        // Update rate limit counter
        const userLimit = rateLimitCache.get(userId);
        if (userLimit) {
            userLimit.count++;
        }
        return {
            content: response.choices[0].message.content,
            usage: response.usage
        };
    }
    catch (error) {
        logger.error('OpenAI API call failed:', error);
        throw new https_1.HttpsError('internal', 'Failed to generate study material');
    }
});
//# sourceMappingURL=openai.js.map