import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { admin } from './admin';
import * as logger from 'firebase-functions/logger';

// Define secrets for secure API key management
const youtubeApiKey = defineSecret('YOUTUBE_API_KEY');

// Configuration for YouTube processing
const CONFIG = {
  TOKENS_PER_ML_TOKEN: 750,
  OUT_TOKENS_DEFAULT: 500,
  FREE_MAX_DURATION_SECONDS: 1800, // 30 min
  PRO_MAX_DURATION_SECONDS: 7200,  // 120 min
  TRANSCRIPT_LANG_FALLBACKS: ['en', 'en-US'],
  CACHE_TTL_MINUTES: 15,
  MAX_CACHE_SIZE: 200,
  
  // Rate limiting and abuse prevention
  MAX_REQUESTS_PER_MINUTE: 10,
  MAX_REQUESTS_PER_HOUR: 60,
  MAX_INGESTS_PER_HOUR: 5,
  MIN_INGEST_INTERVAL_MINUTES: 2,
  MAX_VIDEO_REQUESTS_PER_HOUR: 20,
  MAX_SESSION_REQUESTS: 100,
  SESSION_DURATION_HOURS: 1,
  
  // Security
  MAX_REQUEST_SIZE: 1024, // bytes
  REQUIRED_FIELDS: ['videoId', 'appCheckToken', 'userId'],
  ALLOWED_VIDEO_ID_PATTERN: /^[A-Za-z0-9_-]{11}$/,
} as const;

// LRU Cache for preview results
interface CacheEntry {
  data: any;
  timestamp: number;
  accessCount: number;
}

class LRUCache {
  private cache = new Map<string, CacheEntry>();
  private readonly maxSize: number;
  private readonly ttl: number;

  constructor(maxSize: number, ttlMinutes: number) {
    this.maxSize = maxSize;
    this.ttl = ttlMinutes * 60 * 1000; // Convert to milliseconds
  }

  get(key: string): any | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    // Check if expired
    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    // Update access count and move to end (most recently used)
    entry.accessCount++;
    this.cache.delete(key);
    this.cache.set(key, entry);
    
    return entry.data;
  }

  set(key: string, value: any): void {
    // Remove if already exists
    this.cache.delete(key);

    // Add new entry
    this.cache.set(key, {
      data: value,
      timestamp: Date.now(),
      accessCount: 1,
    });

    // Evict least recently used if over max size
    if (this.cache.size > this.maxSize) {
      let oldestKey = '';
      let oldestAccess = Infinity;
      
      for (const [key, entry] of this.cache.entries()) {
        if (entry.accessCount < oldestAccess) {
          oldestAccess = entry.accessCount;
          oldestKey = key;
        }
      }
      
      if (oldestKey) {
        this.cache.delete(oldestKey);
      }
    }
  }

  clear(): void {
    this.cache.clear();
  }

  size(): number {
    return this.cache.size;
  }
}

// Initialize cache
const previewCache = new LRUCache(CONFIG.MAX_CACHE_SIZE, CONFIG.CACHE_TTL_MINUTES);

// Rate limiting tracking
interface RateLimitEntry {
  requests: number[];
  ingests: number[];
  sessionStart?: number;
  sessionRequests?: number;
}

const rateLimitCache = new Map<string, RateLimitEntry>();
const videoRequestCounts = new Map<string, number>();
const suspiciousVideos = new Set<string>();

// ABUSE PREVENTION FUNCTIONS

/**
 * Validate request input and security
 */
function validateRequest(data: any): { isValid: boolean; error?: string } {
  // Check required fields
  for (const field of CONFIG.REQUIRED_FIELDS) {
    if (!data[field]) {
      return { isValid: false, error: `Missing required field: ${field}` };
    }
  }

  // Validate video ID format
  if (!CONFIG.ALLOWED_VIDEO_ID_PATTERN.test(data.videoId)) {
    return { isValid: false, error: 'Invalid video ID format' };
  }

  // Check request size
  const requestSize = JSON.stringify(data).length;
  if (requestSize > CONFIG.MAX_REQUEST_SIZE) {
    return { isValid: false, error: 'Request too large' };
  }

  return { isValid: true };
}

/**
 * Check rate limits for a user
 */
