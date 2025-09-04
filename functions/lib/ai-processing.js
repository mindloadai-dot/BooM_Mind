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
            firebase_functions_1.logger.error('OpenAI API key not configured');
            throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
        }
        // Call OpenAI API
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
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
            throw new https_1.HttpsError('internal', 'OpenAI API request failed');
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
        // AI response is invalid
        throw new https_1.HttpsError('internal', 'Invalid AI response format');
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
            firebase_functions_1.logger.error('OpenAI API key not configured');
            throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
        }
        // Call OpenAI API
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
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
            throw new https_1.HttpsError('internal', 'OpenAI API request failed');
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
        // AI response is invalid
        throw new https_1.HttpsError('internal', 'Invalid AI response format');
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
                throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
            }
        }
        if (generateFlashcards) {
            if (apiKey) {
                // Generate flashcards directly using OpenAI API
                const flashcardResult = await generateFlashcardsDirectly(content, 10);
                results.flashcards = flashcardResult;
            }
            else {
                throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
            }
        }
        if (generateQuestions) {
            if (apiKey) {
                // Generate quiz questions directly using OpenAI API
                const quizResult = await generateQuizQuestionsDirectly(content, 5);
                results.questions = quizResult;
            }
            else {
                throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
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
    if (!apiKey) {
        throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
    }
    try {
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert at creating concise, informative summaries. Create a clear summary of the content that captures the key points and main ideas. ${customInstructions ? `Additional instructions: ${customInstructions}` : ''}`
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
            return data.choices?.[0]?.message?.content || 'Summary generation failed';
        }
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating AI summary:', error);
    }
    throw new https_1.HttpsError('internal', 'Failed to generate summary');
}
async function generateFlashcardsDirectly(content, count) {
    const apiKey = openaiApiKey.value();
    if (!apiKey) {
        throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
    }
    try {
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert at creating educational flashcards. Create ${count} flashcards from the provided content. Each flashcard should have a clear question on the front and a concise answer on the back. Return the response as a JSON array with objects containing 'question' and 'answer' fields.`
                    },
                    {
                        role: 'user',
                        content: `Create ${count} flashcards from this content:\n\n${content}`
                    }
                ],
                max_tokens: 2000,
                temperature: 0.7,
                response_format: { type: "json_object" }
            }),
        });
        if (response.ok) {
            const data = await response.json();
            const content = data.choices?.[0]?.message?.content;
            if (content) {
                try {
                    const parsed = JSON.parse(content);
                    return parsed.flashcards || [];
                }
                catch (parseError) {
                    firebase_functions_1.logger.error('Error parsing flashcards response:', parseError);
                    return [];
                }
            }
        }
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating flashcards:', error);
    }
    return [];
}
async function generateQuizQuestionsDirectly(content, count) {
    const apiKey = openaiApiKey.value();
    if (!apiKey) {
        throw new https_1.HttpsError('failed-precondition', 'OpenAI API key not configured');
    }
    try {
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4o-mini',
                messages: [
                    {
                        role: 'system',
                        content: `You are an expert educational assessment designer specializing in creating challenging, thought-provoking quiz questions. Create ${count} sophisticated multiple choice questions that go beyond simple recall and test deep understanding.

QUESTION DESIGN PRINCIPLES:
- Focus on higher-order thinking: analysis, synthesis, evaluation, application
- Create questions that require critical thinking and reasoning
- Test conceptual understanding, not just memorization
- Include scenario-based questions that apply knowledge to new situations
- Design questions that connect ideas and require inference
- Use "Why" and "How" reasoning rather than just "What" facts

QUESTION TYPES TO INCLUDE:
- Analytical: "What would happen if..." "Why does this occur..." "What causes..."
- Application: "In this scenario, which approach..." "How would you apply..." "Given these conditions..."
- Synthesis: "What is the relationship between..." "How do these concepts connect..." "What patterns emerge..."
- Evaluation: "Which is the most effective..." "What are the implications of..." "How would you judge..."
- Inference: "Based on this information, what can you conclude..." "What does this suggest about..."

DIFFICULTY PROGRESSION:
- 30% Intermediate: Require connecting 2-3 concepts
- 50% Advanced: Require analysis and application to new contexts  
- 20% Expert: Require synthesis of multiple complex ideas

ANSWER OPTIONS DESIGN:
- Create 4 plausible options with sophisticated distractors
- Include common misconceptions as wrong answers
- Make distractors that require careful analysis to eliminate
- Ensure only one clearly correct answer after thorough reasoning

Return JSON object with 'questions' array containing objects with:
- 'question': The challenging question text
- 'options': Array of 4 plausible answer choices
- 'correctAnswer': Index (0-3) of the correct answer
- 'difficulty': 'intermediate', 'advanced', or 'expert'
- 'explanation': Detailed explanation of why the answer is correct and why others are wrong`
                    },
                    {
                        role: 'user',
                        content: `Create ${count} challenging and inquisitive quiz questions from this content. Focus on deep understanding, critical thinking, and application rather than simple recall. Make questions that would challenge even knowledgeable students and require careful analysis to answer correctly. Extract the most important concepts and create questions that test understanding of relationships, implications, and applications:\n\n${content}`
                    }
                ],
                max_tokens: 3000,
                temperature: 0.8,
                response_format: { type: "json_object" }
            }),
        });
        if (response.ok) {
            const data = await response.json();
            const content = data.choices?.[0]?.message?.content;
            if (content) {
                try {
                    const parsed = JSON.parse(content);
                    return parsed.questions || [];
                }
                catch (parseError) {
                    firebase_functions_1.logger.error('Error parsing quiz response:', parseError);
                    return [];
                }
            }
        }
    }
    catch (error) {
        firebase_functions_1.logger.error('Error generating quiz questions:', error);
    }
    return [];
}
//# sourceMappingURL=ai-processing.js.map