/**
 * Clean up rate limiting data periodically
 */
export declare function cleanupRateLimitData(): void;
/**
 * Scheduled function to clean up rate limiting data
 * Runs every hour to prevent memory leaks
 */
export declare const cleanupYouTubeRateLimit: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    timestamp: number;
}>>;
/**
 * Admin function to reset rate limits for a user
 */
export declare const resetUserRateLimits: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    resetUserId: any;
}>>;
/**
 * Function to get rate limit status for debugging
 */
export declare const getRateLimitStatus: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    hasLimits: boolean;
    requests: number;
    ingests: number;
    sessionRequests: number;
    requestsLastMinute?: undefined;
    requestsLastHour?: undefined;
    ingestsLastHour?: undefined;
    sessionStart?: undefined;
    maxRequestsPerMinute?: undefined;
    maxRequestsPerHour?: undefined;
    maxIngestsPerHour?: undefined;
} | {
    hasLimits: boolean;
    requestsLastMinute: number;
    requestsLastHour: number;
    ingestsLastHour: number;
    sessionRequests: number;
    sessionStart: number | undefined;
    maxRequestsPerMinute: 10;
    maxRequestsPerHour: 60;
    maxIngestsPerHour: 5;
    requests?: undefined;
    ingests?: undefined;
}>>;
/**
 * YouTube Preview Endpoint
 * Returns video metadata and transcript availability with token estimation
 */
export declare const youtubePreview: import("firebase-functions/v2/https").CallableFunction<any, Promise<any>>;
/**
 * YouTube Ingest Endpoint
 * Fetches transcript, sanitizes text, and creates study material
 */
export declare const youtubeIngest: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    materialId: string;
    status: string;
    mlTokensCharged: number;
    inputTokens: number;
}>>;
/**
 * Clean up expired cache entries periodically
 */
export declare const cleanupYouTubeCache: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    entriesCleared: number;
}>>;
