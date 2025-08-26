// Simple test to verify functions deployment
console.log('Testing Firebase Functions deployment...');

// Test TypeScript compilation
try {
  const functions = require('./lib/index');
  console.log('✅ Functions compiled successfully');
  console.log('Available functions:', Object.keys(functions));
} catch (error) {
  console.error('❌ Functions compilation failed:', error.message);
  process.exit(1);
}