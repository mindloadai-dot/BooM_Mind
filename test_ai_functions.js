// Test script for OpenAI AI functions
const { initializeApp } = require('firebase/app');
const { getFunctions, httpsCallable } = require('firebase/functions');

// Firebase configuration (replace with your actual config)
const firebaseConfig = {
  // Your Firebase config here
  projectId: "lca5kr3efmasxydmsi1rvyjoizifj4",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const functions = getFunctions(app);

async function testOpenAIFunctions() {
  console.log('🧪 Testing OpenAI AI Functions...');
  
  const testContent = `
The Amazon rainforest is the largest rainforest in the world, covering an area of about 5.5 million square kilometers. 
It is home to an incredible diversity of wildlife, including jaguars, sloths, and anacondas. 
The Amazon River, which flows through the rainforest, is the second-longest river in the world. 
Deforestation is a major threat to the Amazon, primarily due to cattle ranching and agriculture.
The rainforest plays a crucial role in regulating global climate and produces about 20% of the world's oxygen.
Indigenous communities have lived in the Amazon for thousands of years, developing sustainable practices.
  `;

  try {
    // Test OpenAI Authentication
    console.log('\n🔐 Testing OpenAI Authentication...');
    const testOpenAI = httpsCallable(functions, 'testOpenAI');
    const authResult = await testOpenAI();
    console.log('✅ OpenAI Authentication Test:', authResult.data.success ? 'PASSED' : 'FAILED');
    
    // Test Flashcards Generation
    console.log('\n🃏 Testing Flashcards Generation...');
    const generateFlashcards = httpsCallable(functions, 'generateFlashcards');
    const flashcardResult = await generateFlashcards({
      content: testContent,
      count: 3,
      difficulty: 'intermediate'
    });
    console.log('✅ Flashcards Generation:', flashcardResult.data.flashcards ? 'PASSED' : 'FAILED');
    console.log(`📊 Generated ${flashcardResult.data.flashcards?.length || 0} flashcards`);
    
    // Test Quiz Generation
    console.log('\n❓ Testing Quiz Generation...');
    const generateQuiz = httpsCallable(functions, 'generateQuiz');
    const quizResult = await generateQuiz({
      content: testContent,
      count: 3,
      difficulty: 'intermediate'
    });
    console.log('✅ Quiz Generation:', quizResult.data.questions ? 'PASSED' : 'FAILED');
    console.log(`📊 Generated ${quizResult.data.questions?.length || 0} quiz questions`);
    
    console.log('\n🎉 All AI Function Tests Completed!');
    
  } catch (error) {
    console.error('❌ Test Failed:', error.message);
    console.error('🔍 Error Details:', error);
  }
}

// Run the test
testOpenAIFunctions();
