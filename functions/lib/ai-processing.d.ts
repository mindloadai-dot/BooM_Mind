/**
 * Generate flashcards using OpenAI
 */
export declare const generateFlashcards: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    flashcards: any[];
}>>;
/**
 * Generate quiz using OpenAI
 */
export declare const generateQuiz: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    quiz: any;
}>>;
/**
 * Process content with AI (comprehensive processing)
 */
export declare const processWithAI: import("firebase-functions/v2/https").CallableFunction<any, Promise<any>>;
