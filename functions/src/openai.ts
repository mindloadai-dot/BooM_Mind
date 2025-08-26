import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { admin } from './admin';
import * as logger from 'firebase-functions/logger';

// Define secrets for secure API key management
const openaiApiKey = defineSecret('OPENAI_API_KEY');
const openaiOrgId = defineSecret('OPENAI_ORGANIZATION_ID');

// Configuration for OpenAI processing
const CONFIG = {
  MAX_REQUESTS_PER_MINUTE: 20,
  MAX_TOKENS_PER_REQUEST: 4000,
  MAX_TOKENS_PER_RESPONSE: 2000,
  REQUEST_TIMEOUT_SECONDS: 30,
  DEFAULT_TEMPERATURE: 0.7,
  DEFAULT_MODEL: 'gpt-4o-mini',
} as const;

// Rate limiting cache
const rateLimitCache = new Map<string, { count: number; resetTime: number }>();

/**
 * Validate App Check token properly
 */
async function validateAppCheck(appCheckToken: string): Promise<boolean> {
  try {
    if (!appCheckToken || appCheckToken.length === 0) {
      return false;
    }

    // In production, verify the App Check token with Firebase Admin SDK
    try {
      const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
      
      // Verify the token is for the correct app
      if (appCheckClaims.appId !== process.env.FIREBASE_PROJECT_ID) {
        logger.warn('App Check token app ID mismatch');
        return false;
      }

      // Check if token is not expired
      const now = Math.floor(Date.now() / 1000);
      if (appCheckClaims.exp && appCheckClaims.exp < now) {
        logger.warn('App Check token expired');
        return false;
      }

      return true;
    } catch (verifyError) {
      logger.error('App Check token verification failed:', verifyError);
      return false;
    }
  } catch (error) {
    logger.error('App Check validation failed:', error);
    return false;
  }
}

/**
 * Check rate limits for OpenAI requests
 */
function checkRateLimits(userId: string): { allowed: boolean; error?: string } {
  const now = Date.now();
  const userLimit = rateLimitCache.get(userId);

  if (userLimit) {
    if (now < userLimit.resetTime) {
      if (userLimit.count >= CONFIG.MAX_REQUESTS_PER_MINUTE) {
        return { allowed: false, error: 'Rate limit exceeded' };
      }
    } else {
      // Reset the counter
      rateLimitCache.set(userId, { count: 0, resetTime: now + 60000 });
    }
  } else {
    rateLimitCache.set(userId, { count: 0, resetTime: now + 60000 });
  }

  return { allowed: true };
}

/**
 * Make OpenAI API call
 */
async function makeOpenAICall(
  messages: any[],
  responseFormat?: any,
  model: string = CONFIG.DEFAULT_MODEL
): Promise<any> {
  const requestBody: any = {
    model,
    messages,
    max_tokens: CONFIG.MAX_TOKENS_PER_REQUEST,
    temperature: CONFIG.DEFAULT_TEMPERATURE,
  };

  if (responseFormat) {
    requestBody.response_format = responseFormat;
  }

  const headers: any = {
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
export const generateFlashcards = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '256MiB',
  secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
  const { data, auth } = request;
  
  // Validate authentication
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = auth.uid;
  
  // Validate App Check token
  const isValidAppCheck = await validateAppCheck(data.appCheckToken);
  if (!isValidAppCheck) {
    throw new HttpsError('permission-denied', 'Invalid App Check token');
  }

  // Check rate limits
  const rateLimitCheck = checkRateLimits(userId);
  if (!rateLimitCheck.allowed) {
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  const { content, count, difficulty } = data;

  if (!content || !count || !difficulty) {
    throw new HttpsError('invalid-argument', 'Missing required parameters');
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

  } catch (error) {
    logger.error('OpenAI API call failed:', error);
    throw new HttpsError('internal', 'Failed to generate flashcards');
  }
});

/**
 * Generate study material from content
 */
export const generateStudyMaterial = onCall({
  region: 'us-central1',
  timeoutSeconds: 60,
  memory: '512MiB',
  secrets: [openaiApiKey, openaiOrgId],
}, async (request) => {
  const { data, auth } = request;
  
  // Validate authentication
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = auth.uid;
  
  // Validate App Check token
  const isValidAppCheck = await validateAppCheck(data.appCheckToken);
  if (!isValidAppCheck) {
    throw new HttpsError('permission-denied', 'Invalid App Check token');
  }

  // Check rate limits
  const rateLimitCheck = checkRateLimits(userId);
  if (!rateLimitCheck.allowed) {
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  const { content, materialType, difficulty } = data;

  if (!content || !materialType || !difficulty) {
    throw new HttpsError('invalid-argument', 'Missing required parameters');
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

  } catch (error) {
    logger.error('OpenAI API call failed:', error);
    throw new HttpsError('internal', 'Failed to generate study material');
  }
});