function checkRateLimits(userId: string, isIngest: boolean = false): { allowed: boolean; error?: string } {
  const now = Date.now();
  const oneMinute = 60 * 1000;
  const oneHour = 60 * 60 * 1000;
  
  // Get or create user rate limit entry
  let userLimits = rateLimitCache.get(userId);
  if (!userLimits) {
    userLimits = { requests: [], ingests: [] };
    rateLimitCache.set(userId, userLimits);
  }

  // Clean up old requests
  userLimits.requests = userLimits.requests.filter(timestamp => now - timestamp < oneHour);
  userLimits.ingests = userLimits.ingests.filter(timestamp => now - timestamp < oneHour);

  // Check session limits
  const sessionCheck = checkSessionLimits(userId, userLimits);
  if (!sessionCheck.allowed) {
    return sessionCheck;
  }

  if (isIngest) {
    // Check ingest-specific limits
    const recentIngests = userLimits.ingests.filter(timestamp => now - timestamp < oneHour);
    if (recentIngests.length >= CONFIG.MAX_INGESTS_PER_HOUR) {
      return { allowed: false, error: 'Ingest rate limit exceeded: Too many ingests per hour' };
    }

    // Check minimum interval between ingests
    const lastIngest = Math.max(...userLimits.ingests, 0);
    const timeSinceLastIngest = now - lastIngest;
    const minInterval = CONFIG.MIN_INGEST_INTERVAL_MINUTES * 60 * 1000;
    
    if (lastIngest > 0 && timeSinceLastIngest < minInterval) {
      const waitMinutes = Math.ceil((minInterval - timeSinceLastIngest) / 60000);
      return { allowed: false, error: `Please wait ${waitMinutes} minutes before next ingest` };
    }

    // Record the ingest
    userLimits.ingests.push(now);
  } else {
    // Check preview request limits
    const recentMinute = userLimits.requests.filter(timestamp => now - timestamp < oneMinute);
    if (recentMinute.length >= CONFIG.MAX_REQUESTS_PER_MINUTE) {
      return { allowed: false, error: 'Rate limit exceeded: Too many requests per minute' };
    }

    const recentHour = userLimits.requests.filter(timestamp => now - timestamp < oneHour);
    if (recentHour.length >= CONFIG.MAX_REQUESTS_PER_HOUR) {
      return { allowed: false, error: 'Rate limit exceeded: Too many requests per hour' };
    }
  }

  // Record the request
  userLimits.requests.push(now);
  userLimits.sessionRequests = (userLimits.sessionRequests || 0) + 1;

  return { allowed: true };
}

/**
 * Check session-based limits
 */
function checkSessionLimits(userId: string, userLimits: RateLimitEntry): { allowed: boolean; error?: string } {
  const now = Date.now();
  const sessionDuration = CONFIG.SESSION_DURATION_HOURS * 60 * 60 * 1000;

  // Initialize or reset session if expired
  if (!userLimits.sessionStart || now - userLimits.sessionStart > sessionDuration) {
    userLimits.sessionStart = now;
    userLimits.sessionRequests = 0;
    return { allowed: true };
  }

  // Check session request count
  if ((userLimits.sessionRequests || 0) >= CONFIG.MAX_SESSION_REQUESTS) {
    return { allowed: false, error: 'Session limit exceeded: Too many requests in current session' };
  }

  return { allowed: true };
}

/**
 * Check for abuse patterns
 */
function checkAbusePatterns(videoId: string): { allowed: boolean; error?: string } {
  // Check if video is flagged as suspicious
  if (suspiciousVideos.has(videoId)) {
    return { allowed: false, error: 'Video temporarily unavailable due to abuse detection' };
  }

  // Check video request frequency
  const videoRequests = videoRequestCounts.get(videoId) || 0;
  if (videoRequests >= CONFIG.MAX_VIDEO_REQUESTS_PER_HOUR) {
    suspiciousVideos.add(videoId);
    logger.warn(`Video ${videoId} flagged for excessive requests: ${videoRequests}`);
    return { allowed: false, error: 'Video temporarily unavailable: Too many requests' };
  }

  // Record the video request
  videoRequestCounts.set(videoId, videoRequests + 1);

  return { allowed: true };
}

