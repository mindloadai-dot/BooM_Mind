const { initializeApp } = require('firebase/app');
const { getFunctions, httpsCallable } = require('firebase/functions');

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBc4x8_kfzwLWHk_twksK1DfZUC_S-qCoc",
  authDomain: "lca5kr3efmasxydmsi1rvyjoizifj4.firebaseapp.com",
  projectId: "lca5kr3efmasxydmsi1rvyjoizifj4",
  storageBucket: "lca5kr3efmasxydmsi1rvyjoizifj4.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const functions = getFunctions(app, 'us-central1');

async function testGenerateFlashcards() {
  try {
    console.log('🧪 Testing generateFlashcards function...');
    
    const generateFlashcardsFunction = httpsCallable(functions, 'generateFlashcards');
    const result = await generateFlashcardsFunction({
      content: "The human brain is the command center for the human nervous system. It receives signals from the body's sensory organs and outputs information to the muscles. The human brain has the same basic structure as other mammal brains but is larger in relation to body size than any other brains.",
      count: 5,
      difficulty: "intermediate"
    });
    
    console.log('✅ generateFlashcards test successful!');
    console.log('Response:', result.data);
    
  } catch (error) {
    console.error('❌ generateFlashcards test failed:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error details:', error.details);
  }
}

// Run the test
testGenerateFlashcards();
