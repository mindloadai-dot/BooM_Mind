import OpenAI from 'openai';
/**
 * Test OpenAI authentication
 */
export declare const testOpenAI: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    simpleMessage: string | null;
    complexMessage: string | null;
    simpleUsage: OpenAI.Completions.CompletionUsage | undefined;
    complexUsage: OpenAI.Completions.CompletionUsage | undefined;
}>>;
/**
 * Generate flashcards from content
 */
export declare const generateFlashcards: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    flashcards: any;
    usage: OpenAI.Completions.CompletionUsage | undefined;
}>>;
/**
 * Generate quiz questions from content
 */
export declare const generateQuiz: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    questions: any;
    usage: OpenAI.Completions.CompletionUsage | undefined;
}>>;
/**
 * Generate study material from content
 */
export declare const generateStudyMaterial: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    content: string;
    usage: OpenAI.Completions.CompletionUsage | undefined;
}>>;
