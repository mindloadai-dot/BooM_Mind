import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';

// Define secrets
const openaiApiKey = defineSecret('OPENAI_API_KEY');

/**
 * Generate flashcards using OpenAI
 */
export const generateFlashcards = onCall(
  { secrets: [openaiApiKey] },
  async (request) => {
    try {
      const { content, count = 10, difficulty = 'mixed' } = request.data;
      
      if (!content || typeof content !== 'string') {
        throw new HttpsError('invalid-argument', 'Content is required');
      }

      // Validate count
      const flashcardCount = Math.min(Math.max(parseInt(count), 1), 20);
      
      const apiKey = openaiApiKey.value();
      if (!apiKey) {
        logger.error('OpenAI API key not configured');
        throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
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
        logger.error('OpenAI API error:', response.status, response.statusText);
        throw new HttpsError('internal', 'OpenAI API request failed');
      }

      const data = await response.json() as any;
      const aiResponse = data.choices?.[0]?.message?.content;
      
      if (aiResponse) {
        try {
          const flashcards = JSON.parse(aiResponse);
          if (Array.isArray(flashcards)) {
            return { flashcards };
          }
        } catch (parseError) {
          logger.error('Error parsing AI response:', parseError);
        }
      }

      // AI response is invalid
      throw new HttpsError('internal', 'Invalid AI response format');

    } catch (error) {
      logger.error('Error generating flashcards:', error);
      throw new HttpsError('internal', 'Failed to generate flashcards');
    }
  }
);

/**
 * Generate quiz using OpenAI
 */
export const generateQuiz = onCall(
  { secrets: [openaiApiKey] },
  async (request) => {
    try {
      const { content, questionCount = 5, type = 'multipleChoice' } = request.data;
      
      if (!content || typeof content !== 'string') {
        throw new HttpsError('invalid-argument', 'Content is required');
      }

      const quizQuestionCount = Math.min(Math.max(parseInt(questionCount), 1), 10);
      
      const apiKey = openaiApiKey.value();
      if (!apiKey) {
        logger.error('OpenAI API key not configured');
        throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
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
        logger.error('OpenAI API error:', response.status, response.statusText);
        throw new HttpsError('internal', 'OpenAI API request failed');
      }

      const data = await response.json() as any;
      const aiResponse = data.choices?.[0]?.message?.content;
      
      if (aiResponse) {
        try {
          const quiz = JSON.parse(aiResponse);
          if (quiz && quiz.questions && Array.isArray(quiz.questions)) {
            return { quiz };
          }
        } catch (parseError) {
          logger.error('Error parsing AI response:', parseError);
        }
      }

      // AI response is invalid
      throw new HttpsError('internal', 'Invalid AI response format');

    } catch (error) {
      logger.error('Error generating quiz:', error);
      throw new HttpsError('internal', 'Failed to generate quiz');
    }
  }
);

/**
 * Process content with AI (comprehensive processing)
 */
export const processWithAI = onCall(
  { secrets: [openaiApiKey] },
  async (request) => {
    try {
      const { 
        pdfUrl, 
        generateQuestions = true, 
        generateFlashcards = true, 
        generateSummary = true,
        customInstructions 
      } = request.data;
      
      if (!pdfUrl || typeof pdfUrl !== 'string') {
        throw new HttpsError('invalid-argument', 'PDF URL is required');
      }

      // First, extract text from PDF (this would need a PDF processing service)
      const content = await extractTextFromPDF(pdfUrl);
      
      const results: any = {
        message: 'Content processed successfully',
      };

      const apiKey = openaiApiKey.value();
      
      if (generateSummary) {
        if (apiKey) {
          results.summary = await generateAISummary(content, customInstructions);
        } else {
          throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
        }
      }

      if (generateFlashcards) {
        if (apiKey) {
          const flashcardResult = await generateFlashcards.run({ data: { content, count: 10 } });
          results.flashcards = flashcardResult.flashcards;
        } else {
          throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
        }
      }

      if (generateQuestions) {
        if (apiKey) {
          const quizResult = await generateQuiz.run({ data: { content, questionCount: 5 } });
          results.questions = quizResult.quiz.questions;
        } else {
          throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
        }
      }

      return results;

    } catch (error) {
      logger.error('Error processing with AI:', error);
      throw new HttpsError('internal', 'Failed to process content');
    }
  }
);

// Helper functions
async function extractTextFromPDF(pdfUrl: string): Promise<string> {
  // This would integrate with a PDF processing service
  // For now, return a placeholder
  return 'Extracted text content from PDF would go here...';
}

async function generateAISummary(content: string, customInstructions?: string): Promise<string> {
  const apiKey = openaiApiKey.value();
  if (!apiKey) {
    throw new HttpsError('failed-precondition', 'OpenAI API key not configured');
  }

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
      const data = await response.json() as any;
      return data.choices?.[0]?.message?.content || 'Summary generation failed';
    }
  } catch (error) {
    logger.error('Error generating AI summary:', error);
  }

  throw new HttpsError('internal', 'Failed to generate summary');
}






