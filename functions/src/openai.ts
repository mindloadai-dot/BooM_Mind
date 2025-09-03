import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { admin } from './admin';
import * as logger from 'firebase-functions/logger';
import OpenAI from 'openai';

// Define secrets for secure API key management
const openaiApiKey = defineSecret('OPENAI_API_KEY');
const openaiOrgId = defineSecret('OPENAI_ORGANIZATION_ID');

// Configuration for OpenAI processing - Optimized for large content (500k chars)
const CONFIG = {
  MAX_REQUESTS_PER_MINUTE: 100,
  MAX_TOKENS_PER_REQUEST: 4000, // Increased for larger content processing
  DEFAULT_TEMPERATURE: 0.1, // Minimal temperature for fastest responses
  DEFAULT_MODEL: 'gpt-4o-mini', // Fastest model
  TIMEOUT_MS: 120000, // 2 minute timeout for large content processing
  MAX_CONTENT_LENGTH: 500000, // Maximum 500,000 characters supported
} as const;

// Rate limiting cache
const rateLimitCache = new Map<string, { count: number; resetTime: number }>();

// Function to clear rate limiting cache
function clearRateLimitCache() {
  rateLimitCache.clear();
  logger.info('🧹 Rate limiting cache cleared');
}

/**
 * Retry OpenAI API calls with exponential backoff for handling overload errors
 */
