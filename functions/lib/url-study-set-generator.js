"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onStudySetCreated = exports.generateStudySetFromUrl = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const params_1 = require("firebase-functions/params");
const admin_1 = require("./admin");
const auth_1 = require("firebase-admin/auth");
const openai_1 = __importDefault(require("openai"));
const jsdom_1 = require("jsdom");
const readability_1 = require("@mozilla/readability");
const node_fetch_1 = __importDefault(require("node-fetch"));
// Define secrets for secure API key management
const openaiApiKey = (0, params_1.defineSecret)('OPENAI_API_KEY');
const auth = (0, auth_1.getAuth)();
// Initialize OpenAI with proper secret management
function createOpenAIClient() {
    const apiKey = openaiApiKey.value();
    if (!apiKey) {
        throw new Error('OpenAI API key not configured');
    }
    return new openai_1.default({
        apiKey: apiKey,
    });
}
// HTTPS Callable function for URL content extraction and study set generation
exports.generateStudySetFromUrl = (0, https_1.onCall)({
    maxInstances: 10,
    timeoutSeconds: 540,
    secrets: [openaiApiKey],
}, async (request) => {
    try {
        const { url, userId, title, maxItems = 50 } = request.data;
        if (!url || !userId) {
            throw new Error('URL and userId are required');
        }
        // Verify user authentication
        const user = await auth.getUser(userId);
        if (!user) {
            throw new Error('User not found');
        }
        console.log(`Starting study set generation for URL: ${url}`);
        // Step 1: Fetch and extract content
        const extractionResult = await fetchAndExtract(url);
        // Step 2: Chunk the text
        const chunks = chunkText(extractionResult.text, 1500);
        // Step 3: Generate study items from chunks
        const allItems = [];
        for (const chunk of chunks) {
            const items = await generateItems(chunk);
            allItems.push(...items);
        }
        // Step 4: Merge, dedupe, and cap items
        const finalItems = deduplicateAndCapItems(allItems, maxItems);
        // Step 5: Create study set document
        const studySetId = await createStudySet({
            title: title || extractionResult.title,
            sourceUrl: url,
            preview: extractionResult.text.substring(0, 500) + '...',
            itemCount: finalItems.length,
            userId,
        });
        // Step 6: Save individual items to Firestore (for backup/sync)
        await saveStudyItems(studySetId, finalItems);
        console.log(`Successfully generated study set with ${finalItems.length} items`);
        return {
            success: true,
            studySetId,
            itemCount: finalItems.length,
            title: title || extractionResult.title,
            preview: extractionResult.text.substring(0, 200) + '...',
            items: finalItems, // Return the generated items to client
        };
    }
    catch (error) {
        console.error('Error generating study set:', error);
        throw new Error(`Failed to generate study set: ${error instanceof Error ? error.message : String(error)}`);
    }
});
// Function to fetch and extract content from URL
async function fetchAndExtract(url) {
    try {
        const response = await (0, node_fetch_1.default)(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; MindLoad/1.0)',
            },
        });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        const html = await response.text();
        const dom = new jsdom_1.JSDOM(html, { url });
        const reader = new readability_1.Readability(dom.window.document);
        const article = reader.parse();
        if (!article) {
            throw new Error('Could not extract readable content from URL');
        }
        return {
            title: article.title || 'Untitled Article',
            text: article.textContent || '',
            url,
            wordCount: article.textContent?.split(/\s+/).length || 0,
        };
    }
    catch (error) {
        console.error('Error fetching/extracting content:', error);
        throw new Error(`Failed to extract content from URL: ${error instanceof Error ? error.message : String(error)}`);
    }
}
// Function to chunk text into smaller pieces
function chunkText(text, maxChars) {
    const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
    const chunks = [];
    let currentChunk = '';
    for (const sentence of sentences) {
        const sentenceWithPeriod = sentence.trim() + '. ';
        if (currentChunk.length + sentenceWithPeriod.length > maxChars && currentChunk.length > 0) {
            chunks.push(currentChunk.trim());
            currentChunk = sentenceWithPeriod;
        }
        else {
            currentChunk += sentenceWithPeriod;
        }
    }
    if (currentChunk.trim().length > 0) {
        chunks.push(currentChunk.trim());
    }
    return chunks;
}
/**
 * Retry OpenAI API calls with exponential backoff for handling overload errors
 */