/**
 * Validate App Check token
 */
async function validateAppCheck(appCheckToken: string): Promise<boolean> {
  try {
    // In production, verify the App Check token
    // For now, just check that it exists and is not empty
    return Boolean(appCheckToken && appCheckToken.length > 0);
  } catch (error) {
    logger.error('App Check validation failed:', error);
    return false;
  }
}

/**
 * Clean up rate limiting data periodically
 */
export function cleanupRateLimitData() {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  const oneDay = 24 * 60 * 60 * 1000;

  // Clean up old rate limit entries
  for (const [userId, limits] of rateLimitCache.entries()) {
    limits.requests = limits.requests.filter(timestamp => now - timestamp < oneHour);
    limits.ingests = limits.ingests.filter(timestamp => now - timestamp < oneDay);
    
    // Remove session if expired
    if (limits.sessionStart && now - limits.sessionStart > CONFIG.SESSION_DURATION_HOURS * 60 * 60 * 1000) {
      limits.sessionStart = undefined;
      limits.sessionRequests = undefined;
    }

    // Remove entry if no recent activity
    if (limits.requests.length === 0 && limits.ingests.length === 0) {
      rateLimitCache.delete(userId);
    }
  }

  // Reset video request counts daily
  videoRequestCounts.clear();
  
  // Clear suspicious videos daily
  suspiciousVideos.clear();

  logger.info('Rate limit data cleanup completed');
}

/**
 * Scheduled function to clean up rate limiting data
 * Runs every hour to prevent memory leaks
 */
export const cleanupYouTubeRateLimit = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '128MiB',
}, async () => {
  cleanupRateLimitData();
  return { success: true, timestamp: Date.now() };
});

/**
 * Admin function to reset rate limits for a user
 */
export const resetUserRateLimits = onCall({
  region: 'us-central1',
  timeoutSeconds: 10,
  memory: '128MiB',
}, async (request) => {
  const { data, auth } = request;
  
  // Only allow admin users to reset rate limits
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  // Check if user is admin (you would implement your own admin check)
  const userDoc = await admin.firestore().collection('users').doc(auth.uid).get();
  const userData = userDoc.data();
  
  if (!userData?.isAdmin) {
    throw new HttpsError('permission-denied', 'Admin access required');
  }

  const { targetUserId } = data;
  if (!targetUserId) {
    throw new HttpsError('invalid-argument', 'Target user ID required');
  }

  // Reset rate limits for target user
  rateLimitCache.delete(targetUserId);
  
  logger.info(`Rate limits reset for user ${targetUserId} by admin ${auth.uid}`);
  return { success: true, resetUserId: targetUserId };
});

/**
 * Function to get rate limit status for debugging
 */
export const getRateLimitStatus = onCall({
  region: 'us-central1',
  timeoutSeconds: 10,
  memory: '128MiB',
}, async (request) => {
  const { auth } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  const userId = auth.uid;
  const userLimits = rateLimitCache.get(userId);
  
  if (!userLimits) {
    return {
      hasLimits: false,
      requests: 0,
      ingests: 0,
      sessionRequests: 0,
    };
  }

  const now = Date.now();
  const oneMinute = 60 * 1000;
  const oneHour = 60 * 60 * 1000;

  return {
    hasLimits: true,
    requestsLastMinute: userLimits.requests.filter(t => now - t < oneMinute).length,
    requestsLastHour: userLimits.requests.filter(t => now - t < oneHour).length,
    ingestsLastHour: userLimits.ingests.filter(t => now - t < oneHour).length,
    sessionRequests: userLimits.sessionRequests || 0,
    sessionStart: userLimits.sessionStart,
    maxRequestsPerMinute: CONFIG.MAX_REQUESTS_PER_MINUTE,
    maxRequestsPerHour: CONFIG.MAX_REQUESTS_PER_HOUR,
    maxIngestsPerHour: CONFIG.MAX_INGESTS_PER_HOUR,
  };
});

/**
 * YouTube Preview Endpoint
 * Returns video metadata and transcript availability with token estimation
 */
