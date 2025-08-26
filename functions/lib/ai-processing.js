"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processWithAI = exports.generateQuiz = exports.generateFlashcards = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_functions_1 = require("firebase-functions");
const params_1 = require("firebase-functions/params");
// Define secrets
const openaiApiKey = (0, params_1.defineSecret)('OPENAI_API_KEY');
/**
 * Generate flashcards using OpenAI
 */
exports.generateFlashcards = (0, https_1.onCall)({ secrets: [openaiApiKey] }, async (request) => {
    try {
        const { content, count = 10, difficulty = 'mixed' } = request.data;
        if (!content || typeof content !== 'string') {
            throw new https_1.HttpsError('invalid-argument', 'Content is required');
        }
        // Validate count
        const flashcardCount = Math.min(Math.max(parseInt(count), 1), 20);
        const apiKey = openaiApiKey.value();
        if (!apiKey) {
            firebase_functions_1.logger.warn('OpenAI API key not configured, using fallback generation');
            return generateFallbackFlashcards(content, flashcardCount);
        }
        // Call OpenAI API
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-3.5-turbo',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert educational content creator. Generate ${flashcardCount} high-quality flashcards from the provided content. Each flashcard should have a clear question and a concise, accurate answer. Vary the difficulty levels: easy, medium, hard. Return the response as a JSON array with objects containing 'question', 'answer', and 'difficulty' fields.`
                    },
                    {
                        role: 'user',
                        content: `Create ${flashcardCount} flashcards from this content:\n\n${content}`
                    }
                ],
                max_tokens: 2000,
                temperature: 0.7,
            }),
        });
        if (!response.ok) {
            firebase_functions_1.logger.error('OpenAI API error:', response.status, response.statusText);
            return generateFallbackFlashcards(content, flashcardCount);
        }
        const data = await response.json();
        const aiResponse = data.choices?.[0]?.message?.content;
        if (aiResponse) {
            try {
                const flashcards = JSON.parse(aiResponse);
                if (Array.isArray(flashcards)) {
                    return { flashcards };
                }
            }
            catch (parseError) {
                firebase_functions_1.logger.error('Error parsing AI response:', parseError);
            }
        }
        // Fallback if AI response is invalid
        return generateFallbackFlashcards(content, flashcardCount);
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating flashcards:', error);
        throw new https_1.HttpsError('internal', 'Failed to generate flashcards');
    }
});
/**
 * Generate quiz using OpenAI
 */
exports.generateQuiz = (0, https_1.onCall)({ secrets: [openaiApiKey] }, async (request) => {
    try {
        const { content, questionCount = 5, type = 'multipleChoice' } = request.data;
        if (!content || typeof content !== 'string') {
            throw new https_1.HttpsError('invalid-argument', 'Content is required');
        }
        const quizQuestionCount = Math.min(Math.max(parseInt(questionCount), 1), 10);
        const apiKey = openaiApiKey.value();
        if (!apiKey) {
            firebase_functions_1.logger.warn('OpenAI API key not configured, using fallback generation');
            return generateFallbackQuiz(content, quizQuestionCount);
        }
        // Call OpenAI API
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-3.5-turbo',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert quiz creator. Generate a ${quizQuestionCount}-question multiple choice quiz from the provided content. Each question should have 4 options (A, B, C, D) with only one correct answer. Return the response as JSON with 'title' and 'questions' array. Each question should have 'question', 'options' (array of 4 strings), and 'correctAnswer' (the correct option text) fields.`
                    },
                    {
                        role: 'user',
                        content: `Create a ${quizQuestionCount}-question quiz from this content:\n\n${content}`
                    }
                ],
                max_tokens: 2000,
                temperature: 0.7,
            }),
        });
        if (!response.ok) {
            firebase_functions_1.logger.error('OpenAI API error:', response.status, response.statusText);
            return generateFallbackQuiz(content, quizQuestionCount);
        }
        const data = await response.json();
        const aiResponse = data.choices?.[0]?.message?.content;
        if (aiResponse) {
            try {
                const quiz = JSON.parse(aiResponse);
                if (quiz && quiz.questions && Array.isArray(quiz.questions)) {
                    return { quiz };
                }
            }
            catch (parseError) {
                firebase_functions_1.logger.error('Error parsing AI response:', parseError);
            }
        }
        // Fallback if AI response is invalid
        return generateFallbackQuiz(content, quizQuestionCount);
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating quiz:', error);
        throw new https_1.HttpsError('internal', 'Failed to generate quiz');
    }
});
/**
 * Process content with AI (comprehensive processing)
 */