async function retryOpenAICall(apiCall, operationType, maxRetries = 3) {
    let lastError;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            console.log(`🔄 OpenAI API call attempt ${attempt}/${maxRetries} for ${operationType}`);
            const result = await apiCall();
            if (attempt > 1) {
                console.log(`✅ OpenAI API call succeeded on attempt ${attempt} for ${operationType}`);
            }
            return result;
        }
        catch (error) {
            lastError = error;
            // Check if this is a retryable error
            const isOverloaded = error.message?.includes('Overloaded') ||
                error.message?.includes('overloaded') ||
                error.status === 503 ||
                error.status === 529;
            const isRetryable = [408, 429, 500, 502, 503, 504, 529].includes(error.status) ||
                ['overloaded', 'timeout', 'rate limit', 'server error'].some(msg => (error.message || '').toLowerCase().includes(msg));
            console.warn(`⚠️ OpenAI API call failed (attempt ${attempt}/${maxRetries}) for ${operationType}:`, {
                error: error.message,
                status: error.status,
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
            console.log(`⏳ Retrying in ${Math.round(delay)}ms...`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
    // If we get here, all retries failed - throw the last error
    console.error(`❌ All ${maxRetries} attempts failed for ${operationType}`, {
        finalError: lastError.message,
        status: lastError.status
    });
    throw lastError;
}
// Function to generate study items from text chunk using OpenAI
async function generateItems(textChunk) {
    try {
        // Check if OpenAI API key is properly configured
        const apiKey = openaiApiKey.value();
        if (!apiKey) {
            console.warn('OpenAI API key not configured, returning sample items');
            return generateSampleItems(textChunk);
        }
        const client = createOpenAIClient();
        const prompt = `Generate study items from the following text. Create a mix of multiple choice questions, short answer questions, and flashcards. Focus on key concepts and important details.

Text: "${textChunk}"

Generate 3-5 study items with this structure:
- Multiple choice questions with 4 options
- Short answer questions that test understanding
- Flashcards for key terms and concepts

Make sure questions are clear, accurate, and test different levels of understanding.`;
        // Use retry logic for OpenAI API calls
        const response = await retryOpenAICall(async () => {
            return await client.chat.completions.create({
                model: 'gpt-4o-mini',
                messages: [
                    {
                        role: 'system',
                        content: 'You are an expert educational content creator. Generate high-quality study items that help students learn effectively.',
                    },
                    {
                        role: 'user',
                        content: prompt,
                    },
                ],
                response_format: { type: 'json_object' },
                temperature: 0.7,
                max_tokens: 2000,
            });
        }, 'generateItems');
        const content = response.choices[0]?.message?.content;
        if (!content) {
            throw new Error('No response from OpenAI');
        }
        const parsed = JSON.parse(content);
        const items = [];
        // Parse the structured response
        if (parsed.items && Array.isArray(parsed.items)) {
            for (const item of parsed.items) {
                if (item.type && item.question && item.answer) {
                    items.push({
                        type: item.type,
                        question: item.question,
                        answer: item.answer,
                        options: item.options,
                        explanation: item.explanation,
                        difficulty: item.difficulty || 'medium',
                    });
                }
            }
        }
        return items;
    }
    catch (error) {
        console.error('Error generating items with retry logic:', error);
        // Provide more user-friendly error handling
        if (error.message?.includes('Overloaded') || error.status === 503 || error.status === 529) {
            console.warn('🔄 OpenAI is overloaded, falling back to sample items');
        }
        return generateSampleItems(textChunk);
    }
}
// Function to generate sample items when OpenAI is not available
function generateSampleItems(textChunk) {
    const words = textChunk.split(/\s+/).slice(0, 10); // Take first 10 words
    const sampleText = words.join(' ');
    return [
        {
            type: 'multiple_choice',
            question: `What is the main topic discussed in: "${sampleText}..."?`,
            answer: 'The main topic is discussed in the text',
            options: [
                'The main topic is discussed in the text',
                'The text discusses something else',
                'The topic is not mentioned',
                'The text is about a different subject'
            ],
            explanation: 'This is a sample question generated when OpenAI is not available.',
            difficulty: 'medium',
        },
        {
            type: 'short_answer',
            question: 'Summarize the key points from the provided text.',
            answer: 'The text contains important information that should be summarized based on the content.',
            explanation: 'This is a sample short answer question.',
            difficulty: 'medium',
        },
        {
            type: 'flashcard',
            question: 'Key Concept',
            answer: 'Important information from the text that should be remembered.',
            explanation: 'This is a sample flashcard.',
            difficulty: 'easy',
        },
    ];
}
// Function to deduplicate and cap items
function deduplicateAndCapItems(items, maxItems) {
    const seen = new Set();
    const uniqueItems = [];
    for (const item of items) {
        const key = `${item.type}:${item.question.toLowerCase()}`;
        if (!seen.has(key) && uniqueItems.length < maxItems) {
            seen.add(key);
            uniqueItems.push(item);
        }
    }
    return uniqueItems;
}
// Function to create study set document
async function createStudySet(data) {
    const studySetRef = admin_1.db.collection('study_sets').doc();
    await studySetRef.set({
        title: data.title,
        sourceUrl: data.sourceUrl,
        preview: data.preview,
        itemCount: data.itemCount,
        userId: data.userId,
        createdAt: new Date(),
        updatedAt: new Date(),
        isGenerated: true,
    });
    return studySetRef.id;
}
// Function to save study items
async function saveStudyItems(studySetId, items) {
    const batch = admin_1.db.batch();
    for (const item of items) {
        const itemRef = admin_1.db.collection('study_sets').doc(studySetId).collection('items').doc();
        batch.set(itemRef, {
            type: item.type,
            question: item.question,
            answer: item.answer,
            options: item.options || [],
            explanation: item.explanation || '',
            difficulty: item.difficulty,
            createdAt: new Date(),
        });
    }
    await batch.commit();
}
// Firestore trigger to sync study sets to local storage
exports.onStudySetCreated = (0, firestore_1.onDocumentCreated)('study_sets/{studySetId}', async (event) => {
    const studySetData = event.data?.data();
    if (!studySetData)
        return;
    console.log(`Study set created: ${event.params.studySetId}`);
    // This will be handled by the client-side offline sync
    // The client will download the study set and items for offline use
});
//# sourceMappingURL=url-study-set-generator.js.map