export const youtubePreview = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '256MiB',
  secrets: [youtubeApiKey],
}, async (request) => {
  const { data, auth } = request;
  
  // Validate authentication
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = auth.uid;
  
  // Comprehensive request validation
  const validation = validateRequest(data);
  if (!validation.isValid) {
    logger.warn(`Invalid request from ${userId}: ${validation.error}`);
    throw new HttpsError('invalid-argument', validation.error || 'Invalid request');
  }

  // Validate App Check token
  const isValidAppCheck = await validateAppCheck(data.appCheckToken);
  if (!isValidAppCheck) {
    logger.warn(`Invalid App Check token from ${userId}`);
    throw new HttpsError('permission-denied', 'Invalid App Check token');
  }

  // Check rate limits
  const rateLimitCheck = checkRateLimits(userId, false);
  if (!rateLimitCheck.allowed) {
    logger.warn(`Rate limit exceeded for ${userId}: ${rateLimitCheck.error}`);
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  // Check abuse patterns
  const abuseCheck = checkAbusePatterns(data.videoId);
  if (!abuseCheck.allowed) {
    logger.warn(`Abuse pattern detected for video ${data.videoId}: ${abuseCheck.error}`);
    throw new HttpsError('permission-denied', abuseCheck.error || 'Request blocked');
  }

  const { videoId } = data;

  try {
    // Check cache first
    const cacheKey = `preview_${videoId}`;
    const cached = previewCache.get(cacheKey);
    if (cached) {
      logger.info(`Cache hit for video ${videoId}`);
      return cached;
    }

    // Get user's plan information
    const userDoc = await admin.firestore().collection('users').doc(auth.uid).get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data()!;
    const userTier = userData.tier || 'free';
    const monthlyYoutubeIngests = userData.monthlyYoutubeIngests || 0;
    
    // Count this month's ingests
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);
    
    const ingestsThisMonth = await admin.firestore().collection('materials')
      .where('owner', '==', auth.uid)
      .where('type', '==', 'youtube_transcript')
      .where('createdAt', '>=', startOfMonth)
      .count()
      .get();
    
    const youtubeIngestsRemaining = Math.max(0, monthlyYoutubeIngests - ingestsThisMonth.data().count);

    // Fetch video metadata (simplified - in production, use YouTube Data API)
    const videoMetadata = await fetchVideoMetadata(videoId);
    
    // Check transcript availability
    const transcriptInfo = await checkTranscriptAvailability(videoId);
    
    // Calculate token estimates
    const estimatedTokens = calculateEstimatedTokens(
      videoMetadata.durationSeconds, 
      transcriptInfo.charCount || undefined
    );
    const estimatedMindLoadTokens = Math.ceil((estimatedTokens + CONFIG.OUT_TOKENS_DEFAULT) / CONFIG.TOKENS_PER_ML_TOKEN);
    
    // Check plan limits
    const maxDuration = userTier === 'free' ? CONFIG.FREE_MAX_DURATION_SECONDS : CONFIG.PRO_MAX_DURATION_SECONDS;
    const isOverDurationLimit = videoMetadata.durationSeconds > maxDuration;
    const isOverIngestLimit = youtubeIngestsRemaining <= 0;
    
    const blocked = isOverDurationLimit || isOverIngestLimit;
    let blockReason = null;
    
    if (isOverDurationLimit) {
      blockReason = `Over plan limit (max ${formatDuration(maxDuration)}). Upgrade to continue.`;
    } else if (isOverIngestLimit) {
      blockReason = 'Monthly YouTube ingest limit reached. Upgrade to continue.';
    }

    // Build response
    const response = {
      videoId,
      title: videoMetadata.title,
      channel: videoMetadata.channel,
      durationSeconds: videoMetadata.durationSeconds,
      thumbnail: `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`,
      captionsAvailable: transcriptInfo.available,
      primaryLang: transcriptInfo.language,
      estimatedTokens,
      estimatedMindLoadTokens,
      blocked,
      blockReason,
      limits: {
        maxDurationSeconds: maxDuration,
        plan: userTier,
        monthlyYoutubeIngests,
        youtubeIngestsRemaining,
      },
    };

    // Cache the result
    previewCache.set(cacheKey, response);
    
    logger.info(`Preview generated for video ${videoId}, blocked: ${blocked}`);
    return response;

  } catch (error) {
    logger.error(`Error generating preview for video ${videoId}:`, error);
    throw new HttpsError('internal', 'Failed to generate preview');
  }
});