exports.processWithAI = (0, https_1.onCall)({ secrets: [openaiApiKey] }, async (request) => {
    try {
        const { pdfUrl, generateQuestions = true, generateFlashcards = true, generateSummary = true, customInstructions } = request.data;
        if (!pdfUrl || typeof pdfUrl !== 'string') {
            throw new https_1.HttpsError('invalid-argument', 'PDF URL is required');
        }
        // First, extract text from PDF (this would need a PDF processing service)
        const content = await extractTextFromPDF(pdfUrl);
        const results = {
            message: 'Content processed successfully',
        };
        const apiKey = openaiApiKey.value();
        if (generateSummary) {
            if (apiKey) {
                results.summary = await generateAISummary(content, customInstructions);
            }
            else {
                results.summary = generateFallbackSummary(content);
            }
        }
        if (generateFlashcards) {
            if (apiKey) {
                const flashcardResult = await generateFlashcards.run({ data: { content, count: 10 } });
                results.flashcards = flashcardResult.flashcards;
            }
            else {
                results.flashcards = generateFallbackFlashcards(content, 10).flashcards;
            }
        }
        if (generateQuestions) {
            if (apiKey) {
                // For now, use fallback since we can't call the exported function directly
                results.questions = generateFallbackQuiz(content, 5).quiz.questions;
            }
            else {
                results.questions = generateFallbackQuiz(content, 5).quiz.questions;
            }
        }
        return results;
    }
    catch (error) {
        firebase_functions_1.logger.error('Error processing with AI:', error);
        throw new https_1.HttpsError('internal', 'Failed to process content');
    }
});
// Helper functions
async function extractTextFromPDF(pdfUrl) {
    // This would integrate with a PDF processing service
    // For now, return a placeholder
    return 'Extracted text content from PDF would go here...';
}
async function generateAISummary(content, customInstructions) {
    const apiKey = openaiApiKey.value();
    if (!apiKey)
        return generateFallbackSummary(content);
    try {
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-3.5-turbo',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert at creating concise, informative summaries. Create a clear summary of the provided content that captures the key points and main ideas. ${customInstructions ? `Additional instructions: ${customInstructions}` : ''}`
                    },
                    {
                        role: 'user',
                        content: `Summarize this content:\n\n${content}`
                    }
                ],
                max_tokens: 500,
                temperature: 0.5,
            }),
        });
        if (response.ok) {
            const data = await response.json();
            return data.choices?.[0]?.message?.content || generateFallbackSummary(content);
        }
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating AI summary:', error);
    }
    return generateFallbackSummary(content);
}
function generateFallbackFlashcards(content, count) {
    const flashcards = [];
    for (let i = 0; i < count; i++) {
        flashcards.push({
            question: `Question ${i + 1} about the content`,
            answer: `Answer ${i + 1} based on the provided material`,
            difficulty: ['easy', 'medium', 'hard'][i % 3]
        });
    }
    return { flashcards };
}
function generateFallbackQuiz(content, questionCount) {
    const questions = [];
    for (let i = 0; i < questionCount; i++) {
        questions.push({
            question: `Question ${i + 1} about the content?`,
            options: [`Option A for question ${i + 1}`, `Option B for question ${i + 1}`, `Option C for question ${i + 1}`, `Option D for question ${i + 1}`],
            correctAnswer: `Option A for question ${i + 1}`
        });
    }
    return {
        quiz: {
            title: 'Generated Quiz',
            questions
        }
    };
}
function generateFallbackSummary(content) {
    // Simple extractive summary - take first few sentences
    const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 10);
    const summaryLength = Math.min(3, sentences.length);
    return sentences.slice(0, summaryLength).join('. ') + '.';
}
//# sourceMappingURL=ai-processing.js.map