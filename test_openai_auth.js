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

async function testOpenAI() {
  try {
    console.log('🧪 Testing OpenAI authentication...');
    
    const testOpenAIFunction = httpsCallable(functions, 'testOpenAI');
    const result = await testOpenAIFunction();
    
    console.log('✅ OpenAI test successful!');
    console.log('Response:', result.data);
    
  } catch (error) {
    console.error('❌ OpenAI test failed:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error details:', error.details);
  }
}

// Run the test
testOpenAI();
