/**
 * Generate flashcards from content
 */
export declare const generateFlashcards: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    flashcards: any;
    usage: any;
}>>;
/**
 * Generate study material from content
 */
export declare const generateStudyMaterial: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    content: any;
    usage: any;
}>>;