/**
 * YouTube Ingest Endpoint
 * Fetches transcript, sanitizes text, and creates study material
 */
export const youtubeIngest = onCall({
  region: 'us-central1',
  timeoutSeconds: 60,
  memory: '512MiB',
  secrets: [youtubeApiKey],
}, async (request) => {
  const { data, auth } = request;
  
  // Validate authentication
  if (!auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = auth.uid;
  
  // Comprehensive request validation
  const validation = validateRequest(data);
  if (!validation.isValid) {
    logger.warn(`Invalid ingest request from ${userId}: ${validation.error}`);
    throw new HttpsError('invalid-argument', validation.error || 'Invalid request');
  }

  // Validate App Check token
  const isValidAppCheck = await validateAppCheck(data.appCheckToken);
  if (!isValidAppCheck) {
    logger.warn(`Invalid App Check token for ingest from ${userId}`);
    throw new HttpsError('permission-denied', 'Invalid App Check token');
  }

  // Check rate limits (more restrictive for ingest)
  const rateLimitCheck = checkRateLimits(userId, true);
  if (!rateLimitCheck.allowed) {
    logger.warn(`Ingest rate limit exceeded for ${userId}: ${rateLimitCheck.error}`);
    throw new HttpsError('resource-exhausted', rateLimitCheck.error || 'Rate limit exceeded');
  }

  // Check abuse patterns
  const abuseCheck = checkAbusePatterns(data.videoId);
  if (!abuseCheck.allowed) {
    logger.warn(`Ingest abuse pattern detected for video ${data.videoId}: ${abuseCheck.error}`);
    throw new HttpsError('permission-denied', abuseCheck.error || 'Request blocked');
  }

  const { videoId, preferredLanguage } = data;

  try {
    // Check if material already exists (idempotency)
    const existingMaterial = await checkExistingMaterial(auth.uid, videoId);
    if (existingMaterial) {
      logger.info(`Material already exists for video ${videoId}, user ${auth.uid}`);
      return {
        materialId: existingMaterial.id,
        status: 'already_exists',
        mlTokensCharged: 0,
        inputTokens: 0,
      };
    }

    // Re-run plan/cost checks
    const userDoc = await admin.firestore().collection('users').doc(auth.uid).get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data()!;
    const userTier = userData.tier || 'free';
    const monthlyYoutubeIngests = userData.monthlyYoutubeIngests || 0;
    
    // Check monthly ingest limit
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);
    
    const ingestsThisMonth = await admin.firestore().collection('materials')
      .where('owner', '==', auth.uid)
      .where('type', '==', 'youtube_transcript')
      .where('createdAt', '>=', startOfMonth)
      .count()
      .get();
    
    if (ingestsThisMonth.data().count >= monthlyYoutubeIngests) {
      throw new HttpsError('resource-exhausted', 'Monthly YouTube ingest limit reached');
    }

    // Fetch video metadata and transcript
    const videoMetadata = await fetchVideoMetadata(videoId);
    const transcript = await fetchTranscript(videoId, preferredLanguage);
    
    if (!transcript) {
      throw new HttpsError('failed-precondition', 'No transcript available for this video');
    }

    // Sanitize transcript text
    const sanitizedText = sanitizeTranscript(transcript.text);
    const charCount = sanitizedText.length;
    
    // Calculate final token costs
    const inputTokens = Math.ceil(charCount / 4); // Rough estimate: 4 chars per token
    const mlTokensCharged = Math.ceil((inputTokens + CONFIG.OUT_TOKENS_DEFAULT) / CONFIG.TOKENS_PER_ML_TOKEN);
    
    // Check user has sufficient tokens
    const userTokens = userData.credits || 0;
    if (userTokens < mlTokensCharged) {
      throw new HttpsError('resource-exhausted', 'Insufficient MindLoad Tokens');
    }

    // Use transaction to atomically charge tokens and create material
    const result = await admin.firestore().runTransaction(async (transaction) => {
      // Re-check user document in transaction
      const userDocRef = admin.firestore().collection('users').doc(auth.uid);
      const userDocSnapshot = await transaction.get(userDocRef);
      
      if (!userDocSnapshot.exists) {
        throw new HttpsError('not-found', 'User not found');
      }
      
      const currentUserData = userDocSnapshot.data()!;
      const currentTokens = currentUserData.credits || 0;
      
      if (currentTokens < mlTokensCharged) {
        throw new HttpsError('resource-exhausted', 'Insufficient MindLoad Tokens');
      }
      
      // Create material document
      const materialRef = admin.firestore().collection('materials').doc();
      const materialData = {
        owner: auth.uid,
        type: 'youtube_transcript',
        videoId,
        title: videoMetadata.title,
        durationSeconds: videoMetadata.durationSeconds,
        charCount,
        inputTokens,
        mlTokensCharged,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'ready',
        language: transcript.language,
      };
      
      transaction.set(materialRef, materialData);
      
      // Charge tokens
      transaction.update(userDocRef, {
        credits: currentTokens - mlTokensCharged,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Store transcript text in Cloud Storage
      const transcriptBlob = admin.storage().bucket().file(`materials/${materialRef.id}/transcript.txt`);
      await transcriptBlob.save(sanitizedText, {
        metadata: {
          contentType: 'text/plain',
          metadata: {
            videoId,
            language: transcript.language,
            charCount: charCount.toString(),
          },
        },
      });
      
      return materialRef.id;
    });

    logger.info(`YouTube transcript ingested successfully for video ${videoId}, user ${auth.uid}, material ${result}`);
    
    return {
      materialId: result,
      status: 'processed',
      mlTokensCharged,
      inputTokens,
    };

  } catch (error) {
    logger.error(`Error ingesting YouTube transcript for video ${videoId}:`, error);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError('internal', 'Failed to ingest transcript');
  }
});

/**
 * Helper Functions
 */

async function fetchVideoMetadata(videoId: string): Promise<{
  title: string;
  channel: string;
  durationSeconds: number;
}> {
  try {
    const apiKey = youtubeApiKey.value();
    
    if (apiKey) {
      // Use YouTube Data API v3
      const response = await fetch(
        `https://www.googleapis.com/youtube/v3/videos?id=${videoId}&key=${apiKey}&part=snippet,contentDetails`
      );
      
      if (response.ok) {
        const data = await response.json() as any;
        const video = data.items?.[0];
        
        if (video) {
          const duration = parseDuration(video.contentDetails.duration);
          return {
            title: video.snippet.title,
            channel: video.snippet.channelTitle,
            durationSeconds: duration,
          };
        }
      }
    }
    
    // Fallback: Try to extract basic info from YouTube page
    const pageResponse = await fetch(`https://www.youtube.com/watch?v=${videoId}`);
    if (pageResponse.ok) {
      const html = await pageResponse.text();
      
      // Extract title from meta tags
      const titleMatch = html.match(/<meta property="og:title" content="([^"]+)"/);
      const channelMatch = html.match(/<meta property="og:video:tag" content="([^"]+)"/);
      
      return {
        title: titleMatch?.[1] || `Video ${videoId}`,
        channel: channelMatch?.[1] || 'Unknown Channel',
        durationSeconds: 600, // Default 10 minutes
      };
    }
    
    // Final fallback
    return {
      title: `Video ${videoId}`,
      channel: 'Unknown Channel',
      durationSeconds: 600,
    };
  } catch (error) {
    console.error('Error fetching video metadata:', error);
    return {
      title: `Video ${videoId}`,
      channel: 'Unknown Channel',
      durationSeconds: 600,
    };
  }
}

