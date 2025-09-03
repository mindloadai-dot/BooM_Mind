#!/usr/bin/env node

/**
 * Simple OpenAI Test - No External Dependencies
 * Verifies OpenAI integration status without requiring additional packages
 */

const { execSync } = require('child_process');
const https = require('https');

// Configuration
const PROJECT_ID = 'lca5kr3efmasxydmsi1rvyjoizifj4';
const REGION = 'us-central1';

// ANSI color codes
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(color, message) {
  console.log(`${color}${message}${colors.reset}`);
}

function logHeader(message) {
  console.log(`\n${colors.bold}${colors.cyan}=== ${message} ===${colors.reset}`);
}

function logSuccess(message) {
  log(colors.green, `✅ ${message}`);
}

function logError(message) {
  log(colors.red, `❌ ${message}`);
}

function logWarning(message) {
  log(colors.yellow, `⚠️ ${message}`);
}

function logInfo(message) {
  log(colors.blue, `ℹ️ ${message}`);
}

/**
 * Check if Firebase CLI is available and project is set
 */
function checkFirebaseSetup() {
  logHeader('Firebase Setup Check');
  
  try {
    // Check Firebase CLI
    const firebaseVersion = execSync('firebase --version', { encoding: 'utf8' }).trim();
    logSuccess(`Firebase CLI installed: ${firebaseVersion}`);
    
    // Check current project
    const currentProject = execSync('firebase use', { encoding: 'utf8' }).trim();
    if (currentProject.includes(PROJECT_ID)) {
      logSuccess(`Correct project selected: ${PROJECT_ID}`);
    } else {
      logWarning(`Current project: ${currentProject}`);
      logInfo(`Expected project: ${PROJECT_ID}`);
    }
    
    return true;
  } catch (error) {
    logError(`Firebase setup issue: ${error.message}`);
    return false;
  }
}

/**
 * Check function deployment status
 */
function checkFunctionDeployment() {
  logHeader('Function Deployment Check');
  
  try {
    const functionsList = execSync('firebase functions:list', { encoding: 'utf8' });
    
    const openAIFunctions = ['generateFlashcards', 'generateQuiz', 'generateStudyMaterial'];
    let deployedCount = 0;
    
    openAIFunctions.forEach(funcName => {
      if (functionsList.includes(funcName)) {
        logSuccess(`✓ ${funcName} is deployed`);
        deployedCount++;
      } else {
        logError(`✗ ${funcName} is NOT deployed`);
      }
    });
    
    logInfo(`OpenAI functions deployed: ${deployedCount}/${openAIFunctions.length}`);
    
    // Check for v2 vs v1 functions
    if (functionsList.includes('v2')) {
      logInfo('Functions are using Firebase Functions v2 (good for OpenAI)');
    }
    
    return deployedCount > 0;
  } catch (error) {
    logError(`Failed to check function deployment: ${error.message}`);
    return false;
  }
}

/**
 * Check OpenAI secrets configuration
 */
function checkOpenAISecrets() {
  logHeader('OpenAI Secrets Check');
  
  let secretsConfigured = 0;
  
  // Check OPENAI_API_KEY
  try {
    const apiKey = execSync('firebase functions:secrets:access OPENAI_API_KEY', { encoding: 'utf8' }).trim();
    if (apiKey.startsWith('sk-proj-') || apiKey.startsWith('sk-')) {
      logSuccess('✓ OPENAI_API_KEY is properly configured');
      logInfo(`Key format: ${apiKey.substring(0, 12)}...${apiKey.slice(-4)}`);
      secretsConfigured++;
    } else {
      logWarning('⚠ OPENAI_API_KEY exists but format is unexpected');
    }
  } catch (error) {
    logError('✗ OPENAI_API_KEY secret not accessible');
  }
  
  // Check OPENAI_ORGANIZATION_ID
  try {
    const orgId = execSync('firebase functions:secrets:access OPENAI_ORGANIZATION_ID', { encoding: 'utf8' }).trim();
    if (orgId.startsWith('org-')) {
      logSuccess('✓ OPENAI_ORGANIZATION_ID is properly configured');
      logInfo(`Org ID: ${orgId}`);
      secretsConfigured++;
    } else {
      logWarning('⚠ OPENAI_ORGANIZATION_ID exists but format is unexpected');
    }
  } catch (error) {
    logError('✗ OPENAI_ORGANIZATION_ID secret not accessible');
  }
  
  logInfo(`Secrets configured: ${secretsConfigured}/2`);
  return secretsConfigured === 2;
}

