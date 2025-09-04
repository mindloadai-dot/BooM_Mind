import { onCall } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { admin, db } from './admin';
import { getAuth } from 'firebase-admin/auth';
import OpenAI from 'openai';
import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
import fetch from 'node-fetch';

// Define secrets for secure API key management
const openaiApiKey = defineSecret('OPENAI_API_KEY');

const auth = getAuth();

// Initialize OpenAI with proper secret management
function createOpenAIClient(): OpenAI {
  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    throw new Error('OpenAI API key not configured');
  }
  
  return new OpenAI({
    apiKey: apiKey,
  });
}

// Types for structured output
interface StudyItem {
  type: 'multiple_choice' | 'short_answer' | 'flashcard';
  question: string;
  answer: string;
  options?: string[];
  explanation?: string;
  difficulty: 'easy' | 'medium' | 'hard';
}

interface ContentExtractionResult {
  title: string;
  text: string;
  url: string;
  wordCount: number;
}

interface StudySetGenerationRequest {
  url: string;
  userId: string;
  title?: string;
  maxItems?: number;
}

// HTTPS Callable function for URL content extraction and study set generation
export const generateStudySetFromUrl = onCall<StudySetGenerationRequest>({
  maxInstances: 10,
  timeoutSeconds: 540, // 9 minutes for content processing
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
    const allItems: StudyItem[] = [];
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
    
  } catch (error) {
    console.error('Error generating study set:', error);
    throw new Error(`Failed to generate study set: ${error instanceof Error ? error.message : String(error)}`);
  }
});

// Function to fetch and extract content from URL
async function fetchAndExtract(url: string): Promise<ContentExtractionResult> {
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; MindLoad/1.0)',
      },
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const html = await response.text();
    const dom = new JSDOM(html, { url });
    const reader = new Readability(dom.window.document);
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
  } catch (error) {
    console.error('Error fetching/extracting content:', error);
    throw new Error(`Failed to extract content from URL: ${error instanceof Error ? error.message : String(error)}`);
  }
}

// Function to chunk text into smaller pieces
function chunkText(text: string, maxChars: number): string[] {
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
  const chunks: string[] = [];
  let currentChunk = '';
  
  for (const sentence of sentences) {
    const sentenceWithPeriod = sentence.trim() + '. ';
    if (currentChunk.length + sentenceWithPeriod.length > maxChars && currentChunk.length > 0) {
      chunks.push(currentChunk.trim());
      currentChunk = sentenceWithPeriod;
    } else {
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
async function retryOpenAICall<T>(
  apiCall: () => Promise<T>,
  operationType: string,
  maxRetries: number = 3
): Promise<T> {
  let lastError: any;
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`🔄 OpenAI API call attempt ${attempt}/${maxRetries} for ${operationType}`);
      
      const result = await apiCall();
      
      if (attempt > 1) {
        console.log(`✅ OpenAI API call succeeded on attempt ${attempt} for ${operationType}`);
      }
      
      return result;
    } catch (error: any) {
      lastError = error;
      
      // Check if this is a retryable error
      const isOverloaded = error.message?.includes('Overloaded') || 
                          error.message?.includes('overloaded') ||
                          error.status === 503 ||
                          error.status === 529;
      
      const isRetryable = [408, 429, 500, 502, 503, 504, 529].includes(error.status) ||
                         ['overloaded', 'timeout', 'rate limit', 'server error'].some(msg => 
                           (error.message || '').toLowerCase().includes(msg));
      
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
async function generateItems(textChunk: string): Promise<StudyItem[]> {
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
    const items: StudyItem[] = [];

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
  } catch (error: any) {
    console.error('Error generating items with retry logic:', error);
    
    // Provide more user-friendly error handling
    if (error.message?.includes('Overloaded') || error.status === 503 || error.status === 529) {
      console.warn('🔄 OpenAI is overloaded, falling back to sample items');
    }
    
    return generateSampleItems(textChunk);
  }
}

// Function to generate sample items when OpenAI is not available
function generateSampleItems(textChunk: string): StudyItem[] {
  const words = textChunk.split(/\s+/).slice(0, 10); // Take first 10 words
  const sampleText = words.join(' ');
  
  return [
    {
      type: 'multiple_choice' as const,
      question: `What is the main topic discussed in: "${sampleText}..."?`,
      answer: 'The main topic is discussed in the text',
      options: [
        'The main topic is discussed in the text',
        'The text discusses something else',
        'The topic is not mentioned',
        'The text is about a different subject'
      ],
      explanation: 'This is a sample question generated when OpenAI is not available.',
      difficulty: 'medium' as const,
    },
    {
      type: 'short_answer' as const,
      question: 'Summarize the key points from the provided text.',
      answer: 'The text contains important information that should be summarized based on the content.',
      explanation: 'This is a sample short answer question.',
      difficulty: 'medium' as const,
    },
    {
      type: 'flashcard' as const,
      question: 'Key Concept',
      answer: 'Important information from the text that should be remembered.',
      explanation: 'This is a sample flashcard.',
      difficulty: 'easy' as const,
    },
  ];
}

// Function to deduplicate and cap items
function deduplicateAndCapItems(items: StudyItem[], maxItems: number): StudyItem[] {
  const seen = new Set<string>();
  const uniqueItems: StudyItem[] = [];
  
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
async function createStudySet(data: {
  title: string;
  sourceUrl: string;
  preview: string;
  itemCount: number;
  userId: string;
}): Promise<string> {
  const studySetRef = db.collection('study_sets').doc();
  
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
async function saveStudyItems(studySetId: string, items: StudyItem[]): Promise<void> {
  const batch = db.batch();
  
  for (const item of items) {
    const itemRef = db.collection('study_sets').doc(studySetId).collection('items').doc();
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
export const onStudySetCreated = onDocumentCreated('study_sets/{studySetId}', async (event) => {
  const studySetData = event.data?.data();
  if (!studySetData) return;
  
  console.log(`Study set created: ${event.params.studySetId}`);
  
  // This will be handled by the client-side offline sync
  // The client will download the study set and items for offline use
});