// Helper function to parse YouTube duration format (PT4M13S -> 253 seconds)
function parseDuration(duration: string): number {
  const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!match) return 0;
  
  const hours = parseInt(match[1] || '0', 10);
  const minutes = parseInt(match[2] || '0', 10);
  const seconds = parseInt(match[3] || '0', 10);
  
  return hours * 3600 + minutes * 60 + seconds;
}

async function checkTranscriptAvailability(videoId: string): Promise<{
  available: boolean;
  language: string | null;
  charCount: number | null;
}> {
  try {
    // Try to fetch transcript to check availability
    const transcript = await fetchTranscript(videoId);
    
    if (transcript) {
      return {
        available: true,
        language: transcript.language,
        charCount: transcript.text.length,
      };
    }
    
    return {
      available: false,
      language: null,
      charCount: null,
    };
  } catch (error) {
    console.error('Error checking transcript availability:', error);
    return {
      available: false,
      language: null,
      charCount: null,
    };
  }
}

async function fetchTranscript(videoId: string, preferredLanguage?: string): Promise<{
  text: string;
  language: string;
} | null> {
  try {
    // Try to get transcript from YouTube's auto-generated captions
    // This is a simplified approach - in production, use youtube-transcript library
    const response = await fetch(`https://www.youtube.com/api/timedtext?v=${videoId}&lang=${preferredLanguage || 'en'}&fmt=srv3`);
    
    if (response.ok) {
      const xmlText = await response.text();
      
      // Parse XML and extract text content
      const textMatches = xmlText.match(/<text[^>]*>([^<]+)<\/text>/g);
      if (textMatches) {
        const transcript = textMatches
          .map(match => {
            const textContent = match.replace(/<[^>]*>/g, '');
            return decodeURIComponent(textContent);
          })
          .join(' ')
          .trim();
          
        if (transcript.length > 50) { // Minimum viable transcript length
          return {
            text: sanitizeTranscript(transcript),
            language: preferredLanguage || 'en',
          };
        }
      }
    }
    
    // Try alternative language if preferred language failed
    if (preferredLanguage !== 'en') {
      return await fetchTranscript(videoId, 'en');
    }
    
    // Try auto-generated captions
    const autoResponse = await fetch(`https://www.youtube.com/api/timedtext?v=${videoId}&lang=en&fmt=srv3&tlang=en`);
    if (autoResponse.ok) {
      const xmlText = await autoResponse.text();
      const textMatches = xmlText.match(/<text[^>]*>([^<]+)<\/text>/g);
      
      if (textMatches) {
        const transcript = textMatches
          .map(match => {
            const textContent = match.replace(/<[^>]*>/g, '');
            return decodeURIComponent(textContent);
          })
          .join(' ')
          .trim();
          
        if (transcript.length > 50) {
          return {
            text: sanitizeTranscript(transcript),
            language: 'en',
          };
        }
      }
    }
    
    return null;
  } catch (error) {
    console.error('Error fetching transcript:', error);
    return null;
  }
}