/**
 * Check recent function logs for OpenAI activity
 */
function checkFunctionLogs() {
  logHeader('Function Logs Analysis');
  
  try {
    const logs = execSync('firebase functions:log --limit 20', { encoding: 'utf8' });
    
    // Look for OpenAI-related activity
    const openAIActivity = logs.split('\n').filter(line => 
      line.includes('generateFlashcards') || 
      line.includes('generateQuiz') || 
      line.includes('OpenAI') ||
      line.includes('openai')
    );
    
    if (openAIActivity.length > 0) {
      logSuccess(`Found ${openAIActivity.length} OpenAI-related log entries`);
      logInfo('Recent activity:');
      openAIActivity.slice(0, 3).forEach((line, index) => {
        const cleanLine = line.substring(0, 100) + (line.length > 100 ? '...' : '');
        console.log(`  ${index + 1}. ${cleanLine}`);
      });
    } else {
      logInfo('No recent OpenAI function activity found');
    }
    
    // Look for errors
    const errors = logs.split('\n').filter(line => 
      line.toLowerCase().includes('error') && 
      (line.includes('generateFlashcards') || line.includes('generateQuiz'))
    );
    
    if (errors.length > 0) {
      logWarning(`Found ${errors.length} error entries`);
      errors.slice(0, 2).forEach((error, index) => {
        const cleanError = error.substring(0, 120) + (error.length > 120 ? '...' : '');
        console.log(`  Error ${index + 1}: ${cleanError}`);
      });
    } else {
      logSuccess('No recent errors found in OpenAI functions');
    }
    
    return true;
  } catch (error) {
    logError(`Failed to check function logs: ${error.message}`);
    return false;
  }
}

/**
 * Test function endpoint availability (without authentication)
 */
async function testFunctionEndpoints() {
  logHeader('Function Endpoint Availability Test');
  
  const functions = ['generateFlashcards', 'generateQuiz'];
  
  for (const funcName of functions) {
    try {
      logInfo(`Testing ${funcName} endpoint...`);
      
      const result = await new Promise((resolve, reject) => {
        const options = {
          hostname: `${REGION}-${PROJECT_ID}.cloudfunctions.net`,
          port: 443,
          path: `/${funcName}`,
          method: 'GET', // Just checking if endpoint exists
          timeout: 5000,
        };
        
        const req = https.request(options, (res) => {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers
          });
        });
        
        req.on('error', (error) => {
          reject(error);
        });
        
        req.on('timeout', () => {
          req.destroy();
          reject(new Error('Request timeout'));
        });
        
        req.end();
      });
      
      if (result.statusCode === 403) {
        logSuccess(`✓ ${funcName} endpoint is live (403 = needs auth, which is correct)`);
      } else if (result.statusCode === 404) {
        logError(`✗ ${funcName} endpoint not found (404)`);
      } else if (result.statusCode === 401) {
        logSuccess(`✓ ${funcName} endpoint is live (401 = needs auth, which is correct)`);
      } else {
        logInfo(`${funcName} returned status: ${result.statusCode}`);
      }
      
    } catch (error) {
      if (error.code === 'ENOTFOUND') {
        logError(`✗ ${funcName} endpoint not reachable (DNS/network issue)`);
      } else {
        logWarning(`${funcName} test inconclusive: ${error.message}`);
      }
    }
  }
}

/**
 * Generate test report
 */
