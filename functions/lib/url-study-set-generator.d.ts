interface StudySetGenerationRequest {
    url: string;
    userId: string;
    title?: string;
    maxItems?: number;
}
export declare const generateStudySetFromUrl: import("firebase-functions/v2/https").CallableFunction<StudySetGenerationRequest, any>;
export declare const onStudySetCreated: import("firebase-functions/v2/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    studySetId: string;
}>>;
export {};