async function retryOpenAICall<T>(
  apiCall: () => Promise<T>,
  operationType: string,
  maxRetries: number = 3
): Promise<T> {
  let lastError: any;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      logger.info(`🔄 OpenAI API call attempt ${attempt}/${maxRetries} for ${operationType}`);
      
      const result = await apiCall();
      
      if (attempt > 1) {
        logger.info(`✅ OpenAI API call succeeded on attempt ${attempt} for ${operationType}`);
      }
      
      return result;
    } catch (error: any) {
      lastError = error;
      
      // Check if this is a retryable error
      const isRetryable = isRetryableOpenAIError(error);
      const isOverloaded = error.message?.includes('Overloaded') || 
                          error.message?.includes('overloaded') ||
                          error.status === 503 ||
                          error.status === 529;
      
      logger.warn(`⚠️ OpenAI API call failed (attempt ${attempt}/${maxRetries}) for ${operationType}:`, {
        error: error.message,
        status: error.status,
        code: error.code,
        isRetryable: isRetryable,
        isOverloaded: isOverloaded
      });
      
      // Don't retry on the last attempt or non-retryable errors
      if (attempt === maxRetries || (!isRetryable && !isOverloaded)) {
        break;
      }
      
      // Calculate delay with exponential backoff + jitter
      const baseDelay = Math.pow(2, attempt - 1) * 1000; // 1s, 2s, 4s
      const jitter = Math.random() * 1000; // Add up to 1s random jitter
      const delay = baseDelay + jitter;
      
      logger.info(`⏳ Retrying in ${Math.round(delay)}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  // If we get here, all retries failed
  logger.error(`❌ All ${maxRetries} attempts failed for ${operationType}`, {
    finalError: lastError.message,
    status: lastError.status
  });
  
  // Transform the error into a more user-friendly message
  if (lastError.message?.includes('Overloaded') || lastError.status === 503 || lastError.status === 529) {
    throw new HttpsError('resource-exhausted', 
      'OpenAI service is currently overloaded. Please try again in a few moments.', 
      { 
        originalError: lastError.message,
        retryAfter: 30,
        suggestion: 'The AI service is experiencing high demand. Your request will work with local fallback.'
      }
    );
  }
  
  throw lastError;
}

/**
 * Check if an OpenAI error is retryable
 */
function isRetryableOpenAIError(error: any): boolean {
  // Retryable HTTP status codes
  const retryableStatuses = [408, 429, 500, 502, 503, 504, 529];
  
  // Retryable error messages
  const retryableMessages = [
    'overloaded',
    'timeout',
    'rate limit',
    'server error',
    'internal error',
    'service unavailable',
    'bad gateway',
    'gateway timeout'
  ];
  
  if (retryableStatuses.includes(error.status)) {
    return true;
  }
  
  const errorMessage = (error.message || '').toLowerCase();
  return retryableMessages.some(msg => errorMessage.includes(msg));
}

/**
 * Validate App Check token with enhanced debugging
 */
async function validateAppCheck(request: any): Promise<{ valid: boolean; reason: string }> {
  try {
    // Check if App Check token is present in the request
    const appCheckToken = request.rawRequest?.headers?.['x-firebase-appcheck'] || 
                         request.data?.appCheckToken;
    
    if (!appCheckToken || appCheckToken.length === 0) {
      logger.info('🔍 No App Check token provided - allowing for development');
      return { valid: true, reason: 'no_token_dev_mode' };
    }

    // In production, verify the App Check token with Firebase Admin SDK
    try {
      logger.info('🔐 Verifying App Check token...');
      const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
      
      // Log successful verification
      logger.info('✅ App Check token verified successfully', {
        appId: appCheckClaims.appId
      });
      
      return { valid: true, reason: 'token_verified' };
    } catch (verifyError: any) {
      logger.warn('⚠️ App Check token verification failed, but allowing request:', {
        error: verifyError.message,
        code: verifyError.code
      });
      // Allow requests even if App Check verification fails (for development)
      return { valid: true, reason: 'verification_failed_dev_allowed' };
    }
  } catch (error: any) {
    logger.warn('❌ App Check validation error, allowing request:', {
      error: error.message,
      stack: error.stack
    });
    // Allow requests even if App Check validation fails entirely
    return { valid: true, reason: 'validation_error_dev_allowed' };
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
 * Create OpenAI client
 */
function createOpenAIClient(): OpenAI {
  const apiKey = openaiApiKey.value();
  const orgId = openaiOrgId.value();
  
  logger.info('🔑 Creating OpenAI client with:', {
    hasApiKey: !!apiKey,
    apiKeyLength: apiKey ? apiKey.length : 0,
    hasOrgId: !!orgId,
    orgId: orgId
  });
  
  const config: any = {
    apiKey: apiKey,
  };
  
  if (orgId) {
    config.organization = orgId;
  }
  
  return new OpenAI(config);
}

/**
 * Test OpenAI authentication
 */
export const testOpenAI = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '256MiB',
  secrets: [openaiApiKey, openaiOrgId],
  enforceAppCheck: false,
  cors: true,
}, async (request) => {
  logger.info('🧪 Testing OpenAI authentication');
  
  try {
    const client = createOpenAIClient();
    
    // Test with a simple completion first
    const simpleResponse = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'user',
          content: 'Say "Hello, OpenAI is working!"'
        }
      ],
      max_tokens: 50,
      temperature: 0.1
    });
    
    logger.info('✅ Simple OpenAI test successful:', {
      content: simpleResponse.choices[0].message.content,
      usage: simpleResponse.usage
    });
    
    // Now test with a more complex prompt similar to generateFlashcards
    const complexPrompt = `
Generate 3 flashcards from the following content. 
Difficulty level: intermediate

Content:
The human brain is the command center for the human nervous system. It receives signals from the body's sensory organs and outputs information to the muscles.

Generate flashcards in this exact JSON format:
{
  "flashcards": [
    {
      "question": "Question text here",
      "answer": "Answer text here",
      "difficulty": "intermediate"
    }
  ]
}

Make sure the questions are clear, educational, and cover key concepts from the content.
`;

    const complexResponse = await client.chat.completions.create({
      model: CONFIG.DEFAULT_MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are an expert educator creating flashcards.'
        },
        {
          role: 'user',
          content: complexPrompt
        }
      ],
      max_tokens: CONFIG.MAX_TOKENS_PER_REQUEST,
      temperature: CONFIG.DEFAULT_TEMPERATURE,
      response_format: { type: 'json_object' }
    });
    
    logger.info('✅ Complex OpenAI test successful:', {
      content: complexResponse.choices[0].message.content,
      usage: complexResponse.usage
    });
    
    return {
      success: true,
      simpleMessage: simpleResponse.choices[0].message.content,
      complexMessage: complexResponse.choices[0].message.content,
      simpleUsage: simpleResponse.usage,
      complexUsage: complexResponse.usage
    };
    
  } catch (error: any) {
    logger.error('❌ OpenAI test failed:', {
      error: error.message,
      status: error.status,
      code: error.code,
      type: error.type
    });
    
    throw new HttpsError('internal', `OpenAI test failed: ${error.message}`, {
      originalError: error.message,
      status: error.status,
      code: error.code
    });
  }
});

/**
 * Generate flashcards from content
 */
export const generateFlashcards = onCall({
  region: 'us-central1',
  timeoutSeconds: 180, // 3 minutes for large content processing (500k chars)
  memory: '2GiB', // Increased memory for large content
  cpu: 2,
  secrets: [openaiApiKey, openaiOrgId],
  enforceAppCheck: false,
  cors: true,
}, async (request) => {
  logger.info('🚀 Received generateFlashcards request');
  
  // Clear rate limiting cache for debugging
  clearRateLimitCache();
  
  // Enhanced request logging
  const userId = request.auth?.uid || 'anonymous';
  const hasAuth = request.auth ? true : false;
  const hasAppCheck = request.rawRequest?.headers?.['x-firebase-appcheck'] ? true : false;
  
  logger.info('📊 Request context:', {
    userId: userId,
    hasAuth: hasAuth,
    hasAppCheck: hasAppCheck,
    origin: request.rawRequest?.headers?.origin || 'unknown'
  });
  
  // Validate App Check with enhanced debugging
  const appCheckResult = await validateAppCheck(request);
  logger.info('🔐 App Check validation result:', appCheckResult);

  // Check rate limits
  const rateLimitCheck = checkRateLimits(userId);
  if (!rateLimitCheck.allowed) {
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  const { content, count, difficulty } = request.data;

  if (!content || !count || !difficulty) {
    throw new HttpsError('invalid-argument', 'Missing required parameters');
  }

  // Intelligent content optimization for speed and efficiency
  let processedContent = content;
  const originalLength = content.length;
  
  // Smart content preprocessing for better performance
  if (content.length > 20000) {
    logger.warn(`Large content detected: ${content.length} characters - optimizing for speed`);
    
    // Extract key sentences and paragraphs intelligently
    const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 20);
    const paragraphs = content.split('\n\n').filter(p => p.trim().length > 50);
    
    // Priority content selection (more intelligent than simple truncation)
    const importantSentences = sentences
      .filter(s => {
        const lower = s.toLowerCase();
        // Prioritize sentences with key indicators
        return lower.includes('important') || lower.includes('key') || 
               lower.includes('main') || lower.includes('primary') ||
               lower.includes('essential') || lower.includes('fundamental') ||
               s.length > 50; // Longer sentences often contain more information
      })
      .slice(0, 20); // Top 20 important sentences
    
    // Take first few and last few paragraphs + important sentences
    const keyContent = [
      ...paragraphs.slice(0, 3),
      '--- Key Information ---',
      ...importantSentences,
      '--- Conclusion ---',
      ...paragraphs.slice(-2)
    ].join('\n\n');
    
    processedContent = keyContent.substring(0, 25000); // Hard limit for performance
    logger.info(`Smart optimization: ${originalLength} → ${processedContent.length} chars (${Math.round((1 - processedContent.length/originalLength) * 100)}% reduction)`);
  }

  try {
    const client = createOpenAIClient();
    
    const prompt = `${count} flashcards from:

${processedContent}

JSON format:
{"flashcards":[{"question":"Q","answer":"A","difficulty":"${difficulty}"}]}

Key facts only.`;

    // Implement retry logic with timeout for OpenAI API calls
    const response = await Promise.race([
      retryOpenAICall(async () => {
        return await client.chat.completions.create({
          model: CONFIG.DEFAULT_MODEL,
          messages: [
            {
              role: 'system',
              content: 'Create flashcards quickly. Be concise.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          max_tokens: CONFIG.MAX_TOKENS_PER_REQUEST,
          temperature: CONFIG.DEFAULT_TEMPERATURE,
          response_format: { type: 'json_object' }
        });
      }, 'generateFlashcards'),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('OpenAI API timeout')), CONFIG.TIMEOUT_MS)
      )
    ]) as any;

    // Update rate limit counter
    const userLimit = rateLimitCache.get(userId);
    if (userLimit) {
      userLimit.count++;
    }

    const content_text = response.choices[0].message.content;
    if (!content_text) {
      throw new Error('No content returned from OpenAI');
    }

    return {
      flashcards: JSON.parse(content_text).flashcards,
      usage: response.usage
    };

  } catch (error) {
    logger.error('OpenAI API call failed:', error);
    throw new HttpsError('internal', 'Failed to generate flashcards');
  }
});

/**
 * Generate quiz questions from content
 */
export const generateQuiz = onCall({
  region: 'us-central1',
  timeoutSeconds: 180, // 3 minutes for large content processing (500k chars)
  memory: '2GiB', // Increased memory for large content
  cpu: 2,
  secrets: [openaiApiKey, openaiOrgId],
  enforceAppCheck: false,
  cors: true,
}, async (request) => {
  logger.info('🚀 Received generateQuiz request');
  
  // Enhanced request logging
  const userId = request.auth?.uid || 'anonymous';
  const hasAuth = request.auth ? true : false;
  const hasAppCheck = request.rawRequest?.headers?.['x-firebase-appcheck'] ? true : false;
  
  logger.info('📊 Request context:', {
    userId: userId,
    hasAuth: hasAuth,
    hasAppCheck: hasAppCheck,
    origin: request.rawRequest?.headers?.origin || 'unknown'
  });
  
  // Validate App Check with enhanced debugging
  const appCheckResult = await validateAppCheck(request);
  logger.info('🔐 App Check validation result:', appCheckResult);

  // Check rate limits
  const rateLimitCheck = checkRateLimits(userId);
  if (!rateLimitCheck.allowed) {
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  const { content, count, difficulty } = request.data;

  if (!content || !count || !difficulty) {
    throw new HttpsError('invalid-argument', 'Missing required parameters');
  }

  // Intelligent content optimization for quiz generation speed
  let processedContent = content;
  const originalLength = content.length;
  
  // Smart content preprocessing optimized for quiz questions
  if (content.length > 20000) {
    logger.warn(`Large content detected for quiz: ${content.length} characters - optimizing`);
    
    // Extract content optimized for quiz generation
    const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 15);
    const paragraphs = content.split('\n\n').filter(p => p.trim().length > 30);
    
    // For quizzes, prioritize factual and definitive content
    const factualSentences = sentences
      .filter(s => {
        const lower = s.toLowerCase();
        return lower.includes('is') || lower.includes('are') || lower.includes('was') || 
               lower.includes('were') || lower.includes('can') || lower.includes('will') ||
               lower.includes('must') || lower.includes('should') || /\d/.test(s); // Contains numbers
      })
      .slice(0, 25); // Top 25 factual sentences for quiz generation
    
    const optimizedContent = [
      ...paragraphs.slice(0, 2),
      '--- Key Facts ---',
      ...factualSentences,
      ...paragraphs.slice(-1)
    ].join('\n\n');
    
    processedContent = optimizedContent.substring(0, 20000); // Smaller limit for quiz speed
    logger.info(`Quiz optimization: ${originalLength} → ${processedContent.length} chars (${Math.round((1 - processedContent.length/originalLength) * 100)}% reduction)`);
  }

  try {
    const client = createOpenAIClient();
    
    const prompt = `${count} quiz questions:

${processedContent}

JSON format:
{"questions":[{"question":"Q","options":["A","B","C","D"],"correctAnswer":"A","difficulty":"${difficulty}"}]}

4 options each.`;

    // Implement retry logic with timeout for OpenAI API calls
    const response = await Promise.race([
      retryOpenAICall(async () => {
        return await client.chat.completions.create({
          model: CONFIG.DEFAULT_MODEL,
          messages: [
            {
              role: 'system',
              content: 'Create quiz questions quickly. Be direct and concise.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          max_tokens: 1000, // Ultra-reduced for maximum speed
          temperature: CONFIG.DEFAULT_TEMPERATURE,
          response_format: { type: 'json_object' }
        });
      }, 'generateQuiz'),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('OpenAI API timeout')), CONFIG.TIMEOUT_MS)
      )
    ]) as any;

    // Update rate limit counter
    const userLimit = rateLimitCache.get(userId);
    if (userLimit) {
      userLimit.count++;
    }

    const content_text = response.choices[0].message.content;
    if (!content_text) {
      throw new Error('No content returned from OpenAI');
    }

    return {
      questions: JSON.parse(content_text).questions,
      usage: response.usage
    };

  } catch (error) {
    logger.error('OpenAI API call failed:', error);
    throw new HttpsError('internal', 'Failed to generate quiz questions');
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
  enforceAppCheck: false, // Allow unauthenticated calls for development
  cors: true, // Enable CORS
}, async (request) => {
  const { data } = request;
  
  logger.info('Received generateFlashcards request');
  
  // Skip authentication for development - allow all requests
  const userId = 'anonymous';
  
  // Skip App Check validation for development
  logger.info('Skipping App Check validation for development');

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

    const client = createOpenAIClient();
    
    const response = await client.chat.completions.create({
      model: CONFIG.DEFAULT_MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are an expert educator creating study materials.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      max_tokens: CONFIG.MAX_TOKENS_PER_REQUEST,
      temperature: CONFIG.DEFAULT_TEMPERATURE,
    });

    // Update rate limit counter
    const userLimit = rateLimitCache.get(userId);
    if (userLimit) {
      userLimit.count++;
    }

    const content_text = response.choices[0].message.content;
    if (!content_text) {
      throw new Error('No content returned from OpenAI');
    }

    return {
      content: content_text,
      usage: response.usage
    };

  } catch (error) {
    logger.error('OpenAI API call failed:', error);
    throw new HttpsError('internal', 'Failed to generate study material');
  }
});