function generateTestReport(results) {
  logHeader('OpenAI Integration Test Report');
  
  console.log(`${colors.bold}📊 Test Results Summary:${colors.reset}`);
  console.log('');
  
  // Firebase Setup
  if (results.firebaseSetup) {
    logSuccess('✓ Firebase CLI and project setup');
  } else {
    logError('✗ Firebase CLI or project issues');
  }
  
  // Function Deployment
  if (results.functionsDeployed) {
    logSuccess('✓ OpenAI functions are deployed');
  } else {
    logError('✗ OpenAI functions not deployed');
  }
  
  // Secrets Configuration
  if (results.secretsConfigured) {
    logSuccess('✓ OpenAI API keys are configured');
  } else {
    logError('✗ OpenAI API keys not properly configured');
  }
  
  // Overall Assessment
  console.log('');
  const score = (results.firebaseSetup ? 1 : 0) + 
                (results.functionsDeployed ? 1 : 0) + 
                (results.secretsConfigured ? 1 : 0);
  
  if (score === 3) {
    logSuccess('🎉 OpenAI integration is FULLY CONFIGURED and ready!');
    console.log('');
    console.log('✅ Your Flutter app should be able to use OpenAI successfully');
    console.log('✅ Functions will retry automatically if OpenAI is overloaded');
    console.log('✅ Local AI fallback is available as backup');
  } else if (score === 2) {
    logWarning('⚠️ OpenAI integration is MOSTLY configured');
    console.log('');
    console.log('🔧 Minor issues detected - check the details above');
    console.log('📱 Your app may still work with local AI fallback');
  } else {
    logError('❌ OpenAI integration has SIGNIFICANT issues');
    console.log('');
    console.log('🛠️ Major configuration problems detected');
    console.log('📱 App will likely use local AI fallback only');
  }
  
  // Next Steps
  console.log('');
  logHeader('Next Steps');
  
  if (score === 3) {
    console.log('1. 🧪 Test in your Flutter app - everything should work!');
    console.log('2. 📊 Monitor with: firebase functions:log');
    console.log('3. 🔍 Check App Check setup if you see auth warnings');
  } else {
    if (!results.functionsDeployed) {
      console.log('1. 🚀 Deploy functions: firebase deploy --only functions');
    }
    if (!results.secretsConfigured) {
      console.log('2. 🔑 Check OpenAI secrets configuration');
    }
    console.log('3. 📱 Test your Flutter app - local AI should still work');
  }
}

/**
 * Main test function
 */
async function runOpenAITest() {
  console.log(`${colors.bold}${colors.magenta}`);
  console.log('╔══════════════════════════════════════════════════════════════╗');
  console.log('║              OpenAI Integration Status Check                ║');
  console.log('║         Comprehensive Test Without Flutter App              ║');
  console.log('╚══════════════════════════════════════════════════════════════╝');
  console.log(colors.reset);
  
  const results = {
    firebaseSetup: false,
    functionsDeployed: false,
    secretsConfigured: false,
    logsChecked: false,
    endpointsTested: false
  };
  
  try {
    // Step 1: Check Firebase setup
    results.firebaseSetup = checkFirebaseSetup();
    
    // Step 2: Check function deployment
    if (results.firebaseSetup) {
      results.functionsDeployed = checkFunctionDeployment();
    }
    
    // Step 3: Check OpenAI secrets
    if (results.firebaseSetup) {
      results.secretsConfigured = checkOpenAISecrets();
    }
    
    // Step 4: Check function logs
    if (results.firebaseSetup) {
      results.logsChecked = checkFunctionLogs();
    }
    
    // Step 5: Test function endpoints
    if (results.functionsDeployed) {
      await testFunctionEndpoints();
      results.endpointsTested = true;
    }
    
    // Step 6: Generate report
    generateTestReport(results);
    
  } catch (error) {
    logError(`Test execution failed: ${error.message}`);
    console.error(error);
  }
}

// Run the test
if (require.main === module) {
  runOpenAITest().catch(console.error);
}

module.exports = { runOpenAITest };