function sanitizeTranscript(text: string): string {
  // Remove timestamps, emojis, control characters
  // Normalize whitespace
  return text
    .replace(/\[\d{2}:\d{2}\]/g, '') // Remove timestamps like [00:15]
    .replace(/[\u{1F600}-\u{1F64F}]/gu, '') // Remove emojis
    .replace(/[\u0000-\u001F\u007F-\u009F]/g, '') // Remove control characters
    .replace(/\s+/g, ' ') // Normalize whitespace
    .trim();
}

function calculateEstimatedTokens(durationSeconds: number, charCount?: number): number {
  if (charCount) {
    return Math.ceil(charCount / 4); // 4 chars per token estimate
  }
  
  // Estimate from duration: 150 words per minute, 5 chars per word
  const estimatedChars = (durationSeconds / 60) * 150 * 5;
  return Math.ceil(estimatedChars / 4);
}

function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
}

async function checkExistingMaterial(userId: string, videoId: string): Promise<admin.firestore.DocumentSnapshot | null> {
  const existingMaterials = await admin.firestore().collection('materials')
    .where('owner', '==', userId)
    .where('videoId', '==', videoId)
    .where('type', '==', 'youtube_transcript')
    .limit(1)
    .get();
  
  return existingMaterials.docs[0] || null;
}

/**
 * Clean up expired cache entries periodically
 */
export const cleanupYouTubeCache = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '128MiB',
}, async () => {
  try {
    const beforeSize = previewCache.size();
    previewCache.clear();
    const afterSize = previewCache.size();
    
    logger.info(`YouTube cache cleaned up: ${beforeSize} -> ${afterSize} entries`);
    
    return {
      success: true,
      entriesCleared: beforeSize - afterSize,
    };
  } catch (error) {
    logger.error('Error cleaning up YouTube cache:', error);
    throw new HttpsError('internal', 'Failed to clean up cache');
  }
});
